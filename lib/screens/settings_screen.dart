import 'package:flutter/material.dart';

import '../services/config_store.dart';
import '../services/github_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onSaved});

  /// Called after a successful save (used by the gate on first run).
  final VoidCallback? onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _token = TextEditingController();
  final _owner = TextEditingController();
  final _repo = TextEditingController();
  final _branch = TextEditingController(text: 'main');
  final _sources = TextEditingController();

  bool _busy = false;
  String? _status;

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
    _sources.text = (await cfg.sources).join('\n');
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    await ConfigStore.instance.save(
      token: _token.text,
      owner: _owner.text,
      repo: _repo.text,
      branch: _branch.text,
      sources: _sources.text,
    );
    final err = await GitHubService(ConfigStore.instance).verify();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = err ?? 'Saved & verified ✓';
    });
    if (err == null) {
      widget.onSaved?.call();
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'GitHub connection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Personal access token with "actions: write" and "contents: write" '
            'on the signing repo (fine-grained PAT recommended).',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          _field(_token, 'Personal access token', obscure: true),
          _field(_owner, 'Repo owner (username/org)'),
          _field(_repo, 'Repo name'),
          _field(_branch, 'Branch'),
          const SizedBox(height: 20),
          const Text(
            'Catalog sources',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'One AltStore-style source JSON URL per line.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sources,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'https://example.com/apps.json',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save & verify'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(
              _status!,
              style: TextStyle(
                color: _status!.contains('✓')
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
