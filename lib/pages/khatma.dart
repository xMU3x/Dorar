import 'package:flutter/material.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/khatma.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class KhatmaPage extends StatelessWidget {
  const KhatmaPage({super.key});
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) {
        final p = Pal.of(context);
        final k = khatma(), pg = pagesToday();
        final read = ((k['read'] as num?) ?? 0).toInt(), goal = ((k['goal'] as num?) ?? 5).toInt(), done = ((k['done'] as num?) ?? 0).toInt();
        final rem = 604 - read, days = (rem / goal).ceil();
        final start = DateTime.tryParse(k['start'] as String? ?? '') ?? DateTime.now();
        final since = (DateTime.now().difference(start).inDays + 1).clamp(1, 100000);
        final nextP = (read + 1).clamp(1, 604), juz = juzOfPage(nextP);
        return PageScaffold(title: 'خطة الختمة', children: [
          HeroCard(margin: const EdgeInsets.only(top: 6), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ختمتك الحالية', style: TextStyle(color: Colors.white70)),
              Text('${nf(read)} من ${nf(604)} صفحة', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              Text('مستمرة منذ ${nf(since)} يوم', style: const TextStyle(color: Colors.white70)),
            ])),
            Ring(v: read / 604, size: 72, color: Colors.white, track: Colors.white24, child: Text('${nf((read / 604 * 100).round())}%', style: const TextStyle(fontWeight: FontWeight.w700))),
          ])),
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('ورد اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))), Sub('${nf(pg)}/${nf(goal)} صفحة')]),
            const SizedBox(height: 10),
            Bar(pg / goal),
            const SizedBox(height: 10),
            const Sub('أضف ما قرأته اليوم حتى تتابع التزامك بوضوح.'),
            const SizedBox(height: 10),
            Row(children: [
              for (final n in [1, 5, 10, 20])
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: FilledButton.tonal(onPressed: () {
                  hap.click();
                  if (khatmaAdd(n)) toast('ما شاء الله! أتممت ختمة كاملة، تقبّل الله منك');
                  chalCheck();
                }, child: Text('+${nf(n)}')))),
              IconButton(onPressed: () { hap.tick(); khatmaUndo(); }, icon: const Icon(Icons.undo_rounded)),
            ]),
          ])),
          AppCard(child: Row(children: [
            const IconBox(Icons.menu_book_rounded),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('الخطوة التالية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Sub('الصفحة القادمة في ختمتك: ${nf(nextP)} — الجزء ${nf(juz)}'),
            ])),
          ])),
          SectionTitle('ملخص خطتك', trailing: IconButton(onPressed: () async {
            if (await confirmDialog(context, 'إعادة الختمة؟', 'سيُصفَّر تقدّم ختمتك الحالية.', ok: 'إعادة', danger: true)) {
              store.upd('khatma', {}, (z) { z['read'] = 0; z['start'] = todayKey(); z['last'] = 0; });
            }
          }, icon: const Icon(Icons.refresh_rounded))),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25, children: [
            for (final x in [
              (Icons.flag_rounded, nf(rem), 'صفحة · المتبقي'), (Icons.calendar_month_rounded, nf(days), 'يوم · المدة المتوقعة'),
              (Icons.menu_book_rounded, nf(juz), 'من ${nf(30)} · الجزء الحالي'), (Icons.emoji_events_rounded, nf(done), 'ختمة · ختمات مكتملة'),
            ])
              AppCard(margin: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Icon(x.$1, color: p.pri), Text(x.$2, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)), Sub(x.$3),
              ])),
          ]),
          AppCard(child: Row(children: [
            Icon(Icons.tune_rounded, color: p.pri),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('عدّل الخطة حسب وقتك', style: TextStyle(fontWeight: FontWeight.w700)), Sub('هدفك الحالي ${nf(goal)} صفحات يوميًا')])),
            TextButton(onPressed: () async {
              final c = TextEditingController(text: '$goal');
              final ok = await showAppSheet<bool>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('الهدف اليومي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextField(controller: c, keyboardType: TextInputType.number, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
                  ]));
              if (ok == true) store.upd('khatma', {}, (z) => z['goal'] = (int.tryParse(c.text) ?? 5).clamp(1, 604));
            }, child: const Text('تعديل')),
          ])),
        ]);
      },
    );
  }
}
