import 'package:flutter/material.dart';
import '../app.dart';
import '../core/data.dart';
import '../core/khatma.dart';
import '../core/reports.dart';
import '../core/tasks.dart';
import '../core/util.dart';
import '../ui/nav.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// بطاقة «مهام اليوم» (تُستخدم في أماكن أخرى).
class TasksHomeCard extends StatelessWidget {
  const TasksHomeCard({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final tot = dayTasksTotal(), d = dayTasksDone();
    final f = tot == 0 ? 0.0 : d / tot;
    return AppCard(
      onTap: () => openRoute('tasks'),
      child: Row(children: [
        Ring(v: f, size: 54, stroke: 6, child: Text('${nf((f * 100).round())}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مهام اليوم', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Sub('${nf(d)} من ${nf(tot)} مكتملة'),
        ])),
        Icon(Icons.chevron_left, color: p.on2),
      ]),
    );
  }
}

class _Row {
  final String id, title, time, pill, cat, sectionIcon;
  final bool imp, builtin, bonus;
  final String? route;
  final IconData icon;
  const _Row(this.id, this.title, this.time, this.pill, this.cat, this.icon, {this.imp = false, this.builtin = false, this.bonus = false, this.route, this.sectionIcon = ''});
}

const _times = {'morning': 'بعد الفجر', 'evening': 'بعد العصر', 'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء', 'duha': 'الضحى', 'qiyam': 'الليل'};
const _cats = [('all', 'الكل', Icons.grid_view_rounded), ('worship', 'العبادة', Icons.mosque_outlined), ('personal', 'الشخصي', Icons.person_outline), ('study', 'الدراسة', Icons.school_outlined), ('work', 'العمل', Icons.work_outline)];
const _wk = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
const _wkShort = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

IconData _catIcon(String c) => switch (c) { 'worship' => Icons.mosque, 'study' => Icons.school, 'work' => Icons.work, _ => Icons.person };
IconData _secIcon(String s) => switch (s) { 'athkar' => Icons.eco, 'quran' => Icons.menu_book_rounded, 'salah' => Icons.mosque, 'nawafil' => Icons.mosque, _ => Icons.star };

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String tab = 'today', cat = 'all', q = '';
  DateTime day = noon(DateTime.now());
  bool searching = false, hideDone = false;

  bool get _isToday => dkey(day) == todayKey();

  bool _done(_Row r) {
    if (taskDone(r.id, day)) return true;
    if (r.id == 'wird' && _isToday) {
      final goal = ((khatma()['goal'] as num?) ?? 5).toInt();
      return pagesToday() >= goal && goal > 0;
    }
    return false;
  }

  List<_Row> _rows(DateTime d) {
    final out = <_Row>[];
    for (final s in taskSections) {
      for (final t in s.tasks) {
        out.add(_Row(t.id, t.title, _times[t.id] ?? '', 'يومي', 'worship', _secIcon(s.id), builtin: true, bonus: t.bonus, route: t.route));
      }
    }
    for (final t in customTasks()) {
      if (!customAppliesOn(t, d)) continue;
      out.add(_Row(t.id, t.title, t.time, t.imp ? 'مهم' : switch (t.rp) { 'weekly' => 'أسبوعي', 'once' => 'مرة', _ => 'يومي' }, t.cat, _catIcon(t.cat), imp: t.imp));
    }
    return out;
  }

  void _toggle(_Row r) {
    final v = !_done(r);
    v ? hap.success() : hap.tick();
    taskSet(r.id, v, day);
    if (v && _isToday) touchActivity();
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '${nf(h)}:${pad(t.minute)} ${t.period == DayPeriod.am ? 'ص' : 'م'}';
  }

  Future<void> _add({String rp = 'daily'}) async {
    final title = TextEditingController();
    var c = 'personal', r = rp, time = '', imp = false;
    var date = day;
    final ok = await showAppSheet<bool>(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إضافة مهمة أو عادة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(controller: title, decoration: const InputDecoration(hintText: 'العنوان')),
            const SizedBox(height: 12),
            ChipRow(items: const [('worship', 'العبادة'), ('personal', 'الشخصي'), ('study', 'الدراسة'), ('work', 'العمل')], selected: c, onSelect: (v) => set(() => c = v)),
            const SizedBox(height: 10),
            ChipRow(items: const [('daily', 'عادة يومية'), ('weekly', 'أسبوعية'), ('once', 'مهمة لمرة واحدة')], selected: r, onSelect: (v) => set(() => r = v)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.schedule), label: Text(time.isEmpty ? 'الوقت (اختياري)' : time), onPressed: () async {
                final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                if (t != null) set(() => time = _fmt(t));
              })),
              if (r == 'once') ...[
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.event), label: Text(dkey(date)), onPressed: () async {
                  final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (d != null) set(() => date = noon(d));
                })),
              ],
            ]),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('مهمة مهمّة'), value: imp, onChanged: (v) => set(() => imp = v)),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة'))),
          ]);
        }));
    if (ok != true) return;
    if (title.text.trim().isEmpty) { toast('اكتب عنوانًا أولًا.'); return; }
    customAdd(title: title.text.trim(), time: time, rp: r, cat: c, imp: imp, date: date);
    toast('تمت الإضافة');
  }

  Widget _rowTile(Pal p, _Row r, {bool last = false}) {
    final done = _done(r);
    return Container(
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: p.line))),
      child: InkWell(
        onTap: () => _toggle(r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 12),
          child: Row(children: [
            const SizedBox(width: 8),
            CheckDot(done, size: 38, onTap: () => _toggle(r)),
            const SizedBox(width: 10),
            Container(width: 46, height: 46, decoration: BoxDecoration(color: p.surf2, borderRadius: BorderRadius.circular(14)), child: Icon(r.icon, color: p.pri, size: 26)),
            const SizedBox(width: 12),
            Expanded(child: Text(r.title, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, decoration: done ? TextDecoration.lineThrough : null, decorationColor: p.on2, color: done ? p.on2 : p.on))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: r.imp ? const Color(0xFFFBE0DD) : p.surf2, borderRadius: BorderRadius.circular(14)),
              child: Text(r.pill, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r.imp ? const Color(0xFFC0281E) : p.on2)),
            ),
            if (r.time.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(r.time, style: TextStyle(fontSize: 12.5, color: p.on2))) else const SizedBox(width: 8),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert, color: p.on2),
              onSelected: (v) {
                if (v == 'open' && r.route != null) openRoute(r.route!);
                if (v == 'del') { customDelete(r.id); toast('تم الحذف'); }
              },
              itemBuilder: (_) => [
                if (r.route != null) const PopupMenuItem(value: 'open', child: Text('فتح')),
                if (!r.builtin) const PopupMenuItem(value: 'del', child: Text('حذف')),
                if (r.route == null && r.builtin) const PopupMenuItem(enabled: false, child: Text('مهمة أساسية')),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(builder: (context, _) {
      final p = Pal.of(context);
      final now = DateTime.now();
      final tot = dayTasksTotal(day), dn = dayTasksDone(day);
      final fr = tot == 0 ? 0.0 : (dn / tot).clamp(0.0, 1.0).toDouble();
      // أسبوع يبدأ بالسبت يحتوي اليوم المحدد
      final ws = addDays(day, -((jsDay(day) + 1) % 7));
      final week = [for (var i = 0; i < 7; i++) addDays(ws, i)];
      var rows = _rows(day).where((r) => cat == 'all' || r.cat == cat).toList();
      if (q.trim().isNotEmpty) rows = rows.where((r) => bare(r.title).contains(bare(q))).toList();
      if (hideDone) rows = rows.where((r) => !_done(r)).toList();
      final habits = customTasks().where((t) => t.isHabit).toList();
      final once = customTasks().where((t) => !t.isHabit).toList();
      return PageScaffold(
        title: 'المهام والعادات',
        subtitle: 'خطوات صغيرة تصنع فرقاً كبيراً',
        back: false,
        actions: [
          RoundIconButton(Icons.search, () => setState(() { searching = !searching; q = ''; }), tooltip: 'بحث'),
          RoundIconButton(Icons.menu, () => showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) => Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('خيارات القائمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('إخفاء المكتملة'), value: hideDone, onChanged: (v) { setState(() => hideDone = v); set(() {}); }),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.add), title: const Text('إضافة مهمة أو عادة'), onTap: () { Navigator.pop(ctx); _add(); }),
              ]))), tooltip: 'القائمة'),
        ],
        fab: FloatingActionButton(onPressed: () => _add(rp: tab == 'tasks' ? 'once' : 'daily'), shape: const CircleBorder(), child: const Icon(Icons.add, size: 32)),
        children: [
          TabPills(
            selected: tab,
            onSelect: (v) => setState(() => tab = v),
            items: const [('today', 'اليوم', Icons.calendar_today_outlined), ('week', 'الأسبوع', Icons.bar_chart_rounded), ('habits', 'العادات', Icons.timelapse), ('tasks', 'المهام', Icons.format_list_bulleted)],
          ),
          if (searching) Padding(padding: const EdgeInsets.only(top: 10), child: TextField(autofocus: true, decoration: const InputDecoration(hintText: 'ابحث في المهام...', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => q = v))),
          const SizedBox(height: 10),
          if (tab == 'today') ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
              child: Row(children: [
                for (final d in week)
                  Expanded(
                    child: GestureDetector(
                      onTap: () { hap.select(); setState(() => day = d); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: dkey(d) == dkey(day) ? p.pri : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          FittedBox(fit: BoxFit.scaleDown, child: Text(_wk[(jsDay(d) + 1) % 7], style: TextStyle(fontSize: 12, color: dkey(d) == dkey(day) ? p.onpri : p.on2))),
                          const SizedBox(height: 4),
                          Text(nf(d.day), style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: dkey(d) == dkey(day) ? p.onpri : p.on)),
                          const SizedBox(height: 4),
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dayTasksDone(d) > 0 ? (dkey(d) == dkey(day) ? const Color(0xFFE2B85B) : p.ok) : p.line)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final c in _cats)
                  GestureDetector(
                    onTap: () { hap.select(); setState(() => cat = c.$1); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsetsDirectional.only(end: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: cat == c.$1 ? p.pri : p.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: cat == c.$1 ? p.pri : p.line)),
                      child: Row(children: [Icon(c.$3, size: 22, color: cat == c.$1 ? p.onpri : p.on), const SizedBox(width: 6), Text(c.$2, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cat == c.$1 ? p.onpri : p.on))]),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: StatTile(Icons.format_list_bulleted, nf(tot), 'إجمالي المهام')),
                const SizedBox(width: 8),
                Expanded(child: StatTile(Icons.check_circle, '${nf(dn)} / ${nf(tot)}', 'مكتملة اليوم')),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: p.surf2.withValues(alpha: .6), borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Ring(v: fr, size: 46, stroke: 5, track: p.surf, child: Text('${nf((fr * 100).round())}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
                      const SizedBox(height: 4),
                      FittedBox(child: Text('معدل الإنجاز', style: TextStyle(fontSize: 12, color: p.on2))),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: StatTile(Icons.local_fire_department, nf(streak().cur), 'سلسلة الأيام', color: const Color(0xFFE8731C))),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () { hap.success(); taskSetMany(taskSections.firstWhere((s) => s.id == 'salah').tasks.map((t) => t.id), true); }, icon: const Icon(Icons.done_all, size: 18), label: const FittedBox(child: Text('تسجيل كل الفروض')), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () { hap.success(); taskSetMany(taskSections.firstWhere((s) => s.id == 'nawafil').tasks.map((t) => t.id), true); }, icon: const Icon(Icons.done_all, size: 18), label: const FittedBox(child: Text('تسجيل كل النوافل')), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)))),
            ]),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line), boxShadow: softShadow()),
              child: rows.isEmpty
                  ? Padding(padding: const EdgeInsets.all(30), child: Sub(hideDone ? 'أنجزت كل المهام، تقبّل الله منك' : 'لا توجد مهام في هذا القسم', align: TextAlign.center))
                  : Column(children: [for (var i = 0; i < rows.length; i++) _rowTile(p, rows[i], last: i == rows.length - 1)]),
            ),
            // تقدّم العادات
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('تقدم عاداتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('الالتزام اليوم يصنع مستقبلك غدًا', style: TextStyle(fontSize: 13, color: p.on2)),
                    const SizedBox(height: 10),
                    Row(children: [
                      for (final d in week)
                        Expanded(
                          child: Column(children: [
                            CheckDot(dayAct(d).taskFrac >= .5, size: 30),
                            const SizedBox(height: 4),
                            FittedBox(child: Text(_wkShort[(jsDay(d) + 1) % 7], style: TextStyle(fontSize: 11.5, color: dkey(d) == dkey(now) ? p.pri : p.on2, fontWeight: dkey(d) == dkey(now) ? FontWeight.w800 : FontWeight.w500))),
                          ]),
                        ),
                    ]),
                  ]),
                ),
                const SizedBox(width: 10),
                Container(width: 74, height: 74, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.pc, const Color(0xFFE9D3A8)]), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.spa, size: 44, color: p.ok)),
              ]),
            ),
          ] else if (tab == 'week') ...[
            for (final d in week)
              Builder(builder: (_) {
                final a = dayAct(d);
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  radius: 18,
                  onTap: () => setState(() { day = d; tab = 'today'; }),
                  child: Row(children: [
                    SizedBox(width: 78, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_wk[(jsDay(d) + 1) % 7], style: TextStyle(fontWeight: dkey(d) == dkey(now) ? FontWeight.w800 : FontWeight.w600, color: dkey(d) == dkey(now) ? p.pri : p.on)), Sub('${nf(d.day)} ${gmonths[d.month - 1]}')])),
                    Expanded(child: Bar(a.taskFrac, track: p.surf2)),
                    SizedBox(width: 64, child: Text('${nf(a.tasks)} / ${nf(a.tasksTotal)}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
                );
              }),
          ] else if (tab == 'habits') ...[
            if (habits.isEmpty) _empty(p, 'لا توجد عادات بعد', 'أضف عادة يومية أو أسبوعية وتابع سلسلتها.', () => _add()),
            for (final h in habits)
              AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                radius: 18,
                child: Row(children: [
                  CheckDot(taskDone(h.id, day), onTap: () { taskSet(h.id, !taskDone(h.id, day), day); hap.click(); }),
                  const SizedBox(width: 12),
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: p.surf2, borderRadius: BorderRadius.circular(14)), child: Icon(_catIcon(h.cat), color: p.pri)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(h.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Sub('${h.rp == 'weekly' ? 'أسبوعيًا' : 'يوميًا'}${h.time.isEmpty ? '' : ' · ${h.time}'}')])),
                  const Icon(Icons.local_fire_department, size: 20, color: Color(0xFFE8731C)),
                  Text(nf(habitStreak(h.id)), style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () { customDelete(h.id); toast('تم الحذف'); }, icon: const Icon(Icons.delete_outline, color: Color(0xFFA8332B))),
                ]),
              ),
          ] else ...[
            if (once.isEmpty) _empty(p, 'لا توجد مهام بعد', 'أضف مهمة لمرة واحدة بتاريخ محدد.', () => _add(rp: 'once')),
            for (final t in once)
              Builder(builder: (_) {
                final dt = DateTime.tryParse(t.date ?? '') ?? now;
                final d = noon(dt);
                final isDone = taskDone(t.id, d);
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  radius: 18,
                  child: Row(children: [
                    CheckDot(isDone, onTap: () { taskSet(t.id, !isDone, d); hap.click(); }),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, decoration: isDone ? TextDecoration.lineThrough : null)), Sub('${t.date ?? ''}${t.time.isEmpty ? '' : ' · ${t.time}'}')])),
                    if (t.imp) const Icon(Icons.priority_high, color: Color(0xFFC0281E)),
                    IconButton(onPressed: () { customDelete(t.id); toast('تم الحذف'); }, icon: const Icon(Icons.delete_outline, color: Color(0xFFA8332B))),
                  ]),
                );
              }),
          ],
        ],
      );
    });
  }

  Widget _empty(Pal p, String t, String s, VoidCallback f) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          Icon(Icons.spa_outlined, size: 54, color: p.on2.withValues(alpha: .5)),
          const SizedBox(height: 8),
          Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          Sub(s, align: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: f, icon: const Icon(Icons.add), label: const Text('إضافة')),
        ]),
      );
}
