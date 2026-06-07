import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One version entry in an app's install history.
class VersionRecord {
  VersionRecord({required this.version, required this.date, required this.size});
  final String version;
  final String date; // ISO date
  final int size;

  Map<String, dynamic> toJson() => {'version': version, 'date': date, 'size': size};
  factory VersionRecord.fromJson(Map<String, dynamic> j) =>
      VersionRecord(version: j['version'] ?? '', date: j['date'] ?? '', size: j['size'] ?? 0);
}

/// An installed app (logged after a successful sign + install).
class LibraryEntry {
  LibraryEntry({
    required this.id,
    required this.name,
    required this.tint,
    required this.version,
    required this.sizeBytes,
    required this.installedAt,
    required this.sourceName,
    required this.bundleId,
    this.downloadUrl,
    required this.history,
  });

  final String id;
  final String name;
  final int tint; // color value
  final String version;
  final int sizeBytes;
  final String installedAt; // ISO datetime
  final String sourceName;
  final String bundleId;
  final String? downloadUrl; // original unsigned IPA, for re-sign
  final List<VersionRecord> history;

  Color get tintColor => Color(tint);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tint': tint,
        'version': version,
        'sizeBytes': sizeBytes,
        'installedAt': installedAt,
        'sourceName': sourceName,
        'bundleId': bundleId,
        'downloadUrl': downloadUrl,
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory LibraryEntry.fromJson(Map<String, dynamic> j) => LibraryEntry(
        id: j['id'],
        name: j['name'] ?? '',
        tint: j['tint'] ?? 0xFF0A84FF,
        version: j['version'] ?? '',
        sizeBytes: j['sizeBytes'] ?? 0,
        installedAt: j['installedAt'] ?? '',
        sourceName: j['sourceName'] ?? '',
        bundleId: j['bundleId'] ?? '',
        downloadUrl: j['downloadUrl'],
        history: ((j['history'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(VersionRecord.fromJson)
            .toList(),
      );
}

/// A signed IPA published to a Release — reinstallable without re-signing.
class SignedFile {
  SignedFile({required this.filename, required this.sizeBytes, required this.date, required this.runTag});
  final String filename;
  final int sizeBytes;
  final String date; // ISO date
  final String runTag; // release tag → OTA manifest

  Map<String, dynamic> toJson() => {'filename': filename, 'sizeBytes': sizeBytes, 'date': date, 'runTag': runTag};
  factory SignedFile.fromJson(Map<String, dynamic> j) => SignedFile(
        filename: j['filename'] ?? '',
        sizeBytes: j['sizeBytes'] ?? 0,
        date: j['date'] ?? '',
        runTag: j['runTag'] ?? '',
      );
}

/// Persists the Library (installed apps + signed files) in the keychain.
class LibraryStore {
  LibraryStore._();
  static final LibraryStore instance = LibraryStore._();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _kLibrary = 'library_v1';
  static const _kFiles = 'signed_files_v1';

  Future<List<LibraryEntry>> library() async {
    final raw = await _storage.read(key: _kLibrary);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .whereType<Map<String, dynamic>>()
        .map(LibraryEntry.fromJson)
        .toList();
  }

  Future<List<SignedFile>> files() async {
    final raw = await _storage.read(key: _kFiles);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .whereType<Map<String, dynamic>>()
        .map(SignedFile.fromJson)
        .toList();
  }

  Future<void> _saveLibrary(List<LibraryEntry> list) =>
      _storage.write(key: _kLibrary, value: jsonEncode(list.map((e) => e.toJson()).toList()));

  Future<void> _saveFiles(List<SignedFile> list) =>
      _storage.write(key: _kFiles, value: jsonEncode(list.map((e) => e.toJson()).toList()));

  /// Records a successful install: upserts the library entry (prepending a
  /// history record) and adds a reinstallable signed-file entry.
  Future<void> recordInstall({
    required String name,
    required int tint,
    required String version,
    required int sizeBytes,
    required String sourceName,
    required String bundleId,
    String? downloadUrl,
    required String runTag,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final today = nowIso.substring(0, 10);

    final lib = await library();
    final idx = lib.indexWhere((l) => l.bundleId == bundleId || l.name == name);
    final record = VersionRecord(version: version, date: today, size: sizeBytes);
    if (idx >= 0) {
      final e = lib[idx];
      final hist = (e.history.isNotEmpty && e.history.first.version == version)
          ? e.history
          : [record, ...e.history];
      lib.removeAt(idx);
      lib.insert(
        0,
        LibraryEntry(
          id: e.id,
          name: name,
          tint: tint,
          version: version,
          sizeBytes: sizeBytes,
          installedAt: nowIso,
          sourceName: sourceName,
          bundleId: bundleId,
          downloadUrl: downloadUrl ?? e.downloadUrl,
          history: hist,
        ),
      );
    } else {
      lib.insert(
        0,
        LibraryEntry(
          id: 'l${now.millisecondsSinceEpoch}',
          name: name,
          tint: tint,
          version: version,
          sizeBytes: sizeBytes,
          installedAt: nowIso,
          sourceName: sourceName,
          bundleId: bundleId,
          downloadUrl: downloadUrl,
          history: [record],
        ),
      );
    }
    await _saveLibrary(lib);

    final files = await this.files();
    final filename =
        '${name.replaceAll(RegExp(r'\s'), '')}-$version.ipa';
    files.removeWhere((f) => f.runTag == runTag);
    files.insert(0, SignedFile(filename: filename, sizeBytes: sizeBytes, date: today, runTag: runTag));
    await _saveFiles(files);
  }

  Future<void> removeEntry(String id) async {
    final lib = await library();
    lib.removeWhere((l) => l.id == id);
    await _saveLibrary(lib);
  }

  Future<void> removeFile(String runTag) async {
    final files = await this.files();
    files.removeWhere((f) => f.runTag == runTag);
    await _saveFiles(files);
  }
}
