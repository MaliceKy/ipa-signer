import 'package:flutter/cupertino.dart';

import '../models/sign_job.dart';
import '../services/catalog_service.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'sign_screen.dart';

class AppDetailScreen extends StatelessWidget {
  const AppDetailScreen({super.key, required this.app, this.installedVersion});
  final CatalogApp app;
  final String? installedVersion;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tint = app.tintColor ?? AppColors.accent;
    final installed = installedVersion == app.version;

    return CompactScaffold(
      title: app.name,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                AppIcon(name: app.name, tint: tint, iconUrl: app.iconUrl, size: 92),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name, style: AppType.title2(c.label)),
                      const SizedBox(height: 2),
                      Text(app.developer ?? app.sourceName, style: AppType.subhead(c.labelSecondary)),
                      const SizedBox(height: 12),
                      PillButton(
                        label: installed ? 'Re-sign' : 'GET',
                        icon: installed ? CupertinoIcons.refresh : CupertinoIcons.cloud_download,
                        full: false,
                        height: 44,
                        tintOverride: tint,
                        onTap: () => startSign(context, _job()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // stat strip
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
            decoration: BoxDecoration(
              color: c.bgElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.separator, width: 0.5),
            ),
            child: Row(
              children: [
                _stat(c, 'Version', 'v${app.version ?? '?'}', false),
                _stat(c, 'Size', app.prettySize ?? '—', true),
                _stat(c, 'Category', app.category ?? '—', true),
              ],
            ),
          ),
          if (app.description != null) ...[
            const SectionHeader('About'),
            GroupCard(children: [
              RowTile(last: true, child: Text(app.description!, style: AppType.body(c.label))),
            ]),
            const SizedBox(height: 22),
          ],
          const SectionHeader('Information'),
          GroupCard(children: [
            _info(c, 'Source', app.sourceName),
            if (app.versionDate != null) _info(c, 'Updated', fmtDate(app.versionDate)),
            if (app.bundleId != null) _info(c, 'Bundle ID', app.bundleId!, mono: true, last: true),
          ]),
        ],
      ),
    );
  }

  Widget _stat(AppColors c, String label, String value, bool border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: border ? BoxDecoration(border: Border(left: BorderSide(color: c.separator, width: 0.5))) : null,
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: AppType.footnote(c.labelSecondary).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text(value, style: AppType.callout(c.label).copyWith(fontWeight: FontWeight.w600, fontFeatures: kTabular)),
          ],
        ),
      ),
    );
  }

  Widget _info(AppColors c, String label, String value, {bool mono = false, bool last = false}) {
    return RowTile(
      last: last,
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.body(c.label))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppType.body(c.labelSecondary).copyWith(
                    fontFamily: mono ? AppType.mono : null, fontSize: mono ? 14 : 17)),
          ),
        ],
      ),
    );
  }

  SignJob _job() => SignJob(
        title: app.name,
        subtitle: installedVersion == app.version ? 'Re-sign · v${app.version}' : '${app.developer ?? app.sourceName} · v${app.version ?? '?'}',
        tint: app.tintColor,
        sizeBytes: app.sizeBytes,
        version: app.version,
        bundleId: app.bundleId,
        sourceName: app.sourceName,
        ipaUrl: app.downloadUrl,
      );
}
