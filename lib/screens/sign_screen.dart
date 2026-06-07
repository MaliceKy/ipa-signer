import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/config_store.dart';
import '../services/github_service.dart';

/// Drives one signing job: (optionally upload) → trigger workflow → poll →
/// offer OTA install.
class SignScreen extends StatefulWidget {
  const SignScreen({super.key, this.ipaUrl, this.upload, this.appName});

  final String? ipaUrl;
  final PlatformFile? upload;
  final String? appName;

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  final _gh = GitHubService(ConfigStore.instance);
  final _log = <String>[];

  String? _runTag;
  String? _runUrl;
  SignStatus _status = SignStatus.queued;
  String? _error;
  Timer? _poll;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _say(String s) {
    if (mounted) setState(() => _log.add(s));
  }

  Future<void> _start() async {
    try {
      var url = widget.ipaUrl;

      if (widget.upload != null) {
        final file = widget.upload!;
        final bytes = file.bytes;
        if (bytes == null) {
          throw 'Could not read file bytes (pick again with data enabled).';
        }
        url = await _gh.uploadUnsignedIpa(
          fileName: file.name,
          bytes: bytes,
          onStage: _say,
        );
        _say('Uploaded ✓');
      }

      if (url == null || url.isEmpty) throw 'No IPA source provided.';

      _say('Triggering signing workflow…');
      final tag = await _gh.triggerSign(ipaUrl: url, appName: widget.appName);
      _say('Triggered: $tag');
      setState(() => _runTag = tag);

      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _pollOnce());
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _pollOnce() async {
    if (_runTag == null) return;
    try {
      final run = await _gh.pollRun(_runTag!);
      if (!mounted) return;
      setState(() {
        _status = run.status;
        _runUrl = run.htmlUrl ?? _runUrl;
      });
      if (run.isTerminal) {
        _poll?.cancel();
        setState(() => _done = true);
        if (run.status == SignStatus.success) {
          _say('Signed ✓ — ready to install.');
        } else {
          _say('Workflow ${run.status.name}. Open the run log for details.');
        }
      }
    } catch (e) {
      _say('Poll error: $e');
    }
  }

  Future<void> _install() async {
    final installUrl = await _gh.installUrlFor(_runTag!);
    final ok = await launchUrl(
      Uri.parse(installUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open install URL')),
      );
    }
  }

  Future<void> _openRun() async {
    if (_runUrl == null) return;
    await launchUrl(Uri.parse(_runUrl!), mode: LaunchMode.externalApplication);
  }

  ({String label, Color color, IconData icon}) get _statusDisplay {
    switch (_status) {
      case SignStatus.queued:
        return (label: 'Queued', color: Colors.amber, icon: Icons.schedule);
      case SignStatus.running:
        return (label: 'Signing…', color: Colors.lightBlue, icon: Icons.bolt);
      case SignStatus.success:
        return (
          label: 'Signed',
          color: Colors.greenAccent,
          icon: Icons.check_circle
        );
      case SignStatus.failure:
        return (label: 'Failed', color: Colors.redAccent, icon: Icons.error);
      case SignStatus.cancelled:
        return (label: 'Cancelled', color: Colors.orange, icon: Icons.cancel);
      case SignStatus.unknown:
        return (label: 'Unknown', color: Colors.grey, icon: Icons.help);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _statusDisplay;
    return Scaffold(
      appBar: AppBar(title: Text(widget.appName ?? 'Sign')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(d.icon, color: d.color, size: 28),
                const SizedBox(width: 10),
                Text(
                  d.label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: d.color,
                  ),
                ),
                const Spacer(),
                if (!_done && _error == null)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    [..._log, if (_error != null) '\nERROR:\n$_error']
                        .join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_status == SignStatus.success)
              FilledButton.icon(
                onPressed: _install,
                icon: const Icon(Icons.install_mobile),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Install on this device'),
                ),
              ),
            if (_runUrl != null)
              TextButton.icon(
                onPressed: _openRun,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open workflow run on GitHub'),
              ),
          ],
        ),
      ),
    );
  }
}
