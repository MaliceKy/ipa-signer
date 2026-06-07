import 'package:flutter/cupertino.dart';

import '../models/sign_job.dart';
import '../services/catalog_service.dart';
import '../services/config_store.dart';
import '../services/library_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'app_detail_screen.dart';
import 'settings_screen.dart';
import 'sign_screen.dart';
import 'sources_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.themeMode, required this.onThemeChanged});
  final String themeMode;
  final ValueChanged<String> onThemeChanged;

  @override
  State<CatalogScreen> createState() => CatalogScreenState();
}

class CatalogScreenState extends State<CatalogScreen> {
  List<CatalogApp> _apps = [];
  Map<String, String> _installed = {}; // bundleId/name -> version
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => _loading = true);
    final sources = await ConfigStore.instance.sources;
    final apps = sources.isEmpty ? <CatalogApp>[] : await CatalogService().loadAll(sources);
    final lib = await LibraryStore.instance.library();
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _installed = {for (final l in lib) (l.bundleId): l.version};
      _loading = false;
    });
  }

  String? _installedVersion(CatalogApp a) {
    return _installed[SignJob(title: a.name, subtitle: '', bundleId: a.bundleId).signedBundleId];
  }

  void _openSettings() => Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => SettingsScreen(themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged)));
  void _openSources() => Navigator.of(context)
      .push(CupertinoPageRoute(builder: (_) => const SourcesScreen()))
      .then((_) => load());

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final filtered = _query.isEmpty
        ? _apps
        : _apps
            .where((a) =>
                a.name.toLowerCase().contains(_query) ||
                (a.developer ?? '').toLowerCase().contains(_query))
            .toList();

    final List<Widget> body;
    if (_loading) {
      body = [const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator(radius: 14))))];
    } else if (_apps.isEmpty) {
      body = [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: CupertinoIcons.square_grid_2x2,
            title: 'No apps yet',
            message: 'Add a source from the folder icon to browse installable apps.',
            action: LinkButton(label: 'Manage Sources', icon: CupertinoIcons.folder, onTap: _openSources),
          ),
        ),
      ];
    } else if (filtered.isEmpty) {
      body = [
        SliverToBoxAdapter(
          child: EmptyState(
              icon: CupertinoIcons.search,
              title: 'No results',
              message: 'Nothing matches “$_query”. Try a different name or developer.'),
        ),
      ];
    } else {
      body = [
        SliverToBoxAdapter(child: SectionHeader('${filtered.length} app${filtered.length == 1 ? '' : 's'}')),
        SliverToBoxAdapter(
          child: GroupCard(
            children: [
              for (var i = 0; i < filtered.length; i++)
                _appRow(c, filtered[i], i == filtered.length - 1),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Center(child: Text('Aggregated from your sources · Pull to refresh', style: AppType.caption(c.labelTertiary))),
          ),
        ),
      ];
    }

    return LargeTitleScaffold(
      title: 'Catalog',
      bottomInset: 60,
      onRefresh: load,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        ChromeIconButton(icon: CupertinoIcons.folder, onTap: _openSources),
        ChromeIconButton(icon: CupertinoIcons.gear_alt, onTap: _openSettings),
      ]),
      search: SearchField(placeholder: 'Search apps & developers', onChanged: (v) => setState(() => _query = v.toLowerCase())),
      slivers: body,
    );
  }

  Widget _appRow(AppColors c, CatalogApp a, bool last) {
    final inst = _installedVersion(a);
    final installed = inst != null;
    final upToDate = installed && inst == a.version;
    final btnLabel = upToDate ? 'OPEN' : (installed ? 'UPDATE' : 'GET');
    final tint = a.tintColor ?? AppColors.accent;
    return RowTile(
      last: last,
      leftInset: 84,
      onTap: () => Navigator.of(context)
          .push(CupertinoPageRoute(builder: (_) => AppDetailScreen(app: a, installedVersion: inst)))
          .then((_) => load()),
      leading: AppIcon(name: a.name, tint: tint, iconUrl: a.iconUrl, size: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      trailing: _GetButton(
        label: btnLabel,
        color: upToDate ? c.labelSecondary : tint,
        onTap: upToDate
            ? () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => AppDetailScreen(app: a, installedVersion: inst)))
            : () => startSign(context, _job(a)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline(c.label)),
          const SizedBox(height: 2),
          Text(a.developer ?? a.sourceName,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.footnote(c.labelSecondary)),
          const SizedBox(height: 3),
          Text(
            [
              if (a.version != null) 'v${a.version}',
              if (a.prettySize != null) a.prettySize!,
              if (a.category != null) a.category!,
            ].join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption(c.labelTertiary),
          ),
        ],
      ),
    );
  }

  SignJob _job(CatalogApp a) => SignJob(
        title: a.name,
        subtitle: '${a.developer ?? a.sourceName} · v${a.version ?? '?'}',
        tint: a.tintColor,
        sizeBytes: a.sizeBytes,
        version: a.version,
        bundleId: a.bundleId,
        sourceName: a.sourceName,
        ipaUrl: a.downloadUrl,
      );
}

class _GetButton extends StatelessWidget {
  const _GetButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        constraints: const BoxConstraints(minWidth: 74),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2)),
      ),
    );
  }
}
