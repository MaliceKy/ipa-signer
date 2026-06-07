import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/config_store.dart';

void main() => runApp(const IpaSignerApp());

class IpaSignerApp extends StatelessWidget {
  const IpaSignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPA Signer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A84FF),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const _Gate(),
    );
  }
}

/// Sends the user to Settings until GitHub config exists, then Home.
class _Gate extends StatefulWidget {
  const _Gate();
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
        if (snap.data == true) return const HomeScreen();
        return SettingsScreen(onSaved: _refresh);
      },
    );
  }
}
