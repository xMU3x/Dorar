import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/store.dart';
import '../core/tasbih.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

String _short(String t) {
  final s = t.replaceAll(RegExp('[\u064B-\u065F\u0670]'), '');
  return s.length > 22 ? s.substring(0, 22) : s;
}

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});
  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  // الحالة تعيش في الذاكرة أثناء العدّ (بدون قراءة/كتابة تخزين عند كل لمسة) وتُحفظ بتأخير قصير
  late Map<String, dynamic> t = tasbihState();
  Timer? _saveT;
  bool pressed = false;

  @override
  void dispose() {
    _saveT?.cancel();
    final snapshot = t;
    Future.microtask(() {
      store.set('tasbih', snapshot);
      chalCheck();
    });
    _pulse.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _saveT?.cancel();
    _saveT = Timer(const Duration(milliseconds: 900), () => store.set('tasbih', t, quiet: true));
  }

  void _commit() {
    _saveT?.cancel();
    store.set('tasbih', t);
  }

  Map<String, dynamic> get item {
    final items = (t['items'] as List).cast<Map>();
    return Map<String, dynamic>.from(items.firstWhere((x) => x['id'] == t['cur'], orElse: () => items.first));
  }

  int _n(String id) => (((t['n'] as Map)[id]) as num?)?.toInt() ?? 0;

  int _daySum() {
    final d = ((t['day'] as Map?)?[todayKey()] as Map?) ?? {};
    return d.values.fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0));
  }

  void tap() {
    final it = item;
    final goal = (it['goal'] as num).toInt();
    final done = tasbihTapIn(t, it['id'] as String, goal);
    _pulse.forward(from: 0).then((_) => _pulse.reverse());
    touchActivity();
    final n = _n(it['id'] as String);
    if (done) {
      hap.success();
      if (cfg.get('tsound') == true) SystemSound.play(SystemSoundType.alert);
      toast('أتممت الجولة، تقبّل الله منك');
      _commit();
      chalCheck();
    } else {
      (n % 33 == 0 || n % 10 == 0) ? hap.heavy() : hap.click();
      if (cfg.get('tsound') == true) SystemSound.play(SystemSoundType.click);
      _scheduleSave();
    }
    setState(() {});
  }

  void _mutate(void Function(Map<String, dynamic>) fn) {
    fn(t);
    _commit();
    setState(() {});
  }

  Future<void> addCustom() async {
    final tx = TextEditingController(), g = TextEditingController(text: '33');
    final ok = await showAppSheet<bool>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('إضافة ذكر مخصص', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: tx, decoration: const InputDecoration(hintText: 'نص الذكر')),
          const SizedBox(height: 10),
          TextField(controller: g, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'الهدف')),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة')),
        ]));
    if (ok != true) return;
    if (tx.text.trim().isEmpty) { toast('اكتب شيئًا أولًا.'); return; }
    final id = 'c${DateTime.now().millisecondsSinceEpoch}';
    _mutate((s) {
      (s['items'] as List).add({'id': id, 'text': tx.text.trim(), 'goal': int.tryParse(g.text) ?? 33, 'custom': true});
      s['cur'] = id;
    });
  }

  Future<void> setGoal() async {
    final it = item;
    final c = TextEditingController(text: '${it['goal']}');
    final ok = await showAppSheet<bool>(context, (ctx) => StatefulBuilder(builder: (ctx, set) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('الهدف (عدد التسبيحات في الجولة)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ChipRow(items: [for (final g in [33, 99, 100, 313, 1000]) ('$g', nf(g))], selected: c.text, onSelect: (v) => set(() => c.text = v)),
          const SizedBox(height: 12),
          TextField(controller: c, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ])));
    if (ok != true) return;
    final v = (int.tryParse(c.text) ?? 33).clamp(1, 100000);
    _mutate((s) {
      final m = (s['items'] as List).cast<Map>().firstWhere((x) => x['id'] == it['id']);
      m['goal'] = v;
      final n = (s['n'] as Map);
      final cur = (n[it['id']] as num?)?.toInt() ?? 0;
      n[it['id']] = cur > v - 1 ? v - 1 : cur;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final it = item;
    final goal = (it['goal'] as num).toInt();
    final n = _n(it['id'] as String);
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Backdrop(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, mq.padding.top + 8, 16, mq.padding.bottom + 16),
          child: Column(children: [
            Row(children: [
              RoundIconButton(Icons.arrow_forward, () => Navigator.of(context).maybePop()),
              const SizedBox(width: 8),
              const Expanded(child: Text('التسبيح', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
              Text('اليوم · ${nf(_daySum())}', style: TextStyle(color: p.gold, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final x in (t['items'] as List).cast<Map>())
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: GestureDetector(
                      onLongPress: x['custom'] == true ? () async {
                        if (await confirmDialog(context, 'حذف الذكر المخصص؟', x['text'] as String, ok: 'حذف', danger: true)) {
                          _mutate((s) {
                            s['items'] = (s['items'] as List).where((e) => (e as Map)['id'] != x['id']).toList();
                            if (s['cur'] == x['id']) s['cur'] = ((s['items'] as List).first as Map)['id'];
                          });
                        }
                      } : null,
                      child: ChoiceChip(
                        label: Text(_short(x['text'] as String)),
                        selected: x['id'] == it['id'], showCheckmark: false, selectedColor: p.pri, backgroundColor: p.surf,
                        labelStyle: TextStyle(color: x['id'] == it['id'] ? p.onpri : p.on), shape: const StadiumBorder(), side: BorderSide(color: p.line),
                        onSelected: (_) { hap.select(); _mutate((s) => s['cur'] = x['id']); },
                      ),
                    ),
                  ),
                ActionChip(label: const Text('+ ذكر مخصص'), onPressed: addCustom, shape: const StadiumBorder(), backgroundColor: p.surf, side: BorderSide(color: p.line)),
              ]),
            ),
            const SizedBox(height: 14),
            Text(it['text'] as String, textAlign: TextAlign.center, style: const TextStyle(fontFamily: arabicFont, fontSize: 26, height: 1.9)),
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) { setState(() => pressed = true); tap(); },
                onPointerUp: (_) => setState(() => pressed = false),
                onPointerCancel: (_) => setState(() => pressed = false),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Transform.scale(
                      scale: 1 + _pulse.value * .04 - (pressed ? .03 : 0),
                      child: Ring(
                        v: n / goal, size: 270, stroke: 12, color: p.gold, track: p.surf2, duration: const Duration(milliseconds: 140),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(nf(n), style: TextStyle(fontSize: 72, fontWeight: FontWeight.w700, color: p.pri)),
                          Text('من ${nf(goal)}', style: TextStyle(color: p.on2)),
                          Text('المتبقي ${nf(goal - n)}', style: TextStyle(color: p.on2, fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(onPressed: setGoal, icon: const Icon(Icons.flag), label: const Text('الهدف')),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () async {
                  if (await confirmDialog(context, 'إعادة تعيين العداد؟', 'سيُصفَّر عدّ هذا الذكر', ok: 'إعادة', danger: true)) {
                    _mutate((s) => (s['n'] as Map)[it['id']] = 0);
                    hap.heavy();
                  }
                },
                icon: const Icon(Icons.refresh), label: const Text('إعادة العدّ'),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('الاهتزاز'),
              Switch(value: cfg.get('vibrate') == true, onChanged: (v) { cfg.set('vibrate', v); if (v) hap.click(true); setState(() {}); }),
              const SizedBox(width: 20),
              const Text('الصوت'),
              Switch(value: cfg.get('tsound') == true, onChanged: (v) { cfg.set('tsound', v); setState(() {}); }),
            ]),
          ]),
        ),
      ),
    );
  }
}
