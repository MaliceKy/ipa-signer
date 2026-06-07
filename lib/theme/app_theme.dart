import 'package:flutter/material.dart';

import '../services/config_store.dart';

/// iOS-style accent (systemBlue).
const kAccent = Color(0xFF0A84FF);

/// Apple-flavoured light & dark themes plus the gradient backdrops the glass
/// widgets sample from.
class AppTheme {
  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: kAccent,
      brightness: b,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: '.SF Pro Text',
      splashFactory: NoSplash.splashFactory,
      textTheme: Typography.material2021(platform: TargetPlatform.iOS)
          .black
          .apply(
            bodyColor: isDark ? Colors.white : const Color(0xFF1C1C1E),
            displayColor: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
    );
  }

  /// Full-screen backdrop behind every page; gives glass something to refract.
  static Widget background(Brightness b) {
    final isDark = b == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0B0B12), Color(0xFF15131F), Color(0xFF06080F)]
              : const [Color(0xFFEAF1FB), Color(0xFFF6F1FA), Color(0xFFFDF4F0)],
        ),
      ),
      child: Stack(
        children: [
          // Soft colour blobs for depth.
          _blob(const Alignment(-0.9, -0.8), kAccent.withValues(alpha: 0.30)),
          _blob(const Alignment(1.1, -0.3),
              const Color(0xFF8E5BFF).withValues(alpha: 0.22)),
          _blob(const Alignment(-0.6, 1.0),
              const Color(0xFF34C7B5).withValues(alpha: 0.18)),
        ],
      ),
    );
  }

  static Widget _blob(Alignment a, Color c) => Align(
        alignment: a,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
          ),
        ),
      );
}

/// Holds the active [ThemeMode] and persists it.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._mode);
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  static Future<ThemeController> load() async {
    return ThemeController._(_parse(await ConfigStore.instance.themeMode));
  }

  Future<void> set(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    await ConfigStore.instance.setThemeMode(_name(m));
  }

  static ThemeMode _parse(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _name(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
