import 'package:flutter/cupertino.dart';

import '../models/sign_job.dart';
import '../services/catalog_service.dart';
import '../services/config_store.dart';
import '../services/library_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'app_tile.dart';
import 'repo_screen.dart';
import 'settings_screen.dart';
import 'sources_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.themeMode, required this.onThemeChanged});
  final String themeMode;
  final ValueChanged<String> onThemeChanged;

  @override
  State<CatalogScreen> createState() => CatalogScreenState();
}

class CatalogScreenState extends State<CatalogScreen> {
  List<CatalogSource> _sources = [];
  Map<String, String> _installed = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => _loading = true);
    final urls = await ConfigStore.instance.sources;
    final sources = urls.isEmpty ? <CatalogSource>[] : await CatalogService().loadSources(urls);
    final lib = await LibraryStore.instance.library();
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _installed = {for (final l in lib) l.bundleId: l.version};
      _loading = false;
    });
  }

  String? _installedVersion(CatalogApp a) =>
      _installed[SignJob(title: a.name, subtitle: '', bundleId: a.bundleId).signedBundleId];

  void _openSettings() => Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => SettingsScreen(themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged)));
  void _openSources() => Navigator.of(context)
      .push(CupertinoPageRoute(builder: (_) => const SourcesScreen()))
      .then((_) => load());

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasApps = _sources.any((s) => s.apps.isNotEmpty);

    final List<Widget> body;
    if (_loading) {
      body = [const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator(radius: 14))))];
    } else if (_sources.isEmpty) {
      body = [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: CupertinoIcons.square_grid_2x2,
            title: 'No repositories',
            message: 'Add an AltStore source from the folder icon to start browsing apps.',
            action: LinkButton(label: 'Manage Sources', icon: CupertinoIcons.folder, onTap: _openSources),
          ),
        ),
      ];
    } else if (_query.isNotEmpty) {
      // Global search across every repo.
      final results = [
        for (final s in _sources)
          ...s.apps.where((a) =>
              a.name.toLowerCase().contains(_query) || (a.developer ?? '').toLowerCase().contains(_query))
      ];
      body = results.isEmpty
          ? [SliverToBoxAdapter(child: EmptyState(icon: CupertinoIcons.search, title: 'No results', message: 'Nothing matches “$_query”.'))]
          : [
              SliverToBoxAdapter(child: SectionHeader('${results.length} result${results.length == 1 ? '' : 's'}')),
              SliverToBoxAdapter(
                child: GroupCard(children: [
                  for (var i = 0; i < results.length; i++)
                    CatalogAppTile(app: results[i], installedVersion: _installedVersion(results[i]), last: i == results.length - 1, showSource: true, onReturn: load),
                ]),
              ),
            ];
    } else {
      body = [
        SliverToBoxAdapter(child: SectionHeader('${_sources.length} repositor${_sources.length == 1 ? 'y' : 'ies'}')),
        SliverToBoxAdapter(
          child: GroupCard(children: [
            for (var i = 0; i < _sources.length; i++) _repoRow(c, _sources[i], i == _sources.length - 1),
          ]),
        ),
        if (!hasApps)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Center(child: Text('Pull to refresh', style: AppType.caption(c.labelTertiary))),
            ),
          ),
      ];
    }

    return LargeTitleScaffold(
      title: 'Catalog',
      bottomInset: 96,
      onRefresh: load,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        ChromeIconButton(icon: CupertinoIcons.folder, onTap: _openSources),
        ChromeIconButton(icon: CupertinoIcons.gear_alt, onTap: _openSettings),
      ]),
      search: SearchField(placeholder: 'Search all apps', onChanged: (v) => setState(() => _query = v.toLowerCase())),
      slivers: body,
    );
  }

  Widget _repoRow(AppColors c, CatalogSource s, bool last) {
    final failed = s.error != null;
    return RowTile(
      last: last,
      leftInset: 72,
      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => RepoScreen(source: s))).then((_) => load()),
      leading: _repoPreview(c, s),
      trailing: Icon(CupertinoIcons.chevron_right, size: 16, color: c.labelTertiary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline(c.label)),
          const SizedBox(height: 2),
          Text(failed ? 'Failed to load' : '${s.apps.length} app${s.apps.length == 1 ? '' : 's'}',
              style: AppType.footnote(failed ? c.red : c.labelSecondary)),
        ],
      ),
    );
  }

  /// Overlapped mini icons of the repo's first apps (folder fallback).
  Widget _repoPreview(AppColors c, CatalogSource s) {
    if (s.apps.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(11)),
        child: Icon(s.error != null ? CupertinoIcons.exclamationmark_triangle : CupertinoIcons.folder, color: s.error != null ? c.red : c.labelSecondary, size: 22),
      );
    }
    final preview = s.apps.take(3).toList();
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          for (var i = preview.length - 1; i >= 0; i--)
            Positioned(
              left: i * 11.0,
              top: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: c.bgElevated, width: 1.5),
                ),
                child: AppIcon(name: preview[i].name, tint: preview[i].tintColor, iconUrl: preview[i].iconUrl, size: 32),
              ),
            ),
        ],
      ),
    );
  }
}
