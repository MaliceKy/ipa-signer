import 'package:flutter/cupertino.dart';

import '../services/catalog_service.dart';
import '../services/config_store.dart';
import '../services/github_service.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'sources_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    this.isFirstRun = false,
    this.onSaved,
  });

  final String themeMode;
  final ValueChanged<String> onThemeChanged;
  final bool isFirstRun;
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
  List<CatalogSource> _sources = [];
  late String _mode = widget.themeMode;
  bool _promptForName = false;

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
    _promptForName = await cfg.promptForName;
    final urls = await cfg.sources;
    final src = await CatalogService().loadSources(urls);
    if (mounted) setState(() => _sources = src);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final cfg = ConfigStore.instance;
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
      _status = err ?? 'Saved & verified';
    });
    if (err == null) {
      showToast(context, 'Saved & verified', tone: ToastTone.ok, icon: CupertinoIcons.check_mark_circled);
      widget.onSaved?.call();
      if (Navigator.canPop(context)) Navigator.pop(context);
    } else {
      showToast(context, err, tone: ToastTone.error, icon: CupertinoIcons.exclamationmark_circle);
    }
  }

  Future<void> _disconnect() async {
    await ConfigStore.instance.save(token: '', owner: '', repo: '', branch: 'main', sources: (await ConfigStore.instance.sources).join('\n'));
    _token.clear();
    _owner.clear();
    _repo.clear();
    if (mounted) {
      setState(() => _status = null);
      showToast(context, 'Disconnected from GitHub', icon: CupertinoIcons.trash);
    }
  }

  bool get _canVerify => _token.text.isNotEmpty && _owner.text.isNotEmpty && _repo.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final modeIndex = switch (_mode) { 'light' => 1, 'dark' => 2, _ => 0 };

    return CompactScaffold(
      title: 'Settings',
      leading: widget.isFirstRun ? const SizedBox(width: 44) : null,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          if (widget.isFirstRun)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill, size: 22, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Add your GitHub connection to start signing. These are stored securely in the iOS Keychain.',
                          style: AppType.subhead(c.label)),
                    ),
                  ],
                ),
              ),
            ),
          const SectionHeader('Appearance'),
          GroupCard(children: [
            RowTile(
              last: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Segmented3(
                options: const ['System', 'Light', 'Dark'],
                index: modeIndex,
                onChanged: (i) {
                  final m = switch (i) { 1 => 'light', 2 => 'dark', _ => 'system' };
                  setState(() => _mode = m);
                  widget.onThemeChanged(m);
                },
              ),
            ),
          ]),
          const SizedBox(height: 22),
          const SectionHeader('GitHub Connection'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                AppField(controller: _token, placeholder: 'Personal access token', icon: CupertinoIcons.lock, obscure: true, mono: true),
                const SizedBox(height: 10),
                AppField(controller: _owner, placeholder: 'Repo owner (e.g. MaliceKy)', icon: CupertinoIcons.chevron_left_slash_chevron_right, mono: true),
                const SizedBox(height: 10),
                AppField(controller: _repo, placeholder: 'Repo name (e.g. ipa-signer)', icon: CupertinoIcons.folder, mono: true),
                const SizedBox(height: 10),
                AppField(controller: _branch, placeholder: 'Branch (default: main)', icon: CupertinoIcons.chevron_left_slash_chevron_right, mono: true),
                const SizedBox(height: 12),
                PillButton(label: 'Save & verify', icon: CupertinoIcons.checkmark_shield, loading: _busy, onTap: _canVerify ? _save : null),
                if (_status != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_ok ? CupertinoIcons.check_mark_circled : CupertinoIcons.exclamationmark_circle,
                          size: 18, color: _ok ? c.green : c.red),
                      const SizedBox(width: 6),
                      Flexible(child: Text(_status!, style: AppType.subhead(_ok ? c.green : c.red).copyWith(fontWeight: FontWeight.w500))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SectionFooter('The token signs and triggers the workflow on GitHub Actions. Stored in the Keychain — never synced.'),
          const SizedBox(height: 22),
          const SectionHeader('Signing'),
          GroupCard(children: [
            RowTile(
              last: true,
              trailing: CupertinoSwitch(
                value: _promptForName,
                onChanged: (v) {
                  setState(() => _promptForName = v);
                  ConfigStore.instance.setPromptForName(v);
                },
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prompt for app name', style: AppType.body(c.label)),
                  Text('Ask for a custom name before each sign', style: AppType.footnote(c.labelSecondary)),
                ],
              ),
            ),
          ]),
          const SectionFooter('When off, catalog apps keep their real name and uploaded files keep the name baked into the IPA.'),
          const SizedBox(height: 22),
          const SectionHeader('Installed repositories'),
          GroupCard(children: [
            for (final s in _sources)
              RowTile(
                leftInset: 52,
                leading: Icon(CupertinoIcons.folder, size: 20, color: s.error != null ? c.red : c.labelSecondary),
                trailing: s.error != null
                    ? Text('Failed', style: AppType.body(c.red))
                    : Text('${s.apps.length}', style: AppType.body(c.labelSecondary)),
                child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body(c.label)),
              ),
            RowTile(
              last: true,
              onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const SourcesScreen())).then((_) => _load()),
              trailing: Icon(CupertinoIcons.chevron_right, size: 16, color: c.labelTertiary),
              child: Text('Manage Sources', style: AppType.body(AppColors.accent)),
            ),
          ]),
          if (!widget.isFirstRun) ...[
            const SizedBox(height: 28),
            GroupCard(children: [
              RowTile(
                last: true,
                onTap: _disconnect,
                child: Center(child: Text('Disconnect GitHub', style: AppType.body(c.red))),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
