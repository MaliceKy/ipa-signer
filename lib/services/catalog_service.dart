import 'dart:convert';

import 'package:http/http.dart' as http;

/// One installable app entry parsed from a catalog source.
class CatalogApp {
  CatalogApp({
    required this.name,
    required this.downloadUrl,
    this.bundleId,
    this.version,
    this.iconUrl,
    this.description,
    required this.sourceName,
  });

  final String name;
  final String downloadUrl;
  final String? bundleId;
  final String? version;
  final String? iconUrl;
  final String? description;
  final String sourceName;

  factory CatalogApp.fromJson(Map<String, dynamic> j, String sourceName) {
    return CatalogApp(
      name: (j['name'] ?? j['title'] ?? 'Unknown').toString(),
      downloadUrl: (j['downloadURL'] ?? j['url'] ?? '').toString(),
      bundleId: j['bundleIdentifier']?.toString(),
      version: j['version']?.toString(),
      iconUrl: (j['iconURL'] ?? j['icon'])?.toString(),
      description: (j['localizedDescription'] ?? j['description'])?.toString(),
      sourceName: sourceName,
    );
  }
}

/// Fetches and parses AltStore/AltSource-style catalog JSON.
class CatalogService {
  /// Loads every configured source, tolerating individual failures.
  Future<List<CatalogApp>> loadAll(List<String> sourceUrls) async {
    final results = <CatalogApp>[];
    for (final url in sourceUrls) {
      try {
        results.addAll(await _loadOne(url));
      } catch (_) {
        // Skip a broken source rather than failing the whole list.
      }
    }
    return results;
  }

  Future<List<CatalogApp>> _loadOne(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) return [];
    final sourceName = (data['name'] ?? Uri.parse(url).host).toString();
    final apps = (data['apps'] as List?) ?? const [];
    return apps
        .whereType<Map<String, dynamic>>()
        .map((a) => CatalogApp.fromJson(a, sourceName))
        .where((a) => a.downloadUrl.isNotEmpty)
        .toList();
  }
}
