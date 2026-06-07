import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/catalog_service.dart';
import '../services/config_store.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'sign_screen.dart';
import 'sources_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.theme});
  final ThemeController theme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(_tab == 0 ? 'Catalog' : 'Upload',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          GlassIconButton(
            icon: const Icon(Icons.folder_outlined, size: 20),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SourcesScreen())),
          ),
          GlassIconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SettingsScreen(theme: widget.theme))),
          ),
        ],
      ),
      bottomBar: GlassBottomBar(
        selectedIndex: _tab,
        onTabSelected: (i) => setState(() => _tab = i),
        tabs: const [
          GlassBottomBarTab(
            label: 'Catalog',
            icon: Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
            glowColor: kAccent,
          ),
          GlassBottomBarTab(
            label: 'Upload',
            icon: Icon(CupertinoIcons.arrow_up_doc),
            activeIcon: Icon(CupertinoIcons.arrow_up_doc_fill),
            glowColor: kAccent,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [_CatalogTab(), _UploadTab()],
      ),
    );
  }
}

/// Pushes the signing flow.
void _startSign(BuildContext context,
    {String? ipaUrl, PlatformFile? upload, String? appName}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          SignScreen(ipaUrl: ipaUrl, upload: upload, appName: appName),
    ),
  );
}

// ───────────────────────────── Catalog ─────────────────────────────
class _CatalogTab extends StatefulWidget {
  const _CatalogTab();
  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  late Future<List<CatalogApp>> _apps;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _apps = _load();
  }

  Future<List<CatalogApp>> _load() async {
    final sources = await ConfigStore.instance.sources;
    if (sources.isEmpty) return [];
    return CatalogService().loadAll(sources);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GlassSearchBar(
              placeholder: 'Search apps',
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() => _apps = _load()),
              child: FutureBuilder<List<CatalogApp>>(
                future: _apps,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                        child: GlassProgressIndicator.circular(size: 30));
                  }
                  final apps = (snap.data ?? [])
                      .where((a) =>
                          _query.isEmpty ||
                          a.name.toLowerCase().contains(_query) ||
                          (a.developer ?? '').toLowerCase().contains(_query))
                      .toList();
                  if (apps.isEmpty) {
                    return _empty(dark);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: apps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _AppCard(app: apps[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(bool dark) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(CupertinoIcons.square_stack_3d_up_slash,
              size: 56, color: dark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 16),
          Text('No apps yet.\nAdd an AltStore source from the folder icon.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: dark ? Colors.white54 : Colors.black45)),
        ],
      );
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app});
  final CatalogApp app;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = app.tintColor ?? kAccent;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: app.iconUrl != null
                ? Image.network(app.iconUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(tint))
                : _placeholder(tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (app.developer != null) app.developer!,
                    if (app.version != null) 'v${app.version}',
                    if (app.prettySize != null) app.prettySize!,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: dark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                _startSign(context, ipaUrl: app.downloadUrl, appName: app.name),
            child: GlassContainer(
              shape: const LiquidRoundedSuperellipse(borderRadius: 16),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                child: Text('GET',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: tint)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color tint) => Container(
        width: 56,
        height: 56,
        color: tint.withValues(alpha: 0.2),
        child: Icon(CupertinoIcons.app, color: tint),
      );
}

// ───────────────────────────── Upload ─────────────────────────────
class _UploadTab extends StatefulWidget {
  const _UploadTab();
  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  final _url = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!file.name.toLowerCase().endsWith('.ipa')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please pick a .ipa file')));
      }
      return;
    }
    if (!mounted) return;
    _startSign(context,
        upload: file, appName: file.name.replaceAll('.ipa', ''));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
        children: [
          GestureDetector(
            onTap: _pickFile,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(CupertinoIcons.cloud_upload,
                      size: 48, color: kAccent),
                  const SizedBox(height: 12),
                  const Text('Pick an .ipa from Files',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Sign an IPA already on your device',
                      style: TextStyle(
                          fontSize: 13,
                          color: dark ? Colors.white54 : Colors.black45)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Center(
              child: Text('— or from a direct URL —',
                  style: TextStyle(
                      color: dark ? Colors.white38 : Colors.black38))),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassTextField(
                  controller: _url,
                  placeholder: 'https://…/app.ipa',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    final u = _url.text.trim();
                    if (u.startsWith('http')) _startSign(context, ipaUrl: u);
                  },
                  child: GlassContainer(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 14),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      child: const Text('Sign from URL',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kAccent)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
