import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sign_job.dart';
import '../services/catalog_service.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'app_detail_screen.dart';
import 'sign_screen.dart';

/// A single catalog app row (icon, name, dev·version, date·size, GET button).
/// Shared by the repo view and global search.
class CatalogAppTile extends StatelessWidget {
  const CatalogAppTile({
    super.key,
    required this.app,
    required this.installedVersion,
    required this.last,
    this.showSource = false,
    this.onReturn,
  });

  final CatalogApp app;
  final String? installedVersion;
  final bool last;
  final bool showSource;
  final VoidCallback? onReturn;

  static String shortDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final installed = installedVersion != null;
    final upToDate = installed && installedVersion == app.version;
    final tint = app.tintColor ?? AppColors.accent;
    final meta = [
      if (showSource) app.sourceName,
      if (app.versionDate != null) shortDate(app.versionDate!),
      if (app.prettySize != null) app.prettySize!,
    ].join('  ·  ');

    void openDetail() => Navigator.of(context)
        .push(CupertinoPageRoute(builder: (_) => AppDetailScreen(app: app, installedVersion: installedVersion)))
        .then((_) => onReturn?.call());

    Future<void> openApp() async {
      final scheme = app.urlScheme;
      if (scheme == null || scheme.isEmpty) {
        openDetail(); // no scheme known → fall back to the detail page
        return;
      }
      final uri = Uri.parse(scheme.contains('://') ? scheme : '$scheme://');
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) openDetail();
      } catch (_) {
        if (context.mounted) showToast(context, "Couldn't open ${app.name}", tone: ToastTone.error);
      }
    }

    return RowTile(
      last: last,
      leftInset: 84,
      onTap: openDetail,
      leading: AppIcon(name: app.name, tint: tint, iconUrl: app.iconUrl, size: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      trailing: _GetButton(
        label: upToDate ? 'OPEN' : (installed ? 'UPDATE' : 'GET'),
        color: upToDate ? c.labelSecondary : (installed ? AppColors.accent : tint),
        faded: upToDate,
        onTap: upToDate ? openApp : () => startSign(context, _job()).then((_) => onReturn?.call()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline(c.label)),
          const SizedBox(height: 2),
          Row(
            children: [
              if (app.developer != null)
                Flexible(
                  child: Text(app.developer!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.footnote(c.labelSecondary)),
                ),
              if (app.developer != null && app.version != null)
                Text('  ·  ', style: AppType.footnote(c.labelSecondary)),
              if (app.version != null)
                Text('v${app.version}', style: AppType.footnote(c.labelSecondary)),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption(c.labelTertiary)),
          ],
        ],
      ),
    );
  }

  SignJob _job() => SignJob(
        title: app.name,
        subtitle: '${app.developer ?? app.sourceName} · v${app.version ?? '?'}',
        tint: app.tintColor,
        sizeBytes: app.sizeBytes,
        version: app.version,
        bundleId: app.bundleId,
        sourceName: app.sourceName,
        ipaUrl: app.downloadUrl,
        nameForSigning: app.name,
        iconUrl: app.iconUrl,
      );
}

class _GetButton extends StatelessWidget {
  const _GetButton({required this.label, required this.color, required this.onTap, this.faded = false});
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool faded;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          constraints: const BoxConstraints(minWidth: 74),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2)),
        ),
      ),
    );
  }
}
