import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/catalog_service.dart';
import '../services/config_store.dart';
import '../theme/app_theme.dart';

/// Add / remove AltStore-style repository sources.
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
    final url = _url.text.trim();
    if (!url.startsWith('http')) return;
    setState(() => _adding = true);
    await ConfigStore.instance.addSource(url);
    _url.clear();
    await _reload();
    if (mounted) setState(() => _adding = false);
  }

  Future<void> _remove(String url) async {
    await ConfigStore.instance.removeSource(url);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Sources',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassTextField(
                    controller: _url,
                    placeholder: 'https://…/apps.json',
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _add(),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _adding ? null : _add,
                    child: GlassContainer(
                      shape: const LiquidRoundedSuperellipse(borderRadius: 14),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        child: _adding
                            ? const GlassProgressIndicator.circular(size: 18)
                            : const Text('Add source',
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
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: GlassProgressIndicator.circular(size: 28)),
              )
            else if (_sources.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text('No sources yet.\nAdd an AltStore repo URL above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: dark ? Colors.white54 : Colors.black45)),
              )
            else
              ..._sources.map((s) => _sourceTile(s, dark)),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile(CatalogSource s, bool dark) {
    final ok = s.error == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(ok ? Icons.folder_special : Icons.error_outline,
                color: ok ? kAccent : const Color(0xFFFF453A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(ok ? '${s.apps.length} apps' : 'Failed: ${s.error}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: ok
                              ? (dark ? Colors.white54 : Colors.black45)
                              : const Color(0xFFFF453A))),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: dark ? Colors.white54 : Colors.black45,
              onPressed: () => _remove(s.url),
            ),
          ],
        ),
      ),
    );
  }
}
