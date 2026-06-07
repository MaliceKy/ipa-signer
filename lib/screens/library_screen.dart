import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/config_store.dart';
import '../services/github_service.dart';
import '../services/library_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'library_detail_screen.dart';
import 'settings_screen.dart';
import 'sources_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.themeMode, required this.onThemeChanged});
  final String themeMode;
  final ValueChanged<String> onThemeChanged;

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  List<LibraryEntry> _lib = [];
  List<SignedFile> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final lib = await LibraryStore.instance.library();
    final files = await LibraryStore.instance.files();
    if (!mounted) return;
    setState(() {
      _lib = lib;
      _files = files;
      _loading = false;
    });
  }

  Future<void> _reinstall(SignedFile f) async {
    final url = await GitHubService(ConfigStore.instance).installUrlFor(f.runTag);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _deleteFile(SignedFile f) async {
    await LibraryStore.instance.removeFile(f.runTag);
    // Also remove the signed release from GitHub (frees storage).
    GitHubService(ConfigStore.instance).deleteSignedRelease(f.runTag);
    await load();
    if (mounted) showToast(context, 'IPA file deleted', icon: CupertinoIcons.trash);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final trailing = Row(mainAxisSize: MainAxisSize.min, children: [
      ChromeIconButton(icon: CupertinoIcons.folder, onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const SourcesScreen()))),
      ChromeIconButton(icon: CupertinoIcons.gear_alt, onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => SettingsScreen(themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged)))),
    ]);

    if (!_loading && _lib.isEmpty && _files.isEmpty) {
      return LargeTitleScaffold(
        title: 'Library',
        bottomInset: 96,
        trailing: trailing,
        slivers: const [
          SliverToBoxAdapter(
            child: EmptyState(
                icon: CupertinoIcons.square_stack_3d_up,
                title: 'Nothing installed yet',
                message: 'Apps you sign and install will be logged here with their version history.'),
          ),
        ],
      );
    }

    final totalBytes = _lib.fold<int>(0, (s, l) => s + l.sizeBytes) + _files.fold<int>(0, (s, f) => s + f.sizeBytes);
    final sizeStr = fmtSize(totalBytes).split(' ');

    return LargeTitleScaffold(
      title: 'Library',
      bottomInset: 96,
      onRefresh: load,
      trailing: trailing,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
            child: Row(children: [
              _statCard(c, 'Installed', '${_lib.length}', 'apps'),
              const SizedBox(width: 12),
              _statCard(c, 'Storage used', sizeStr.isNotEmpty ? sizeStr[0] : '0', '${sizeStr.length > 1 ? sizeStr[1] : 'MB'} on device'),
            ]),
          ),
        ),
        if (_lib.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Installed apps')),
          SliverToBoxAdapter(
            child: GroupCard(children: [
              for (var i = 0; i < _lib.length; i++) _appRow(c, _lib[i], i == _lib.length - 1),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
        ],
        const SliverToBoxAdapter(child: SectionHeader('On-device .ipa files')),
        SliverToBoxAdapter(
          child: _files.isEmpty
              ? GroupCard(children: [RowTile(last: true, child: Text('No stored IPA files', style: AppType.callout(c.labelSecondary)))])
              : GroupCard(children: [
                  for (var i = 0; i < _files.length; i++) _fileRow(c, _files[i], i == _files.length - 1),
                ]),
        ),
        const SliverToBoxAdapter(child: SectionFooter('Signed IPA files stay reinstallable from their GitHub Release without re-signing.')),
      ],
    );
  }

  Widget _statCard(AppColors c, String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: c.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.separator, width: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppType.footnote(c.labelSecondary).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Text(value, style: AppType.title1(c.label).copyWith(fontFeatures: kTabular)),
            Text(sub, style: AppType.footnote(c.labelTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _appRow(AppColors c, LibraryEntry l, bool last) {
    return RowTile(
      last: last,
      leftInset: 72,
      onTap: () => Navigator.of(context)
          .push(CupertinoPageRoute(builder: (_) => LibraryDetailScreen(entry: l)))
          .then((_) => load()),
      leading: AppIcon(name: l.name, tint: l.tintColor, size: 44),
      trailing: Icon(CupertinoIcons.chevron_right, size: 16, color: c.labelTertiary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.callout(c.label).copyWith(fontWeight: FontWeight.w600)),
          Text('v${l.version} · ${fmtSize(l.sizeBytes)} · ${relTime(l.installedAt)}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.footnote(c.labelSecondary).copyWith(fontFeatures: kTabular)),
        ],
      ),
    );
  }

  Widget _fileRow(AppColors c, SignedFile f, bool last) {
    return RowTile(
      last: last,
      leftInset: 60,
      onTap: () => _reinstall(f),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(9)),
        child: Icon(CupertinoIcons.doc, size: 19, color: c.labelSecondary),
      ),
      trailing: GestureDetector(
        onTap: () => _deleteFile(f),
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(CupertinoIcons.trash, size: 20, color: c.labelTertiary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.filename, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: AppType.mono, fontSize: 14, color: c.label)),
          Text('${fmtSize(f.sizeBytes)} · ${fmtDate(f.date)} · tap to reinstall',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.footnote(c.labelSecondary).copyWith(fontFeatures: kTabular)),
        ],
      ),
    );
  }
}
