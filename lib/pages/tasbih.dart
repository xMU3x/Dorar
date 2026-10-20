import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/store.dart';
import '../core/tasbih.dart';
import '../core/util.dart';
import 'dart:math' as math;
import '../ui/nav.dart';
import '../ui/skyline.dart';
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
    _track();
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

  int get _dayGoal => ((t['dgoal'] as num?) ?? 1000).toInt();
  int _sessions() => (((t['sess'] as Map?)?[todayKey()]) as num?)?.toInt() ?? 0;
  int _durSec() => (((t['dur'] as Map?)?[todayKey()]) as num?)?.toInt() ?? 0;

  /// جلسة جديدة بعد توقف دقيقتين؛ والمدة تُجمع من الفواصل القصيرة بين اللمسات.
  void _track() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = (t['lt'] as num?)?.toInt() ?? 0;
    final k = todayKey();
    t['sess'] ??= <String, dynamic>{};
    t['dur'] ??= <String, dynamic>{};
    final sess = t['sess'] as Map, dur = t['dur'] as Map;
    if (now - last > 120000) {
      sess[k] = ((sess[k] as num?)?.toInt() ?? 0) + 1;
    } else {
      dur[k] = ((dur[k] as num?)?.toInt() ?? 0) + ((now - last) / 1000).round().clamp(0, 15);
    }
    t['lt'] = now;
  }

  void minus() {
    final id = item['id'] as String;
    final n = _n(id);
    if (n <= 0) return;
    hap.tick();
    _mutate((s) {
      (s['n'] as Map)[id] = n - 1;
      final tot = s['total'] as Map;
      tot[id] = (((tot[id] as num?)?.toInt() ?? 1) - 1).clamp(0, 1 << 30);
      final dd = ((s['day'] as Map?)?[todayKey()] as Map?);
      if (dd != null) dd[id] = (((dd[id] as num?)?.toInt() ?? 1) - 1).clamp(0, 1 << 30);
    });
  }

  Future<void> setDayGoal() async {
    final c = TextEditingController(text: '$_dayGoal');
    final ok = await showAppSheet<bool>(context, (ctx) => StatefulBuilder(builder: (ctx, set) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('الهدف اليومي (عدد التسبيحات)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ChipRow(items: [for (final g in [100, 300, 500, 1000, 3000]) ('$g', nf(g))], selected: c.text, onSelect: (v) => set(() => c.text = v)),
          const SizedBox(height: 12),
          TextField(controller: c, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ])));
    if (ok == true) _mutate((s) => s['dgoal'] = (int.tryParse(c.text) ?? 1000).clamp(1, 1000000));
  }

  void _history() {
    final p = Pal.of(context);
    final days = [for (var i = 6; i >= 0; i--) addDays(DateTime.now(), -i)];
    final sums = [for (final d in days) tasbihDaySum('all', dkey(d))];
    final mx = sums.fold<int>(1, (a, b) => b > a ? b : a);
    showAppSheet(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('سجل التسبيح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 70, child: Text(wdays[jsDay(days[i])], style: TextStyle(color: p.on2, fontSize: 13))),
                Expanded(child: Bar(sums[i] / mx)),
                SizedBox(width: 52, child: Text(nf(sums[i]), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
          const Divider(height: 24),
          for (final x in (t['items'] as List).cast<Map>())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(_short(x['text'] as String), style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${nf((((t['total'] as Map)[x['id']]) as num?)?.toInt() ?? 0)} تسبيحة · ${nf((((t['rounds'] as Map)[x['id']]) as num?)?.toInt() ?? 0)} جولة', style: TextStyle(color: p.on2, fontSize: 12.5)),
              ]),
            ),
        ]));
  }

  void _settings() {
    showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('إعدادات التسبيح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('الاهتزاز'), value: cfg.get('vibrate') == true, onChanged: (v) { cfg.set('vibrate', v); if (v) hap.click(true); set(() {}); }),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('الصوت'), value: cfg.get('tsound') == true, onChanged: (v) { cfg.set('tsound', v); set(() {}); }),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag), title: const Text('هدف الجولة لهذا الذكر'), onTap: () { Navigator.pop(ctx); setGoal(); }),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.track_changes), title: const Text('الهدف اليومي'), onTap: () { Navigator.pop(ctx); setDayGoal(); }),
        ])));
  }

  void _manage() {
    showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إدارة الأذكار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Sub('اضغط مطوّلًا على ذكر مخصص لحذفه، أو أضف ذكرًا جديدًا.'),
          const SizedBox(height: 8),
          for (final x in (t['items'] as List).cast<Map>())
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(x['text'] as String, style: const TextStyle(fontFamily: quranFont, fontSize: 19)),
              subtitle: Text('الهدف ${nf(x['goal'])}'),
              trailing: x['custom'] == true ? IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFA8332B)), onPressed: () {
                _mutate((s) {
                  s['items'] = (s['items'] as List).where((e) => (e as Map)['id'] != x['id']).toList();
                  if (s['cur'] == x['id']) s['cur'] = ((s['items'] as List).first as Map)['id'];
                });
                set(() {});
              }) : null,
              onTap: () { _mutate((s) => s['cur'] = x['id']); Navigator.pop(ctx); },
            ),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: () { Navigator.pop(ctx); addCustom(); }, icon: const Icon(Icons.add), label: const Text('ذكر مخصص')),
        ])));
  }

  Widget _side(Pal p, IconData ic, String? label, VoidCallback f, {bool circle = false}) => GestureDetector(
        onTap: () { hap.click(); f(); },
        child: Container(
          width: circle ? 58 : 64, height: circle ? 58 : 68,
          decoration: BoxDecoration(color: const Color(0xEEFFF9EA), shape: circle ? BoxShape.circle : BoxShape.rectangle, borderRadius: circle ? null : BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ic, size: circle ? 30 : 28, color: const Color(0xFF10261E)),
            if (label != null) Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6F7C74))),
          ]),
        ),
      );

  static const _chipIcons = [Icons.volunteer_activism, Icons.favorite_border, Icons.eco, Icons.mosque, Icons.nightlight_round, Icons.auto_awesome, Icons.star_border];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final it = item;
    final goal = (it['goal'] as num).toInt();
    final n = _n(it['id'] as String);
    final mq = MediaQuery.of(context);
    final sum = _daySum();
    final dg = _dayGoal;
    final dv = (sum / dg).clamp(0.0, 1.0).toDouble();
    final sceneH = mq.padding.top + 400;
    final items = (t['items'] as List).cast<Map>();
    final name = _short(it['text'] as String);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, height: sceneH, child: SkylineHeader(height: sceneH, arch: true, beads: true)),
        // عنوان داخل القوس
        Positioned(
          top: 0, left: 70, right: 70,
          child: Container(
            padding: EdgeInsets.fromLTRB(8, mq.padding.top + 12, 8, 14),
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xF2073A2D), Color(0xCC0B4A38)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(36))),
            child: Column(children: [
              const Text('التسبيح', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('اذكر الله في كل وقت', style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: .85))),
            ]),
          ),
        ),
        Positioned(
          top: mq.padding.top + 8, left: 14, right: 14,
          child: Row(children: [
            RoundIconButton(Icons.settings_outlined, _settings, tooltip: 'الإعدادات'),
            RoundIconButton(Icons.bar_chart_rounded, _history, tooltip: 'الإحصاءات'),
            const Spacer(),
            RoundIconButton(Icons.arrow_forward, () => Navigator.of(context).maybePop(), tooltip: 'رجوع', solid: true),
          ]),
        ),
        // العدّاد
        Positioned(
          top: mq.padding.top + 96, left: 0, right: 0,
          child: Center(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) { setState(() => pressed = true); tap(); },
              onPointerUp: (_) => setState(() => pressed = false),
              onPointerCancel: (_) => setState(() => pressed = false),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Transform.scale(
                  scale: 1 + _pulse.value * .035 - (pressed ? .025 : 0),
                  child: SizedBox(
                    width: 262, height: 262,
                    child: CustomPaint(
                      painter: _DialPainter(n / goal, p.pri),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(nf(n), style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w800, color: Color(0xFF10261E), height: 1.05)),
                        Text('من ${nf(goal)}', style: const TextStyle(fontSize: 18, color: Color(0xFF6F7C74))),
                        const SizedBox(height: 14),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: FittedBox(fit: BoxFit.scaleDown, child: Text(name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF10261E))))),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(top: mq.padding.top + 190, right: 14, child: Column(children: [_side(p, Icons.bar_chart_rounded, 'السجل', _history), const SizedBox(height: 14), _side(p, Icons.add, null, tap, circle: true)])),
        Positioned(
          top: mq.padding.top + 190, left: 14,
          child: Column(children: [
            _side(p, Icons.refresh, 'إعادة', () async {
              if (await confirmDialog(context, 'إعادة تعيين العداد؟', 'سيُصفَّر عدّ هذا الذكر', ok: 'إعادة', danger: true)) {
                _mutate((s) => (s['n'] as Map)[it['id']] = 0);
                hap.heavy();
              }
            }),
            const SizedBox(height: 14),
            _side(p, Icons.remove, null, minus, circle: true),
          ]),
        ),
        // اللوحة السفلية
        Positioned.fill(
          top: sceneH - 22,
          child: Container(
            decoration: BoxDecoration(color: p.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                AppCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(children: [
                    SecHead('الأذكار الشائعة', trailing: TextButton.icon(onPressed: _manage, icon: const Icon(Icons.format_list_bulleted, size: 20), label: const Text('إدارة الأذكار'), iconAlignment: IconAlignment.end)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 104,
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        for (var i = 0; i < items.length; i++)
                          _chip(p, items[i], i, items[i]['id'] == it['id']),
                      ]),
                    ),
                  ]),
                ),
                AppCard(
                  onTap: setDayGoal,
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  margin: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(16)), child: Icon(Icons.track_changes, color: p.pri, size: 30)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('الهدف اليومي', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                      Text('${nf(dg)} تسبيحة', style: TextStyle(fontSize: 13, color: p.on2)),
                    ]),
                    Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 12), color: p.line),
                    Expanded(child: Bar(dv, track: p.pc)),
                    const SizedBox(width: 10),
                    Text('${nf(sum)} / ${nf(dg)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Icon(Icons.chevron_left, color: p.on2),
                  ]),
                ),
                AppCard(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  child: Column(children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: SecHead('إحصائيات اليوم')),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(children: [
                        _stat(p, Icons.bar_chart_rounded, p.pri, '${nf((dv * 100).round())}%', '', 'نسبة الإنجاز'),
                        _vl(p),
                        _stat(p, Icons.autorenew, p.ok, nf(_sessions()), 'جلسات', 'عدد الجلسات'),
                        _vl(p),
                        _stat(p, Icons.local_fire_department, const Color(0xFFE8731C), nf(sum), 'تسبيحة', 'إجمالي اليوم'),
                        _vl(p),
                        _stat(p, Icons.schedule, const Color(0xFFD9A63B), nf((_durSec() / 60).ceil()), 'دقيقة', 'مدة التسبيح'),
                      ]),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _vl(Pal p) => Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: p.line);

  Widget _stat(Pal p, IconData ic, Color c, String v, String unit, String label) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, color: c, size: 28),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, height: 1.1))),
          Text(unit.isEmpty ? ' ' : unit, style: TextStyle(fontSize: 12.5, color: p.on)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 11.5, color: p.on2))),
        ]),
      );

  Widget _chip(Pal p, Map x, int i, bool sel) {
    final ic = _chipIcons[i % _chipIcons.length];
    final tint = [const Color(0xFFFBEBD3), const Color(0xFFE3F0E4), const Color(0xFFE3F0E4), const Color(0xFFDDEFE6), const Color(0xFFF6E8CF), const Color(0xFFE3F0E4), const Color(0xFFFBEBD3)][i % 7];
    return GestureDetector(
      onLongPress: x['custom'] == true ? () async {
        if (await confirmDialog(context, 'حذف الذكر المخصص؟', x['text'] as String, ok: 'حذف', danger: true)) {
          _mutate((s) {
            s['items'] = (s['items'] as List).where((e) => (e as Map)['id'] != x['id']).toList();
            if (s['cur'] == x['id']) s['cur'] = ((s['items'] as List).first as Map)['id'];
          });
        }
      } : null,
      onTap: () { hap.select(); _mutate((s) => s['cur'] = x['id']); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 88, margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: sel ? p.pri : tint, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFFE2B85B) : Colors.transparent, width: 2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: sel ? Colors.white.withValues(alpha: .15) : Colors.white.withValues(alpha: .75), shape: BoxShape.circle), child: Icon(sel ? Icons.check : ic, size: 22, color: sel ? const Color(0xFFE2B85B) : p.pri)),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FittedBox(fit: BoxFit.scaleDown, child: Text(_short(x['text'] as String), maxLines: 1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : p.on)))),
          Text(nf(x['goal']), style: TextStyle(fontSize: 13, color: sel ? Colors.white70 : p.on2)),
        ]),
      ),
    );
  }
}

/// قرص العدّ: دائرة كريمية بقوس أخضر وعقدة ذهبية عند بداية القوس.
class _DialPainter extends CustomPainter {
  final double v;
  final Color c;
  _DialPainter(this.v, this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final ctr = s.center(Offset.zero), r = s.width / 2;
    canvas.drawCircle(ctr, r, Paint()..color = const Color(0xFFFFF9EA).withValues(alpha: .97)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14));
    canvas.drawCircle(ctr, r, Paint()..color = const Color(0xFFFFF9EA).withValues(alpha: .97));
    final rect = Rect.fromCircle(center: ctr, radius: r - 17);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 24..color = const Color(0xFFE9E4D3));
    final vv = v.clamp(0.0, 1.0);
    if (vv > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * vv, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 24..strokeCap = StrokeCap.round..color = c);
    final a = -math.pi / 2;
    final k = ctr + Offset(math.cos(a), math.sin(a)) * (r - 17);
    canvas.drawCircle(k, 15, Paint()..shader = const RadialGradient(colors: [Color(0xFFFFE9A6), Color(0xFFD9A63B)]).createShader(Rect.fromCircle(center: k, radius: 15)));
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.v != v || o.c != c;
}
