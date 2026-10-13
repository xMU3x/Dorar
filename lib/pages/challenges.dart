import 'package:flutter/material.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/wicons.dart';

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
          const cats = {
            'quran': ('القرآن', 'book'), 'dhikr': ('ذكر', 'spark'), 'prayer': ('صلاة', 'mosque'), 'good': ('أعمال خير', 'hand'),
            'manners': ('أخلاق', 'user'), 'habits': ('عادات يومية', 'sun'), 'self': ('تطوير النفس', 'flag'), 'worship': ('عبادة', 'star'),
          };
          const ptsOf = {'day': 10, 'week': 30, 'month': 100};
          return PageScaffold(title: 'التحديات', children: [
            HeroCard(
              light: true,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(done >= S.length && S.isNotEmpty ? 'ما شاء الله! أتممت الكل' : done > 0 ? 'أحسنت، واصل' : 'ابدأ بأسهل تحدٍّ', style: const TextStyle(fontFamily: arabicFont, fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Sub('خطوة صغيرة اليوم تصنع عادة دائمة.'),
                  ])),
                  Ring(v: S.isEmpty ? 0 : done / S.length, size: 92, stroke: 10, color: p.pri, track: const Color(0x263C6A3E), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(nf(done), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.1)),
                    Sub('من ${nf(S.length)}'),
                  ])),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(24)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (var i = 0; i < 7; i++)
                      Builder(builder: (_) {
                        final d = act[dkey(DateTime(ws.year, ws.month, ws.day + i, 12))] != null;
                        return Column(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 34, height: 34,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: d ? p.gold : Colors.transparent, border: Border.all(color: d ? p.gold : p.line, width: 1.5)),
                            child: d ? const Center(child: WIcon('check', size: 18, color: Colors.white)) : null,
                          ),
                          const SizedBox(height: 6),
                          Sub(wd[i]),
                        ]);
                      }),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  WIcon('fire', size: 22, color: p.pri),
                  const SizedBox(width: 6),
                  Text('${nf(st.cur)} يوم متواصل', style: TextStyle(fontWeight: FontWeight.w700, color: p.pri)),
                  const Spacer(),
                  Sub('أفضل سلسلة ${nf(st.best)}'),
                ]),
              ]),
            ),
            Padding(padding: const EdgeInsets.only(top: 14), child: ChipRow(items: [for (final k in ['day', 'week', 'month']) (k, periodName[k]!)], selected: tab, onSelect: (v) => setState(() => tab = v))),
            Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 0), child: Text(periodName[tab]!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
            const Padding(padding: EdgeInsets.fromLTRB(4, 2, 4, 10), child: Sub('ابدأ بما تستطيع، فالخطوة الصغيرة تكفي')),
            for (var i = 0; i < S.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  margin: EdgeInsets.zero,
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderColor: i == nextIdx ? p.gold : null,
                  borderWidth: i == nextIdx ? 1.5 : 1,
                  onTap: () {
                    final x = S[i];
                    if (x.c['auto'] != null && x.v != null && !x.ok) { toast('يُحتسب هذا التحدي تلقائيًا عند إنجازه'); return; }
                    chalToggle('${x.c['id']}:${periodKey(tab)}');
                    touchActivity();
                    hap.click();
                  },
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (i == nextIdx) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [WIcon('flag', size: 18, color: p.gold), const SizedBox(width: 6), Text('خطوتك التالية', style: TextStyle(color: p.gold, fontWeight: FontWeight.w700, fontSize: 14))])),
                    Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: const Cubic(.05, .7, .1, 1),
                        width: 42, height: 42,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: S[i].ok ? p.pri : Colors.transparent, border: Border.all(color: S[i].ok ? p.pri : p.line, width: 2)),
                        child: Center(child: WIcon('check', size: 22, color: S[i].ok ? p.onpri : Colors.transparent)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(S[i].c['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Row(children: [
                          WIcon((cats[S[i].c['cat']] ?? ('', 'star')).$2, size: 14, color: p.on2),
                          const SizedBox(width: 6),
                          Flexible(child: Sub('${(cats[S[i].c['cat']] ?? ('', 'star')).$1}${S[i].v != null && !S[i].ok ? ' · ${nf(S[i].v!.clamp(0, S[i].t))}/${nf(S[i].t)}' : ''}')),
                        ]),
                      ])),
                      Directionality(textDirection: TextDirection.ltr, child: Text('+${ptsOf[tab]}', style: TextStyle(color: p.on2, fontSize: 13))),
                    ]),
                  ]),
                ),
              ),
            SectionTitle('الإنجازات', trailing: Sub('المستوى ${nf(lvl)} · ${nf(pn)} نقطة للمستوى التالي')),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.45, children: [
              for (final a in achievements(tot, st))
                Opacity(
                  opacity: a.$2 ? 1 : .5,
                  child: AppCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(12),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconBox.named(a.$2 ? 'trophy' : 'lock'),
                      const SizedBox(height: 8),
                      Text(a.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),
            const Padding(padding: EdgeInsets.all(30), child: Sub('التحديات للتذكير والمتابعة، وليست أحكامًا شرعية', align: TextAlign.center)),
          ]);
        },
      ),
    );
  }
}
