import 'package:flutter/cupertino.dart';

import '../models/sign_job.dart';
import '../services/catalog_service.dart';
import '../services/library_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import 'app_tile.dart';

/// Shows the apps inside a single repository.
class RepoScreen extends StatefulWidget {
  const RepoScreen({super.key, required this.source});
  final CatalogSource source;

  @override
  State<RepoScreen> createState() => _RepoScreenState();
}

class _RepoScreenState extends State<RepoScreen> {
  Map<String, String> _installed = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadLib();
  }

  Future<void> _loadLib() async {
    final lib = await LibraryStore.instance.library();
    if (mounted) setState(() => _installed = {for (final l in lib) l.bundleId: l.version});
  }

  String? _installedVersion(CatalogApp a) =>
      _installed[SignJob(title: a.name, subtitle: '', bundleId: a.bundleId).signedBundleId];

  @override
  Widget build(BuildContext context) {
    final apps = _query.isEmpty
        ? widget.source.apps
        : widget.source.apps
            .where((a) =>
                a.name.toLowerCase().contains(_query) ||
                (a.developer ?? '').toLowerCase().contains(_query))
            .toList();

    return CompactScaffold(
      title: widget.source.name,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(placeholder: 'Search ${widget.source.name}', onChanged: (v) => setState(() => _query = v.toLowerCase())),
          ),
          if (apps.isEmpty)
            EmptyState(
                icon: CupertinoIcons.search,
                title: _query.isEmpty ? 'No apps' : 'No results',
                message: _query.isEmpty ? 'This repository has no apps.' : 'Nothing matches “$_query”.')
          else ...[
            SectionHeader('${apps.length} app${apps.length == 1 ? '' : 's'}'),
            GroupCard(children: [
              for (var i = 0; i < apps.length; i++)
                CatalogAppTile(app: apps[i], installedVersion: _installedVersion(apps[i]), last: i == apps.length - 1, onReturn: _loadLib),
            ]),
          ],
        ],
      ),
    );
  }
}
