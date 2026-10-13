import 'package:flutter/material.dart';
import '../core/azkar.dart';
import '../core/notify.dart';
import '../core/notify_plan.dart';
import '../core/salawat.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// الإعدادات والتخصيص: تبويبان — «الصلاة على النبي» و«إعدادات الأذكار».
class NotifSettingsPage extends StatefulWidget {
  final int initialTab;
  const NotifSettingsPage({super.key, this.initialTab = 0});
  @override
  State<NotifSettingsPage> createState() => _NotifSettingsPageState();
}

class _NotifSettingsPageState extends State<NotifSettingsPage> with WidgetsBindingObserver {
  late int tab = widget.initialTab;
  bool? perm, exact, battery;
  int pending = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check().then((_) => notifier.schedule());
  }

  Future<void> _check() async {
    final a = await notifier.notificationsAllowed();
    final b = await notifier.exactAllowed();
    final c = await notifier.batteryIgnored();
    final n = await notifier.pendingCount();
    if (mounted) setState(() { perm = a; exact = b; battery = c; pending = n; });
  }

  static String _every(int m) => m % 60 == 0 ? (m == 60 ? 'كل ساعة' : 'كل ${nf(m ~/ 60)} ساعات') : 'كل ${nf(m)} دقيقة';

  Widget _sw(String t, String s, bool v, ValueChanged<bool>? f, {String? badge}) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(children: [
          Flexible(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700))),
          if (badge != null) Container(margin: const EdgeInsetsDirectional.only(start: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Pal.of(context).pc, borderRadius: BorderRadius.circular(10)), child: Text(badge, style: TextStyle(fontSize: 11, color: Pal.of(context).pri, fontWeight: FontWeight.w700))),
        ]),
        subtitle: Sub(s),
        value: v,
        onChanged: f == null ? null : (x) { hap.tick(); f(x); },
      );

  Widget _drop<T>(T value, List<(T, String)> items, ValueChanged<T> f) {
    final p = Pal.of(context);
    final list = items.any((e) => e.$1 == value) ? items : [...items, (value, '$value')];
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, color: p.on2),
      decoration: InputDecoration(filled: true, fillColor: p.surf2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
      items: [for (final e in list) DropdownMenuItem<T>(value: e.$1, child: Text(e.$2, maxLines: 2, overflow: TextOverflow.ellipsis))],
      onChanged: (v) { if (v != null) { hap.select(); f(v); } },
    );
  }

  Widget _status(Pal p, bool? ok, String yes, String no, {bool warn = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(ok == true ? Icons.check_circle : (warn ? Icons.info_outline : Icons.error_outline), size: 20, color: ok == true ? p.ok : (warn ? p.on2 : const Color(0xFFA8332B))),
          const SizedBox(width: 8),
          Expanded(child: Text(ok == true ? yes : no)),
        ]),
      );

  Widget _tabs(Pal p) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(24), border: Border.all(color: p.line)),
        child: Row(children: [
          for (final t in const [(0, 'الصلاة على النبي ﷺ', Icons.favorite), (1, 'إعدادات الأذكار', Icons.menu_book)])
            Expanded(
              child: GestureDetector(
                onTap: () { hap.tick(); setState(() => tab = t.$1); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: tab == t.$1 ? p.gold : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(t.$3, size: 18, color: tab == t.$1 ? Colors.black87 : p.on2),
                    const SizedBox(width: 6),
                    Flexible(child: Text(t.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: tab == t.$1 ? Colors.black87 : p.on2))),
                  ]),
                ),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(builder: (context, _) {
      final p = Pal.of(context);
      final n = ntPrefs();
      return PageScaffold(
        title: 'الإعدادات والتخصيص',
        children: [
          Padding(padding: const EdgeInsets.only(top: 4), child: _tabs(p)),
          if (tab == 0) ..._salawat(p, n) else ..._athkar(p, n),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  // ---------------------------------------------------------------- الصلاة على النبي
  List<Widget> _salawat(Pal p, NtPrefs n) {
    final today = salawatToday();
    return [
      AppCard(child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('صلِّ على محمد ﷺ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const Sub('تفعيل التذكير بالصلاة على النبي'),
        ])),
        Switch(value: n.periodic, onChanged: (v) { hap.tick(); ntSet({'periodic': v, 'master': true}); }),
      ])),
      AppCard(child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('اليوم: ${nf(today)}${DateTime.now().weekday == DateTime.friday ? ' / ${nf(n.fridayGoal)}' : ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Sub('الأسبوع ${nf(salawatWeek())} · الشهر ${nf(salawatMonth())} · الكل ${nf(salawatTotal())}'),
        ])),
        FilledButton(onPressed: () { salawatAdd(); hap.success(); }, child: const Text('صليت ﷺ')),
      ])),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('الإعدادات العامة للتذكير', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const Divider(height: 18),
        _sw('التذكير بالوضع الصامت', 'نطق التذكير حتى أثناء وضع الصامت', n.silentMode, (v) => ntSet({'silentMode': v})),
        _sw('إيقاف التذكير أثناء المكالمات', 'يكتم النظام صوت الإشعارات أثناء المحادثة الهاتفية', n.stopCalls, (v) => ntSet({'stopCalls': v})),
        _sw('إيقاف التذكير أثناء النوم', 'ساعات النوم (${nf(n.quietStart)}:00 – ${nf(n.quietEnd)}:00) بلا إشعارات صلاة على النبي', n.quiet, (v) => ntSet({'quiet': v})),
        _sw('التذكير عند فتح الهاتف', 'نطق الذكر عند فتح قفل الشاشة', false, null, badge: 'قريبًا'),
      ])),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('اختر وقت تكرار الإشعار', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        _drop<int>(n.interval, [for (final m in const [5, 10, 15, 30, 45, 60, 120]) (m, _every(m))], (v) => ntSet({'interval': v})),
      ])),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('اختر صوت وصيغة التذكير', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          OutlinedButton.icon(
            onPressed: () async { if (perm != true) await notifier.requestPermission(); await notifier.testSalawat(); await _check(); },
            icon: const Icon(Icons.volume_up, size: 18),
            label: const Text('استماع'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
          ),
        ]),
        const SizedBox(height: 10),
        const Sub('الصيغة (نص الإشعار)'),
        const SizedBox(height: 6),
        _drop<int>(n.formula, [for (final e in kSalFormulas.entries) (e.key, '${nf(e.key)} - ${e.value}')], (v) => ntSet({'formula': v})),
        const SizedBox(height: 12),
        const Sub('النغمة'),
        const SizedBox(height: 6),
        _drop<String>(n.salSound, [for (final s in kSalSounds) (s, kSalSoundNames[s]!)], (v) => ntSet({'salSound': v})),
        const SizedBox(height: 8),
        const Sub('«استماع» يرسل إشعارًا تجريبيًا بالنغمة والصيغة المختارتين.'),
      ])),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sw('تكثيف الصلاة يوم الجمعة 🌿', 'من مغرب الخميس وحتى مغيب شمس الجمعة: مضاعفة التذكير لتكثير الصلاة على النبي ﷺ', n.fridayBoost, (v) => ntSet({'fridayBoost': v}), badge: 'سنّة مؤكدة'),
        if (n.fridayBoost) ...[
          const Divider(height: 18),
          const Sub('تكرار التذكير يوم الجمعة'),
          const SizedBox(height: 6),
          _drop<int>(n.fridayInterval, [for (final m in const [5, 10, 15, 30]) (m, m == 10 ? '${_every(m)} (موصى به 🌿)' : _every(m))], (v) => ntSet({'fridayInterval': v})),
          const SizedBox(height: 12),
          const Sub('هدف ورد الجمعة المباركة 🎯'),
          const SizedBox(height: 6),
          _drop<int>(n.fridayGoal, [for (final g in const [100, 300, 500, 1000, 3000, 5000]) (g, g == 500 ? '${nf(g)} صلاة (البداية المباركة)' : '${nf(g)} صلاة')], (v) => ntSet({'fridayGoal': v})),
          if (DateTime.now().weekday == DateTime.friday) ...[const SizedBox(height: 12), Bar(salawatToday() / n.fridayGoal)],
        ],
        const Divider(height: 22),
        _sw('ليلة الجمعة', 'إشعار مساء الخميس يذكّر بكثرة الصلاة على النبي ﷺ', n.friday, (v) => ntSet({'friday': v})),
      ])),
      ..._diagnostics(p),
    ];
  }

  // ---------------------------------------------------------------- إعدادات الأذكار
  List<Widget> _athkar(Pal p, NtPrefs n) => [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sw('الذكر العائم أثناء استخدام الهاتف', 'ظهور نافذة الذكر العائمة تلقائيًا كل فترة محددة أثناء استخدام الهاتف للتذكير بالورد الحالي دون مقاطعة', false, null, badge: 'قريبًا'),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sw('الأصوات الهادئة والتكبيرات', 'تشغيل صوت تنبيه عند إتمام الورد', doneSoundOn(), (v) => cfg.set('doneSound', v)),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sw('الانتقال التلقائي للذكر التالي', 'الانتقال فور إكمال عدد التسبيحات المطلوب', autoNextOn(), (v) => cfg.set('autoNext', v)),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sw('تذكير الأذكار المتبقية', 'يتوقف تلقائيًا للمرحلة التي أتممتها اليوم', n.dhikr, (v) => ntSet({'dhikr': v, 'master': true})),
          if (n.dhikr) ...[
            const Sub('وقت ظهور الذكر التالي'),
            const SizedBox(height: 6),
            _drop<int>(n.dhikrMin, [for (final m in const [10, 15, 20, 30, 45, 60, 120]) (m, m == 20 ? '${_every(m)} (افتراضي)' : _every(m))], (v) => ntSet({'dhikrMin': v})),
            const SizedBox(height: 8),
          ],
          _sw('تنبيه قرب نهاية الوقت', 'قبل نهاية أذكار الصباح والمساء والنوم بـ ${nf(kClosingLeadMin)} دقيقة', n.closing, (v) => ntSet({'closing': v, 'master': true})),
        ])),
        AppCard(child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تصفير أذكار اليوم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Sub('إعادة ضبط العدادات للبدء من جديد اليوم'),
          ])),
          OutlinedButton(
            onPressed: () async { if (await confirmDialog(context, 'تصفير أذكار اليوم؟', 'ستُصفَّر عدّادات كل الأذكار لهذا اليوم.', ok: 'تصفير', danger: true)) { zikrResetAll(); toast('تم التصفير'); } },
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC96A5A), side: const BorderSide(color: Color(0xFFC96A5A))),
            child: const Text('تصفير'),
          ),
        ])),
        ..._diagnostics(p),
      ];

  // ---------------------------------------------------------------- أذونات وتشخيص (يهم عمل الإشعارات في الخلفية)
  List<Widget> _diagnostics(Pal p) => [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('الأذونات وتوفير البطارية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          _status(p, perm, 'الإشعارات مسموحة', 'الإشعارات غير مفعّلة'),
          _status(p, exact, 'التنبيه الدقيق مسموح', 'التنبيه الدقيق غير مفعّل (قد يتأخر الإشعار قليلًا)', warn: true),
          _status(p, battery, 'التطبيق مستثنى من توفير البطارية', 'توفير البطارية قد يؤخّر الإشعارات أو يمنعها', warn: true),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (perm != true) FilledButton(onPressed: () async { if (!await notifier.requestPermission()) await notifier.openSettings(); await _check(); notifier.schedule(); }, child: const Text('السماح بالإشعارات')),
            if (exact != true) OutlinedButton(onPressed: () async { await notifier.requestExact(); await _check(); notifier.schedule(); }, child: const Text('تفعيل التنبيه الدقيق')),
            if (battery != true) OutlinedButton(onPressed: () async { if (!await notifier.requestBatteryIgnore()) await notifier.openSettings(); await _check(); }, child: const Text('بلا قيود للبطارية')),
          ]),
          const SizedBox(height: 8),
          const Sub('على هواتف هواوي وشاومي وأوبو فعّل أيضًا «التشغيل التلقائي» للتطبيق من إعدادات النظام ليبقى التذكير يعمل في الخلفية.'),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('تجربة وتشخيص', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: () async {
              if (perm != true) await notifier.requestPermission();
              final e = await notifier.testIn(60);
              toast(e == null ? 'سيصلك إشعار بعد دقيقة (يمكنك قفل الشاشة)' : 'فشلت الجدولة: $e');
              await _check();
            }, child: const Text('إشعار مجدول بعد دقيقة')),
            OutlinedButton(onPressed: () async { if (perm != true) await notifier.requestPermission(); await notifier.testDhikr(); await _check(); }, child: const Text('تجربة تذكير الأذكار')),
          ]),
          const SizedBox(height: 10),
          Sub('إشعارات مجدولة الآن: ${pending < 0 ? '—' : nf(pending)} · المنطقة الزمنية: ${notifier.tzName}'),
          if (notifier.lastError.isNotEmpty) Text('آخر خطأ: ${notifier.lastError}', style: const TextStyle(color: Color(0xFFA8332B), fontSize: 12)),
        ])),
      ];
}
