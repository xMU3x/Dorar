import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/hijri_util.dart';
import '../core/khatma.dart';
import '../core/qindex.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/nav.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'quran.dart';

const _khatmaDua = 'اللَّهُمَّ ارْحَمْنِي بِالْقُرْآنِ، وَاجْعَلْهُ لِي إِمَامًا وَنُورًا وَهُدًى وَرَحْمَةً.\nاللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ، وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ، وَارْزُقْنِي تِلَاوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ، وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ الْعَالَمِينَ.\nاللَّهُمَّ اجْعَلِ الْقُرْآنَ رَبِيعَ قَلْبِي، وَنُورَ صَدْرِي، وَجَلَاءَ حُزْنِي، وَذَهَابَ هَمِّي وَغَمِّي.\nاللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي.';

int _juzEnd(int j) => j >= 30 ? 604 : juzStartPage[j] - 1; // j من 1
const _plans = [(30, 'ختمة في شهر', 'ختمة كاملة في ٣٠ يومًا'), (60, 'ختمة في شهرين', 'وتيرة هادئة تناسب الانشغال'), (90, 'ختمة في ٣ أشهر', 'صفحات قليلة كل يوم'), (120, 'ختمة في ٤ أشهر', 'خمس صفحات تقريبًا يوميًا'), (180, 'ختمة في ٦ أشهر', 'ثلاث صفحات يوميًا'), (365, 'ختمة في سنة', 'صفحتان يوميًا تقريبًا')];

class KhatmaPage extends StatefulWidget {
  const KhatmaPage({super.key});
  @override
  State<KhatmaPage> createState() => _KhatmaPageState();
}

class _KhatmaPageState extends State<KhatmaPage> {
  String tab = 'current';
  double newDays = 60;
  bool fresh = false;
  late final ScrollController _juzC = ScrollController();

  @override
  void dispose() {
    _juzC.dispose();
    super.dispose();
  }

  void _setPlan(int days, {bool reset = false}) {
    final goal = (604 / days).ceil().clamp(1, 604);
    store.upd('khatma', {}, (z) {
      z['goal'] = goal;
      if (reset) { z['read'] = 0; z['start'] = todayKey(); z['last'] = 0; }
    });
    toast('تم ضبط الخطة: ${nf(goal)} صفحة يوميًا');
    setState(() => tab = 'current');
  }

  Future<void> _gear() async {
    final k = khatma();
    final c = TextEditingController(text: '${((k['goal'] as num?) ?? 5).toInt()}');
    await showAppSheet<void>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إعدادات الختمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Sub('ختمات مكتملة: ${nf(((k['done'] as num?) ?? 0).toInt())}'),
          const SizedBox(height: 12),
          const Text('الهدف اليومي (صفحات)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: c, keyboardType: TextInputType.number, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: () { store.upd('khatma', {}, (z) => z['goal'] = (int.tryParse(c.text) ?? 5).clamp(1, 604)); Navigator.pop(ctx); }, child: const Text('حفظ')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              if (await confirmDialog(context, 'إعادة الختمة؟', 'سيُصفَّر تقدّم ختمتك الحالية.', ok: 'إعادة', danger: true)) {
                store.upd('khatma', {}, (z) { z['read'] = 0; z['start'] = todayKey(); z['last'] = 0; });
              }
            },
            icon: const Icon(Icons.refresh, color: Color(0xFFA8332B)),
            label: const Text('إعادة الختمة من البداية', style: TextStyle(color: Color(0xFFA8332B))),
          ),
        ]));
  }

  void _stats(int read, int goal, int done, int pg) {
    final rem = 604 - read;
    showAppSheet(context, (ctx) {
      final p = Pal.of(ctx);
      Widget r(IconData i, String v, String l) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(i, color: p.pri), title: Text(l), trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)));
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('إحصاءات مفصلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        r(Icons.flag, nf(rem), 'صفحة · المتبقي'),
        r(Icons.calendar_month, nf((rem / goal).ceil()), 'يوم · المدة المتوقعة'),
        r(Icons.menu_book, nf(juzOfPage((read + 1).clamp(1, 604))), 'الجزء الحالي من ٣٠'),
        r(Icons.today, '${nf(pg)} / ${nf(goal)}', 'ورد اليوم'),
        r(Icons.emoji_events, nf(done), 'ختمات مكتملة'),
        r(Icons.local_fire_department, nf(streak().cur), 'أيام متتالية'),
      ]);
    });
  }

  void _review(int juzDone) {
    showAppSheet(context, (ctx) {
      final p = Pal.of(ctx);
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('مراجعة الأجزاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const Sub('الأجزاء التي أتممت قراءتها، اضغط جزءًا لإعادة قراءته.'),
        const SizedBox(height: 10),
        if (juzDone == 0) const Padding(padding: EdgeInsets.all(20), child: Sub('لم تُكمل أي جزء بعد', align: TextAlign.center)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var j = 1; j <= juzDone; j++)
            GestureDetector(
              onTap: () async { Navigator.pop(ctx); await openJuz(j); },
              child: Container(width: 70, padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(14)), child: Column(children: [Icon(Icons.refresh, size: 18, color: p.pri), Text('الجزء ${nf(j)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))])),
            ),
        ]),
      ]);
    });
  }

  String _lastTxt(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = dayDiff(d, DateTime.now());
    final day = diff == 0 ? 'اليوم' : diff == 1 ? 'أمس' : '${nf(d.day)} ${gmonths[d.month - 1]}';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$day - ${nf(h)}:${pad(d.minute)} ${d.hour < 12 ? 'ص' : 'م'}';
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(builder: (context, _) {
      final p = Pal.of(context);
      final k = khatma(), pg = pagesToday();
      final read = ((k['read'] as num?) ?? 0).toInt(), goal = (((k['goal'] as num?) ?? 5).toInt()).clamp(1, 604), done = ((k['done'] as num?) ?? 0).toInt();
      final planDays = (604 / goal).ceil(), remDays = ((604 - read) / goal).ceil();
      final start = DateTime.tryParse(k['start'] as String? ?? '') ?? DateTime.now();
      final end = addDays(start, planDays - 1);
      final hs = hj(start), he = hj(end);
      var juzDone = 0;
      for (var j = 1; j <= 30; j++) { if (_juzEnd(j) <= read) juzDone++; }
      final cur = juzOfPage((read + 1).clamp(1, 604));
      final cs = juzStartPage[cur - 1], ce = _juzEnd(cur);
      final jv = ((read + 1 - cs) / (ce - cs + 1)).clamp(0.0, 1.0).toDouble();
      final v = read / 604;
      final lt = ((k['lt'] as num?) ?? 0).toInt();
      final lastN = ((k['last'] as num?) ?? 0).toInt();
      return PageScaffold(
        title: 'ختمة القرآن',
        subtitle: 'رحلة إيمانية نحو مجتمع كتاب الله',
        arch: true,
        actions: [
          RoundIconButton(Icons.settings_outlined, _gear, tooltip: 'إعدادات الختمة'),
          RoundIconButton(Icons.groups_outlined, () => Share.share('أتممت ${nf(read)} من ٦٠٤ صفحة في ختمتي (${nf((v * 100).round())}٪) عبر تطبيق دُرَر'), tooltip: 'مشاركة'),
        ],
        children: [
          AppCard(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(Icons.menu_book_rounded, color: p.pri, size: 30), const SizedBox(width: 8), const Text('ختمتي الحالية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))]),
                    const SizedBox(height: 8),
                    Text('ختمة في ${nf(planDays)} يوم', style: TextStyle(fontSize: 15, color: p.on2)),
                    const SizedBox(height: 4),
                    Text('${nf(hs.d)} ${hmonths[hs.m - 1]} ${nf(hs.y)} هـ - ${nf(he.d)} ${hmonths[he.m - 1]} ${nf(he.y)} هـ', style: TextStyle(fontSize: 13.5, color: p.on2, height: 1.5)),
                  ]),
                ),
                Ring(v: v, size: 128, stroke: 12, track: p.surf2, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${nf((v * 100).round())}%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  Text('${nf(juzDone)} من ${nf(30)}', style: TextStyle(fontSize: 13, color: p.on2)),
                ])),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: StatTile(Icons.pie_chart_rounded, '${nf((v * 100).round())}%', 'نسبة الإنجاز')),
                const SizedBox(width: 8),
                Expanded(child: StatTile(Icons.menu_book_rounded, nf(juzDone), 'الأجزاء المكتملة')),
                const SizedBox(width: 8),
                Expanded(child: StatTile(Icons.hourglass_bottom, nf(remDays), 'يوماً متبقياً')),
                const SizedBox(width: 8),
                Expanded(child: StatTile(Icons.calendar_month, nf(planDays), 'إجمالي الأيام')),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          TabPills(selected: tab, onSelect: (t) => setState(() => tab = t), items: const [('current', 'الختمة الحالية', Icons.menu_book_outlined), ('plans', 'الخطط الجاهزة', Icons.calendar_month_outlined), ('new', 'إنشاء خطة جديدة', Icons.add_circle_outline)]),
          if (tab == 'current') ...[
            AppCard(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              child: Column(children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: SecHead('التقدم التفصيلي', icon: Icons.bar_chart_rounded)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 84,
                  child: ListView.builder(
                    controller: _juzC,
                    scrollDirection: Axis.horizontal,
                    itemCount: 30,
                    itemBuilder: (_, i) {
                      final j = i + 1, isDone = _juzEnd(j) <= read, isCur = j == cur;
                      return GestureDetector(
                        onTap: () => openJuz(j),
                        child: Container(
                          width: 66,
                          margin: const EdgeInsetsDirectional.only(end: 4),
                          child: Column(children: [
                            Container(
                              width: 52, height: 52, alignment: Alignment.center,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: isDone ? p.pri : p.surf2, border: isCur ? Border.all(color: p.pri, width: 2.2) : null, boxShadow: isDone ? [BoxShadow(color: p.pri.withValues(alpha: .25), blurRadius: 0, spreadRadius: 4)] : null),
                              child: isDone ? Icon(Icons.check, color: p.onpri, size: 26) : Text(nf(j), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isCur ? p.on : p.on2)),
                            ),
                            const SizedBox(height: 5),
                            Text('الجزء ${nf(j)}', style: TextStyle(fontSize: 11.5, fontWeight: isCur ? FontWeight.w800 : FontWeight.w500, color: isCur ? p.on : p.on2)),
                            if (isCur) Icon(Icons.arrow_drop_up, size: 16, color: p.on),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SecHead('قراءات اليوم', icon: Icons.menu_book_rounded, trailing: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: () => openPage(read + 1),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('متابعة القراءة'),
                  iconAlignment: IconAlignment.end,
                )),
                const SizedBox(height: 10),
                FutureBuilder<QIndex>(
                  future: qIndex(),
                  builder: (_, qs) => FutureBuilder<List>(
                    future: data.surahs(),
                    builder: (_, ss) {
                      String nm(int? s) => s == null || ss.data == null ? '…' : (ss.data![s - 1][1] as String).replaceFirst(RegExp(r'^سُورَةُ\s*'), '');
                      final a = nm(qs.data?.juzStart[cur]?.$1), b = nm(qs.data?.juzEndSurah[cur]);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => openJuz(cur),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                          decoration: BoxDecoration(color: p.surf2.withValues(alpha: .55), borderRadius: BorderRadius.circular(16)),
                          child: Column(children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('الجزء ${nf(cur)}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                                Text('من سورة $a إلى سورة $b', style: TextStyle(fontSize: 14, color: p.on2)),
                              ])),
                              Icon(Icons.chevron_left, color: p.on2),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [Text('${nf((jv * 100).round())}%', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 8), Expanded(child: Bar(jv, track: p.surf))]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [Text('ورد اليوم', style: TextStyle(color: p.on2)), const Spacer(), Text('${nf(pg)}/${nf(goal)} صفحة', style: TextStyle(color: p.pri, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 6),
                Bar(pg / goal, track: p.surf2),
                const SizedBox(height: 10),
                const Sub('أضف ما قرأته اليوم حتى تتابع التزامك بوضوح.'),
                const SizedBox(height: 8),
                Row(children: [
                  for (final n in [1, 5, 10, 20])
                    Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: FilledButton.tonal(onPressed: () {
                      hap.click();
                      if (khatmaAdd(n)) toast('ما شاء الله! أتممت ختمة كاملة، تقبّل الله منك');
                      chalCheck();
                    }, child: Text('+${nf(n)}')))),
                  IconButton(onPressed: () { hap.tick(); khatmaUndo(); }, icon: const Icon(Icons.undo)),
                ]),
              ]),
            ),
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(children: [
                const SecHead('آخر قراءة', icon: Icons.history),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                  decoration: BoxDecoration(color: p.surf2.withValues(alpha: .55), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    CheckDot(lastN > 0, size: 46),
                    const SizedBox(width: 12),
                    Expanded(child: lastN == 0 ? Sub('لم تُسجَّل قراءة بعد') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('الجزء ${nf(juzOfPage(read.clamp(1, 604)))}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('أضفتَ ${nf(lastN)} صفحة · وصلت إلى الصفحة ${nf(read)}', style: TextStyle(fontSize: 13, color: p.on2)),
                      if (lt > 0) Text(_lastTxt(lt), style: TextStyle(fontSize: 12.5, color: p.on2)),
                    ])),
                  ]),
                ),
              ]),
            ),
            Row(children: [
              Expanded(child: _tile(p, Icons.bar_chart_rounded, 'إحصاءات مفصلة', 'تتبع تقدمك بالتفصيل', () => _stats(read, goal, done, pg))),
              const SizedBox(width: 10),
              Expanded(child: _tile(p, Icons.autorenew, 'مراجعة الأجزاء', 'إعادة قراءة الأجزاء المكتملة', () => _review(juzDone))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tile(p, Icons.share, 'مشاركة الإنجاز', 'شارك ختمتك مع الأصدقاء', () => Share.share('أتممت ${nf(juzDone)} جزءًا من القرآن (${nf((v * 100).round())}٪ من ختمتي) عبر تطبيق دُرَر'))),
              const SizedBox(width: 10),
              Expanded(child: _tile(p, Icons.volunteer_activism, 'أدعية الختمة', 'أدعية من السنة النبوية', () => showAppSheet(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('دعاء ختم القرآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(_khatmaDua, textAlign: TextAlign.center, style: const TextStyle(fontFamily: quranFont, fontSize: 23, height: 2)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(onPressed: () => copyText(_khatmaDua), icon: const Icon(Icons.copy), label: const Text('نسخ')),
                  ])))),
            ]),
          ] else if (tab == 'plans') ...[
            const SizedBox(height: 4),
            for (final pl in _plans)
              AppCard(
                margin: const EdgeInsets.only(top: 10),
                onTap: () async {
                  if (await confirmDialog(context, pl.$2, 'ضبط الهدف اليومي على ${nf((604 / pl.$1).ceil())} صفحة. يمكنك بدء ختمة جديدة بهذه الخطة أو متابعة ختمتك الحالية.', ok: 'ضبط الخطة')) _setPlan(pl.$1);
                },
                child: Row(children: [
                  Container(width: 54, height: 54, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text(nf(pl.$1), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.pri))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pl.$2, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)), Sub('${pl.$3} · ${nf((604 / pl.$1).ceil())} صفحة يوميًا')])),
                  Icon(Icons.chevron_left, color: p.on2),
                ]),
              ),
          ] else ...[
            AppCard(
              margin: const EdgeInsets.only(top: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مدة الخطة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${nf(newDays.round())} يوم · ${nf((604 / newDays.round()).ceil())} صفحة يوميًا', style: TextStyle(color: p.pri, fontWeight: FontWeight.w700)),
                Slider(value: newDays, min: 7, max: 365, divisions: 358, onChanged: (x) => setState(() => newDays = x)),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('البدء من جديد'), subtitle: const Sub('تصفير تقدّم الختمة الحالية وبدء اليوم'), value: fresh, onChanged: (x) => setState(() => fresh = x)),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
                  if (fresh && !await confirmDialog(context, 'بدء ختمة جديدة؟', 'سيُصفَّر تقدّم ختمتك الحالية.', ok: 'ابدأ', danger: true)) return;
                  _setPlan(newDays.round(), reset: fresh);
                }, child: const Text('إنشاء الخطة'))),
              ]),
            ),
          ],
        ],
      );
    });
  }

  Widget _tile(Pal p, IconData ic, String t, String s, VoidCallback f) => AppCard(
        margin: EdgeInsets.zero,
        radius: 20,
        padding: const EdgeInsets.all(12),
        onTap: f,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), Text(s, style: TextStyle(fontSize: 11.5, color: p.on2, height: 1.4))])),
          const SizedBox(width: 6),
          Container(width: 44, height: 44, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Icon(ic, color: p.pri, size: 24)),
        ]),
      );
}
