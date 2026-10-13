import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/player.dart';
import '../core/util.dart';
import '../pages/surah.dart';
import 'theme.dart';
import 'widgets.dart';

String _fmt(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  final mm = m.toString().padLeft(2, '0'), ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

bool _open = false;

/// يفتح المشغّل بملء الشاشة (شاشة كاملة وليست لوحة سفلية).
Future<void> showPlayer(BuildContext context) async {
  if (_open || player.cur == null) return;
  _open = true;
  try {
    await Navigator.of(navKey.currentContext ?? context, rootNavigator: true).push(PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const PlayerPage(),
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: const Cubic(.3, 0, 0, 1), reverseCurve: Curves.easeInCubic);
        return SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(c), child: child);
      },
    ));
  } finally {
    _open = false;
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  double? drag;

  Future<void> _sleepSheet() async {
    final r = await showAppSheet<int>(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مؤقت النوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const Padding(padding: EdgeInsets.only(top: 2, bottom: 10), child: Sub('يتوقف التشغيل تلقائيًا بعد المدة المختارة.')),
          for (final m in const [5, 10, 15, 30, 45, 60])
            ItemTile(iconName: 'clock', title: m == 60 ? 'ساعة' : '${nf(m)} دقيقة', onTap: () => Navigator.pop(ctx, m)),
          if (player.sleepAt != null) ItemTile(iconName: 'close', title: 'إلغاء المؤقت', onTap: () => Navigator.pop(ctx, 0)),
        ]));
    if (r == null) return;
    player.setSleep(r == 0 ? null : Duration(minutes: r));
    toast(r == 0 ? 'أُلغي مؤقت النوم' : 'سيتوقف التشغيل بعد ${nf(r)} دقيقة');
  }

  void _queueSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1A0F13),
      barrierColor: Colors.black.withValues(alpha: .6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: .78, minChildSize: .4, maxChildSize: .95,
        builder: (ctx, _) => const _QueueView(),
      ),
    );
  }

  Widget _circle(Pal p, Widget child, VoidCallback f, {double size = 56, bool on = false, Color? bg}) => GestureDetector(
        onTap: () { hap.tick(); f(); },
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg ?? (on ? Colors.white.withValues(alpha: .16) : Colors.white.withValues(alpha: .05)), border: Border.all(color: Colors.white.withValues(alpha: on ? .5 : .18))),
          child: Center(child: child),
        ),
      );

  Widget _skip(Pal p, bool fwd) => _circle(p, Stack(alignment: Alignment.center, children: [
        Icon(fwd ? Icons.rotate_right : Icons.rotate_left, size: 34, color: Colors.white),
        const Padding(padding: EdgeInsets.only(top: 2), child: Text('30', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
      ]), () => player.skip(fwd ? 30 : -30));

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mq = MediaQuery.of(context);
    final cover = math.min(mq.size.width * .46, mq.size.height * .22); // لوجو أصغر (كان ٧٢٪/٣٤٪)
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF0B0809), const Color(0xFF120A0D), p.hero.last.withValues(alpha: .85)], stops: const [0, .55, 1])),
        child: ListenableBuilder(
          listenable: player,
          builder: (context, _) {
            final t = player.cur;
            if (t == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).maybePop(); });
              return const SizedBox.shrink();
            }
            final repIcon = player.repeat == RepeatKind.one ? Icons.repeat_one : Icons.repeat;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(children: [
                  const SizedBox(height: 6),
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 10),
                  Row(children: [
                    _circle(p, const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28), () => Navigator.of(context).maybePop(), size: 46),
                    const Expanded(child: Text('الآن يُشغَّل', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500))),
                    const SizedBox(width: 46),
                  ]),
                  const Spacer(flex: 2),
                  Container(
                    width: cover, height: cover,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: p.pri.withValues(alpha: .7), width: 2.5), boxShadow: [BoxShadow(color: p.pri.withValues(alpha: .45), blurRadius: 60, spreadRadius: -8)]),
                    child: ClipOval(child: Image.asset('assets/brand/app_icon.png', fit: BoxFit.cover)),
                  ),
                  const Spacer(flex: 2),
                  Text(t.sub, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'سورة ${t.title}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      if (t.extra != null) TextSpan(text: '  -  ${t.extra}', style: const TextStyle(color: Colors.white60)),
                    ]),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 17),
                  ),
                  if (player.error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(player.error!, style: const TextStyle(color: Color(0xFFFF8A80)))),
                  const Spacer(),
                  StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    builder: (_, ds) => StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (_, ps) {
                        final dur = ds.data ?? Duration.zero, pos = ps.data ?? Duration.zero;
                        final max = dur.inMilliseconds.toDouble();
                        final v = drag ?? (max <= 0 ? 0.0 : pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble());
                        return Column(children: [
                          SliderTheme(
                            data: SliderThemeData(trackHeight: 5, activeTrackColor: p.pri, inactiveTrackColor: Colors.white.withValues(alpha: .18), thumbColor: Colors.white, overlayColor: Colors.white24, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9)),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Slider(
                                value: max <= 0 ? 0 : v.clamp(0, max).toDouble(),
                                max: max <= 0 ? 1 : max,
                                onChanged: max <= 0 ? null : (x) => setState(() => drag = x),
                                onChangeEnd: (x) { player.seek(Duration(milliseconds: x.toInt())); setState(() => drag = null); },
                              ),
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(_fmt(Duration(milliseconds: v.toInt())), style: const TextStyle(color: Colors.white60, fontSize: 14)),
                                Text(max <= 0 ? '--:--' : _fmt(dur), style: const TextStyle(color: Colors.white60, fontSize: 14)),
                              ]),
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _circle(p, const Icon(Icons.skip_previous, color: Colors.white, size: 32), player.prev, size: 66),
                      GestureDetector(
                        onTap: () { hap.click(); player.toggle(); },
                        child: Container(
                          width: 92, height: 92,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [p.pri2, p.hero.last], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: Colors.white.withValues(alpha: .28), width: 1.5), boxShadow: [BoxShadow(color: p.pri.withValues(alpha: .5), blurRadius: 28, spreadRadius: -6)]),
                          child: player.loading
                              ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white))
                              : Icon(player.playing ? Icons.pause : Icons.play_arrow, size: 52, color: Colors.white),
                        ),
                      ),
                      _circle(p, const Icon(Icons.skip_next, color: Colors.white, size: 32), player.next, size: 66),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _skip(p, false),
                      _circle(p, Icon(repIcon, color: Colors.white, size: 24), player.cycleRepeat, on: player.repeat != RepeatKind.off),
                      _circle(p, const Icon(Icons.queue_music, color: Colors.white, size: 26), _queueSheet),
                      _circle(p, Icon(Icons.bedtime_outlined, color: Colors.white, size: 24), _sleepSheet, on: player.sleepAt != null),
                      _skip(p, true),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton.icon(
                      onPressed: t.surah == null ? null : () { Navigator.of(context).maybePop(); pushPage(SurahPage(t.surah!)); },
                      icon: const Icon(Icons.menu_book_outlined, size: 18, color: Colors.white70),
                      label: const Text('فتح السورة', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async { final ok = await launchUrl(Uri.parse(t.url), mode: LaunchMode.externalApplication); if (!ok) toast('تعذّر فتح رابط التحميل'); },
                      icon: const Icon(Icons.file_download_outlined, size: 18, color: Colors.white70),
                      label: const Text('تحميل', style: TextStyle(color: Colors.white70)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// قائمة التشغيل: تفتح مباشرةً على السورة الحالية وتتبعها تلقائيًا عند الانتقال.
class _QueueView extends StatefulWidget {
  const _QueueView();
  @override
  State<_QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<_QueueView> {
  static const _h = 58.0;
  late final ScrollController _sc = ScrollController(initialScrollOffset: math.max(0, player.index * _h - 150));
  int _last = player.index;

  @override
  void initState() {
    super.initState();
    player.addListener(_onPlayer);
  }

  void _onPlayer() {
    if (player.index != _last && _sc.hasClients) {
      _last = player.index;
      final max = _sc.position.maxScrollExtent;
      _sc.animateTo(math.min(max, math.max(0, player.index * _h - 150)), duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    player.removeListener(_onPlayer);
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ListenableBuilder(
      listenable: player,
      builder: (_, __) => Column(children: [
        Container(width: 44, height: 5, margin: const EdgeInsets.only(top: 10, bottom: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(children: [
            const Expanded(child: Text('قائمة التشغيل', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
            Text('${nf(player.index + 1)} / ${nf(player.queue.length)}', style: const TextStyle(color: Colors.white60)),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'الانتقال للسورة الحالية',
              onPressed: () { if (_sc.hasClients) _sc.animateTo(math.max(0, player.index * _h - 150), duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic); },
              icon: const Icon(Icons.my_location, color: Colors.white70, size: 20),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            controller: _sc,
            itemExtent: _h,
            itemCount: player.queue.length,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            itemBuilder: (_, i) {
              final cur = i == player.index;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Material(
                  color: cur ? p.pri.withValues(alpha: .28) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () { hap.tick(); player.jumpTo(i); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(children: [
                        SizedBox(width: 34, child: cur ? Icon(player.playing ? Icons.graphic_eq : Icons.pause, color: Colors.white, size: 22) : Text(nf(i + 1), style: const TextStyle(color: Colors.white54))),
                        Expanded(child: Text('سورة ${player.queue[i].title}', style: TextStyle(color: cur ? Colors.white : Colors.white70, fontWeight: cur ? FontWeight.w700 : FontWeight.w500, fontSize: 16))),
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
