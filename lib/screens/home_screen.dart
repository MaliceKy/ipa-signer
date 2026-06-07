import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/catalog_service.dart';
import '../services/config_store.dart';
import 'settings_screen.dart';
import 'sign_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IPA Signer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [_CatalogTab(), _UploadTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.apps), label: 'Catalog'),
          NavigationDestination(
              icon: Icon(Icons.upload_file), label: 'Upload'),
        ],
      ),
    );
  }
}

/// Starts the signing flow for a given IPA source on the sign screen.
void _startSign(
  BuildContext context, {
  String? ipaUrl,
  PlatformFile? upload,
  String? appName,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SignScreen(
        ipaUrl: ipaUrl,
        upload: upload,
        appName: appName,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Catalog tab
// ---------------------------------------------------------------------------
class _CatalogTab extends StatefulWidget {
  const _CatalogTab();
  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  late Future<List<CatalogApp>> _apps;

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
    return RefreshIndicator(
      onRefresh: () async => setState(() => _apps = _load()),
      child: FutureBuilder<List<CatalogApp>>(
        future: _apps,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snap.data ?? [];
          if (apps.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No catalog apps.\nAdd source URLs in Settings, '
                      'then pull to refresh.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            itemCount: apps.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = apps[i];
              return ListTile(
                leading: a.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          a.iconUrl!,
                          width: 44,
                          height: 44,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.apps, size: 40),
                        ),
                      )
                    : const Icon(Icons.apps, size: 40),
                title: Text(a.name),
                subtitle: Text(
                  [a.version, a.sourceName]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(' • '),
                ),
                trailing: const Icon(Icons.download),
                onTap: () => _startSign(
                  context,
                  ipaUrl: a.downloadUrl,
                  appName: a.name,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upload tab (pick from Files, or paste a direct URL)
// ---------------------------------------------------------------------------
class _UploadTab extends StatefulWidget {
  const _UploadTab();
  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  final _url = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!file.name.toLowerCase().endsWith('.ipa')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a .ipa file')),
        );
      }
      return;
    }
    if (!mounted) return;
    _startSign(context, upload: file, appName: file.name.replaceAll('.ipa', ''));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Pick an .ipa from Files'),
            ),
          ),
          const SizedBox(height: 32),
          const Text('— or sign from a direct URL —',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'https://…/app.ipa',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final u = _url.text.trim();
              if (u.startsWith('http')) {
                _startSign(context, ipaUrl: u);
              }
            },
            child: const Text('Sign from URL'),
          ),
        ],
      ),
    );
  }
}
