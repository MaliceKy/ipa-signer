import 'package:flutter/cupertino.dart';

import '../services/catalog_service.dart';
import '../services/config_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});
  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final _url = TextEditingController();
  List<CatalogSource> _sources = [];
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final urls = await ConfigStore.instance.sources;
    final loaded = await CatalogService().loadSources(urls);
    if (!mounted) return;
    setState(() {
      _sources = loaded;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final u = _url.text.trim();
    if (!RegExp(r'^https?://.+', caseSensitive: false).hasMatch(u)) {
      showToast(context, 'Enter a valid repo URL', tone: ToastTone.error, icon: CupertinoIcons.exclamationmark_circle);
      return;
    }
    setState(() => _adding = true);
    await ConfigStore.instance.addSource(u);
    _url.clear();
    await _reload();
    if (!mounted) return;
    final matches = _sources.where((s) => s.url == u);
    final ok = matches.isNotEmpty && matches.first.error == null;
    showToast(context, ok ? 'Source added' : 'Source failed to load',
        tone: ok ? ToastTone.ok : ToastTone.error,
        icon: ok ? CupertinoIcons.check_mark_circled : CupertinoIcons.exclamationmark_circle);
    setState(() => _adding = false);
  }

  Future<void> _delete(CatalogSource s) async {
    await ConfigStore.instance.removeSource(s.url);
    await _reload();
    if (mounted) showToast(context, 'Source removed', icon: CupertinoIcons.trash);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CompactScaffold(
      title: 'Sources',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          const SectionHeader('Add a source'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                AppField(controller: _url, placeholder: 'https://…/apps.json', icon: CupertinoIcons.link, mono: true, keyboardType: TextInputType.url, onSubmitted: (_) => _add()),
                const SizedBox(height: 10),
                PillButton(label: 'Add source', icon: CupertinoIcons.add, loading: _adding, onTap: _add),
              ],
            ),
          ),
          const SectionFooter('AltStore-style repositories. Each repo’s apps appear in the Catalog.'),
          const SizedBox(height: 22),
          SectionHeader('${_sources.length} source${_sources.length == 1 ? '' : 's'}'),
          if (_loading)
            const Padding(padding: EdgeInsets.only(top: 30), child: Center(child: CupertinoActivityIndicator()))
          else if (_sources.isEmpty)
            const EmptyState(icon: CupertinoIcons.folder, title: 'No sources yet', message: 'Add a repository URL above to start browsing apps.')
          else
            GroupCard(children: [
              for (var i = 0; i < _sources.length; i++) _sourceRow(c, _sources[i], i == _sources.length - 1),
            ]),
        ],
      ),
    );
  }

  Widget _sourceRow(AppColors c, CatalogSource s, bool last) {
    final failed = s.error != null;
    return RowTile(
      last: last,
      leftInset: 60,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: failed ? c.red.withValues(alpha: 0.14) : c.fill, borderRadius: BorderRadius.circular(9)),
        child: Icon(CupertinoIcons.folder, size: 19, color: failed ? c.red : c.labelSecondary),
      ),
      trailing: GestureDetector(
        onTap: () => _delete(s),
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(CupertinoIcons.trash, size: 20, color: c.red)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.callout(c.label).copyWith(fontWeight: FontWeight.w600)),
          Text(failed ? 'Failed: ${s.error}' : '${s.apps.length} app${s.apps.length == 1 ? '' : 's'}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.footnote(failed ? c.red : c.labelSecondary)),
          Text(s.url.replaceFirst(RegExp(r'^https?://'), ''),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: AppType.mono, fontSize: 11, color: c.labelTertiary)),
        ],
      ),
    );
  }
}
