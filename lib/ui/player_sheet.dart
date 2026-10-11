import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/player.dart';
import '../core/util.dart';
import '../pages/surah.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wicons.dart';

String _fmt(Duration d) {
  final m = d.inMinutes, s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// يفتح مشغّل القرآن بملء الشاشة تقريبًا (غلاف + شريط تقدّم + أدوات تحكم + قائمة التشغيل).
Future<void> showPlayer(BuildContext context) {
  final p = Pal.of(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.surf,
    barrierColor: Colors.black.withValues(alpha: .5),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 420), reverseDuration: const Duration(milliseconds: 280), curve: const Cubic(.3, 0, 0, 1)),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .94,
      minChildSize: .5,
      maxChildSize: .97,
      builder: (ctx, sc) => PlayerView(scroll: sc),
    ),
  );
}

class PlayerView extends StatefulWidget {
  final ScrollController scroll;
  const PlayerView({super.key, required this.scroll});
  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  double? drag;

  Widget _skip15(Pal p, bool fwd) => GestureDetector(
        onTap: () { hap.tick(); player.skip(fwd ? 15 : -15); },
        child: SizedBox(
          width: 52, height: 52,
          child: Stack(alignment: Alignment.center, children: [
            Icon(fwd ? Icons.rotate_right : Icons.rotate_left, size: 50, color: p.on),
            Text('15', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.on)),
          ]),
        ),
      );

  Widget _act(Pal p, IconData ic, String label, VoidCallback f, {bool on = false}) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: on ? p.pc : p.surf2,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () { hap.tick(); f(); },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(ic, size: 26, color: on ? p.pri : p.on),
                  const SizedBox(height: 6),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: on ? p.pri : p.on2, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ),
      );

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

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final t = player.cur;
        if (t == null) return const SizedBox.shrink();
        final repIcon = player.repeat == RepeatKind.one ? Icons.repeat_one : Icons.repeat;
        final repLabel = switch (player.repeat) { RepeatKind.off => 'تكرار', RepeatKind.one => 'تكرار سورة', RepeatKind.all => 'تكرار الكل' };
        return ListView(
          controller: widget.scroll,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)))),
            Center(
              child: Container(
                width: 190, height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  gradient: LinearGradient(colors: [p.pri2, p.pri], begin: Alignment.bottomRight, end: Alignment.topLeft),
                  boxShadow: [BoxShadow(color: p.pri.withValues(alpha: .35), blurRadius: 40, spreadRadius: -12, offset: const Offset(0, 18))],
                ),
                child: Center(child: WIcon('book', size: 84, color: p.onpri)),
              ),
            ),
            const SizedBox(height: 22),
            Text('سورة ${t.title}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(player.error ?? t.sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: player.error != null ? const Color(0xFFA8332B) : p.on2)),
            const SizedBox(height: 14),
            StreamBuilder<Duration?>(
              stream: player.durationStream,
              builder: (_, ds) => StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (_, ps) {
                  final dur = ds.data ?? Duration.zero, pos = ps.data ?? Duration.zero;
                  final max = dur.inMilliseconds.toDouble();
                  final v = drag ?? (max <= 0 ? 0.0 : pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble());
                  return Column(children: [
                    Slider(
                      value: max <= 0 ? 0 : v.clamp(0, max),
                      max: max <= 0 ? 1 : max,
                      onChanged: max <= 0 ? null : (x) => setState(() => drag = x),
                      onChangeEnd: (x) { player.seek(Duration(milliseconds: x.toInt())); setState(() => drag = null); },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(_fmt(Duration(milliseconds: v.toInt())), style: TextStyle(color: p.on2, fontSize: 15)),
                          Text(max <= 0 ? '--:--' : _fmt(dur), style: TextStyle(color: p.on2, fontSize: 15)),
                        ]),
                      ),
                    ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _skip15(p, false),
              IconButton(iconSize: 40, onPressed: () { hap.tick(); player.prev(); }, icon: Icon(Icons.skip_previous, color: p.on)),
              GestureDetector(
                onTap: () { hap.click(); player.toggle(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 92, height: 92,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.pri, boxShadow: [BoxShadow(color: p.pri.withValues(alpha: .4), blurRadius: 24, spreadRadius: -6, offset: const Offset(0, 10))]),
                  child: player.loading
                      ? Padding(padding: const EdgeInsets.all(28), child: CircularProgressIndicator(strokeWidth: 4, color: p.onpri))
                      : Icon(player.playing ? Icons.pause : Icons.play_arrow, size: 52, color: p.onpri),
                ),
              ),
              IconButton(iconSize: 40, onPressed: () { hap.tick(); player.next(); }, icon: Icon(Icons.skip_next, color: p.on)),
              _skip15(p, true),
            ]),
            const SizedBox(height: 22),
            Row(children: [
              _act(p, repIcon, repLabel, player.cycleRepeat, on: player.repeat != RepeatKind.off),
              _act(p, Icons.bedtime_outlined, player.sleepAt == null ? 'مؤقت النوم' : 'ينتهي ${_fmt(player.sleepAt!.difference(DateTime.now()).isNegative ? Duration.zero : player.sleepAt!.difference(DateTime.now()))}', _sleepSheet, on: player.sleepAt != null),
              _act(p, Icons.file_download_outlined, 'تحميل', () async {
                final ok = await launchUrl(Uri.parse(t.url), mode: LaunchMode.externalApplication);
                if (!ok) toast('تعذّر فتح رابط التحميل');
              }),
              _act(p, Icons.menu_book_outlined, 'فتح السورة', () {
                if (t.surah == null) return;
                Navigator.of(context).pop();
                pushPage(SurahPage(t.surah!));
              }),
            ]),
            if (player.queue.length > 1) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 26, 4, 8),
                child: Row(children: [
                  const Expanded(child: Text('قائمة التشغيل', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                  Sub('${nf(player.index + 1)} / ${nf(player.queue.length)}'),
                ]),
              ),
              for (var i = 0; i < player.queue.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: i == player.index ? p.pc : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () { hap.tick(); player.play(player.queue, i); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(children: [
                          SizedBox(width: 30, child: i == player.index ? Icon(player.playing ? Icons.graphic_eq : Icons.pause, color: p.pri, size: 22) : Text(nf(i + 1), style: TextStyle(color: p.on2))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(player.queue[i].title, style: TextStyle(fontWeight: i == player.index ? FontWeight.w700 : FontWeight.w500, color: i == player.index ? p.pri : p.on))),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
