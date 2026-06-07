import 'package:flutter/cupertino.dart';

import '../models/sign_job.dart';
import '../services/library_store.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'sign_screen.dart';

class LibraryDetailScreen extends StatelessWidget {
  const LibraryDetailScreen({super.key, required this.entry});
  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canResign = entry.downloadUrl != null && entry.downloadUrl!.isNotEmpty;

    return CompactScaffold(
      title: entry.name,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                AppIcon(name: entry.name, tint: entry.tintColor, size: 92),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, style: AppType.title2(c.label)),
                      const SizedBox(height: 2),
                      Text('Installed v${entry.version}',
                          style: AppType.subhead(c.labelSecondary).copyWith(fontFeatures: kTabular)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
            child: PillButton(
              label: canResign ? 'Re-sign & reinstall' : 'Original IPA unavailable',
              icon: CupertinoIcons.refresh,
              onTap: canResign
                  ? () => startSign(
                        context,
                        SignJob(
                          title: entry.name,
                          subtitle: 'Re-sign · v${entry.version}',
                          tint: entry.tintColor,
                          sizeBytes: entry.sizeBytes,
                          version: entry.version,
                          bundleId: entry.bundleId,
                          sourceName: entry.sourceName,
                          ipaUrl: entry.downloadUrl,
                          nameForSigning: entry.name,
                        ),
                      )
                  : null,
            ),
          ),
          const SectionHeader('Information'),
          GroupCard(children: [
            _info(c, 'Installed', fmtDate(entry.installedAt)),
            _info(c, 'Source', entry.sourceName),
            _info(c, 'Bundle ID', entry.bundleId, mono: true, last: true),
          ]),
          const SizedBox(height: 22),
          const SectionHeader('Version history'),
          GroupCard(children: [
            for (var i = 0; i < entry.history.length; i++) _historyRow(c, entry.history[i], i == 0, i == entry.history.length - 1),
          ]),
          const SizedBox(height: 28),
          GroupCard(children: [
            RowTile(
              last: true,
              onTap: () async {
                await LibraryStore.instance.removeEntry(entry.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: Center(child: Text('Remove from Library', style: AppType.body(c.red))),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _info(AppColors c, String label, String value, {bool mono = false, bool last = false}) {
    return RowTile(
      last: last,
      child: Row(children: [
        Expanded(child: Text(label, style: AppType.body(c.label))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppType.body(c.labelSecondary).copyWith(fontFamily: mono ? AppType.mono : null, fontSize: mono ? 14 : 17)),
        ),
      ]),
    );
  }

  Widget _historyRow(AppColors c, VersionRecord h, bool current, bool last) {
    return RowTile(
      last: last,
      leftInset: 46,
      leading: SizedBox(
        width: 30,
        child: Center(
          child: Container(width: 9, height: 9, decoration: BoxDecoration(color: current ? c.green : c.labelQuaternary, shape: BoxShape.circle)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('v${h.version}', style: AppType.callout(c.label).copyWith(fontWeight: FontWeight.w600, fontFeatures: kTabular)),
            if (current) ...[
              const SizedBox(width: 8),
              Text('CURRENT', style: TextStyle(color: c.green, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ]),
          Text('${fmtDate(h.date)} · ${fmtSize(h.size)}',
              style: AppType.footnote(c.labelSecondary).copyWith(fontFeatures: kTabular)),
        ],
      ),
    );
  }
}
