import 'package:flutter/cupertino.dart';

import 'tokens.dart';

/// Large collapsing-title screen (Catalog / Upload / Library) with native blur.
class LargeTitleScaffold extends StatelessWidget {
  const LargeTitleScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
    this.search,
    this.onRefresh,
    this.bottomInset = 0,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Widget? search;
  final Future<void> Function()? onRefresh;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CupertinoPageScaffold(
      backgroundColor: c.bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title, style: TextStyle(color: c.label)),
            backgroundColor: c.chrome,
            border: Border(bottom: BorderSide(color: c.chromeBorder, width: 0.0)),
            automaticallyImplyLeading: false,
            trailing: trailing,
          ),
          if (onRefresh != null) CupertinoSliverRefreshControl(onRefresh: onRefresh),
          if (search != null)
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 4), child: search),
            ),
          ...slivers,
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24)),
        ],
      ),
    );
  }
}

/// Compact centered-title screen (detail / settings / sources / sign).
class CompactScaffold extends StatelessWidget {
  const CompactScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.bottomBar,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CupertinoPageScaffold(
      backgroundColor: c.bg,
      navigationBar: CupertinoNavigationBar(
        middle: Text(title, style: TextStyle(color: c.label)),
        backgroundColor: c.chrome,
        border: Border(bottom: BorderSide(color: c.chromeBorder, width: 0.5)),
        leading: leading,
        trailing: trailing,
        automaticallyImplyLeading: leading == null,
      ),
      child: bottomBar == null
          ? SafeArea(bottom: false, child: child)
          : Column(
              children: [
                Expanded(child: SafeArea(bottom: false, child: child)),
                bottomBar!,
              ],
            ),
    );
  }
}
