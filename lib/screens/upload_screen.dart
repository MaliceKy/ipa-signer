import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import '../models/sign_job.dart';
import '../ui/components.dart';
import '../ui/scaffolds.dart';
import '../ui/tokens.dart';
import 'settings_screen.dart';
import 'sign_screen.dart';
import 'sources_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.themeMode, required this.onThemeChanged});
  final String themeMode;
  final ValueChanged<String> onThemeChanged;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _url = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!file.name.toLowerCase().endsWith('.ipa')) {
      if (mounted) showToast(context, 'Please pick a .ipa file', tone: ToastTone.error, icon: CupertinoIcons.exclamationmark_circle);
      return;
    }
    if (!mounted) return;
    startSign(
      context,
      SignJob(
        title: file.name.replaceAll('.ipa', ''),
        subtitle: 'From Files · ${fmtSize(file.size)}',
        sizeBytes: file.size,
        version: 'sideloaded',
        upload: file,
      ),
    );
  }

  void _signUrl() {
    final u = _url.text.trim();
    final valid = RegExp(r'^https?://.+\.ipa(\?.*)?$', caseSensitive: false).hasMatch(u);
    if (!valid) {
      showToast(context, 'Enter a direct link ending in .ipa', tone: ToastTone.error, icon: CupertinoIcons.exclamationmark_circle);
      return;
    }
    final fn = Uri.decodeComponent(u.split('/').last.split('?').first);
    startSign(context, SignJob(title: fn, subtitle: 'From a direct URL', ipaUrl: u, version: 'remote'));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LargeTitleScaffold(
      title: 'Upload',
      bottomInset: 96,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        ChromeIconButton(
            icon: CupertinoIcons.folder,
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const SourcesScreen()))),
        ChromeIconButton(
            icon: CupertinoIcons.gear_alt,
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => SettingsScreen(themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged)))),
      ]),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: GestureDetector(
              onTap: _pickFile,
              child: DashedRoundedBorder(
                color: AppColors.accent.withValues(alpha: 0.7),
                radius: 16,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: c.isDark ? 0.06 : 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
                        child: const Icon(CupertinoIcons.cloud_upload, size: 30, color: AppColors.accent),
                      ),
                      const SizedBox(height: 14),
                      Text('Pick an .ipa from Files', style: AppType.title3(c.label), textAlign: TextAlign.center),
                      const SizedBox(height: 5),
                      Text('Tap to choose an IPA already on your device.', style: AppType.subhead(c.labelSecondary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
            child: Row(children: [
              Expanded(child: Container(height: 0.5, color: c.separatorStrong)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or from a direct URL', style: AppType.footnote(c.labelTertiary))),
              Expanded(child: Container(height: 0.5, color: c.separatorStrong)),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                AppField(controller: _url, placeholder: 'https://…/app.ipa', icon: CupertinoIcons.link, mono: true, keyboardType: TextInputType.url, onSubmitted: (_) => _signUrl()),
                const SizedBox(height: 12),
                PillButton(label: 'Sign from URL', icon: CupertinoIcons.cloud_download, onTap: _signUrl),
                const SizedBox(height: 12),
                Text('The link must point directly to an .ipa file. Signing runs remotely, then installs over-the-air.',
                    style: AppType.footnote(c.labelSecondary), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
