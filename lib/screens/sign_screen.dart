import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectionArea, SelectableText;
import 'package:url_launcher/url_launcher.dart';

import '../models/sign_job.dart';
import '../services/config_store.dart';
import '../services/github_service.dart';
import '../services/library_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';

/// Pushes the Sign screen as a modal and runs the job.
Future<void> startSign(BuildContext context, SignJob job) {
  return Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute(fullscreenDialog: true, builder: (_) => SignScreen(job: job)),
  );
}

enum _Phase { uploading, starting, queued, signing, signed, failed }

class _Line {
  _Line(this.time, this.text, this.tone);
  final String time;
  final String text;
  final String tone; // neutral | ok | error | accent
}

class _Step {
  _Step(this.name, this.status); // queued|running|success|failed|skipped
  String name;
  String status;
}

class SignScreen extends StatefulWidget {
  const SignScreen({super.key, required this.job});
  final SignJob job;

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  final _gh = GitHubService(ConfigStore.instance);

  _Phase _phase = _Phase.starting;
  double _pct = 0; // displayed (eased)
  double _target = 0;
  double _uploadFrac = 0;
  final _steps = <_Step>[];
  final _lines = <_Line>[];
  String? _error;
  String? _runTag;
  int? _runId;
  String? _runUrl;
  bool _installing = false;
  bool _installed = false;

  DateTime? _triggeredAt;
  int _etaSeconds = 40;
  Timer? _poll;
  Timer? _ease;
  int _tick = 0;

  static const _stepNames = [
    'Build zsign',
    'Restore certificate & provisioning profile',
    'Download unsigned IPA',
    'Sign IPA',
    'Generate OTA manifest',
    'Publish signed IPA + manifest to a Release',
  ];

  bool get _inProgress => _phase != _Phase.signed && _phase != _Phase.failed;

  @override
  void initState() {
    super.initState();
    for (final n in _stepNames) {
      _steps.add(_Step(n, 'queued'));
    }
    ConfigStore.instance.lastSignSeconds.then((v) => _etaSeconds = max(20, v));
    _ease = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final d = _target - _pct;
      if (d.abs() < 0.2) return;
      setState(() => _pct += d * 0.16);
    });
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ease?.cancel();
    super.dispose();
  }

  void _log(String text, [String tone = 'neutral']) {
    final now = DateTime.now();
    final stamp = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    if (mounted) setState(() => _lines.add(_Line(stamp, text, tone)));
  }

  Future<void> _start() async {
    try {
      var url = widget.job.ipaUrl;
      if (widget.job.isUpload) {
        final file = widget.job.upload!;
        final bytes = file.bytes;
        if (bytes == null) throw 'Could not read file bytes.';
        setState(() {
          _phase = _Phase.uploading;
          _target = 6;
        });
        _log('Uploading ${fmtSize(bytes.length)}…', 'accent');
        url = await _gh.uploadUnsignedIpa(
          fileName: file.name,
          bytes: bytes,
          onStage: (s) => _log(s),
          onProgress: (f) => setState(() {
            _uploadFrac = f;
            _target = 6 + 19 * f;
          }),
        );
        _log('Uploaded 100% (${fmtSize(bytes.length)})', 'ok');
      }
      if (url == null || url.isEmpty) throw 'No IPA source provided.';

      setState(() {
        _phase = _Phase.starting;
        _target = max(_target, 28);
      });
      final tag = await _gh.triggerSign(
        ipaUrl: url,
        appName: widget.job.title,
        bundleId: widget.job.signedBundleId,
      );
      setState(() {
        _runTag = tag;
        _phase = _Phase.queued;
        _target = 36;
        _triggeredAt = DateTime.now();
      });
      final slug = '${await ConfigStore.instance.owner}/${await ConfigStore.instance.repo}';
      _log('Triggered: workflow_dispatch on $slug', 'neutral');

      _poll = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    } catch (e) {
      _fail(e.toString());
    }
  }

  void _fail(String msg) {
    _poll?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _error = msg;
      _target = _pct;
    });
    _log('✗ $msg', 'error');
  }

  Future<void> _onTick() async {
    _tick++;
    // time-based progress toward ETA while waiting/signing
    if (_triggeredAt != null && _inProgress) {
      final elapsed = DateTime.now().difference(_triggeredAt!).inSeconds;
      final t = 28 + 68 * (elapsed / _etaSeconds);
      _target = max(_target, t.clamp(28, 96));
    }
    if (_tick % 3 != 0) return;
    try {
      final run = await _gh.pollRun(_runTag!);
      if (run.runId != null && _phase == _Phase.queued && run.status != SignStatus.queued) {
        setState(() => _phase = _Phase.signing);
      }
      List<JobStep> apiSteps = const [];
      if (run.runId != null) apiSteps = await _gh.pollJobSteps(run.runId!);
      if (!mounted) return;
      setState(() {
        _runId = run.runId ?? _runId;
        _runUrl = run.htmlUrl ?? _runUrl;
        if (apiSteps.isNotEmpty) _mergeSteps(apiSteps);
        final done = _steps.where((s) => s.status == 'success').length;
        if (_steps.isNotEmpty) {
          _target = max(_target, (28 + 68 * (done / _steps.length)).clamp(28, 96));
        }
      });
      if (run.isTerminal) {
        _poll?.cancel();
        if (run.status == SignStatus.success) {
          setState(() {
            _phase = _Phase.signed;
            _target = 100;
            for (final s in _steps) {
              if (s.status != 'failed') s.status = 'success';
            }
          });
          _log('Done — signed IPA published ✓', 'ok');
          if (_triggeredAt != null) {
            ConfigStore.instance.setLastSignSeconds(
                DateTime.now().difference(_triggeredAt!).inSeconds);
          }
        } else {
          _fail('Workflow ${run.status.name} — open the run log on GitHub for details.');
        }
      }
    } catch (e) {
      _log('Poll error: $e', 'error');
    }
  }

  void _mergeSteps(List<JobStep> api) {
    for (final a in api) {
      final i = _steps.indexWhere((s) => s.name == a.name);
      if (i < 0) continue;
      _steps[i].status = switch ((a.status, a.conclusion)) {
        ('completed', 'success') => 'success',
        ('completed', 'skipped') => 'skipped',
        ('completed', _) => 'failed',
        ('in_progress', _) => 'running',
        _ => 'queued',
      };
    }
  }

  // ── derived display ──
  String get _phaseLabel => switch (_phase) {
        _Phase.uploading => 'Uploading',
        _Phase.starting => 'Starting',
        _Phase.queued => 'Queued',
        _Phase.signing => 'Signing',
        _Phase.signed => 'Signed',
        _Phase.failed => 'Failed',
      };

  PillTone get _pillTone => switch (_phase) {
        _Phase.queued => PillTone.amber,
        _Phase.signed => PillTone.green,
        _Phase.failed => PillTone.red,
        _ => PillTone.blue,
      };

  String get _etaText {
    switch (_phase) {
      case _Phase.failed:
        return 'Signing failed';
      case _Phase.signed:
        return _installed ? 'Installed on this device' : 'Done — ready to install';
      case _Phase.uploading:
        return 'Uploading ${(_uploadFrac * 100).round()}%';
      case _Phase.starting:
        return 'Starting workflow…';
      case _Phase.queued:
        return 'Queued — waiting for a runner';
      case _Phase.signing:
        if (_pct > 92) return 'Almost done…';
        final est = max(2, ((100 - _pct) * 0.55).round());
        return '~${est}s remaining';
    }
  }

  String get _fullLog {
    final glyph = {'queued': '○', 'running': '⟳', 'success': '✓', 'skipped': '⊘', 'failed': '✗'};
    return [
      'IPA Signer — ${widget.job.title}',
      if (_runTag != null) 'run_tag: $_runTag',
      if (_runUrl != null) 'run: $_runUrl',
      '',
      for (final s in _steps) '${glyph[s.status]} ${s.name}',
      '',
      for (final l in _lines) '[${l.time}] ${l.text}',
      if (_error != null) '\nERROR: $_error',
    ].join('\n');
  }

  Future<void> _install() async {
    setState(() => _installing = true);
    final installUrl = await _gh.installUrlFor(_runTag!);
    await launchUrl(Uri.parse(installUrl), mode: LaunchMode.externalApplication);
    // Record to Library (we can't truly know iOS finished, but the user
    // confirmed the OTA prompt; log it so it shows in Library).
    await LibraryStore.instance.recordInstall(
      name: widget.job.title,
      tint: (widget.job.tint ?? AppColors.accent).toARGB32(),
      version: widget.job.version ?? '1.0.0',
      sizeBytes: widget.job.sizeBytes ?? 0,
      sourceName: widget.job.sourceName ?? 'Sideloaded',
      bundleId: widget.job.signedBundleId,
      downloadUrl: widget.job.ipaUrl,
      runTag: _runTag!,
    );
    if (!mounted) return;
    setState(() {
      _installing = false;
      _installed = true;
    });
    showToast(context, '${widget.job.title} installing…', tone: ToastTone.ok, icon: CupertinoIcons.check_mark_circled);
  }

  Future<void> _openRun() async {
    if (_runUrl != null) await launchUrl(Uri.parse(_runUrl!), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final failed = _phase == _Phase.failed;
    final signed = _phase == _Phase.signed;
    final barColor = failed ? c.red : signed ? c.green : AppColors.accent;
    final pctColor = failed ? c.red : signed ? c.green : c.label;

    return CompactScaffold(
      title: 'Signing',
      leading: _Press2(
        onTap: () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(_inProgress ? 'Cancel' : 'Done',
              style: const TextStyle(color: AppColors.accent, fontSize: 17)),
        ),
      ),
      trailing: ChromeIconButton(
          icon: CupertinoIcons.share, onTap: () => copyToClipboard(context, _fullLog, 'Log')),
      bottomBar: _dock(c, signed, failed),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        children: [
          _progressCard(c, barColor, pctColor, failed, signed),
          const SizedBox(height: 16),
          _console(c),
          if (failed && _error != null) ...[
            const SizedBox(height: 14),
            _errorBanner(c),
          ],
        ],
      ),
    );
  }

  Widget _progressCard(AppColors c, Color barColor, Color pctColor, bool failed, bool signed) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              widget.job.tint != null
                  ? AppIcon(name: widget.job.title, tint: widget.job.tint, size: 44)
                  : Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(10)),
                      child: Icon(CupertinoIcons.doc, size: 22, color: c.labelSecondary)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.job.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline(c.label)),
                    Text(widget.job.subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.footnote(c.labelSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: _phaseLabel,
                tone: _pillTone,
                spin: _inProgress && _phase != _Phase.queued,
                dot: _phase == _Phase.queued,
                icon: signed ? CupertinoIcons.checkmark_alt : failed ? CupertinoIcons.xmark : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (failed)
            Text('Failed', style: AppType.title1(c.red))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${_pct.round()}',
                    style: TextStyle(
                        fontSize: 52,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                        color: pctColor,
                        fontFeatures: kTabular)),
                Text('%',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: pctColor)),
              ],
            ),
          const SizedBox(height: 12),
          ProgressBar(value: _pct / 100, color: barColor, indeterminate: failed),
          const SizedBox(height: 10),
          Text(_etaText,
              style: AppType.footnote(failed ? c.red : c.labelSecondary).copyWith(
                  fontWeight: FontWeight.w500, fontFeatures: kTabular)),
        ],
      ),
    );
  }

  Widget _console(AppColors c) {
    final toneColor = {
      'error': c.red,
      'ok': c.green,
      'accent': AppColors.accent,
      'neutral': c.labelSecondary,
    };
    return Container(
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.separator, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.separator, width: 0.5))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CONSOLE',
                    style: AppType.footnote(c.labelSecondary).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                _Press2(
                  onTap: () => copyToClipboard(context, _fullLog, 'Log'),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(CupertinoIcons.doc_on_doc, size: 15, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text('Copy', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 236,
            child: SingleChildScrollView(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in _steps) _stepRow(c, s),
                  if (_lines.isNotEmpty) ...[
                    Container(height: 1, color: c.separator, margin: const EdgeInsets.symmetric(vertical: 8)),
                    SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final l in _lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${l.time} ',
                                      style: TextStyle(fontFamily: AppType.mono, fontSize: 12.5, height: 20 / 12.5, color: c.labelTertiary)),
                                  Expanded(
                                    child: Text(l.text,
                                        style: TextStyle(
                                            fontFamily: AppType.mono,
                                            fontSize: 12.5,
                                            height: 20 / 12.5,
                                            color: toneColor[l.tone])),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(AppColors c, _Step s) {
    Widget glyph;
    switch (s.status) {
      case 'running':
        glyph = const CupertinoActivityIndicator(radius: 7, color: AppColors.accent);
      case 'success':
        glyph = Icon(CupertinoIcons.check_mark_circled_solid, size: 15, color: c.green);
      case 'failed':
        glyph = Icon(CupertinoIcons.xmark_circle_fill, size: 15, color: c.red);
      case 'skipped':
        glyph = Icon(CupertinoIcons.minus_circle, size: 15, color: c.labelTertiary);
      default:
        glyph = Icon(CupertinoIcons.circle, size: 15, color: c.labelTertiary);
    }
    return Opacity(
      opacity: s.status == 'queued' ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 16, child: Center(child: glyph)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(s.name,
                  style: AppType.subhead(s.status == 'failed' ? c.red : c.label).copyWith(
                      fontSize: 14, fontWeight: s.status == 'running' ? FontWeight.w600 : FontWeight.w400)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: c.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 20, color: c.red),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(_error!,
                style: TextStyle(color: c.red, fontFamily: AppType.mono, fontSize: 12.5, height: 18 / 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _dock(AppColors c, bool signed, bool failed) {
    if (!signed && !failed && _runUrl == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [c.bg, c.bg.withValues(alpha: 0)],
          stops: const [0.6, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (signed)
            PillButton(
              label: _installed ? 'Done' : 'Install on this device',
              kind: BtnKind.success,
              icon: _installed ? CupertinoIcons.checkmark_alt : CupertinoIcons.cloud_download,
              loading: _installing,
              onTap: _installed ? () => Navigator.of(context).maybePop() : _install,
            ),
          if (failed)
            PillButton(
              label: 'Copy error',
              kind: BtnKind.danger,
              icon: CupertinoIcons.doc_on_doc,
              onTap: () => copyToClipboard(context, _error ?? _fullLog, 'Error'),
            ),
          if (_runUrl != null && !_installed) ...[
            const SizedBox(height: 8),
            LinkButton(label: 'Open run on GitHub', icon: CupertinoIcons.chevron_left_slash_chevron_right, onTap: _openRun),
          ],
        ],
      ),
    );
  }
}

/// Minimal press wrapper (avoids importing the private one from components).
class _Press2 extends StatelessWidget {
  const _Press2({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
}
