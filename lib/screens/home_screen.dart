import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

import '../services/library_store.dart';
import '../ui/tokens.dart';
import 'catalog_screen.dart';
import 'library_screen.dart';
import 'upload_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.themeMode, required this.onThemeChanged});
  final String themeMode;
  final ValueChanged<String> onThemeChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _catalogKey = GlobalKey<CatalogScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();

  void _select(int i) {
    setState(() => _tab = i);
    if (i == 0) _catalogKey.currentState?.load();
    if (i == 2) _libraryKey.currentState?.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CupertinoPageScaffold(
      backgroundColor: c.bg,
      child: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              CatalogScreen(key: _catalogKey, themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged),
              UploadScreen(themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged),
              LibraryScreen(key: _libraryKey, themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 2,
            child: Center(child: _TabBar(index: _tab, onTap: _select)),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (CupertinoIcons.square_grid_2x2, CupertinoIcons.square_grid_2x2_fill, 'Catalog'),
    (CupertinoIcons.arrow_up_doc, CupertinoIcons.arrow_up_doc_fill, 'Upload'),
    (CupertinoIcons.square_stack_3d_up, CupertinoIcons.square_stack_3d_up_fill, 'Library'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: c.chrome,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: c.chromeBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: c.isDark ? 0.45 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.accent.withValues(alpha: 0.16) : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TabIcon(
                          icon: i == index ? _tabs[i].$2 : _tabs[i].$1,
                          color: i == index ? AppColors.accent : c.labelTertiary,
                          badge: i == 2, // Library shows the updates badge
                          borderColor: c.chrome,
                        ),
                        const SizedBox(height: 3),
                        Text(_tabs[i].$3,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                                color: i == index ? AppColors.accent : c.labelTertiary)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab-bar icon with an optional red updates badge (driven by [updatesBadge]).
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.color, required this.badge, required this.borderColor});
  final IconData icon;
  final Color color;
  final bool badge;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 24, color: color);
    if (!badge) return iconWidget;
    return ValueListenableBuilder<int>(
      valueListenable: updatesBadge,
      builder: (context, count, _) {
        if (count <= 0) return iconWidget;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            Positioned(
              right: -5,
              top: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
