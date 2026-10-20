import 'package:flutter/material.dart';
import '../core/data.dart';
import '../core/fasting.dart';
import '../core/hijri_util.dart';
import '../core/notify.dart';
import '../core/reports.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/nav.dart';
import '../ui/skyline.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

const _satFirst = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
const _gold = Color(0xFFE0A030);

/// طلب فتح «إضافة يوم صيام» من خارج الصفحة (الاختصارات).
final ValueNotifier<int> fastAddReq = ValueNotifier(0);

/// صفحة الصيام: بطاقة الصيام القادم، تبويبات الأنواع، إحصائيات، تقويم (هجري/ميلادي)، قائمة صيامي.
class FastingPage extends StatefulWidget {
  final bool openAdd;
  const FastingPage({super.key, this.openAdd = false});
  @override
  State<FastingPage> createState() => _FastingPageState();
}

class _FastingPageState extends State<FastingPage> {
  String tab = 'tatawu', mode = 'hijri';
  late int hy, hm, gy, gm;
  DateTime sel = noon(DateTime.now());

  @override
  void initState() {
    super.initState();
    final h = hj();
    hy = h.y;
    hm = h.m;
    gy = DateTime.now().year;
    gm = DateTime.now().month;
    fastAddReq.addListener(_onAddReq);
    if (widget.openAdd) WidgetsBinding.instance.addPostFrameCallback((_) => addCustom());
  }

  /// يمكن تعديل أيام الشهر الهجري الحالي فقط؛ ما قبله مقفل وما بعده لم يحن.
  bool _editable(DateTime d) {
    final a = hj(d), b = hj();
    return a.y == b.y && a.m == b.m;
  }

  void _onAddReq() {
    if (mounted) addCustom();
  }

  @override
  void dispose() {
    fastAddReq.removeListener(_onAddReq);
    super.dispose();
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

  Future<void> addCustom() async {
    final title = TextEditingController();
    var type = 'once', date = noon(DateTime.now()), wd = <int>{1, 4}, hd = hj().d, hmm = hj().m;
    final ok = await showAppSheet<bool>(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إضافة يوم صيام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(controller: title, decoration: const InputDecoration(hintText: 'عنوان (اختياري)')),
            const SizedBox(height: 12),
            ChipRow(items: const [('once', 'مرة واحدة'), ('week', 'أسبوعيًا'), ('month', 'كل شهر هجري'), ('year', 'كل عام هجري')], selected: type, onSelect: (v) => set(() => type = v)),
            const SizedBox(height: 12),
            if (type == 'once') OutlinedButton.icon(onPressed: () async {
              final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) set(() => date = noon(d));
            }, icon: const Icon(Icons.event), label: Text(dkey(date))),
            if (type == 'week') Wrap(spacing: 8, children: [for (var i = 0; i < 7; i++) FilterChip(label: Text(wdays[i]), selected: wd.contains(i), onSelected: (s) => set(() => s ? wd.add(i) : wd.remove(i)))]),
            if (type == 'month' || type == 'year') Row(children: [
              Expanded(child: DropdownButtonFormField<int>(value: hd, items: [for (var i = 1; i <= 30; i++) DropdownMenuItem(value: i, child: Text(nf(i)))], onChanged: (v) => set(() => hd = v ?? hd), decoration: const InputDecoration(labelText: 'اليوم الهجري'))),
              if (type == 'year') const SizedBox(width: 10),
              if (type == 'year') Expanded(child: DropdownButtonFormField<int>(value: hmm, items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(hmonths[i - 1]))], onChanged: (v) => set(() => hmm = v ?? hmm), decoration: const InputDecoration(labelText: 'الشهر'))),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة'))),
          ]);
        }));
    if (ok != true) return;
    fastUpdate((s) => s.custom.add({'id': DateTime.now().millisecondsSinceEpoch, 'title': title.text.trim(), 'type': type, 'date': dkey(date), 'wd': wd.toList(), 'hd': hd, 'hm': hmm, 'on': true}));
    notifier.schedule();
    toast('تمت الإضافة');
  }

  static const _notes = {1: 'المحرّم: أفضل الصيام بعد رمضان', 8: 'شعبان: كان النبي ﷺ يُكثر الصيام فيه', 9: 'رمضان: صيام الشهر كله فرض', 10: 'شوّال: يُستحب صيام ست أيام منه', 12: 'ذو الحجة: التسع الأوائل ويوم عرفة'};

  Color _kindColor(Pal p, bool dark, String main) => switch (main) {
        'fard' => p.pri,
        'sunna' || 'mt' => dark ? const Color(0xFF2B5246) : const Color(0xFFBFDCD3),
        'bid' => dark ? const Color(0xFF4B4226) : const Color(0xFFEBDFB8),
        'eid' => dark ? const Color(0xFF5B2E2B) : const Color(0xFFF2CBC4),
        'custom' => dark ? const Color(0xFF2E4062) : const Color(0xFFCAD8EE),
        _ => p.surf2,
      };

  /// هل تنتمي هذه الوسوم لتبويب الأنواع المختار؟
  bool _match(FastInfo f) {
    switch (tab) {
      case 'sunna': return f.tags.any((t) => t.kind == 'sunna' || t.kind == 'mt');
      case 'bid': return f.tags.any((t) => t.kind == 'bid');
      case 'ram': return f.tags.any((t) => t.kind == 'fard');
      default: return f.fast;
    }
  }

  void _daySheet(DateTime date) {
    final F = fastState();
    final f = fastInfo(date, F);
    final key = dkey(date);
    showAppSheet(context, (ctx) {
      final p = Pal.of(ctx);
      final dark = p.bg.computeLuminance() < .3;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(gregString(date), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        Sub('${nf(f.h.d)} ${hmonths[f.h.m - 1]} ${nf(f.h.y)} هـ'),
        const SizedBox(height: 12),
        if (f.tags.isEmpty) const Sub('لا يوجد صيام مستحب محدد لهذا اليوم، ويمكنك إضافته كيوم مخصّص.'),
        for (final t in f.tags)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surf2, borderRadius: BorderRadius.circular(16)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 14, height: 14, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: _kindColor(p, dark, t.kind), borderRadius: BorderRadius.circular(5))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.t, style: const TextStyle(fontWeight: FontWeight.w700)), Sub(t.note)])),
            ]),
          ),
        if (!f.eid && !_editable(date)) Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.surf2, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [Icon(Icons.lock_outline, size: 18, color: p.on2), const SizedBox(width: 8), Expanded(child: Text(f.done ? 'صمتَ هذا اليوم · لا يمكن تعديل الأشهر السابقة' : 'يمكن تسجيل الصيام داخل الشهر الهجري الحالي فقط', style: TextStyle(fontSize: 12.5, color: p.on2)))]),
        ),
        if (!f.eid && _editable(date)) ...[
          const SizedBox(height: 6),
          f.done
              ? OutlinedButton.icon(onPressed: () { hap.tick(); fastUpdate((s) => s.done.remove(key)); touchActivity(); Navigator.pop(ctx); toast('تم إلغاء التسجيل'); }, icon: Icon(Icons.check, size: 20, color: p.pri), label: const SizedBox(width: double.infinity, child: Center(child: Text('تم تسجيل الصيام · إلغاء'))))
              : FilledButton.icon(onPressed: () { hap.success(); fastUpdate((s) => s.done[key] = 1); touchActivity(); Navigator.pop(ctx); toast('تقبّل الله صيامك'); }, icon: Icon(Icons.check, size: 20, color: p.onpri), label: const SizedBox(width: double.infinity, child: Center(child: Text('صمتُ هذا اليوم')))),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); addCustom(); }, icon: Icon(Icons.add, size: 20, color: p.pri), label: const SizedBox(width: double.infinity, child: Center(child: Text('إضافة صيام مخصّص لهذا اليوم')))),
      ]);
    });
  }

  Future<void> _pickMonth() async {
    var y = mode == 'hijri' ? hy : gy;
    final res = await showAppSheet<(int, int)>(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          final p = Pal.of(ctx);
          final names = mode == 'hijri' ? hmonths : gmonths;
          final cur = mode == 'hijri' ? hm : gm;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: () => set(() => y--), icon: const Icon(Icons.chevron_right)),
              Text('${nf(y)}${mode == 'hijri' ? ' هـ' : 'م'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => set(() => y++), icon: const Icon(Icons.chevron_left)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (var i = 0; i < 12; i++)
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, (y, i + 1)),
                  child: Container(
                    width: 96, padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(color: (i + 1) == cur && y == (mode == 'hijri' ? hy : gy) ? p.pri : p.surf2, borderRadius: BorderRadius.circular(16)),
                    child: Center(child: FittedBox(child: Text(names[i], style: TextStyle(fontWeight: FontWeight.w700, color: (i + 1) == cur && y == (mode == 'hijri' ? hy : gy) ? p.onpri : p.on)))),
                  ),
                ),
            ]),
          ]);
        }));
    if (res == null) return;
    setState(() {
      if (mode == 'hijri') { hy = res.$1; hm = res.$2; } else { gy = res.$1; gm = res.$2; }
    });
  }

  /// خلايا الشهر الحالي مع أيام الشهرين المجاورين لإكمال الأسابيع (السبت أولًا).
  List<(DateTime, bool)> _cells() {
    final List<DateTime> days;
    if (mode == 'hijri') {
      days = hmonth(hy, hm).days;
    } else {
      final n = DateTime(gy, gm + 1, 0).day;
      days = [for (var i = 1; i <= n; i++) DateTime(gy, gm, i, 12)];
    }
    final lead = (jsDay(days.first) + 1) % 7;
    final out = <(DateTime, bool)>[];
    for (var i = lead; i > 0; i--) { out.add((addDays(days.first, -i), false)); }
    for (final d in days) { out.add((d, true)); }
    var k = 1;
    while (out.length % 7 != 0) { out.add((addDays(days.last, k++), false)); }
    return out;
  }

  Widget _cell(Pal p, bool dark, FastState F, DateTime d, bool inMonth) {
    final inf = fastInfo(d, F);
    final isToday = dkey(d) == todayKey(), isSel = dkey(d) == dkey(sel);
    final label = mode == 'hijri' ? hj(d).d : d.day;
    final match = inMonth && _match(inf);
    final isBid = inf.tags.any((t) => t.kind == 'bid'), isRam = inf.tags.any((t) => t.kind == 'fard');
    Color? bg = !inMonth ? p.surf2.withValues(alpha: .7) : p.surf;
    if (match && !isToday && !isSel) bg = p.pc;
    if (isSel && !isToday) bg = dark ? const Color(0xFF4B4226) : const Color(0xFFF8E9C9);
    final fg = isToday ? p.onpri : (inMonth ? p.on : p.on2.withValues(alpha: .6));
    final dotColor = isToday ? Colors.white : (inf.done ? p.pri : isBid ? _gold : p.ok);
    final showDot = inMonth && (inf.done || (match && !isRam));
    return GestureDetector(
      onTap: () { hap.select(); setState(() => sel = d); _daySheet(d); },
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? p.pri : bg,
          borderRadius: BorderRadius.circular(isToday ? 28 : 14),
          border: Border.all(color: isSel && !isToday ? const Color(0xFFD9A63B) : (isToday ? Colors.transparent : p.line.withValues(alpha: inMonth ? 1 : .4)), width: isSel && !isToday ? 1.6 : 1),
          boxShadow: isToday ? [BoxShadow(color: p.pri.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(nf(label), style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: fg, height: 1.1)),
          const SizedBox(height: 3),
          SizedBox(
            height: 8,
            child: isRam && inMonth && (tab == 'ram' || tab == 'tatawu')
                ? Icon(Icons.nightlight_round, size: 9, color: isToday ? Colors.white : _gold)
                : showDot ? Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)) : null,
          ),
        ]),
      ),
    );
  }

  Widget _legendItem(Pal p, Widget mark, String t) => Row(mainAxisSize: MainAxisSize.min, children: [mark, const SizedBox(width: 6), Text(t, style: TextStyle(fontSize: 12.5, color: p.on2))]);

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) {
        final p = Pal.of(context);
        final dark = p.bg.computeLuminance() < .3;
        final F = fastState();
        final now = DateTime.now();
        final h0 = hj(now);
        final nx = nextFast();
        // إحصائيات
        var mDone = 0, yDone = 0;
        for (final k in F.done.keys) {
          final x = k.split('-').map(int.parse).toList();
          final h = hj(DateTime(x[0], x[1], x[2], 12));
          if (h.y == h0.y) {
            yDone++;
            if (h.m == h0.m) mDone++;
          }
        }
        const goalMonth = 12;
        final goalV = (mDone / goalMonth).clamp(0.0, 1.0).toDouble();
        final adj = ((cfg.get('hijriAdj') as num?) ?? 0).toInt();
        final cells = _cells();
        final titleTxt = mode == 'hijri' ? '${hmonths[hm - 1]} ${nf(hy)} هـ' : '${gmonths[gm - 1]} ${nf(gy)}م';
        final midHm = mode == 'hijri' ? hm : hj(DateTime(gy, gm, 15, 12)).m;
        final nxTitle = nx == null ? 'لا توجد أيام قريبة' : (nx.info.tags.where((t) => t.kind != 'eid').firstOrNull?.t ?? 'يوم صيام');
        final nxDate = nx == null ? '' : '${wdays[jsDay(nx.info.date)]} ${nf(nx.info.h.d)} ${hmonths[nx.info.h.m - 1]} ${nf(nx.info.h.y)} هـ';
        final done = fastDoneDays().where(_editable).toList();
        final seasonsL = seasons();
        return PageScaffold(
          title: 'الصيام',
          subtitle: 'قربٌ من الله وصحة للحياة',
          back: false,
          actions: [RoundIconButton(Icons.tune, () => _rulesSheet(context), tooltip: 'تخصيص أيام الصيام')],
          children: [
            // بطاقة الصيام القادم (مصغّرة)
            AppCard(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              radius: 18,
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(14)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(nx == null ? '–' : nf(nx.inDays), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
                    Text(nx != null && nx.inDays == 0 ? 'اليوم' : 'يوم', style: TextStyle(fontSize: 10.5, color: p.on2)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الصيام القادم', style: TextStyle(fontSize: 11.5, color: p.on2)),
                    Text(nxTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.3)),
                    if (nxDate.isNotEmpty) Text(nxDate, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: p.on2)),
                  ]),
                ),
                const Icon(Icons.nightlight_round, color: _gold, size: 22),
              ]),
            ),
            // الإحصائيات
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(children: [
                SecHead('إحصائيات الصيام', icon: Icons.bar_chart_rounded),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: p.surf2.withValues(alpha: .6), borderRadius: BorderRadius.circular(18)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Ring(v: goalV, size: 62, stroke: 6, track: p.surf, child: Text('${nf((goalV * 100).round())}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                          const SizedBox(height: 4),
                          Text('تحقيق الهدف', style: TextStyle(fontSize: 12, color: p.on2)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(Icons.calendar_month, nf(mDone), 'هذا الشهر')),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(Icons.star_rounded, nf(yDone), 'هذا العام', color: _gold)),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(Icons.bar_chart_rounded, nf(F.done.length), 'إجمالي الأيام')),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            TabPills(
              selected: tab,
              onSelect: (v) => setState(() => tab = v),
              items: const [('sunna', 'الأيام المستحبة', Icons.calendar_month), ('bid', 'الأيام البيض', Icons.wb_sunny_outlined), ('ram', 'رمضان', Icons.nightlight_round), ('tatawu', 'صيام التطوع', Icons.eco)],
            ),
            // التقويم
            AppCard(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              child: GestureDetector(
                onHorizontalDragEnd: (d) { if ((d.primaryVelocity ?? 0).abs() > 300) shift(d.primaryVelocity! < 0 ? 1 : -1); },
                child: Column(children: [
                  Row(children: [
                    SegToggle(items: const [('hijri', 'هجري'), ('greg', 'ميلادي')], selected: mode, onSelect: (v) => setState(() => mode = v)),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickMonth,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(titleTxt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
                          Icon(Icons.keyboard_arrow_down, color: p.on2),
                        ]),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(visualDensity: VisualDensity.compact, onPressed: () => shift(-1), icon: const Icon(Icons.chevron_right)),
                        Container(width: 1, height: 22, color: p.line),
                        IconButton(visualDensity: VisualDensity.compact, onPressed: () => shift(1), icon: const Icon(Icons.chevron_left)),
                      ]),
                    ),
                  ]),
                  if (_notes[midHm] != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(14)),
                      child: Text(_notes[midHm]!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: dark ? p.pri : p.pri2)),
                    ),
                  const SizedBox(height: 12),
                  Row(children: [for (final w in _satFirst) Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(w, style: TextStyle(fontSize: 12, color: p.on2)))))]),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                    child: GridView.count(
                      key: ValueKey('$mode-$hy-$hm-$gy-$gm-$adj-$tab'),
                      crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1.0,
                      children: [for (final c in cells) _cell(p, dark, F, c.$1, c.$2)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 6, children: [
                    _legendItem(p, Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: p.pri)), 'صيام'),
                    _legendItem(p, Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: p.ok.withValues(alpha: .7))), 'صيام مستحب'),
                    _legendItem(p, Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: _gold)), 'الأيام البيض'),
                    _legendItem(p, const Icon(Icons.nightlight_round, size: 15, color: _gold), 'رمضان'),
                  ]),
                ]),
              ),
            ),
            // قائمة صيامي
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
              child: Column(children: [
                SecHead('صيامي · ${hmonths[h0.m - 1]}', icon: Icons.format_list_bulleted_rounded, trailing: SoftPill('إضافة', addCustom, icon: Icons.add)),
                const SizedBox(height: 10),
                if (done.isEmpty) Padding(padding: const EdgeInsets.all(18), child: Sub('لم تسجّل صيامًا هذا الشهر. اضغط على يوم في التقويم ثم «صمتُ هذا اليوم». تُحفظ الأشهر السابقة ولا تُعدَّل.', align: TextAlign.center)),
                for (final d in done)
                  Builder(builder: (_) {
                    final f = fastInfo(d, F);
                    final ttl = f.tags.where((t) => t.kind != 'eid').firstOrNull?.t ?? 'صيام تطوع';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
                      child: Row(children: [
                        const CheckDot(true, size: 46),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ttl, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                          Text('${nf(f.h.d)} ${hmonths[f.h.m - 1]} ${nf(f.h.y)} هـ', style: TextStyle(fontSize: 13, color: p.on2)),
                        ])),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: p.on2),
                          onSelected: (v) {
                            if (v == 'undo') { fastUpdate((s) => s.done.remove(dkey(d))); toast('تم إلغاء التسجيل'); }
                            if (v == 'open') { setState(() => sel = d); _daySheet(d); }
                          },
                          itemBuilder: (_) => const [PopupMenuItem(value: 'open', child: Text('تفاصيل اليوم')), PopupMenuItem(value: 'undo', child: Text('إلغاء التسجيل'))],
                        ),
                      ]),
                    );
                  }),
              ]),
            ),
            // المواسم القادمة
            const GoldTitle('المواسم القادمة'),
            AppCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < seasonsL.length; i++)
                  Builder(builder: (_) {
                    final s = seasonsL[i];
                    final df = dayDiff(now, s.st), on = df <= 0;
                    final hs = hj(s.st);
                    final rg = s.d1 == s.d2 ? nf(s.d1) : '${nf(s.d1)}–${nf(s.d2)}';
                    return InkWell(
                      onTap: () => setState(() { sel = noon(s.st); gy = s.st.year; gm = s.st.month; hy = hs.y; hm = hs.m; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: p.line))),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: on ? p.pri : p.surf2, borderRadius: BorderRadius.circular(14)),
                            child: Text(on ? 'جارٍ الآن' : df == 1 ? 'غدًا' : 'بعد ${nf(df)} يومًا', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? p.onpri : (dark ? p.pri : p.pri2))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Sub('$rg ${hmonths[hs.m - 1]} ${nf(hs.y)} هـ · ${s.st.day} ${gmonths[s.st.month - 1]}'),
                          ])),
                        ]),
                      ),
                    );
                  }),
              ]),
            ),
            if (F.custom.isNotEmpty) const GoldTitle('أيامي المخصّصة'),
            for (final c in F.custom)
              AppCard(margin: const EdgeInsets.only(bottom: 10), radius: 18, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((c['title'] as String?)?.isNotEmpty == true ? c['title'] as String : 'يوم صيام', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Sub(switch (c['type']) { 'once' => 'مرة واحدة · ${c['date']}', 'week' => 'أسبوعيًا', 'month' => 'كل شهر هجري · يوم ${nf(c['hd'])}', _ => 'كل عام هجري · ${nf(c['hd'])} ${hmonths[(((c['hm'] as num?) ?? 1).toInt() - 1).clamp(0, 11)]}' }),
                ])),
                Switch(value: c['on'] != false, onChanged: (v) { fastUpdate((s) => s.custom.firstWhere((x) => x['id'] == c['id'])['on'] = v); notifier.schedule(); }),
                IconButton(onPressed: () { fastUpdate((s) => s.custom.removeWhere((x) => x['id'] == c['id'])); notifier.schedule(); }, icon: const Icon(Icons.delete_outline, color: Color(0xFFA8332B))),
              ])),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Sub('تعديل التاريخ الهجري حسب رؤية الهلال في بلدك'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: adj,
                  decoration: InputDecoration(filled: true, fillColor: p.surf2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('بلا تعديل (أم القرى)')),
                    DropdownMenuItem(value: -1, child: Text('يوم أقل (−١)')),
                    DropdownMenuItem(value: 1, child: Text('يوم أكثر (+١)')),
                    DropdownMenuItem(value: -2, child: Text('يومان أقل (−٢)')),
                    DropdownMenuItem(value: 2, child: Text('يومان أكثر (+٢)')),
                  ],
                  onChanged: (v) { if (v == null) return; hap.click(); cfg.set('hijriAdj', v); notifier.schedule(); setState(() {}); },
                ),
              ]),
            ),
          ],
        );
      },
    );
  }

  void _rulesSheet(BuildContext context) {
    showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          final F = fastState();
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تخصيص أيام الصيام', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const Padding(padding: EdgeInsets.only(top: 2, bottom: 10), child: Sub('اختر ما يظهر في التقويم. رمضان والأعياد تظهر دائمًا.')),
            for (final r in ruleLabels)
              AppCard(
                margin: const EdgeInsets.only(bottom: 10), radius: 18, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(children: [
                  Expanded(child: Text(r[1], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  Switch(value: F.rules[r[0]] == true, onChanged: (v) { hap.tick(); fastUpdate((s) => s.rules[r[0]] = v); notifier.schedule(); set(() {}); }),
                ]),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: () { Navigator.pop(ctx); addCustom(); }, icon: Icon(Icons.add, size: 20, color: Pal.of(ctx).onpri), label: const SizedBox(width: double.infinity, child: Center(child: Text('يوم صيام')))),
          ]);
        }));
  }
}
