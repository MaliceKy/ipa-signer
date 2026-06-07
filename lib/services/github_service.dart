import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import 'config_store.dart';

/// One step of the running workflow job (for the live console).
class JobStep {
  JobStep(this.name, this.status, this.conclusion);
  final String name;
  final String status; // queued | in_progress | completed
  final String? conclusion; // success | failure | skipped | null
}

const _workflowFile = 'sign-ipa.yml';

/// High-level status of a signing run.
enum SignStatus { queued, running, success, failure, cancelled, unknown }

class SignRun {
  SignRun({
    required this.runTag,
    required this.status,
    this.runId,
    this.htmlUrl,
  });

  final String runTag;
  final SignStatus status;
  final int? runId;
  final String? htmlUrl;

  bool get isTerminal =>
      status == SignStatus.success ||
      status == SignStatus.failure ||
      status == SignStatus.cancelled;
}

/// Thin client over the GitHub REST API for triggering and tracking the
/// signing workflow, plus uploading IPAs the user picked on-device.
class GitHubService {
  GitHubService(this._cfg);

  final ConfigStore _cfg;

  Future<Map<String, String>> _headers({String? accept}) async {
    final token = await _cfg.token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': accept ?? 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };
  }

  Future<String> get _slug async => '${await _cfg.owner}/${await _cfg.repo}';

  static String newRunTag() {
    final rnd = Random.secure();
    final suffix = List.generate(6, (_) => rnd.nextInt(16).toRadixString(16)).join();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'sign-$ts-$suffix';
  }

  /// Verifies the token + repo are reachable. Returns null on success or an
  /// error message.
  Future<String?> verify() async {
    final slug = await _slug;
    final res = await http.get(
      Uri.parse('https://api.github.com/repos/$slug'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return null;
    if (res.statusCode == 401) return 'Bad token (401). Check your PAT.';
    if (res.statusCode == 404) {
      return 'Repo not found (404). Check owner/repo and that the token can see it.';
    }
    return 'GitHub error ${res.statusCode}: ${res.body}';
  }

  /// Uploads an unsigned IPA to a throwaway release and returns the API asset
  /// URL the workflow can download (works for private repos).
  Future<String> uploadUnsignedIpa({
    required String fileName,
    required Uint8List bytes,
    void Function(String stage)? onStage,
    void Function(double fraction)? onProgress,
  }) async {
    final slug = await _slug;
    final tag = 'src-${DateTime.now().millisecondsSinceEpoch}';

    onStage?.call('Creating upload release…');
    final relRes = await http.post(
      Uri.parse('https://api.github.com/repos/$slug/releases'),
      headers: await _headers(),
      body: jsonEncode({
        'tag_name': tag,
        'name': 'upload $tag',
        'body': 'Unsigned IPA upload (source).',
        'prerelease': true,
      }),
    );
    if (relRes.statusCode != 201) {
      throw GitHubException('Could not create upload release', relRes);
    }
    final rel = jsonDecode(relRes.body) as Map<String, dynamic>;
    final releaseId = rel['id'] as int;
    final uploadUrl = (rel['upload_url'] as String).split('{').first;

    onStage?.call('Uploading ${(bytes.length / 1048576).toStringAsFixed(1)} MB…');
    // dio reports real byte-level send progress so the UI bar is accurate.
    final dio = Dio();
    try {
      final res = await dio.post(
        '$uploadUrl?name=${Uri.encodeComponent(fileName)}',
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            ...await _headers(),
            'Content-Type': 'application/octet-stream',
            'Content-Length': bytes.length,
          },
          responseType: ResponseType.json,
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      final asset = res.data as Map;
      final assetId = asset['id'] as int;
      return 'https://api.github.com/repos/$slug/releases/assets/$assetId'
          '#release=$releaseId';
    } on DioException catch (e) {
      throw 'Asset upload failed (HTTP ${e.response?.statusCode}): '
          '${e.response?.data ?? e.message}';
    }
  }

  /// Triggers the signing workflow. Returns the run_tag to track it.
  Future<String> triggerSign({
    required String ipaUrl,
    String? appName,
    String? bundleId,
  }) async {
    final slug = await _slug;
    final branch = await _cfg.branch;
    final runTag = newRunTag();
    // Strip our private "#release=" marker before sending.
    final cleanUrl = ipaUrl.split('#release=').first;

    final res = await http.post(
      Uri.parse(
        'https://api.github.com/repos/$slug/actions/workflows/$_workflowFile/dispatches',
      ),
      headers: await _headers(),
      body: jsonEncode({
        'ref': branch,
        'inputs': {
          'ipa_url': cleanUrl,
          'run_tag': runTag,
          if (appName != null && appName.isNotEmpty) 'app_name': appName,
          if (bundleId != null && bundleId.isNotEmpty) 'bundle_id': bundleId,
        },
      }),
    );
    if (res.statusCode != 204) {
      throw GitHubException('Could not trigger workflow', res);
    }
    return runTag;
  }

  /// Looks up the run whose name matches the run_tag.
  Future<SignRun> pollRun(String runTag) async {
    final slug = await _slug;
    final res = await http.get(
      Uri.parse(
        'https://api.github.com/repos/$slug/actions/workflows/$_workflowFile/runs?per_page=30',
      ),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw GitHubException('Could not list runs', res);
    }
    final runs = (jsonDecode(res.body)['workflow_runs'] as List)
        .cast<Map<String, dynamic>>();
    final match = runs.firstWhere(
      (r) => (r['name'] as String?) == 'sign-$runTag',
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) {
      return SignRun(runTag: runTag, status: SignStatus.queued);
    }
    return SignRun(
      runTag: runTag,
      runId: match['id'] as int?,
      htmlUrl: match['html_url'] as String?,
      status: _statusFrom(
        match['status'] as String?,
        match['conclusion'] as String?,
      ),
    );
  }

  /// Fetches the steps of the run's job so the UI can show a live console.
  Future<List<JobStep>> pollJobSteps(int runId) async {
    final slug = await _slug;
    final res = await http.get(
      Uri.parse('https://api.github.com/repos/$slug/actions/runs/$runId/jobs'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return const [];
    final jobs = (jsonDecode(res.body)['jobs'] as List?) ?? const [];
    if (jobs.isEmpty) return const [];
    final steps = ((jobs.first as Map)['steps'] as List?) ?? const [];
    return steps
        .whereType<Map>()
        .map((s) => JobStep(
              (s['name'] ?? '').toString(),
              (s['status'] ?? 'queued').toString(),
              s['conclusion']?.toString(),
            ))
        // Hide GitHub's noisy implicit setup/teardown steps.
        .where((s) =>
            !s.name.startsWith('Set up job') &&
            !s.name.startsWith('Post ') &&
            !s.name.startsWith('Complete job'))
        .toList();
  }

  /// The OTA install URL the user taps once signing succeeds.
  Future<String> installUrlFor(String runTag) async {
    final slug = await _slug;
    final manifest =
        'https://github.com/$slug/releases/download/$runTag/manifest.plist';
    return 'itms-services://?action=download-manifest&url=$manifest';
  }

  SignStatus _statusFrom(String? status, String? conclusion) {
    if (status == 'queued') return SignStatus.queued;
    if (status == 'in_progress') return SignStatus.running;
    if (status == 'completed') {
      switch (conclusion) {
        case 'success':
          return SignStatus.success;
        case 'cancelled':
          return SignStatus.cancelled;
        case 'failure':
        case 'timed_out':
          return SignStatus.failure;
        default:
          return SignStatus.unknown;
      }
    }
    return SignStatus.unknown;
  }
}

class GitHubException implements Exception {
  GitHubException(this.message, http.Response res)
      : detail = 'HTTP ${res.statusCode}: ${res.body}';
  final String message;
  final String detail;
  @override
  String toString() => '$message\n$detail';
}
