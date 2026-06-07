import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/config_store.dart';
import '../services/github_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.theme, this.onSaved});

  final ThemeController theme;
  final VoidCallback? onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _token = TextEditingController();
  final _owner = TextEditingController();
  final _repo = TextEditingController();
  final _branch = TextEditingController(text: 'main');

  bool _busy = false;
  String? _status;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = ConfigStore.instance;
    _token.text = await cfg.token ?? '';
    _owner.text = await cfg.owner ?? '';
    _repo.text = await cfg.repo ?? '';
    _branch.text = await cfg.branch;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final cfg = ConfigStore.instance;
    // Preserve existing sources; this screen no longer edits them.
    await cfg.save(
      token: _token.text,
      owner: _owner.text,
      repo: _repo.text,
      branch: _branch.text,
      sources: (await cfg.sources).join('\n'),
    );
    final err = await GitHubService(cfg).verify();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _ok = err == null;
      _status = err ?? 'Saved & verified ✓';
    });
    if (err == null) {
      widget.onSaved?.call();
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final modeIndex = switch (widget.theme.mode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _sectionLabel('APPEARANCE', dark),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: GlassSegmentedControl(
                segments: const ['System', 'Light', 'Dark'],
                selectedIndex: modeIndex,
                onSegmentSelected: (i) {
                  final m = switch (i) {
                    1 => ThemeMode.light,
                    2 => ThemeMode.dark,
                    _ => ThemeMode.system,
                  };
                  widget.theme.set(m);
                },
              ),
            ),
            const SizedBox(height: 22),
            _sectionLabel('GITHUB CONNECTION', dark),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Personal access token', dark),
                  GlassTextField(
                    controller: _token,
                    placeholder: 'ghp_… (repo + workflow scopes)',
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  _label('Repo owner', dark),
                  GlassTextField(controller: _owner, placeholder: 'MaliceKy'),
                  const SizedBox(height: 14),
                  _label('Repo name', dark),
                  GlassTextField(controller: _repo, placeholder: 'ipa-signer'),
                  const SizedBox(height: 14),
                  _label('Branch', dark),
                  GlassTextField(controller: _branch, placeholder: 'main'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _busy ? null : _save,
              child: GlassContainer(
                shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  child: _busy
                      ? const GlassProgressIndicator.circular(size: 20)
                      : const Text('Save & verify',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: kAccent)),
                ),
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: 14),
              Text(_status!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ok
                          ? const Color(0xFF30D158)
                          : const Color(0xFFFF453A))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String s, bool dark) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        child: Text(s,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: dark ? Colors.white38 : Colors.black38)),
      );

  Widget _label(String s, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(s,
            style: TextStyle(
                fontSize: 12.5,
                color: dark ? Colors.white60 : Colors.black54)),
      );
}
