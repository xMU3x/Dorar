import 'package:flutter/material.dart';
import '../core/fasting.dart';
import '../core/hijri_util.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class FastingPage extends StatefulWidget {
  final bool openAdd;
  const FastingPage({super.key, this.openAdd = false});
  @override
  State<FastingPage> createState() => _FastingPageState();
}

class _FastingPageState extends State<FastingPage> {
  late int vy, vm;
  DateTime sel = noon(DateTime.now());

  @override
  void initState() {
    super.initState();
    final h = hj(DateTime.now());
    vy = h.y;
    vm = h.m;
    if (widget.openAdd) WidgetsBinding.instance.addPostFrameCallback((_) => addCustom());
  }

  void shift(int d) {
    var m = vm + d, y = vy;
    if (m > 12) { m = 1; y++; }
    if (m < 1) { m = 12; y--; }
    hap.tick();
    setState(() { vm = m; vy = y; });
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
            }, icon: const Icon(Icons.event_rounded), label: Text(dkey(date))),
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

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(tab: widget.openAdd ? null : 3,
      builder: (context, _) {
        final p = Pal.of(context);
        final F = fastState();
        final M = hmonth(vy, vm);
        final first = M.days.isEmpty ? 0 : (jsDay(M.days.first) + 1) % 7; // السبت أول الأسبوع
        final si = fastInfo(sel, F);
        const heads = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
        final todayK = dkey(DateTime.now());
        return PageScaffold(
          title: 'الصيام · التقويم الهجري',
          back: false,
          actions: [RoundIconButton(Icons.tune_rounded, () => _rulesSheet(context), tooltip: 'القواعد'), RoundIconButton(Icons.add_rounded, addCustom, tooltip: 'يوم مخصّص')],
          children: [
            AppCard(margin: const EdgeInsets.only(top: 6), child: Column(children: [
              Row(children: [
                IconButton(onPressed: () => shift(-1), icon: const Icon(Icons.chevron_right_rounded)),
                Expanded(child: Column(children: [
                  Text('${hmonths[vm - 1]} ${nf(vy)} هـ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  if (M.days.isNotEmpty) Sub('${gmonths[M.days.first.month - 1]} ${nf(M.days.first.year)}'),
                ])),
                IconButton(onPressed: () => shift(1), icon: const Icon(Icons.chevron_left_rounded)),
              ]),
              const SizedBox(height: 8),
              Row(children: [for (final h in heads) Expanded(child: Center(child: Text(h, style: TextStyle(color: p.on2, fontWeight: FontWeight.w700))))]),
              const SizedBox(height: 6),
              GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: .95, children: [
                for (var i = 0; i < first; i++) const SizedBox.shrink(),
                for (var i = 0; i < M.days.length; i++)
                  Builder(builder: (_) {
                    final d = M.days[i], inf = fastInfo(d, F), isSel = dkey(d) == dkey(sel), isToday = dkey(d) == todayK;
                    final c = _kindColor(p, inf.main);
                    return GestureDetector(
                      onTap: () { hap.select(); setState(() => sel = d); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSel ? p.pri : (inf.main.isNotEmpty ? c.withValues(alpha: .16) : Colors.transparent),
                          borderRadius: BorderRadius.circular(14),
                          border: isToday ? Border.all(color: p.gold, width: 2) : null,
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(nf(i + 1), style: TextStyle(fontWeight: FontWeight.w700, color: isSel ? p.onpri : p.on)),
                          Text(nf(d.day), style: TextStyle(fontSize: 10, color: isSel ? p.onpri.withValues(alpha: .8) : p.on2)),
                          if (inf.done) Icon(Icons.check_circle_rounded, size: 12, color: isSel ? p.onpri : p.ok),
                        ]),
                      ),
                    );
                  }),
              ]),
            ])),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${wdays[jsDay(sel)]} · ${nf(si.h.d)} ${hmonths[si.h.m - 1]} ${nf(si.h.y)} هـ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Sub('${nf(sel.day)} ${gmonths[sel.month - 1]} ${nf(sel.year)}'),
              const SizedBox(height: 8),
              if (si.tags.isEmpty) const Sub('لا يوجد صيام مخصوص في هذا اليوم'),
              for (final t in si.tags)
                Padding(padding: const EdgeInsets.only(top: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6, left: 10), decoration: BoxDecoration(shape: BoxShape.circle, color: _kindColor(p, t.kind))),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.t, style: const TextStyle(fontWeight: FontWeight.w700)), Sub('${kindLabels[t.kind] ?? ''} · ${t.note}')])),
                ])),
              if (si.fast) Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton.icon(
                onPressed: () {
                  si.done ? hap.click() : hap.success();
                  fastUpdate((s) => si.done ? s.done.remove(dkey(sel)) : s.done[dkey(sel)] = 1);
                },
                icon: Icon(si.done ? Icons.undo_rounded : Icons.check_rounded),
                label: Text(si.done ? 'إلغاء التسجيل' : 'صمتُ هذا اليوم'),
              )),
            ])),
            const SectionTitle('المواسم القادمة'),
            for (final s in seasons())
              ItemTile(
                icon: Icons.event_available_rounded, title: s.name,
                sub: '${nf(s.st.day)} ${gmonths[s.st.month - 1]} · ${dayDiff(DateTime.now(), s.st) <= 0 ? 'الآن' : 'بعد ${nf(dayDiff(DateTime.now(), s.st))} يوم'}',
                onTap: () => setState(() { sel = noon(s.st); final h = hj(s.st); vy = h.y; vm = h.m; }),
                trailing: const SizedBox.shrink(),
              ),
            if (F.custom.isNotEmpty) const SectionTitle('أيامي المخصّصة'),
            for (final c in F.custom)
              AppCard(margin: const EdgeInsets.only(top: 10), radius: 22, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((c['title'] as String?)?.isNotEmpty == true ? c['title'] as String : 'يوم صيام', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Sub(switch (c['type']) { 'once' => 'مرة واحدة · ${c['date']}', 'week' => 'أسبوعيًا', 'month' => 'كل شهر هجري · يوم ${nf(c['hd'])}', _ => 'كل عام هجري · ${nf(c['hd'])} ${hmonths[((c['hm'] as num).toInt() - 1).clamp(0, 11)]}' }),
                ])),
                Switch(value: c['on'] != false, onChanged: (v) => fastUpdate((s) => s.custom.firstWhere((x) => x['id'] == c['id'])['on'] = v)),
                IconButton(onPressed: () => fastUpdate((s) => s.custom.removeWhere((x) => x['id'] == c['id'])), icon: const Icon(Icons.delete_outline_rounded)),
              ])),
          ],
        );
      },
    );
  }

  void _rulesSheet(BuildContext context) {
    showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          final F = fastState();
          return Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('أنواع الصيام المعروضة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            for (final r in ruleLabels)
              SwitchListTile(title: Text(r[1]), value: F.rules[r[0]] == true, onChanged: (v) { hap.tick(); fastUpdate((s) => s.rules[r[0]] = v); set(() {}); }),
          ]);
        }));
  }
}
