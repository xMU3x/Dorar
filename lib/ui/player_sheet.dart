import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/player.dart';
import '../core/util.dart';
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

  /// زر دائري بنمط Material 3 (tonal): يتبع ألوان الثيم.
  Widget _tonal(Pal p, IconData icon, VoidCallback f, {double size = 52, double iconSize = 24, bool on = false, String? tip}) => Tooltip(
        message: tip ?? '',
        child: Material(
          color: on ? p.pri : p.pc,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () { hap.tick(); f(); },
            child: SizedBox(width: size, height: size, child: Icon(icon, size: iconSize, color: on ? p.onpri : p.pri)),
          ),
        ),
      );

  Widget _skip(Pal p, bool fwd) => _tonal(p, fwd ? Icons.forward_30_rounded : Icons.replay_30_rounded, () => player.skip(fwd ? 30 : -30), size: 48, iconSize: 26, tip: fwd ? 'تقديم ٣٠ ثانية' : 'رجوع ٣٠ ثانية');

  /// الغلاف: صورة الشيخ إن توفّرت، وإلا أيقونة مصحف مسطّحة (flat).
  Widget _cover(Pal p, Track t, double size) {
    Widget flat() => Container(
          color: p.pc,
          alignment: Alignment.center,
          child: Icon(Icons.auto_stories_rounded, size: size * .5, color: p.pri),
        );
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), boxShadow: softShadow(24, 10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: t.image == null
            ? flat()
            : Image.network(t.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => flat(), loadingBuilder: (_, c, pr) => pr == null ? c : flat()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mq = MediaQuery.of(context);
    final cover = math.min(mq.size.width * .62, mq.size.height * .32);
    return Scaffold(
      backgroundColor: p.bg,
      body: ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final t = player.cur;
          if (t == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).maybePop(); });
            return const SizedBox.shrink();
          }
          final repIcon = player.repeat == RepeatKind.one ? Icons.repeat_one_rounded : Icons.repeat_rounded;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(children: [
                const SizedBox(height: 6),
                Row(children: [
                  _tonal(p, Icons.keyboard_arrow_down_rounded, () => Navigator.of(context).maybePop(), size: 44, iconSize: 28, tip: 'إغلاق'),
                  Expanded(child: Text('الآن يُشغَّل', textAlign: TextAlign.center, style: TextStyle(color: p.on2, fontSize: 15, fontWeight: FontWeight.w700))),
                  _tonal(p, Icons.queue_music_rounded, _queueSheet, size: 44, iconSize: 22, tip: 'قائمة التشغيل'),
                ]),
                const Spacer(flex: 2),
                _cover(p, t, cover),
                const Spacer(flex: 2),
                Text(t.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.on, fontSize: 26, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 4),
                Text(t.sub, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.pri, fontSize: 17, fontWeight: FontWeight.w700)),
                if (t.extra != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(t.extra!, textAlign: TextAlign.center, style: TextStyle(color: p.on2, fontSize: 13))),
                if (player.error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(player.error!, style: const TextStyle(color: Color(0xFFD32F2F)))),
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
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Slider(
                            value: max <= 0 ? 0 : v.clamp(0, max).toDouble(),
                            max: max <= 0 ? 1 : max,
                            onChanged: max <= 0 ? null : (x) => setState(() => drag = x),
                            onChangeEnd: (x) { player.seek(Duration(milliseconds: x.toInt())); setState(() => drag = null); },
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(_fmt(Duration(milliseconds: v.toInt())), style: TextStyle(color: p.on2, fontSize: 13)),
                              Text(max <= 0 ? '--:--' : _fmt(dur), style: TextStyle(color: p.on2, fontSize: 13)),
                            ]),
                          ),
                        ),
                      ]);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _skip(p, false),
                    _tonal(p, Icons.skip_previous_rounded, player.prev, size: 58, iconSize: 32),
                    Material(
                      color: p.pri,
                      borderRadius: BorderRadius.circular(32),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () { hap.click(); player.toggle(); },
                        child: SizedBox(
                          width: 84, height: 84,
                          child: player.loading
                              ? Padding(padding: const EdgeInsets.all(26), child: CircularProgressIndicator(strokeWidth: 4, color: p.onpri))
                              : Icon(player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 48, color: p.onpri),
                        ),
                      ),
                    ),
                    _tonal(p, Icons.skip_next_rounded, player.next, size: 58, iconSize: 32),
                    _skip(p, true),
                  ]),
                ),
                const SizedBox(height: 18),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _tonal(p, repIcon, player.cycleRepeat, on: player.repeat != RepeatKind.off, tip: 'تكرار'),
                    _tonal(p, Icons.bedtime_outlined, _sleepSheet, on: player.sleepAt != null, tip: 'مؤقّت النوم'),
                  ]),
                ),
                const SizedBox(height: 18),
              ]),
            ),
          );
        },
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
                        Expanded(child: Text(player.queue[i].label, style: TextStyle(color: cur ? Colors.white : Colors.white70, fontWeight: cur ? FontWeight.w700 : FontWeight.w500, fontSize: 16))),
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
