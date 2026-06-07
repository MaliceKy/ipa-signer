import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

/// Everything the Sign screen needs to run a job and log the install.
class SignJob {
  SignJob({
    required this.title,
    required this.subtitle,
    this.tint,
    this.sizeBytes,
    this.version,
    this.bundleId,
    this.sourceName,
    this.ipaUrl,
    this.upload,
    this.nameForSigning,
  });

  final String title; // display name in the UI
  final String subtitle;
  final Color? tint;
  final int? sizeBytes;
  final String? version;
  final String? bundleId; // original bundle id (for derive + library key)
  final String? sourceName;
  final String? ipaUrl; // catalog / url / re-sign
  final PlatformFile? upload; // local file

  /// Display name to bake into the signed app (zsign `-n`). When null, the
  /// IPA keeps its own embedded name — important for uploads, where the file
  /// name is not a good app name.
  final String? nameForSigning;

  bool get isUpload => upload != null;

  SignJob copyWith({String? title, String? nameForSigning}) => SignJob(
        title: title ?? this.title,
        subtitle: subtitle,
        tint: tint,
        sizeBytes: sizeBytes,
        version: version,
        bundleId: bundleId,
        sourceName: sourceName,
        ipaUrl: ipaUrl,
        upload: upload,
        nameForSigning: nameForSigning ?? this.nameForSigning,
      );

  /// Wildcard prefix this user's Ad-Hoc provisioning profile covers.
  /// Every signed app's bundle id must fall under it to install.
  static const bundlePrefix = 'com.maliceky.ipasign';

  /// Deterministic bundle id under the wildcard (so re-signs update in place).
  String get signedBundleId {
    if (bundleId != null && bundleId!.startsWith(bundlePrefix)) return bundleId!;
    final base = (bundleId ?? title).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$bundlePrefix.${base.isEmpty ? 'app' : base}';
  }
}
