import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sign_job.dart';
import '../services/config_store.dart';
import '../services/github_service.dart';
import '../services/library_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'library_detail_screen.dart';
import 'settings_screen.dart';
import 'sign_screen.dart';
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
  List<StashedIpa> _stash = [];
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final lib = await LibraryStore.instance.library();
    final files = await LibraryStore.instance.files();
    final stash = await LibraryStore.instance.stashed();
    if (!mounted) return;
    setState(() {
      _lib = lib;
      _files = files;
      _stash = stash;
      _loading = false;
    });
  }

  Future<void> _addIpa() async {
    final result = await FilePicker.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!file.name.toLowerCase().endsWith('.ipa') || file.bytes == null) {
      if (mounted) showToast(context, 'Please pick a .ipa file', tone: ToastTone.error, icon: CupertinoIcons.exclamationmark_circle);
      return;
    }
    setState(() => _adding = true);
    try {
      final marked = await GitHubService(ConfigStore.instance).uploadUnsignedIpa(
        fileName: file.name,
        bytes: file.bytes!,
        tagPrefix: 'stash-',
      );
      final signUrl = marked.split('#release=').first;
      final releaseId = int.tryParse(marked.split('#release=').last) ?? 0;
      await LibraryStore.instance.addStash(StashedIpa(
        id: 'st${DateTime.now().millisecondsSinceEpoch}',
        name: file.name,
        sizeBytes: file.size,
        date: DateTime.now().toIso8601String().substring(0, 10),
        signUrl: signUrl,
        releaseId: releaseId,
      ));
      await load();
      if (mounted) showToast(context, 'Added to Library', tone: ToastTone.ok, icon: CupertinoIcons.check_mark_circled);
    } catch (e) {
      if (mounted) showToast(context, 'Upload failed', tone: ToastTone.error, icon: CupertinoIcons.exclamationmark_circle);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _signStash(StashedIpa s) {
    startSign(
      context,
      SignJob(
        title: s.name.replaceAll('.ipa', ''),
        subtitle: 'Stashed · ${fmtSize(s.sizeBytes)}',
        sizeBytes: s.sizeBytes,
        ipaUrl: s.signUrl,
      ),
    ).then((_) => load());
  }

  Future<void> _deleteStash(StashedIpa s) async {
    await LibraryStore.instance.removeStash(s.id);
    if (s.releaseId != 0) GitHubService(ConfigStore.instance).deleteRelease(s.releaseId);
    await load();
    if (mounted) showToast(context, 'Removed', icon: CupertinoIcons.trash);
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
      _adding
          ? const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: CupertinoActivityIndicator())
          : ChromeIconButton(icon: CupertinoIcons.add, onTap: _addIpa),
      ChromeIconButton(icon: CupertinoIcons.folder, onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const SourcesScreen()))),
      ChromeIconButton(icon: CupertinoIcons.gear_alt, onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => SettingsScreen(themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged)))),
    ]);

    if (!_loading && _lib.isEmpty && _files.isEmpty && _stash.isEmpty) {
      return LargeTitleScaffold(
        title: 'Library',
        bottomInset: 96,
        trailing: trailing,
        slivers: [
          SliverToBoxAdapter(
            child: EmptyState(
                icon: CupertinoIcons.square_stack_3d_up,
                title: 'Nothing here yet',
                message: 'Sign apps to log them here, or tap + to stash an .ipa for later.',
                action: LinkButton(label: 'Add an IPA', icon: CupertinoIcons.add, onTap: _addIpa)),
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
        if (_stash.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Stashed IPAs · unsigned')),
          SliverToBoxAdapter(
            child: GroupCard(children: [
              for (var i = 0; i < _stash.length; i++) _stashRow(c, _stash[i], i == _stash.length - 1),
            ]),
          ),
          const SliverToBoxAdapter(child: SectionFooter('IPAs saved for later. Tap one to sign & install it.')),
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

  Widget _stashRow(AppColors c, StashedIpa s, bool last) {
    return RowTile(
      last: last,
      leftInset: 60,
      onTap: () => _signStash(s),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)),
        child: const Icon(CupertinoIcons.doc, size: 19, color: AppColors.accent),
      ),
      trailing: GestureDetector(
        onTap: () => _deleteStash(s),
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(CupertinoIcons.trash, size: 20, color: c.red)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: AppType.mono, fontSize: 14, color: c.label)),
          Text('${fmtSize(s.sizeBytes)} · ${fmtDate(s.date)} · tap to sign',
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
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(CupertinoIcons.trash, size: 20, color: c.red)),
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
