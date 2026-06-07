import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/config_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = await ThemeController.load();
  runApp(IpaSignerApp(theme: theme));
}

class IpaSignerApp extends StatelessWidget {
  const IpaSignerApp({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        return LiquidGlassWidgets.wrap(
          child: MaterialApp(
            title: 'IPA Signer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            builder: (context, child) {
              final b = Theme.of(context).brightness;
              return Stack(
                children: [
                  Positioned.fill(child: AppTheme.background(b)),
                  ?child,
                ],
              );
            },
            home: _Gate(theme: theme),
          ),
        );
      },
    );
  }
}

/// Sends the user to Settings until GitHub config exists, then Home.
class _Gate extends StatefulWidget {
  const _Gate({required this.theme});
  final ThemeController theme;

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late Future<bool> _configured;

  @override
  void initState() {
    super.initState();
    _configured = ConfigStore.instance.isConfigured;
  }

  void _refresh() => setState(() {
        _configured = ConfigStore.instance.isConfigured;
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _configured,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == true) return HomeScreen(theme: widget.theme);
        return SettingsScreen(theme: widget.theme, onSaved: _refresh);
      },
    );
  }
}
