import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, InkWell, Colors;
import 'package:flutter/services.dart';

import 'tokens.dart';

// ───────────────────────────── AppIcon ─────────────────────────────
/// Tinted squircle with a 2-letter monogram (or remote icon if provided).
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.name, this.tint, this.iconUrl, this.size = 56});
  final String name;
  final Color? tint;
  final String? iconUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = size * 0.225;
    final t = tint ?? const Color(0xFF8E8E93);
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final letters = cleaned.isEmpty
        ? '?'
        : cleaned.substring(0, cleaned.length >= 2 ? 2 : 1).toUpperCase();
    final monogram = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t, Color.lerp(t, Colors.black, 0.28)!],
        ),
      ),
      alignment: Alignment.center,
      child: Text(letters,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.4,
              letterSpacing: -0.5)),
    );
    if (iconUrl == null || iconUrl!.isEmpty) return monogram;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Image.network(iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => monogram),
    );
  }
}

// ───────────────────────────── Buttons ─────────────────────────────
enum BtnKind { primary, success, danger, neutral, amber }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.kind = BtnKind.primary,
    this.icon,
    this.loading = false,
    this.full = true,
    this.height = 50,
    this.tintOverride,
  });

  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final IconData? icon;
  final bool loading;
  final bool full;
  final double height;
  final Color? tintOverride;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg = switch (kind) {
      BtnKind.primary => tintOverride ?? AppColors.accent,
      BtnKind.success => c.green,
      BtnKind.danger => c.red,
      BtnKind.amber => c.amber,
      BtnKind.neutral => c.fill,
    };
    final fg = kind == BtnKind.neutral ? AppColors.accent : Colors.white;
    final disabled = onTap == null || loading;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: _Press(
        onTap: disabled ? null : onTap,
        child: Container(
          height: height,
          width: full ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(height / 2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
            children: loading
                ? [CupertinoActivityIndicator(color: fg)]
                : [
                    if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
                    Text(label,
                        style: TextStyle(color: fg, fontSize: height <= 36 ? 15 : 17, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
                  ],
          ),
        ),
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, this.onTap, this.icon, this.color});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final col = color ?? AppColors.accent;
    return _Press(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 17, color: col), const SizedBox(width: 5)],
            Text(label, style: TextStyle(color: col, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

/// Tappable wrapper with iOS press feedback (scale + fade).
class _Press extends StatefulWidget {
  const _Press({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          opacity: _down ? 0.7 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

// ───────────────────────────── Inputs ─────────────────────────────
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.onChanged, this.placeholder = 'Search'});
  final ValueChanged<String> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(CupertinoIcons.search, size: 18, color: c.labelSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: CupertinoTextField(
              onChanged: onChanged,
              placeholder: placeholder,
              placeholderStyle: AppType.body(c.labelTertiary),
              style: AppType.body(c.label),
              decoration: const BoxDecoration(),
              padding: EdgeInsets.zero,
              cursorColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.controller,
    this.placeholder,
    this.icon,
    this.obscure = false,
    this.mono = false,
    this.keyboardType,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String? placeholder;
  final IconData? icon;
  final bool obscure;
  final bool mono;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  bool _reveal = false;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.separatorStrong, width: 0.5),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: c.labelSecondary), const SizedBox(width: 9)],
          Expanded(
            child: CupertinoTextField(
              controller: widget.controller,
              placeholder: widget.placeholder,
              placeholderStyle: AppType.body(c.labelTertiary).copyWith(fontFamily: widget.mono ? AppType.mono : null),
              obscureText: widget.obscure && !_reveal,
              keyboardType: widget.keyboardType,
              onSubmitted: widget.onSubmitted,
              autocorrect: false,
              enableSuggestions: false,
              cursorColor: AppColors.accent,
              decoration: const BoxDecoration(),
              padding: EdgeInsets.zero,
              style: AppType.body(c.label).copyWith(fontFamily: widget.mono ? AppType.mono : null, fontSize: widget.mono ? 15 : 17),
            ),
          ),
          if (widget.obscure && widget.controller.text.isNotEmpty)
            _Press(
              onTap: () => setState(() => _reveal = !_reveal),
              child: Text(_reveal ? 'Hide' : 'Show',
                  style: TextStyle(color: c.labelSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

class Segmented3 extends StatelessWidget {
  const Segmented3({super.key, required this.options, required this.index, required this.onChanged});
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(builder: (context, box) {
      final innerW = box.maxWidth - 4;
      final segW = innerW / options.length;
      return Container(
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(9)),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: index * segW,
              top: 0,
              bottom: 0,
              width: segW,
              child: Container(
                decoration: BoxDecoration(
                  color: c.bgElevated,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 3, offset: const Offset(0, 1))],
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < options.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(options[i],
                            style: TextStyle(
                                color: c.label,
                                fontSize: 13,
                                fontWeight: i == index ? FontWeight.w600 : FontWeight.w500)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ───────────────────────────── Progress / Pill ─────────────────────────────
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 8, this.indeterminate = false});
  final double value; // 0..1
  final Color? color;
  final double height;
  final bool indeterminate;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = color ?? AppColors.accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: c.fillStrong,
        child: indeterminate
            ? _Indeterminate(color: col, height: height)
            : Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value.clamp(0, 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(height / 2)),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Indeterminate extends StatefulWidget {
  const _Indeterminate({required this.color, required this.height});
  final Color color;
  final double height;
  @override
  State<_Indeterminate> createState() => _IndeterminateState();
}

class _IndeterminateState extends State<_Indeterminate> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      return AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) {
          final w = box.maxWidth * 0.4;
          final x = (box.maxWidth + w) * _ctl.value - w;
          return Stack(children: [
            Positioned(
              left: x,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(widget.height / 2)),
              ),
            ),
          ]);
        },
      );
    });
  }
}

enum PillTone { blue, green, red, amber, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = PillTone.neutral, this.spin = false, this.dot = false, this.icon});
  final String label;
  final PillTone tone;
  final bool spin;
  final bool dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = switch (tone) {
      PillTone.blue => AppColors.accent,
      PillTone.green => c.green,
      PillTone.red => c.red,
      PillTone.amber => c.amber,
      PillTone.neutral => c.labelSecondary,
    };
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: col.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spin) ...[SizedBox(width: 13, height: 13, child: CupertinoActivityIndicator(color: col, radius: 6)), const SizedBox(width: 5)]
          else if (dot) ...[Container(width: 7, height: 7, decoration: BoxDecoration(color: col, shape: BoxShape.circle)), const SizedBox(width: 5)]
          else if (icon != null) ...[Icon(icon, size: 14, color: col), const SizedBox(width: 5)],
          Text(label, style: TextStyle(color: col, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.1)),
        ],
      ),
    );
  }
}

// ───────────────────────────── Grouped list ─────────────────────────────
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.margin = const EdgeInsets.symmetric(horizontal: 16)});
  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: c.separator, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class RowTile extends StatelessWidget {
  const RowTile({
    super.key,
    this.leading,
    required this.child,
    this.trailing,
    this.onTap,
    this.last = false,
    this.leftInset = 16,
    this.minHeight = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
  });
  final Widget? leading;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool last;
  final double leftInset;
  final double minHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, splashColor: c.fill, highlightColor: c.fill, child: row))
          : row,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        if (!last)
          Padding(
            padding: EdgeInsets.only(left: leftInset),
            child: Container(height: 0.5, color: c.separator),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 6),
      child: Text(text.toUpperCase(), style: AppType.footnote(c.labelSecondary).copyWith(letterSpacing: 0.4)),
    );
  }
}

class SectionFooter extends StatelessWidget {
  const SectionFooter(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 7, 32, 0),
      child: Text(text, style: AppType.footnote(c.labelSecondary)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, size: 32, color: c.labelTertiary),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppType.title3(c.label), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppType.subhead(c.labelSecondary), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

// ───────────────────────────── Chrome buttons ─────────────────────────────
class ChromeIconButton extends StatelessWidget {
  const ChromeIconButton({super.key, required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return _Press(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Icon(icon, size: 23, color: AppColors.accent),
      ),
    );
  }
}

// ───────────────────────────── Toast ─────────────────────────────
enum ToastTone { neutral, ok, error }

void showToast(BuildContext context, String msg, {ToastTone tone = ToastTone.neutral, IconData? icon}) {
  final overlay = Overlay.of(context);
  final c = context.c;
  final col = switch (tone) {
    ToastTone.ok => c.green,
    ToastTone.error => c.red,
    ToastTone.neutral => c.label,
  };
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 0,
      right: 0,
      bottom: 110,
      child: IgnorePointer(
        child: Center(
          child: _ToastBubble(msg: msg, icon: icon, iconColor: col, colors: c),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2200), entry.remove);
}

class _ToastBubble extends StatelessWidget {
  const _ToastBubble({required this.msg, this.icon, required this.iconColor, required this.colors});
  final String msg;
  final IconData? icon;
  final Color iconColor;
  final AppColors colors;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.separator, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: iconColor), const SizedBox(width: 8)],
            Flexible(child: Text(msg, style: AppType.subhead(colors.label).copyWith(fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Dashed border ─────────────────────────────
/// Paints a dashed rounded-rect outline (blueprint look) around [child].
class DashedRoundedBorder extends StatelessWidget {
  const DashedRoundedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 16,
    this.dash = 7,
    this.gap = 5,
    this.strokeWidth = 1.6,
  });
  final Widget child;
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, radius: radius, dash: dash, gap: gap, strokeWidth: strokeWidth),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.color, required this.radius, required this.dash, required this.gap, required this.strokeWidth});
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rrect = RRect.fromRectAndRadius(
      Offset(strokeWidth / 2, strokeWidth / 2) & Size(size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius || old.dash != dash || old.gap != gap || old.strokeWidth != strokeWidth;
}

// ───────────────────────────── Misc helpers ─────────────────────────────
void copyToClipboard(BuildContext context, String text, String what) {
  Clipboard.setData(ClipboardData(text: text));
  showToast(context, '$what copied', icon: CupertinoIcons.doc_on_doc);
}

String fmtSize(int? bytes) {
  if (bytes == null) return '';
  final mb = bytes / 1000000;
  if (mb >= 1000) return '${(mb / 1000).toStringAsFixed(2)} GB';
  if (mb >= 100) return '${mb.round()} MB';
  return '${mb.toStringAsFixed(1)} MB';
}

String fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String relTime(String? iso) {
  if (iso == null) return '';
  final then = DateTime.tryParse(iso);
  if (then == null) return '';
  final m = DateTime.now().difference(then).inMinutes;
  if (m < 60) return '${m}m ago';
  final h = (m / 60).round();
  if (h < 24) return '${h}h ago';
  final d = (h / 24).round();
  return d == 1 ? 'Yesterday' : '${d}d ago';
}
