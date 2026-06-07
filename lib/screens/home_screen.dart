import 'dart:ui';

import 'package:flutter/cupertino.dart';

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
          Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(index: _tab, onTap: _select)),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(top: 8, bottom: 26),
          decoration: BoxDecoration(
            color: c.chrome,
            border: Border(top: BorderSide(color: c.chromeBorder, width: 0.5)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(i == index ? _tabs[i].$2 : _tabs[i].$1,
                            size: 26, color: i == index ? AppColors.accent : c.labelTertiary),
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
          ),
        ),
      ),
    );
  }
}
