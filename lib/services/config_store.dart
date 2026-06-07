import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the small amount of config the app needs, in the iOS keychain.
class ConfigStore {
  ConfigStore._();
  static final ConfigStore instance = ConfigStore._();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kToken = 'gh_token';
  static const _kOwner = 'gh_owner';
  static const _kRepo = 'gh_repo';
  static const _kBranch = 'gh_branch';
  static const _kSources = 'catalog_sources'; // newline-separated URLs

  Future<String?> get token => _storage.read(key: _kToken);
  Future<String?> get owner => _storage.read(key: _kOwner);
  Future<String?> get repo => _storage.read(key: _kRepo);

  Future<String> get branch async =>
      (await _storage.read(key: _kBranch))?.trim().isNotEmpty == true
          ? (await _storage.read(key: _kBranch))!.trim()
          : 'main';

  Future<List<String>> get sources async {
    final raw = await _storage.read(key: _kSources) ?? '';
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> save({
    required String token,
    required String owner,
    required String repo,
    required String branch,
    required String sources,
  }) async {
    await _storage.write(key: _kToken, value: token.trim());
    await _storage.write(key: _kOwner, value: owner.trim());
    await _storage.write(key: _kRepo, value: repo.trim());
    await _storage.write(key: _kBranch, value: branch.trim());
    await _storage.write(key: _kSources, value: sources.trim());
  }

  Future<bool> get isConfigured async =>
      (await token)?.isNotEmpty == true &&
      (await owner)?.isNotEmpty == true &&
      (await repo)?.isNotEmpty == true;
}
