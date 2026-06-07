import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/config_store.dart';
import '../services/github_service.dart';
import '../theme/app_theme.dart';

enum _Phase { uploading, triggering, waiting, done, error }

/// Drives one signing job: (optionally upload) → trigger → poll steps → install.
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

  _Phase _phase = _Phase.triggering;
  double _uploadFrac = 0;
  SignStatus _status = SignStatus.queued;
  List<JobStep> _steps = const [];
  String? _runTag;
  int? _runId;
  String? _runUrl;
  String? _error;

  DateTime? _triggeredAt;
  int _etaSeconds = 40;
  int _elapsed = 0;
  Timer? _ticker;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    ConfigStore.instance.lastSignSeconds.then((v) => _etaSeconds = max(20, v));
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
        if (bytes == null) throw 'Could not read file bytes.';
        setState(() => _phase = _Phase.uploading);
        _say('Preparing upload: ${file.name}');
        url = await _gh.uploadUnsignedIpa(
          fileName: file.name,
          bytes: bytes,
          onStage: _say,
          onProgress: (f) => setState(() => _uploadFrac = f),
        );
        _say('Uploaded ✓');
      }

      if (url == null || url.isEmpty) throw 'No IPA source provided.';

      setState(() => _phase = _Phase.triggering);
      _say('Triggering signing workflow…');
      final tag = await _gh.triggerSign(ipaUrl: url, appName: widget.appName);
      setState(() {
        _runTag = tag;
        _phase = _Phase.waiting;
        _triggeredAt = DateTime.now();
      });
      _say('Triggered: $tag');

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    } catch (e) {
      setState(() {
        _error = e.toString();
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _onTick() async {
    _tick++;
    if (_triggeredAt != null) {
      setState(() =>
          _elapsed = DateTime.now().difference(_triggeredAt!).inSeconds);
    }
    // Poll the API every 3s (cheap on rate limit, responsive enough).
    if (_tick % 3 != 0) return;
    try {
      final run = await _gh.pollRun(_runTag!);
      List<JobStep> steps = _steps;
      if (run.runId != null) steps = await _gh.pollJobSteps(run.runId!);
      if (!mounted) return;
      setState(() {
        _status = run.status;
        _runId = run.runId ?? _runId;
        _runUrl = run.htmlUrl ?? _runUrl;
        _steps = steps;
      });
      if (run.isTerminal) {
        _ticker?.cancel();
        if (run.status == SignStatus.success) {
          setState(() => _phase = _Phase.done);
          _say('Signed ✓ — ready to install.');
          if (_triggeredAt != null) {
            ConfigStore.instance.setLastSignSeconds(
                DateTime.now().difference(_triggeredAt!).inSeconds);
          }
        } else {
          setState(() {
            _phase = _Phase.error;
            _error = 'Workflow ${run.status.name}. '
                'Open the run log on GitHub for the full output.';
          });
        }
      }
    } catch (e) {
      _say('Poll error: $e');
    }
  }

  // ── Progress model ─────────────────────────────────────────────────────────
  double get _progress {
    if (_status == SignStatus.success || _phase == _Phase.done) return 1;
    if (_phase == _Phase.uploading) return 0.04 + 0.20 * _uploadFrac;
    if (_phase == _Phase.triggering) return 0.25;
    // waiting/running: blend time-based estimate with step completion.
    double t = 0.27 + 0.68 * (_elapsed / _etaSeconds);
    if (_steps.isNotEmpty) {
      final done = _steps.where((s) => s.status == 'completed').length;
      t = max(t, 0.27 + 0.68 * (done / _steps.length));
    }
    return t.clamp(0.04, 0.96);
  }

  String get _etaText {
    if (_phase == _Phase.done) return 'Done';
    if (_phase == _Phase.error) return '—';
    if (_phase == _Phase.uploading) {
      return 'Uploading ${(_uploadFrac * 100).round()}%';
    }
    final remaining = _etaSeconds - _elapsed;
    if (remaining > 1) return '~${remaining}s remaining';
    return 'Almost done…';
  }

  String get _phaseLabel => switch (_phase) {
        _Phase.uploading => 'Uploading',
        _Phase.triggering => 'Starting',
        _Phase.waiting => switch (_status) {
            SignStatus.queued => 'Queued',
            SignStatus.running => 'Signing',
            _ => 'Working',
          },
        _Phase.done => 'Signed',
        _Phase.error => 'Failed',
      };

  Color get _phaseColor => switch (_phase) {
        _Phase.done => const Color(0xFF30D158),
        _Phase.error => const Color(0xFFFF453A),
        _ => kAccent,
      };

  // ── Copy helpers ────────────────────────────────────────────────────────────
  String get _fullLog => [
        if (_runTag != null) 'run_tag: $_runTag',
        if (_runUrl != null) 'run_url: $_runUrl',
        'phase: ${_phase.name}  status: ${_status.name}  elapsed: ${_elapsed}s',
        '',
        '── steps ──',
        for (final s in _steps)
          '${_stepGlyph(s)} ${s.name}'
              '${s.conclusion != null ? " (${s.conclusion})" : ""}',
        '',
        '── log ──',
        ..._log,
        if (_error != null) '\n── error ──\n$_error',
      ].join('\n');

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what copied'), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _install() async {
    final installUrl = await _gh.installUrlFor(_runTag!);
    await launchUrl(Uri.parse(installUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> _openRun() async {
    if (_runUrl != null) {
      await launchUrl(Uri.parse(_runUrl!), mode: LaunchMode.externalApplication);
    }
  }

  String _stepGlyph(JobStep s) {
    if (s.status != 'completed') {
      return s.status == 'in_progress' ? '▶' : '·';
    }
    return switch (s.conclusion) {
      'success' => '✓',
      'skipped' => '⊘',
      _ => '✗',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(widget.appName ?? 'Sign',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          GlassIconButton(
            icon: const Icon(Icons.ios_share, size: 20),
            onPressed: () => _copy(_fullLog, 'Log'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _progressCard(dark),
              const SizedBox(height: 14),
              Expanded(child: _consoleCard(dark)),
              const SizedBox(height: 14),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressCard(bool dark) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _phaseDot(),
              const SizedBox(width: 10),
              Text(_phaseLabel,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _phaseColor)),
              const Spacer(),
              Text('${(_progress * 100).round()}%',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: dark ? Colors.white70 : Colors.black54)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: double.infinity,
              child: GlassProgressIndicator.linear(
                value: _phase == _Phase.error ? null : _progress,
                height: 8,
                color: _phaseColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(_etaText,
              style: TextStyle(
                  fontSize: 13,
                  color: dark ? Colors.white60 : Colors.black45)),
        ],
      ),
    );
  }

  Widget _phaseDot() {
    if (_phase == _Phase.done) {
      return const Icon(Icons.check_circle, color: Color(0xFF30D158), size: 24);
    }
    if (_phase == _Phase.error) {
      return const Icon(Icons.error, color: Color(0xFFFF453A), size: 24);
    }
    return const SizedBox(
      width: 20,
      height: 20,
      child: GlassProgressIndicator.circular(size: 20, strokeWidth: 2.5),
    );
  }

  Widget _consoleCard(bool dark) {
    final mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.5,
      color: dark ? Colors.white : Colors.black87,
    );
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal,
                  size: 16, color: dark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 6),
              Text('Console',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white54 : Colors.black45)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_all, size: 18),
                tooltip: 'Copy console',
                onPressed: () => _copy(_fullLog, 'Console'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in _steps) _stepRow(s, mono),
                  if (_steps.isNotEmpty) const SizedBox(height: 8),
                  SelectableText(
                    [..._log, if (_error != null) '\nERROR:\n$_error']
                        .join('\n'),
                    style: mono,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(JobStep s, TextStyle mono) {
    final (icon, color) = switch ((s.status, s.conclusion)) {
      ('completed', 'success') => (Icons.check_circle, const Color(0xFF30D158)),
      ('completed', 'skipped') => (Icons.remove_circle, Colors.grey),
      ('completed', _) => (Icons.cancel, const Color(0xFFFF453A)),
      ('in_progress', _) => (Icons.autorenew, kAccent),
      _ => (Icons.circle_outlined, Colors.grey),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(s.name, style: mono)),
        ],
      ),
    );
  }

  Widget _actions() {
    if (_phase == _Phase.done) {
      return _PillButton(
        label: 'Install on this device',
        icon: Icons.install_mobile,
        color: const Color(0xFF30D158),
        onTap: _install,
      );
    }
    if (_phase == _Phase.error) {
      return Column(
        children: [
          _PillButton(
            label: 'Copy error',
            icon: Icons.copy,
            color: const Color(0xFFFF453A),
            onTap: () => _copy(_error ?? _fullLog, 'Error'),
          ),
          if (_runUrl != null)
            TextButton.icon(
              onPressed: _openRun,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open run on GitHub'),
            ),
        ],
      );
    }
    if (_runUrl != null) {
      return TextButton.icon(
        onPressed: _openRun,
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Open run on GitHub'),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Full-width prominent glass action button.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 18),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
