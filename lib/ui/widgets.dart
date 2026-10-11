import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/store.dart';
import '../core/util.dart';
import 'theme.dart';
import 'wicons.dart';

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
      'sun': Icons.wb_sunny, 'sunset': Icons.wb_twilight, 'moon': Icons.nightlight_round, 'book': Icons.menu_book,
      'check': Icons.check, 'bell': Icons.notifications, 'spark': Icons.auto_awesome, 'trophy': Icons.emoji_events,
      'flag': Icons.flag, 'water': Icons.water_drop, 'cal': Icons.calendar_month, 'music': Icons.music_note,
      'grid': Icons.grid_view, 'user': Icons.person, 'tune': Icons.tune, 'info': Icons.info_outline,
      'fav': Icons.favorite, 'add': Icons.add, 'mosque': Icons.mosque, 'hand': Icons.volunteer_activism,
      'home': Icons.home, 'pin': Icons.place, 'fire': Icons.local_fire_department, 'star': Icons.star,
      'clock': Icons.access_time, 'more': Icons.more_vert,
    }[n] ??
    Icons.auto_awesome;

// ================== الزخرفة (مطابقة لـ --star في css/app.css) ==================
/// بلاطة 80×80: نجمة ثمانية بخط ذهبي + دائرة صغيرة.
class StarTilePainter extends CustomPainter {
  final Color color;
  const StarTilePainter(this.color);
  static Path _star() => Path()
    ..moveTo(40, 6)
    ..relativeLineTo(6.5, 13.5)
    ..relativeLineTo(14.8, -4.8)
    ..relativeLineTo(-4.8, 14.8)
    ..lineTo(70, 36)
    ..relativeLineTo(-13.5, 6.5)
    ..relativeLineTo(4.8, 14.8)
    ..relativeLineTo(-14.8, -4.8)
    ..lineTo(40, 66)
    ..relativeLineTo(-6.5, -13.5)
    ..relativeLineTo(-14.8, 4.8)
    ..relativeLineTo(4.8, -14.8)
    ..lineTo(10, 36)
    ..relativeLineTo(13.5, -6.5)
    ..relativeLineTo(-4.8, -14.8)
    ..relativeLineTo(14.8, 4.8)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final star = _star();
    final a = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = color.withValues(alpha: .26);
    final b = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = color.withValues(alpha: .2);
    for (var y = 0.0; y < size.height; y += 80) {
      for (var x = 0.0; x < size.width; x += 80) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(star, a);
        canvas.drawCircle(const Offset(40, 36), 3, b);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(StarTilePainter o) => o.color != color;
}

/// طبقة نجوم تنجرف ببطء (drift) — تُرسم مرة وتُحرَّك بالـ Transform فقط (رخيصة).
class StarLayer extends StatefulWidget {
  final Color color;
  final double opacity;
  final int seconds;
  const StarLayer({super.key, this.color = const Color(0xFFB3923F), this.opacity = 1, this.seconds = 60});
  @override
  State<StarLayer> createState() => _StarLayerState();
}

class _StarLayerState extends State<StarLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: widget.opacity,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, child) => Transform.translate(offset: Offset(_c.value * 80 - 80, _c.value * 80 - 80), child: child),
                child: RepaintBoundary(child: CustomPaint(size: const Size(1200, 2600), painter: StarTilePainter(widget.color))),
              ),
            ),
          ),
        ),
      );
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
        if (palSetting() == 'green') StarLayer(color: p.gold, seconds: 70),
        child,
      ]),
    );
  }
}

/// مقياس ضغط ناعم (مثل :active{transform:scale(.985)} في الويب).
class Press extends StatefulWidget {
  final Widget Function(BuildContext, bool pressed) builder;
  const Press({super.key, required this.builder});
  @override
  State<Press> createState() => PressState();
}

class PressState extends State<Press> {
  bool down = false;
  @override
  Widget build(BuildContext context) => widget.builder(context, down);
}

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? color;
  final Color? borderColor;
  final double radius, borderWidth;
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14), this.margin = const EdgeInsets.only(top: 14), this.color, this.borderColor, this.radius = 20, this.borderWidth = 1});
  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final r = BorderRadius.circular(widget.radius);
    return Padding(
      padding: widget.margin,
      child: AnimatedScale(
        scale: _down ? .985 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: r, boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1))]),
          child: Material(
            color: widget.color ?? p.surf,
            borderRadius: r,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: r,
              splashFactory: InkSparkle.splashFactory,
              splashColor: p.pri.withValues(alpha: .10),
              highlightColor: p.pc.withValues(alpha: .55),
              onHighlightChanged: widget.onTap == null ? null : (v) => setState(() => _down = v),
              onTap: widget.onTap == null ? null : () { hap.tick(); widget.onTap!(); },
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(borderRadius: r, border: Border.all(color: widget.borderColor ?? p.line, width: widget.borderWidth)),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة hero حيّة: تدرّج متحرك + نجوم تنجرف + توهج ذهبي (مثل .hero في الويب). [light] = النسخة الهادئة .hero.cl
class HeroCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final bool light;
  final List<Color>? colors;
  final EdgeInsets padding;
  const HeroCard({super.key, required this.child, this.onTap, this.margin = const EdgeInsets.only(top: 14), this.light = false, this.colors, this.padding = const EdgeInsets.all(16)});
  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> with TickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(seconds: 16));
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void initState() {
    super.initState();
    if (!widget.light) {
      _sheen.repeat(reverse: true);
      _glow.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final r = BorderRadius.circular(20);
    final fg = widget.light ? p.on : Colors.white;
    final content = DefaultTextStyle.merge(
      style: TextStyle(color: fg),
      child: IconTheme(data: IconThemeData(color: fg), child: Padding(padding: widget.padding, child: widget.child)),
    );
    if (widget.light) {
      return Padding(
        padding: widget.margin,
        child: Material(color: p.pc, borderRadius: r, clipBehavior: Clip.antiAlias, child: InkWell(onTap: widget.onTap == null ? null : () { hap.tick(); widget.onTap!(); }, child: content)),
      );
    }
    final cols = widget.colors ?? p.hero;
    return Padding(
      padding: widget.margin,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: r, boxShadow: [BoxShadow(color: p.pri2.withValues(alpha: .35), blurRadius: 26, spreadRadius: -14, offset: const Offset(0, 10))]),
        child: ClipRRect(
          borderRadius: r,
          child: Stack(children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sheen,
                builder: (_, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cols,
                      begin: Alignment(-1.4 + _sheen.value * 1.4, -1),
                      end: Alignment(0.6 + _sheen.value * 1.4, 1),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: StarLayer(color: Color(0xFFD6B764), opacity: .9, seconds: 55)),
            PositionedDirectional(
              top: -70,
              end: -50,
              child: AnimatedBuilder(
                animation: _glow,
                builder: (_, c) => Transform.translate(offset: Offset(-26 * _glow.value, 22 * _glow.value), child: Transform.scale(scale: 1 + .18 * _glow.value, child: c)),
                child: IgnorePointer(child: Container(width: 210, height: 210, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x57D6B764), Color(0x00D6B764)], stops: [0, .66])))),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: widget.onTap == null ? null : () { hap.tick(); widget.onTap!(); }, splashFactory: InkSparkle.splashFactory, child: content),
            ),
          ]),
        ),
      ),
    );
  }
}

/// بطاقة داكنة بنجوم (التذكير القادم / الصيام القادم) — .rhero
class RHero extends StatelessWidget {
  final IconData? iconData;
  final String icon, kicker, title;
  final String? when;
  final List<Widget> actions;
  final bool ring;
  const RHero({super.key, this.iconData, this.icon = 'bell', required this.kicker, required this.title, this.when, this.actions = const [], this.ring = true});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DecoratedBox(
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(28)), boxShadow: [BoxShadow(color: Color(0x660B2A26), blurRadius: 28, spreadRadius: -18, offset: Offset(0, 14))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(children: [
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF142F2E), Color(0xFF1B4A43), Color(0xFF143A36)], begin: Alignment.topRight, end: Alignment.bottomLeft)))),
            const Positioned.fill(child: StarLayer(color: Color(0xFFD6B764), opacity: .9, seconds: 60)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Color(0xFFF3EFE0)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x24B3923F), border: Border.all(color: const Color(0xFFB3923F), width: 1.5)),
                      child: ring ? RingingIcon(child: WIcon(icon, size: 26, color: const Color(0xFFD9B766))) : WIcon(icon, size: 26, color: const Color(0xFFD9B766)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(kicker, style: const TextStyle(fontSize: 13, color: Color(0xB3F3EFE0))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35))),
                      if (when != null) Text(when!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.gold == const Color(0xFFB3923F) ? const Color(0xFFD9B766) : p.gold)),
                    ])),
                  ]),
                  if (actions.isNotEmpty) ...[const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: actions)],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// أيقونة الجرس تهتز كل ~3 ثوانٍ (ring في الويب).
class RingingIcon extends StatefulWidget {
  final Widget child;
  const RingingIcon({super.key, required this.child});
  @override
  State<RingingIcon> createState() => _RingingIconState();
}

class _RingingIconState extends State<RingingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, c) {
            final t = _c.value;
            var a = 0.0;
            if (t > .6) {
              final k = (t - .6) / .4; // 0..1 خلال الاهتزاز
              a = (1 - k) * .24 * math.sin(k * math.pi * 5);
            }
            return Transform.rotate(angle: a, alignment: const Alignment(0, -.85), child: c);
          },
          child: widget.child,
        ),
      );
}

/// زر حبّة داخل البطاقة الداكنة (.pillb)
class PillB extends StatelessWidget {
  final String label;
  final String? icon;
  final bool outlined;
  final VoidCallback onTap;
  const PillB(this.label, this.onTap, {super.key, this.icon, this.outlined = false});
  @override
  Widget build(BuildContext context) => Material(
        color: outlined ? Colors.transparent : const Color(0x1AFFFFFF),
        shape: StadiumBorder(side: outlined ? const BorderSide(color: Color(0xBFB3923F), width: 1.5) : BorderSide.none),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () { hap.tick(); onTap(); },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[WIcon(icon!, size: 20, color: outlined ? const Color(0xFFD9B766) : const Color(0xFFF3EFE0)), const SizedBox(width: 8)],
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: outlined ? const Color(0xFFD9B766) : const Color(0xFFF3EFE0))),
            ]),
          ),
        ),
      );
}

class Ring extends StatelessWidget {
  final double v, size, stroke;
  final Color? color, track;
  final Widget? child;
  final Duration duration;
  const Ring({super.key, required this.v, this.size = 72, this.stroke = 8, this.color, this.track, this.child, this.duration = const Duration(milliseconds: 600)});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v.clamp(0, 1).toDouble()),
        duration: duration,
        curve: const Cubic(.3, 0, 0, 1),
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
      borderRadius: BorderRadius.circular(4),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: const Cubic(.3, 0, 0, 1),
        builder: (_, val, __) => LinearProgressIndicator(value: val, minHeight: 8, backgroundColor: track ?? p.surf2, valueColor: AlwaysStoppedAnimation(color ?? p.gold)),
      ),
    );
  }
}

/// مربع أيقونة مستدير (.ic): خلفية pc وأيقونة pri. يقبل IconData أو اسم أيقونة الويب.
class IconBox extends StatelessWidget {
  final IconData? icon;
  final String? name;
  final double size;
  final bool circle;
  const IconBox(this.icon, {super.key, this.size = 40, this.circle = false}) : name = null;
  const IconBox.named(this.name, {super.key, this.size = 40, this.circle = false}) : icon = null;
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(circle ? size / 2 : 14)),
      child: name != null ? Center(child: WIcon(name!, size: size * .55, color: p.pri)) : Icon(icon, color: p.pri, size: size * .55),
    );
  }
}

class ItemTile extends StatelessWidget {
  final IconData? icon;
  final String? iconName;
  final String title;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? trailing;
  const ItemTile({super.key, this.icon, this.iconName, required this.title, this.sub, this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return AppCard(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      onTap: onTap,
      child: Row(children: [
        iconName != null ? IconBox.named(iconName) : IconBox(icon),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (sub != null) Text(sub!, style: TextStyle(color: p.on2, fontSize: 12, height: 1.5)),
        ])),
        trailing ?? WIcon('chev', color: p.on2),
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
      floatingActionButton: fab == null ? null : _FabIn(child: fab!),
      body: Backdrop(
        child: ListView(
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(14, mq.padding.top + 6, 14, mq.padding.bottom + 110),
          children: [
            SizedBox(
              height: 52,
              child: Row(children: [
                if (back) _RoundBtn(WIcon('chevr', size: 22, color: p.on), () { hap.tick(); Navigator.of(context).maybePop(); }, p) else const SizedBox(width: 42),
                Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                if (actions.isEmpty) const SizedBox(width: 42) else ...actions,
              ]),
            ),
            const SizedBox(height: 4),
            ...children.asMap().entries.map((e) => _Stagger(index: e.key, child: e.value)),
          ],
        ),
      ),
    );
  }
}

/// ظهور الزر العائم بحركة (fabin)
class _FabIn extends StatelessWidget {
  final Widget child;
  const _FabIn({required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: const Cubic(.05, .7, .1, 1),
        builder: (_, v, c) => Opacity(opacity: v.clamp(0, 1).toDouble(), child: Transform.translate(offset: Offset(0, (1 - v) * 90), child: Transform.scale(scale: .6 + .4 * v, child: c))),
        child: child,
      );
}

class _Stagger extends StatelessWidget {
  final int index;
  final Widget child;
  const _Stagger({required this.index, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + (index.clamp(0, 6)) * 40),
        curve: const Cubic(.05, .7, .1, 1),
        builder: (_, v, c) => Opacity(opacity: v.clamp(0, 1).toDouble(), child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: c)),
        child: child,
      );
}

class _RoundBtn extends StatefulWidget {
  final Widget icon;
  final VoidCallback onTap;
  final Pal p;
  const _RoundBtn(this.icon, this.onTap, this.p);
  @override
  State<_RoundBtn> createState() => _RoundBtnState();
}

class _RoundBtnState extends State<_RoundBtn> {
  bool _d = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: _d ? .92 : 1,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: widget.p.surf,
          shape: CircleBorder(side: BorderSide(color: widget.p.line)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onHighlightChanged: (v) => setState(() => _d = v),
            onTap: widget.onTap,
            child: SizedBox(width: 42, height: 42, child: Center(child: widget.icon)),
          ),
        ),
      );
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const RoundIconButton(this.icon, this.onTap, {super.key, this.tooltip});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Tooltip(message: tooltip ?? '', child: _RoundBtn(Icon(icon, size: 22, color: p.on), () { hap.tick(); onTap(); }, p)),
    );
  }
}

/// شرائح الاختيار (.chip): الفعّالة بخلفية pc وإطار وخط pri.
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: it.$1 == selected ? p.pc : p.surf,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: it.$1 == selected ? p.pri : p.line),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () { hap.select(); onSelect(it.$1); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Text(it.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: it.$1 == selected ? p.pri : p.on)),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// عنوان قسم (h2 في الويب)
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
        child: Row(children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))), if (trailing != null) trailing!]),
      );
}

/// عنوان قسم بشريط ذهبي (.secH في v3)
class GoldTitle extends StatelessWidget {
  final String text;
  final String? sub;
  final Widget? trailing;
  const GoldTitle(this.text, {super.key, this.sub, this.trailing});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, constraints: const BoxConstraints(minHeight: 22), decoration: BoxDecoration(color: const Color(0xFFB3923F), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            if (sub != null) Text(sub!, style: TextStyle(fontSize: 12, color: p.on2)),
          ])),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class Sub extends StatelessWidget {
  final String text;
  final TextAlign? align;
  const Sub(this.text, {super.key, this.align});
  @override
  Widget build(BuildContext context) => Text(text, textAlign: align, style: TextStyle(color: Pal.of(context).on2, fontSize: 12, height: 1.55));
}

Future<bool> confirmDialog(BuildContext c, String title, String body, {String ok = 'حسنًا', bool danger = false}) async {
  final p = Pal.of(c);
  final r = await showGeneralDialog<bool>(
    context: c,
    barrierDismissible: true,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: .5),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, a, __, child) {
      final k = CurvedAnimation(parent: a, curve: const Cubic(.3, 0, 0, 1));
      return FadeTransition(opacity: k, child: ScaleTransition(scale: Tween(begin: .9, end: 1.0).animate(k), child: child));
    },
    pageBuilder: (_, __, ___) => Center(
      child: Material(
        color: p.surf,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(body, style: TextStyle(color: p.on2, height: 1.6)),
              const SizedBox(height: 14),
              Row(children: [
                TextButton(onPressed: () => Navigator.pop(c, true), child: Text(ok, style: TextStyle(color: danger ? const Color(0xFFA8332B) : p.pri, fontWeight: FontWeight.w700))),
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text('إلغاء', style: TextStyle(color: p.on2))),
              ]),
            ]),
          ),
        ),
      ),
    ),
  );
  return r == true;
}

/// لوحة سفلية Material 3: مقبض سحب، زوايا 28، ظل خلفية .5، حركة emphasized.
Future<T?> showAppSheet<T>(BuildContext c, Widget Function(BuildContext) b) {
  final p = Pal.of(c);
  return showModalBottomSheet<T>(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.surf,
    barrierColor: Colors.black.withValues(alpha: .5),
    elevation: 8,
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 380), reverseDuration: const Duration(milliseconds: 260), curve: const Cubic(.3, 0, 0, 1)),
    constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * .88),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)))),
          b(ctx),
        ]),
      ),
    ),
  );
}

void copyText(String t) {
  Clipboard.setData(ClipboardData(text: t));
  hap.click();
  toast('تم النسخ');
}
