import 'package:flutter/cupertino.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/config_store.dart';
import 'ui/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mode = await ConfigStore.instance.themeMode;
  final configured = await ConfigStore.instance.isConfigured;
  runApp(IpaSignerApp(initialMode: mode, configured: configured));
}

class IpaSignerApp extends StatefulWidget {
  const IpaSignerApp({super.key, required this.initialMode, required this.configured});
  final String initialMode;
  final bool configured;

  @override
  State<IpaSignerApp> createState() => _IpaSignerAppState();
}

class _IpaSignerAppState extends State<IpaSignerApp> {
  late String _mode = widget.initialMode;
  late bool _configured = widget.configured;

  void _setMode(String m) {
    setState(() => _mode = m);
    ConfigStore.instance.setThemeMode(m);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = switch (_mode) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => null, // follow system
    };
    return CupertinoApp(
      title: 'IPA Signer',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: brightness == Brightness.dark ? AppColors.dark.bg : null,
      ),
      builder: (context, child) {
        final b = CupertinoTheme.brightnessOf(context);
        final colors = b == Brightness.dark ? AppColors.dark : AppColors.light;
        return AppColorsScope(colors: colors, child: child!);
      },
      home: _configured
          ? HomeShell(themeMode: _mode, onThemeChanged: _setMode)
          : SettingsScreen(
              themeMode: _mode,
              onThemeChanged: _setMode,
              isFirstRun: true,
              onSaved: () => setState(() => _configured = true),
            ),
    );
  }
}
