import 'package:flutter/widgets.dart';

/// iOS-native design tokens (light + dark), ported from the design spec.
class AppColors {
  const AppColors({
    required this.bg,
    required this.bgElevated,
    required this.bgElevated2,
    required this.fill,
    required this.fillStrong,
    required this.label,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.labelQuaternary,
    required this.separator,
    required this.separatorStrong,
    required this.chrome,
    required this.chromeBorder,
    required this.green,
    required this.red,
    required this.amber,
    required this.isDark,
  });

  final Color bg;
  final Color bgElevated;
  final Color bgElevated2;
  final Color fill;
  final Color fillStrong;
  final Color label;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color labelQuaternary;
  final Color separator;
  final Color separatorStrong;
  final Color chrome;
  final Color chromeBorder;
  final Color green;
  final Color red;
  final Color amber;
  final bool isDark;

  static const accent = Color(0xFF0A84FF);

  static const light = AppColors(
    bg: Color(0xFFF2F2F7),
    bgElevated: Color(0xFFFFFFFF),
    bgElevated2: Color(0xFFF2F2F7),
    fill: Color(0x1F767680),
    fillStrong: Color(0x33767680),
    label: Color(0xFF000000),
    labelSecondary: Color(0x993C3C43),
    labelTertiary: Color(0x4D3C3C43),
    labelQuaternary: Color(0x2E3C3C43),
    separator: Color(0x293C3C43),
    separatorStrong: Color(0x4A3C3C43),
    chrome: Color(0xD1F9F9F9),
    chromeBorder: Color(0x293C3C43),
    green: Color(0xFF34C759),
    red: Color(0xFFFF3B30),
    amber: Color(0xFFFF9500),
    isDark: false,
  );

  static const dark = AppColors(
    bg: Color(0xFF000000),
    bgElevated: Color(0xFF1C1C1E),
    bgElevated2: Color(0xFF2C2C2E),
    fill: Color(0x3D767680),
    fillStrong: Color(0x5C767680),
    label: Color(0xFFFFFFFF),
    labelSecondary: Color(0x99EBEBF5),
    labelTertiary: Color(0x4DEBEBF5),
    labelQuaternary: Color(0x2EEBEBF5),
    separator: Color(0x8C545458),
    separatorStrong: Color(0xB3545458),
    chrome: Color(0xCC1C1C1E),
    chromeBorder: Color(0x73545458),
    green: Color(0xFF30D158),
    red: Color(0xFFFF453A),
    amber: Color(0xFFFF9F0A),
    isDark: true,
  );

  static AppColors of(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? dark
          : light; // overridden by AppColorsScope below
}

/// Provides the resolved [AppColors] down the tree (respects app theme mode).
class AppColorsScope extends InheritedWidget {
  const AppColorsScope({super.key, required this.colors, required super.child});
  final AppColors colors;

  static AppColors of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppColorsScope>();
    assert(scope != null, 'AppColorsScope missing');
    return scope!.colors;
  }

  @override
  bool updateShouldNotify(AppColorsScope old) => old.colors != colors;
}

/// Shorthand: `context.c` → resolved colors.
extension AppColorsContext on BuildContext {
  AppColors get c => AppColorsScope.of(this);
}

/// iOS type scale (size, height, weight, letter-spacing).
class AppType {
  static const fontFamily = '.SF Pro Text';
  static const mono = 'monospace';

  static TextStyle large(Color c) => TextStyle(
      color: c, fontSize: 34, height: 41 / 34, fontWeight: FontWeight.w700, letterSpacing: 0.37);
  static TextStyle title1(Color c) => TextStyle(
      color: c, fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, letterSpacing: 0.36);
  static TextStyle title2(Color c) => TextStyle(
      color: c, fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, letterSpacing: 0.35);
  static TextStyle title3(Color c) => TextStyle(
      color: c, fontSize: 20, height: 25 / 20, fontWeight: FontWeight.w600, letterSpacing: 0.38);
  static TextStyle headline(Color c) => TextStyle(
      color: c, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, letterSpacing: -0.43);
  static TextStyle body(Color c) => TextStyle(
      color: c, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w400, letterSpacing: -0.43);
  static TextStyle callout(Color c) => TextStyle(
      color: c, fontSize: 16, height: 21 / 16, fontWeight: FontWeight.w400, letterSpacing: -0.31);
  static TextStyle subhead(Color c) => TextStyle(
      color: c, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w400, letterSpacing: -0.23);
  static TextStyle footnote(Color c) => TextStyle(
      color: c, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, letterSpacing: -0.08);
  static TextStyle caption(Color c) => TextStyle(
      color: c, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400);
  static TextStyle caption2(Color c) => TextStyle(
      color: c, fontSize: 11, height: 13 / 11, fontWeight: FontWeight.w400, letterSpacing: 0.06);
}

const kRadiusCard = 12.0;
const kRadiusCardLg = 14.0;
const kRadiusField = 10.0;

/// Tabular figures feature for numbers that shouldn't jitter.
const kTabular = [FontFeature.tabularFigures()];
