import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/store.dart';
import '../core/util.dart';
import 'theme.dart';

/// التبويب الحالي في الشريط السفلي.
final ValueNotifier<int> tabIndex = ValueNotifier(0);

/// يعيد البناء عند تغيّر التخزين. إذا حُدِّد [tab] فلا يعيد البناء وهو مخفي (يوفّر عملًا كبيرًا).
class StoreBuilder extends StatefulWidget {
  final int? tab;
  final Widget Function(BuildContext, Object?) builder;
  const StoreBuilder({super.key, this.tab, required this.builder});
  @override
  State<StoreBuilder> createState() => _StoreBuilderState();
}

class _StoreBuilderState extends State<StoreBuilder> {
  bool get _visible => widget.tab == null || tabIndex.value == widget.tab;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    if (widget.tab != null) tabIndex.addListener(_onTab);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    tabIndex.removeListener(_onTab);
    super.dispose();
  }

  void _onStore() {
    if (!mounted) return;
    if (_visible) {
      setState(() {});
    } else {
      _dirty = true;
    }
  }

  void _onTab() {
    if (mounted && _dirty && _visible) {
      _dirty = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, null);
}

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> msgKey = GlobalKey<ScaffoldMessengerState>();

void toast(String m) {
  msgKey.currentState?.hideCurrentSnackBar();
  msgKey.currentState?.showSnackBar(SnackBar(
    content: Text(m, textAlign: TextAlign.center),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(milliseconds: 2400),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 96),
  ));
}

/// انتقال بين الصفحات بمنحنى emphasized مع اهتزاز خفيف.
Future<T?> pushPage<T>(Widget page) {
  hap.tick();
  return navKey.currentState!.push<T>(PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(position: Tween(begin: const Offset(-0.06, 0), end: Offset.zero).animate(c), child: child),
      );
    },
  ));
}

IconData iconOf(String n) => const {
      'sun': Icons.wb_sunny_rounded, 'sunset': Icons.wb_twilight_rounded, 'moon': Icons.nightlight_round, 'book': Icons.menu_book_rounded,
      'check': Icons.check_rounded, 'bell': Icons.notifications_rounded, 'spark': Icons.auto_awesome_rounded, 'trophy': Icons.emoji_events_rounded,
      'flag': Icons.flag_rounded, 'water': Icons.water_drop_rounded, 'cal': Icons.calendar_month_rounded, 'music': Icons.music_note_rounded,
      'grid': Icons.grid_view_rounded, 'user': Icons.person_rounded, 'tune': Icons.tune_rounded, 'info': Icons.info_outline_rounded,
      'fav': Icons.favorite_rounded, 'add': Icons.add_rounded, 'mosque': Icons.mosque_rounded, 'hand': Icons.volunteer_activism_rounded,
      'home': Icons.home_rounded, 'pin': Icons.place_rounded, 'fire': Icons.local_fire_department_rounded, 'star': Icons.star_rounded,
      'clock': Icons.access_time_rounded, 'more': Icons.more_vert_rounded,
    }[n] ??
    Icons.auto_awesome_rounded;

/// زخرفة نجمية خفيفة في الخلفية.
class StarsPainter extends CustomPainter {
  final Color color;
  StarsPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const step = 86.0;
    for (var y = 20.0, r = 0; y < size.height; y += step, r++) {
      for (var x = (r.isEven ? 20.0 : 20.0 + step / 2); x < size.width; x += step) {
        final path = Path();
        for (var i = 0; i < 16; i++) {
          final rad = i.isEven ? 6.0 : 2.6;
          final a = i * math.pi / 8;
          final pt = Offset(x + rad * math.cos(a), y + rad * math.sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path..close(), p);
      }
    }
  }

  @override
  bool shouldRepaint(StarsPainter old) => old.color != color;
}

class Backdrop extends StatelessWidget {
  final Widget child;
  const Backdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ColoredBox(
      color: p.bg,
      child: Stack(fit: StackFit.expand, children: [
        // الزخرفة تُرسم مرة واحدة في RepaintBoundary ولا تتأثر بالتمرير
        RepaintBoundary(child: CustomPaint(painter: StarsPainter(p.pri.withValues(alpha: .05)))),
        child,
      ]),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? color;
  final double radius;
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(18), this.margin = const EdgeInsets.only(top: 14), this.color, this.radius = 28});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? p.surf,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap == null ? null : () { hap.tick(); onTap!(); },
          child: Container(
            padding: padding,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: Border.all(color: p.line)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  const HeroCard({super.key, required this.child, this.onTap, this.margin = const EdgeInsets.only(top: 14)});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: margin,
      child: Material(
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(colors: p.hero, begin: Alignment.topRight, end: Alignment.bottomLeft),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: InkWell(
            onTap: onTap == null ? null : () { hap.tick(); onTap!(); },
            child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: IconTheme(data: const IconThemeData(color: Colors.white), child: Padding(padding: const EdgeInsets.all(20), child: child))),
          ),
        ),
      ),
    );
  }
}

class Ring extends StatelessWidget {
  final double v, size, stroke;
  final Color? color, track;
  final Widget? child;
  final Duration duration;
  const Ring({super.key, required this.v, this.size = 72, this.stroke = 8, this.color, this.track, this.child, this.duration = const Duration(milliseconds: 500)});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v.clamp(0, 1).toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, val, __) => CustomPaint(
          painter: _RingPainter(val, stroke, color ?? p.pri, track ?? p.surf2),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, w;
  final Color c, t;
  _RingPainter(this.v, this.w, this.c, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(w / 2, w / 2, s.width - w, s.height - w);
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = t;
    final fg = Paint()..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round..color = c;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.c != c || o.t != t;
}

class Bar extends StatelessWidget {
  final double v;
  final Color? color, track;
  const Bar(this.v, {super.key, this.color, this.track});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (_, val, __) => LinearProgressIndicator(value: val, minHeight: 8, backgroundColor: track ?? p.surf2, valueColor: AlwaysStoppedAnimation(color ?? p.pri)),
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  const IconBox(this.icon, {super.key, this.size = 46});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(width: size, height: size, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(size / 2.6)), child: Icon(icon, color: p.pri, size: size * .5));
  }
}

class ItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? trailing;
  const ItemTile({super.key, required this.icon, required this.title, this.sub, this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return AppCard(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 24,
      onTap: onTap,
      child: Row(children: [
        IconBox(icon),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (sub != null) Text(sub!, style: TextStyle(color: p.on2, fontSize: 13)),
        ])),
        trailing ?? Icon(Icons.chevron_left_rounded, color: p.on2),
      ]),
    );
  }
}

class PageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final bool back;
  final Widget? fab;
  const PageScaffold({super.key, required this.title, required this.children, this.actions = const [], this.back = true, this.fab});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: fab,
      body: Backdrop(
        child: ListView(
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, mq.padding.top + 8, 16, mq.padding.bottom + 110),
          children: [
            Row(children: [
              if (back) _RoundBtn(Icons.arrow_forward_rounded, () { hap.tick(); Navigator.of(context).maybePop(); }, p),
              if (back) const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
              ...actions,
            ]),
            const SizedBox(height: 8),
            ...children.asMap().entries.map((e) => _Stagger(index: e.key, child: e.value)),
          ],
        ),
      ),
    );
  }
}

class _Stagger extends StatelessWidget {
  final int index;
  final Widget child;
  const _Stagger({required this.index, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 280 + (index.clamp(0, 8)) * 45),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: c)),
        child: child,
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Pal p;
  const _RoundBtn(this.icon, this.onTap, this.p);
  @override
  Widget build(BuildContext context) => Material(color: p.surf, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 22, color: p.on))));
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const RoundIconButton(this.icon, this.onTap, {super.key, this.tooltip});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 6),
        child: Tooltip(message: tooltip ?? '', child: _RoundBtn(icon, () { hap.tick(); onTap(); }, Pal.of(context))),
      );
}

class ChipRow extends StatelessWidget {
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelect;
  const ChipRow({super.key, required this.items, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final it in items)
        ChoiceChip(
          label: Text(it.$2),
          selected: it.$1 == selected,
          showCheckmark: false,
          selectedColor: p.pri,
          backgroundColor: p.surf,
          labelStyle: TextStyle(color: it.$1 == selected ? p.onpri : p.on, fontWeight: FontWeight.w600),
          side: BorderSide(color: p.line),
          shape: const StadiumBorder(),
          onSelected: (_) { hap.select(); onSelect(it.$1); },
        ),
    ]);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 4),
        child: Row(children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))), if (trailing != null) trailing!]),
      );
}

class Sub extends StatelessWidget {
  final String text;
  final TextAlign? align;
  const Sub(this.text, {super.key, this.align});
  @override
  Widget build(BuildContext context) => Text(text, textAlign: align, style: TextStyle(color: Pal.of(context).on2, fontSize: 14, height: 1.6));
}

Future<bool> confirmDialog(BuildContext c, String title, String body, {String ok = 'حسنًا', bool danger = false}) async {
  final p = Pal.of(c);
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      backgroundColor: p.surf,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text('إلغاء', style: TextStyle(color: p.on2))),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(ok, style: TextStyle(color: danger ? const Color(0xFFA8332B) : p.pri, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return r == true;
}

Future<T?> showAppSheet<T>(BuildContext c, Widget Function(BuildContext) b) {
  final p = Pal.of(c);
  return showModalBottomSheet<T>(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.surf,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom), child: SingleChildScrollView(child: b(ctx))),
  );
}

void copyText(String t) {
  Clipboard.setData(ClipboardData(text: t));
  hap.click();
  toast('تم النسخ');
}
