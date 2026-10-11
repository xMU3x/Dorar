import 'package:flutter/material.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});
  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  String tab = 'day';

  @override
  void initState() {
    super.initState();
    chalCheck();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) => FutureBuilder(
        future: chalStateFor(tab),
        builder: (context, snap) {
          final p = Pal.of(context);
          final S = snap.data ?? [];
          final done = S.where((x) => x.ok).length;
          final st = streak(), tot = chalTotal(), lvl = tot.pts ~/ 100 + 1, pn = 100 - tot.pts % 100;
          final act = ((store.peekMap('activity', {'days': {}})['days']) as Map?) ?? {};
          final ws = weekStart(DateTime.now());
          final nextIdx = S.indexWhere((x) => !x.ok);
          const wd = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
          return PageScaffold(title: 'التحديات', children: [
            HeroCard(margin: const EdgeInsets.only(top: 6), child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(done >= S.length && S.isNotEmpty ? 'ما شاء الله! أتممت الكل' : done > 0 ? 'أحسنت، واصل' : 'ابدأ بأسهل تحدٍّ', style: const TextStyle(fontFamily: arabicFont, fontSize: 26, fontWeight: FontWeight.w700)),
                  const Text('خطوة صغيرة اليوم تصنع عادة دائمة.', style: TextStyle(color: Colors.white70)),
                ])),
                Ring(v: S.isEmpty ? 0 : done / S.length, size: 80, color: Colors.white, track: Colors.white24, child: Text('${nf(done)}/${nf(S.length)}', style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                for (var i = 0; i < 7; i++)
                  Column(children: [
                    CircleAvatar(radius: 13, backgroundColor: act[dkey(DateTime(ws.year, ws.month, ws.day + i, 12))] != null ? p.gold : Colors.white24, child: act[dkey(DateTime(ws.year, ws.month, ws.day + i, 12))] != null ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null),
                    const SizedBox(height: 4),
                    Text(wd[i], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ]),
              ]),
              const SizedBox(height: 12),
              Row(children: [Text('🔥 ${nf(st.cur)} يوم متواصل', style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text('أفضل سلسلة ${nf(st.best)}', style: const TextStyle(color: Colors.white70))]),
            ])),
            Padding(padding: const EdgeInsets.only(top: 14), child: ChipRow(items: [for (final k in ['day', 'week', 'month']) (k, periodName[k]!)], selected: tab, onSelect: (v) => setState(() => tab = v))),
            SectionTitle(periodName[tab]!),
            const Sub('ابدأ بما تستطيع، فالخطوة الصغيرة تكفي'),
            for (var i = 0; i < S.length; i++)
              AppCard(
                margin: const EdgeInsets.only(top: 10),
                radius: 24,
                color: i == nextIdx ? p.pc : p.surf,
                onTap: () {
                  final x = S[i];
                  if (x.c['auto'] != null && x.v != null && !x.ok) { toast('يُحتسب هذا التحدي تلقائيًا عند إنجازه'); return; }
                  chalToggle('${x.c['id']}:${periodKey(tab)}');
                  touchActivity();
                  hap.click();
                },
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (i == nextIdx) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(Icons.flag_rounded, size: 16, color: p.pri), const SizedBox(width: 4), Text('خطوتك التالية', style: TextStyle(color: p.pri, fontWeight: FontWeight.w700, fontSize: 13))])),
                  Row(children: [
                    AnimatedContainer(duration: const Duration(milliseconds: 220), width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: S[i].ok ? p.pri : Colors.transparent, border: Border.all(color: S[i].ok ? p.pri : p.on2, width: 2)), child: S[i].ok ? Icon(Icons.check_rounded, size: 18, color: p.onpri) : null),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(S[i].c['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Sub('${chalCats[S[i].c['cat']]?.first ?? ''}${S[i].v != null ? ' · ${nf(S[i].v!.clamp(0, S[i].t))}/${nf(S[i].t)}' : ''}'),
                    ])),
                  ]),
                ]),
              ),
            SectionTitle('الإنجازات', trailing: Sub('المستوى ${nf(lvl)} · ${nf(pn)} نقطة للتالي')),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.7, children: [
              for (final a in achievements(tot, st))
                Opacity(opacity: a.$2 ? 1 : .5, child: AppCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(10), radius: 22, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(a.$2 ? Icons.emoji_events_rounded : Icons.lock_rounded, color: p.gold), Text(a.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]))),
            ]),
            const Padding(padding: EdgeInsets.all(16), child: Sub('التحديات للتذكير والمتابعة، وليست أحكامًا شرعية', align: TextAlign.center)),
          ]);
        },
      ),
    );
  }
}
