import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// One installable app entry parsed from an AltStore-style catalog source.
class CatalogApp {
  CatalogApp({
    required this.name,
    required this.downloadUrl,
    this.bundleId,
    this.version,
    this.versionDate,
    this.developer,
    this.sizeBytes,
    this.iconUrl,
    this.description,
    this.tintColor,
    this.category,
    required this.sourceName,
  });

  final String name;
  final String downloadUrl;
  final String? bundleId;
  final String? version;
  final String? versionDate;
  final String? developer;
  final int? sizeBytes;
  final String? iconUrl;
  final String? description;
  final Color? tintColor;
  final String? category;
  final String sourceName;

  String? get prettySize {
    if (sizeBytes == null) return null;
    final mb = sizeBytes! / 1048576;
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory CatalogApp.fromJson(Map<String, dynamic> j, String sourceName) {
    // Newer AltStore format nests download info under versions[0].
    final versions = (j['versions'] as List?)?.whereType<Map>().toList();
    final v = versions != null && versions.isNotEmpty ? versions.first : null;

    String? str(String key) =>
        (v?[key] ?? j[key])?.toString().trim().isNotEmpty == true
            ? (v?[key] ?? j[key]).toString()
            : null;

    return CatalogApp(
      name: (j['name'] ?? j['title'] ?? 'Unknown').toString(),
      downloadUrl: (v?['downloadURL'] ?? j['downloadURL'] ?? j['url'] ?? '')
          .toString(),
      bundleId: j['bundleIdentifier']?.toString(),
      version: str('version'),
      versionDate: str('date') ?? str('versionDate'),
      developer: j['developerName']?.toString(),
      sizeBytes: int.tryParse((v?['size'] ?? j['size'] ?? '').toString()),
      iconUrl: (j['iconURL'] ?? j['icon'])?.toString(),
      description: (v?['localizedDescription'] ??
              j['localizedDescription'] ??
              j['description'])
          ?.toString(),
      tintColor: _parseHex(j['tintColor']?.toString()),
      category: (j['category'] ?? j['cat'] ?? j['subtitle'])?.toString(),
      sourceName: sourceName,
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}

/// A parsed source (one AltStore repo URL).
class CatalogSource {
  CatalogSource({
    required this.url,
    required this.name,
    required this.apps,
    this.error,
  });

  final String url;
  final String name;
  final List<CatalogApp> apps;
  final String? error;
}

/// Fetches and parses AltStore/AltSource-style catalog JSON.
class CatalogService {
  /// Loads every configured source, keeping per-source results & errors.
  Future<List<CatalogSource>> loadSources(List<String> sourceUrls) async {
    final out = <CatalogSource>[];
    for (final url in sourceUrls) {
      try {
        out.add(await _loadOne(url));
      } catch (e) {
        out.add(CatalogSource(
          url: url,
          name: Uri.tryParse(url)?.host ?? url,
          apps: const [],
          error: e.toString(),
        ));
      }
    }
    return out;
  }

  /// Flat list of every app across all sources (used by the catalog grid).
  Future<List<CatalogApp>> loadAll(List<String> sourceUrls) async {
    final sources = await loadSources(sourceUrls);
    return [for (final s in sources) ...s.apps];
  }

  /// Fetches one source URL just to validate it and read its name + count.
  Future<CatalogSource> _loadOne(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw 'HTTP ${res.statusCode}';
    }
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw 'Not an AltStore source';
    final sourceName = (data['name'] ?? Uri.parse(url).host).toString();
    final apps = ((data['apps'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((a) => CatalogApp.fromJson(a, sourceName))
        .where((a) => a.downloadUrl.isNotEmpty)
        .toList();
    return CatalogSource(url: url, name: sourceName, apps: apps);
  }
}
