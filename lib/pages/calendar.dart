import 'package:flutter/material.dart';
import '../app.dart';
import '../core/data.dart';
import '../core/fasting.dart';
import '../core/hijri_util.dart';
import '../core/khatma.dart';
import '../core/reports.dart';
import '../core/tasbih.dart';
import '../core/tasks.dart';
import '../core/util.dart';
import '../ui/skyline.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// التبويب الفرعي المعروض في «التقويم والتقارير» (يُضبط من الشريط السفلي أيضًا).
final ValueNotifier<String> calTab = ValueNotifier('calendar');

const _sat = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
const _cFast = Color(0xFF1F8A5B), _cQiyam = Color(0xFF6C7BE0), _cAzkar = Color(0xFFE0A030), _cKhatma = Color(0xFF2BB5A0);

class CalendarReportsPage extends StatefulWidget {
  const CalendarReportsPage({super.key});
  @override
  State<CalendarReportsPage> createState() => _CalendarReportsPageState();
}

class _CalendarReportsPageState extends State<CalendarReportsPage> {
  String mode = 'hijri', range = 'week';
  late int hy, hm, gy, gm;
  DateTime sel = noon(DateTime.now());

  @override
  void initState() {
    super.initState();
    final h = hj();
    hy = h.y; hm = h.m;
    gy = DateTime.now().year; gm = DateTime.now().month;
  }

  void shift(int d) {
    hap.tick();
    setState(() {
      if (mode == 'hijri') {
        var m = hm + d, y = hy;
        if (m > 12) { m = 1; y++; }
        if (m < 1) { m = 12; y--; }
        hm = m; hy = y;
      } else {
        var m = gm + d, y = gy;
        if (m > 12) { m = 1; y++; }
        if (m < 1) { m = 12; y--; }
        gm = m; gy = y;
      }
    });
  }

  List<DateTime> _monthDays() {
    if (mode == 'hijri') return hmonth(hy, hm).days;
    final n = DateTime(gy, gm + 1, 0).day;
    return [for (var i = 1; i <= n; i++) DateTime(gy, gm, i, 12)];
  }

  List<(DateTime, bool)> _cells(List<DateTime> days) {
    final lead = (jsDay(days.first) + 1) % 7;
    final out = <(DateTime, bool)>[];
    for (var i = lead; i > 0; i--) { out.add((addDays(days.first, -i), false)); }
    for (final d in days) { out.add((d, true)); }
    var k = 1;
    while (out.length % 7 != 0) { out.add((addDays(days.last, k++), false)); }
    return out;
  }

  Widget _dot(Color c) => Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(shape: BoxShape.circle, color: c));

  Widget _calendarCard(Pal p, FastState F) {
    final days = _monthDays();
    final cells = _cells(days);
    final title = mode == 'hijri' ? '${hmonths[hm - 1]} ${nf(hy)} هـ' : '${gmonths[gm - 1]} ${nf(gy)}م';
    return AppCard(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: GestureDetector(
        onHorizontalDragEnd: (d) { if ((d.primaryVelocity ?? 0).abs() > 300) shift(d.primaryVelocity! < 0 ? 1 : -1); },
        child: Column(children: [
          Row(children: [
            SegToggle(items: const [('hijri', 'هجري'), ('greg', 'ميلادي')], selected: mode, onSelect: (v) => setState(() => mode = v)),
            Expanded(child: Center(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)))),
            Container(
              decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(visualDensity: VisualDensity.compact, onPressed: () => shift(-1), icon: const Icon(Icons.chevron_right)),
                Container(width: 1, height: 22, color: p.line),
                IconButton(visualDensity: VisualDensity.compact, onPressed: () => shift(1), icon: const Icon(Icons.chevron_left)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [for (final w in _sat) Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(w, style: TextStyle(fontSize: 12, color: p.on2)))))]),
          const SizedBox(height: 8),
          GridView.count(
            key: ValueKey('$mode-$hy-$hm-$gy-$gm'),
            crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1.05,
            children: [
              for (final c in cells)
                Builder(builder: (_) {
                  final d = c.$1, inM = c.$2;
                  final a = dayAct(d, F);
                  final isToday = dkey(d) == todayKey(), isSel = dkey(d) == dkey(sel);
                  final label = mode == 'hijri' ? hj(d).d : d.day;
                  final dots = <Color>[if (a.fast) _cFast, if (a.qiyam) _cQiyam, if (a.azkar > 0) _cAzkar, if (a.pages > 0) _cKhatma];
                  return GestureDetector(
                    onTap: () { hap.select(); setState(() => sel = d); },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday ? p.pri : (inM ? p.surf : p.surf2.withValues(alpha: .7)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSel && !isToday ? const Color(0xFFD9A63B) : (isToday ? Colors.transparent : p.line.withValues(alpha: inM ? 1 : .4)), width: isSel && !isToday ? 1.8 : 1),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(nf(label), style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: isToday ? p.onpri : (inM ? p.on : p.on2.withValues(alpha: .6)))),
                        const SizedBox(height: 3),
                        SizedBox(height: 7, child: inM ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final c in dots.take(3)) _dot(isToday ? Colors.white : c)]) : null),
                      ]),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 6, children: [
            for (final l in const [(_cFast, 'صيام'), (_cQiyam, 'قيام'), (_cAzkar, 'أذكار'), (_cKhatma, 'ختمة')])
              Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: l.$1)), const SizedBox(width: 6), Text(l.$2, style: TextStyle(fontSize: 12.5, color: p.on2))]),
            Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, size: 15, color: p.pri), const SizedBox(width: 6), Text('مهمة مكتملة', style: TextStyle(fontSize: 12.5, color: p.on2))]),
          ]),
        ]),
      ),
    );
  }

  Widget _dayCard(Pal p, FastState F) {
    final a = dayAct(sel, F);
    final h = hj(sel);
    final fi = fastInfo(sel, F);
    Widget item(IconData ic, String t, Widget st) => Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Icon(ic, color: p.pri, size: 26)),
            const SizedBox(height: 5),
            FittedBox(fit: BoxFit.scaleDown, child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
            const SizedBox(height: 3),
            st,
          ]),
        );
    Widget status(bool ok, String yes, String no) => FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(ok ? yes : no, style: TextStyle(fontSize: 12, color: p.on2)), const SizedBox(width: 3), Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: ok ? p.pri : p.on2)]));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(children: [
        Row(children: [
          Container(width: 62, height: 62, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(18)), child: Icon(Icons.mosque, color: p.pri, size: 36)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${wdays[jsDay(sel)]} ${nf(h.d)} ${hmonths[h.m - 1]} ${nf(h.y)} هـ', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text('${nf(sel.day)} ${gmonths[sel.month - 1]} ${nf(sel.year)} م', style: TextStyle(fontSize: 13.5, color: p.on2)),
          ])),
          SoftPill('أحداث اليوم', () => _events(fi), icon: Icons.format_list_bulleted),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          item(Icons.checklist_rounded, 'المهام', Row(mainAxisSize: MainAxisSize.min, children: [Text('${nf(a.tasks)}/${nf(a.tasksTotal)}', style: TextStyle(fontSize: 12, color: p.on2)), const SizedBox(width: 4), Ring(v: a.taskFrac, size: 20, stroke: 3, track: p.surf2)])),
          item(Icons.eco, 'صيام', status(a.fast, 'تم', fi.fast ? 'مستحب' : 'لا')),
          item(Icons.mosque_outlined, 'الفجر', status(taskDone('fajr', sel), 'مكتمل', 'لم يُسجَّل')),
          item(Icons.auto_awesome, 'الأذكار', status(a.azkar > 0, nf(a.azkar), 'لا شيء')),
          item(Icons.menu_book_rounded, 'قراءة قرآن', FittedBox(fit: BoxFit.scaleDown, child: Text('${nf(a.pages)} صفحة', style: TextStyle(fontSize: 12, color: p.on2)))),
        ]),
      ]),
    );
  }

  void _events(FastInfo fi) {
    showAppSheet(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(gregString(sel), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (fi.tags.isEmpty) const Sub('لا توجد مناسبات أو أيام صيام لهذا اليوم.'),
          for (final t in fi.tags) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.event_available), title: Text(t.t), subtitle: Text(t.note)),
          const SizedBox(height: 6),
          FilledButton.icon(onPressed: () { Navigator.pop(ctx); openRoute('fasting'); }, icon: const Icon(Icons.nightlight_round), label: const Text('فتح صفحة الصيام')),
        ]));
  }

  Widget _prog(Pal p, IconData ic, Color c, String v, String l, double pct) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(color: p.surf2.withValues(alpha: .6), borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Icon(ic, color: c, size: 26),
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(l, style: TextStyle(fontSize: 12, color: p.on2))),
            const SizedBox(height: 6),
            Text('${nf((pct * 100).round())}%', style: TextStyle(fontSize: 11.5, color: p.on2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Bar(pct, color: c, track: p.surf),
          ]),
        ),
      );

  Widget _monthStats(Pal p, FastState F) {
    final days = _monthDays();
    final now = noon(DateTime.now());
    final past = days.where((d) => !d.isAfter(now)).toList();
    final el = past.isEmpty ? 1 : past.length;
    var tasks = 0, tTot = 0, read = 0, azk = 0, azDays = 0, fast = 0;
    for (final d in past) {
      final a = dayAct(d, F);
      tasks += a.tasks; tTot += a.tasksTotal;
      if (a.pages > 0) read++;
      azk += a.azkar;
      if (a.azkar > 0) azDays++;
      if (a.fast) fast++;
    }
    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      child: Column(children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: SecHead('إحصائيات الشهر', icon: Icons.bar_chart_rounded)),
        const SizedBox(height: 12),
        Row(children: [
          _prog(p, Icons.check_box, p.pri, nf(tasks), 'المهام المكتملة', tTot == 0 ? 0 : tasks / tTot),
          const SizedBox(width: 8),
          _prog(p, Icons.menu_book_rounded, p.ok, nf(read), 'أيام القراءة', read / el),
          const SizedBox(width: 8),
          _prog(p, Icons.auto_awesome, _cAzkar, nf(azk), 'مجموع الأذكار', azDays / el),
          const SizedBox(width: 8),
          _prog(p, Icons.nightlight_round, _cAzkar, nf(fast), 'أيام الصيام', (fast / 12).clamp(0.0, 1.0).toDouble()),
        ]),
      ]),
    );
  }

  Widget _chart(Pal p, int n, String sub) {
    final list = lastDays(n);
    final pts = [for (final a in list) a.score];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: SecHead('مستوى الاستمرارية', icon: Icons.trending_up)),
        Align(alignment: AlignmentDirectional.centerStart, child: Padding(padding: const EdgeInsets.only(right: 36, top: 2), child: Sub(sub))),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: Directionality(textDirection: TextDirection.ltr, child: CustomPaint(size: Size.infinite, painter: _LinePainter(pts, p.ok, p.line, p.on2))),
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final i in [0, (n * .2).round(), (n * .4).round(), (n * .6).round(), (n * .8).round(), n - 1])
              Text('${list[i].d.day} ${gmonths[list[i].d.month - 1]}', style: TextStyle(fontSize: 9.5, color: p.on2)),
          ]),
        ),
      ]),
    );
  }

  // ---------- تبويبات أخرى ----------
  Widget _reports(Pal p, FastState F) {
    final n = range == 'week' ? 7 : range == 'month' ? 30 : 90;
    final list = lastDays(n);
    var tasks = 0, azk = 0, pages = 0, tas = 0, fast = 0, act = 0;
    for (final a in list) {
      tasks += a.tasks; azk += a.azkar; pages += a.pages; tas += a.tasbih;
      if (a.fast) fast++;
      if (a.any) act++;
    }
    final shown = n <= 30 ? list : [for (var i = 0; i < n; i += 3) list[i]];
    return Column(children: [
      const SizedBox(height: 12),
      ChipRow(items: const [('week', 'آخر ٧ أيام'), ('month', 'آخر ٣٠ يومًا'), ('q', 'آخر ٩٠ يومًا')], selected: range, onSelect: (v) => setState(() => range = v)),
      AppCard(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        child: Column(children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: SecHead('النشاط اليومي', icon: Icons.bar_chart_rounded)),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final a in shown)
                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1.5), child: Container(height: 6 + 124 * a.score, decoration: BoxDecoration(color: a.score > .6 ? p.pri : p.ok.withValues(alpha: .55), borderRadius: BorderRadius.circular(5))))),
              ]),
            ),
          ),
        ]),
      ),
      AppCard(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.05,
          children: [
            StatTile(Icons.today, nf(act), 'أيام نشطة'),
            StatTile(Icons.check_box, nf(tasks), 'مهام مكتملة'),
            StatTile(Icons.auto_awesome, nf(azk), 'أذكار'),
            StatTile(Icons.menu_book_rounded, nf(pages), 'صفحات قرآن'),
            StatTile(Icons.touch_app, nf(tas), 'تسبيحات'),
            StatTile(Icons.nightlight_round, nf(fast), 'أيام صيام'),
          ],
        ),
      ),
    ]);
  }

  Widget _achievements(Pal p) {
    final pr = (quranState()['pagesRead'] as Map?) ?? const {};
    final pages = pr.values.fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0));
    final tot = ((tasbihPeek()['total'] as Map?) ?? const {}).values.fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0));
    final st = streak();
    final fasts = fastState().done.length;
    final list = <(String, bool, IconData)>[
      ('نشاط ٣ أيام متتالية', st.best >= 3, Icons.local_fire_department),
      ('نشاط ٧ أيام متتالية', st.best >= 7, Icons.local_fire_department),
      ('نشاط ٣٠ يومًا متتالية', st.best >= 30, Icons.local_fire_department),
      ('قراءة ١٠ صفحات', pages >= 10, Icons.menu_book_rounded),
      ('قراءة ١٠٠ صفحة', pages >= 100, Icons.menu_book_rounded),
      ('قراءة ٦٠٤ صفحات', pages >= 604, Icons.menu_book_rounded),
      ('١٬٠٠٠ تسبيحة', tot >= 1000, Icons.auto_awesome),
      ('١٠٬٠٠٠ تسبيحة', tot >= 10000, Icons.auto_awesome),
      ('صيام ١٠ أيام', fasts >= 10, Icons.nightlight_round),
      ('صيام ٣٠ يومًا', fasts >= 30, Icons.nightlight_round),
    ];
    return Column(children: [
      const SizedBox(height: 12),
      for (final a in list)
        AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          radius: 18,
          color: a.$2 ? p.pc : null,
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: a.$2 ? p.pri : p.surf2, shape: BoxShape.circle), child: Icon(a.$3, color: a.$2 ? p.onpri : p.on2)),
            const SizedBox(width: 12),
            Expanded(child: Text(a.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
            Icon(a.$2 ? Icons.verified : Icons.lock_outline, color: a.$2 ? p.pri : p.on2),
          ]),
        ),
      AppCard(onTap: () => openRoute('challenges'), child: Row(children: [Icon(Icons.emoji_events, color: p.pri), const SizedBox(width: 12), const Expanded(child: Text('تحديات اليوم', style: TextStyle(fontWeight: FontWeight.w800))), Icon(Icons.chevron_left, color: p.on2)])),
    ]);
  }

  Widget _stats(Pal p) {
    final xp = totalAzkarAll();
    final lv = levelOf(xp);
    final pr = (quranState()['pagesRead'] as Map?) ?? const {};
    final pages = pr.values.fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0));
    return Column(children: [
      const SizedBox(height: 12),
      AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.5,
          children: [
            StatTile(Icons.auto_awesome, nf(xp), 'إجمالي الأذكار والتسبيح'),
            StatTile(Icons.local_fire_department, nf(streak().cur), 'أيام متتالية', color: const Color(0xFFE8731C)),
            StatTile(Icons.menu_book_rounded, nf(pages), 'صفحات القرآن المقروءة'),
            StatTile(Icons.nightlight_round, nf(fastState().done.length), 'أيام الصيام'),
            StatTile(Icons.military_tech, lv.name, 'المستوى ${lv.ord}'),
            StatTile(Icons.emoji_events, nf(((khatma()['done'] as num?) ?? 0).toInt()), 'ختمات مكتملة'),
          ],
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) => ValueListenableBuilder<String>(
        valueListenable: calTab,
        builder: (context, tab, _) {
          final p = Pal.of(context);
          final F = fastState();
          return PageScaffold(
            title: 'التقويم والتقارير',
            subtitle: 'رحلتك الإيمانية في نظرة واحدة',
            children: [
              TabPills(selected: tab, onSelect: (v) => calTab.value = v, items: const [('stats', 'الإحصائيات', Icons.pie_chart_outline), ('ach', 'الإنجازات', Icons.emoji_events_outlined), ('reports', 'التقارير', Icons.bar_chart_rounded), ('calendar', 'التقويم', Icons.calendar_month_outlined)]),
              const SizedBox(height: 10),
              if (tab == 'calendar') ...[
                _calendarCard(p, F),
                _dayCard(p, F),
                _monthStats(p, F),
                _chart(p, 30, 'آخر ٣٠ يوم'),
              ] else if (tab == 'reports') ...[
                _reports(p, F),
                _chart(p, 30, 'آخر ٣٠ يوم'),
              ] else if (tab == 'ach')
                _achievements(p)
              else
                _stats(p),
            ],
          );
        },
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> v;
  final Color c, grid, txt;
  _LinePainter(this.v, this.c, this.grid, this.txt);
  @override
  void paint(Canvas canvas, Size s) {
    const lw = 38.0;
    final w = s.width - lw, h = s.height - 6;
    final gp = Paint()..color = grid..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = 3 + h * i / 2;
      canvas.drawLine(Offset(lw, y), Offset(s.width, y), gp);
      final tp = TextPainter(text: TextSpan(text: '${100 - i * 50}%', style: TextStyle(fontSize: 10, color: txt)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    if (v.length < 2) return;
    final pts = [for (var i = 0; i < v.length; i++) Offset(lw + w * i / (v.length - 1), 3 + h * (1 - v[i]))];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final m = (pts[i - 1].dx + pts[i].dx) / 2;
      path.cubicTo(m, pts[i - 1].dy, m, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    final fill = Path.from(path)..lineTo(pts.last.dx, 3 + h)..lineTo(pts.first.dx, 3 + h)..close();
    canvas.drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.withValues(alpha: .35), c.withValues(alpha: 0)]).createShader(Rect.fromLTWH(lw, 0, w, h)));
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..color = c);
    for (var i = 0; i < pts.length; i += 5) {
      canvas.drawCircle(pts[i], 3.2, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.v != v || o.c != c;
}
