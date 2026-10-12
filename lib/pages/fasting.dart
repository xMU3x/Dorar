import 'package:flutter/material.dart';
import '../core/fasting.dart';
import '../core/hijri_util.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/wicons.dart';
import '../core/notify.dart';
import '../core/store.dart';
import '../core/data.dart';

class FastingPage extends StatefulWidget {
  final bool openAdd;
  const FastingPage({super.key, this.openAdd = false});
  @override
  State<FastingPage> createState() => _FastingPageState();
}

class _FastingPageState extends State<FastingPage> {
  late int gy, gm; // الشهر الميلادي المعروض (الأساسي)
  DateTime sel = noon(DateTime.now());

  @override
  void initState() {
    super.initState();
    gy = DateTime.now().year;
    gm = DateTime.now().month;
    if (widget.openAdd) WidgetsBinding.instance.addPostFrameCallback((_) => addCustom());
  }

  void shift(int d) {
    var m = gm + d, y = gy;
    if (m > 12) { m = 1; y++; }
    if (m < 1) { m = 12; y--; }
    hap.tick();
    setState(() { gm = m; gy = y; });
  }

  Color _kindColor(Pal p, String k) => switch (k) {
        'fard' => p.pri, 'sunna' => p.gold, 'bid' => p.ok, 'eid' => const Color(0xFFA8332B), 'custom' => const Color(0xFF6A5ACD), 'mt' => p.pri.withValues(alpha: .6), _ => Colors.transparent,
      };

  Future<void> addCustom() async {
    final title = TextEditingController();
    var type = 'once', date = noon(DateTime.now()), wd = <int>{1, 4}, hd = hj().d, hm = hj().m;
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
              if (type == 'year') Expanded(child: DropdownButtonFormField<int>(value: hm, items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(hmonths[i - 1]))], onChanged: (v) => set(() => hm = v ?? hm), decoration: const InputDecoration(labelText: 'الشهر'))),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة'))),
          ]);
        }));
    if (ok != true) return;
    fastUpdate((s) => s.custom.add({'id': DateTime.now().millisecondsSinceEpoch, 'title': title.text.trim(), 'type': type, 'date': dkey(date), 'wd': wd.toList(), 'hd': hd, 'hm': hm, 'on': true}));
    toast('تمت الإضافة');
  }

  static const _notes = {1: 'المحرّم: أفضل الصيام بعد رمضان', 8: 'شعبان: كان النبي ﷺ يُكثر الصيام فيه', 9: 'رمضان: صيام الشهر كله فرض', 10: 'شوّال: يُستحب صيام ست أيام منه', 12: 'ذو الحجة: التسع الأوائل ويوم عرفة'};

  Color _cellBg(Pal p, bool dark, String main) => switch (main) {
        'fard' => p.pri,
        'sunna' => dark ? const Color(0xFF2B5246) : const Color(0xFFBFDCD3),
        'bid' => dark ? const Color(0xFF4B4226) : const Color(0xFFEBDFB8),
        'eid' => dark ? const Color(0xFF5B2E2B) : const Color(0xFFF2CBC4),
        'custom' => dark ? const Color(0xFF2E4062) : const Color(0xFFCAD8EE),
        _ => p.surf2,
      };

  Widget _legend(Pal p, bool dark) {
    Widget k(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5))),
          const SizedBox(width: 6),
          Text(t, style: TextStyle(fontSize: 12, color: p.on2)),
        ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
      child: Wrap(spacing: 14, runSpacing: 8, children: [
        k(p.pri, 'فرض'), k(_cellBg(p, dark, 'sunna'), 'مستحب'), k(_cellBg(p, dark, 'bid'), 'أيام بيض'), k(_cellBg(p, dark, 'eid'), 'يُمنع الصيام'), k(_cellBg(p, dark, 'custom'), 'أيامي'),
        Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: p.pri)), const SizedBox(width: 6), Text('الاثنين والخميس', style: TextStyle(fontSize: 12, color: p.on2))]),
      ]),
    );
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
              Container(width: 14, height: 14, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: _cellBg(p, dark, t.kind == 'mt' ? 'sunna' : t.kind), borderRadius: BorderRadius.circular(5))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.t, style: const TextStyle(fontWeight: FontWeight.w700)), Sub(t.note)])),
            ]),
          ),
        if (!f.eid) ...[
          const SizedBox(height: 6),
          f.done
              ? OutlinedButton.icon(onPressed: () { hap.tick(); fastUpdate((s) => s.done.remove(key)); touchActivity(); Navigator.pop(ctx); toast('تم إلغاء التسجيل'); }, icon: WIcon('check', size: 20, color: p.pri), label: const SizedBox(width: double.infinity, child: Center(child: Text('تم تسجيل الصيام · إلغاء'))))
              : FilledButton.icon(onPressed: () { hap.success(); fastUpdate((s) => s.done[key] = 1); touchActivity(); Navigator.pop(ctx); toast('تقبّل الله صيامك'); }, icon: WIcon('check', size: 20, color: p.onpri), label: const SizedBox(width: double.infinity, child: Center(child: Text('صمتُ هذا اليوم')))),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); addCustom(); }, icon: WIcon('add', size: 20, color: p.pri), label: const SizedBox(width: double.infinity, child: Center(child: Text('إضافة صيام مخصّص لهذا اليوم')))),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      tab: widget.openAdd ? null : 3,
      builder: (context, _) {
        final p = Pal.of(context);
        final dark = p.bg.computeLuminance() < .3;
        final F = fastState();
        final now = DateTime.now();
        final h0 = hj(now);
        final nDays = DateTime(gy, gm + 1, 0).day;
        final days = [for (var i = 1; i <= nDays; i++) DateTime(gy, gm, i, 12)];
        final first = (jsDay(days.first) + 1) % 7;
        final hA = hj(days.first), hB = hj(days.last), hMid = hj(days[14]);
        final nx = nextFast();
        final yDone = F.done.keys.where((k) {
          final x = k.split('-').map(int.parse).toList();
          return hj(DateTime(x[0], x[1], x[2], 12)).y == h0.y;
        }).length;
        final adj = ((cfg.get('hijriAdj') as num?) ?? 0).toInt();
        final todayK = dkey(now);
        final away = gy != now.year || gm != now.month;
        // التاريخ الهجري ثانوي: نطاق الشهور الهجرية التي يغطيها الشهر الميلادي
        final rng = hA.m == hB.m ? '${hmonths[hA.m - 1]} ${toAr(hA.y)} هـ' : '${hmonths[hA.m - 1]} – ${hmonths[hB.m - 1]} ${toAr(hB.y)} هـ';
        final nxTags = nx?.info.tags.where((t) => t.kind != 'eid').map((t) => t.t).toList() ?? [];
        final nxTxt = nx == null ? '' : (nx.inDays == 0 ? 'اليوم' : nx.inDays == 1 ? 'غدًا' : 'بعد ${nf(nx.inDays)} أيام');
        return PageScaffold(
          title: 'التقويم',
          back: false,
          actions: [RoundIconButton(Icons.tune, () => _rulesSheet(context), tooltip: 'تخصيص')],
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 12), child: Sub('${gregString(now)} · ${hijriString(now)}')),
            RHero(
              icon: 'moon',
              ring: false,
              kicker: 'الصيام القادم',
              title: nx == null ? 'لا توجد أيام قريبة' : (nxTags.isEmpty ? 'يوم صيام' : nxTags.first),
              when: nx == null ? null : '$nxTxt · ${wdays[jsDay(nx.info.date)]} ${nf(nx.info.h.d)} ${hmonths[nx.info.h.m - 1]}',
              actions: [PillB('يوم صيام', addCustom, icon: 'add'), PillB('صمتُ ${nf(yDone)} يوم هذا العام', () {}, icon: 'check', outlined: true)],
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: GestureDetector(
                onHorizontalDragEnd: (d) { if ((d.primaryVelocity ?? 0).abs() > 300) shift(d.primaryVelocity! < 0 ? 1 : -1); },
                child: Column(children: [
                  Row(children: [
                    RoundIconButton(Icons.chevron_right, () => shift(-1)),
                    Expanded(child: Column(children: [
                      Text('${gmonths[gm - 1]} ${nf(gy)}م', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                      Sub(rng),
                    ])),
                    RoundIconButton(Icons.chevron_left, () => shift(1)),
                  ]),
                  if (_notes[hMid.m] != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(14)),
                      child: Text(_notes[hMid.m]!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: dark ? p.pri : p.pri2)),
                    ),
                  const SizedBox(height: 12),
                  Row(children: [for (final w in const ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة']) Expanded(child: Center(child: Text(w, style: TextStyle(fontSize: 12, color: p.on2))))]),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: const Cubic(.05, .7, .1, 1),
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(.12, 0), end: Offset.zero).animate(a), child: c)),
                    child: GridView.count(
                      key: ValueKey('$gy-$gm-$adj'),
                      crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: .86,
                      children: [
                        for (var i = 0; i < first; i++) const SizedBox.shrink(),
                        for (var i = 0; i < days.length; i++)
                          Builder(builder: (_) {
                            final d = days[i], inf = fastInfo(d, F), isSel = dkey(d) == dkey(sel), isToday = dkey(d) == todayK;
                            final bg = _cellBg(p, dark, inf.main);
                            final fg = inf.main == 'fard' ? p.onpri : p.on;
                            final mt = inf.tags.any((t) => t.kind == 'mt'), cs = inf.tags.any((t) => t.kind == 'custom');
                            return AnimatedScale(
                              scale: isSel ? .92 : 1,
                              duration: const Duration(milliseconds: 180),
                              child: Material(
                                color: bg,
                                borderRadius: BorderRadius.circular(14),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () { hap.select(); setState(() => sel = d); _daySheet(d); },
                                  child: Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: isToday ? Border.all(color: p.pri, width: 2.5) : null),
                                    child: Stack(alignment: Alignment.center, children: [
                                      Column(mainAxisSize: MainAxisSize.min, children: [
                                        Text(nf(d.day), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.2, color: fg)),
                                        Opacity(opacity: .6, child: Text(toAr(hj(d).d), style: TextStyle(fontSize: 11, height: 1.1, color: fg))),
                                      ]),
                                      if (mt) Positioned(bottom: 4, child: Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: inf.main == 'fard' ? p.onpri : p.pri))),
                                      if (cs) PositionedDirectional(top: 4, end: 4, child: Transform.rotate(angle: .785, child: Container(width: 6, height: 6, decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(2))))),
                                      if (inf.done) PositionedDirectional(top: 2, start: 3, child: WIcon('check', size: 13, color: inf.main == 'fard' ? Colors.white : p.ok)),
                                    ]),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  _legend(p, dark),
                  if (away)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton(onPressed: () { hap.click(); setState(() { gy = now.year; gm = now.month; }); }, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), side: BorderSide(color: p.on2, width: 1)), child: const Text('العودة إلى اليوم'))),
                    ),
                ]),
              ),
            ),
            const GoldTitle('المواسم القادمة'),
            AppCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < seasons().length; i++)
                  Builder(builder: (_) {
                    final s = seasons()[i];
                    final df = dayDiff(now, s.st), on = df <= 0;
                    final hs = hj(s.st);
                    final rg = s.d1 == s.d2 ? nf(s.d1) : '${nf(s.d1)}–${nf(s.d2)}';
                    return InkWell(
                      onTap: () => setState(() { sel = noon(s.st); gy = s.st.year; gm = s.st.month; }),
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
            FilledButton.icon(onPressed: () { Navigator.pop(ctx); addCustom(); }, icon: WIcon('add', size: 20, color: Pal.of(ctx).onpri), label: const SizedBox(width: double.infinity, child: Center(child: Text('يوم صيام')))),
          ]);
        }));
  }
}
