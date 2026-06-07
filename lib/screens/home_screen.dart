import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

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
            bottom: MediaQuery.viewPaddingOf(context).bottom + 10,
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
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: c.chrome,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: c.chromeBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: c.isDark ? 0.45 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.accent.withValues(alpha: 0.16) : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(i == index ? _tabs[i].$2 : _tabs[i].$1,
                            size: 24, color: i == index ? AppColors.accent : c.labelTertiary),
                        const SizedBox(height: 2),
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
          ),
        ),
      ),
    );
  }
}
