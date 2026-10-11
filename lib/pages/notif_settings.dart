import 'package:flutter/material.dart';
import '../core/notify.dart';
import '../core/notify_plan.dart';
import '../core/salawat.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// إعدادات إشعارات الأذكار والصلاة على النبي ﷺ (مكافئ لوظائف Athar 1.45 المحلية).
class NotifSettingsPage extends StatefulWidget {
  const NotifSettingsPage({super.key});
  @override
  State<NotifSettingsPage> createState() => _NotifSettingsPageState();
}

class _NotifSettingsPageState extends State<NotifSettingsPage> with WidgetsBindingObserver {
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

  // عند العودة من شاشة إعدادات النظام نعيد فحص الأذونات والجدولة
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

  static String _every(int m) => m % 60 == 0 ? (m == 60 ? 'كل ساعة' : 'كل ${nf(m ~/ 60)} ساعات') : 'كل ${nf(m)} د';

  List<(String, String)> _chips(List<int> base, int cur) {
    final l = {...base, cur}.toList()..sort();
    return [for (final m in l) ('$m', _every(m))];
  }

  Widget _sw(String t, String s, bool v, ValueChanged<bool> f) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Sub(s),
        value: v,
        onChanged: (x) { hap.tick(); f(x); },
      );

  Widget _status(Pal p, bool? ok, String yes, String no, {bool warn = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(ok == true ? Icons.check_circle : (warn ? Icons.info_outline : Icons.error_outline), size: 20, color: ok == true ? p.ok : (warn ? p.on2 : const Color(0xFFA8332B))),
          const SizedBox(width: 8),
          Expanded(child: Text(ok == true ? yes : no)),
        ]),
      );

  Future<void> _hour(bool start, NtPrefs n) async {
    final cur = start ? n.quietStart : n.quietEnd;
    final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: cur, minute: 0), helpText: start ? 'بداية الهدوء' : 'نهاية الهدوء');
    if (r != null) ntSet({start ? 'quietStart' : 'quietEnd': r.hour});
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(builder: (context, _) {
      final p = Pal.of(context);
      final n = ntPrefs();
      final nx = notifier.nextAthkar();
      final today = salawatToday();
      final isFri = DateTime.now().weekday == DateTime.friday;
      return PageScaffold(title: 'إشعارات الأذكار', children: [
        HeroCard(margin: const EdgeInsets.only(top: 6), child: Row(children: [
          const Icon(Icons.notifications_active, size: 32),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('أقرب إشعار أذكار', style: TextStyle(color: Colors.white70)),
            Text(!n.master || nx == null ? 'لا توجد إشعارات مفعّلة' : nx.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            if (n.master && nx != null) Text(whenLabel(nx.at), style: const TextStyle(color: Colors.white70)),
          ])),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('الأذونات وتوفير البطارية', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
          const Sub('على هواتف هواوي وشاومي وأوبو فعّل أيضًا «التشغيل التلقائي» للتطبيق من إعدادات النظام.'),
        ])),
        AppCard(child: _sw('تفعيل إشعارات الأذكار', 'مفتاح رئيسي لكل الإشعارات أدناه (لا يؤثر على «التذكيرات»)', n.master, (v) => ntSet({'master': v}))),
        if (n.master) ...[
          const SectionTitle('الصلاة على النبي ﷺ'),
          AppCard(margin: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('اليوم: ${nf(today)}${isFri ? ' / ${nf(kFridayTarget)}' : ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                Sub('الأسبوع ${nf(salawatWeek())} · الشهر ${nf(salawatMonth())} · الكل ${nf(salawatTotal())}'),
              ])),
              FilledButton(onPressed: () { salawatAdd(); hap.success(); }, child: const Text('صليت ﷺ')),
            ]),
            if (isFri) ...[const SizedBox(height: 10), Bar(today / kFridayTarget)],
            const Divider(height: 24),
            _sw('تذكير دوري', 'إشعار بالصلاة على النبي مع زر «صليت» يسجّل العدّ', n.periodic, (v) => ntSet({'periodic': v})),
            if (n.periodic) ChipRow(items: _chips(const [5, 10, 15, 30, 60, 120], n.interval), selected: '${n.interval}', onSelect: (v) => ntSet({'interval': int.parse(v)})),
            _sw('تعزيز يوم الجمعة', 'تكرار أسرع يوم الجمعة', n.fridayBoost, (v) => ntSet({'fridayBoost': v})),
            if (n.fridayBoost) ChipRow(items: _chips(const [5, 10, 15, 30], n.fridayInterval), selected: '${n.fridayInterval}', onSelect: (v) => ntSet({'fridayInterval': int.parse(v)})),
            _sw('ليلة الجمعة', 'إشعار مساء الخميس يذكّر بكثرة الصلاة على النبي ﷺ', n.friday, (v) => ntSet({'friday': v})),
          ])),
          const SectionTitle('الأذكار'),
          AppCard(margin: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sw('تذكير الأذكار المتبقية', 'يتوقف تلقائيًا للمرحلة التي أتممتها اليوم', n.dhikr, (v) => ntSet({'dhikr': v})),
            if (n.dhikr) ChipRow(items: _chips(const [10, 20, 30, 60, 120], n.dhikrMin), selected: '${n.dhikrMin}', onSelect: (v) => ntSet({'dhikrMin': int.parse(v)})),
            _sw('تنبيه قرب نهاية الوقت', 'قبل نهاية أذكار الصباح والمساء والنوم بـ ${nf(kClosingLeadMin)} دقيقة', n.closing, (v) => ntSet({'closing': v})),
          ])),
          const SectionTitle('الهدوء والصوت'),
          AppCard(margin: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sw('ساعات الهدوء', 'بلا إشعارات أذكار دورية في هذه الفترة', n.quiet, (v) => ntSet({'quiet': v})),
            if (n.quiet) Wrap(spacing: 8, children: [
              OutlinedButton.icon(onPressed: () => _hour(true, n), icon: const Icon(Icons.bedtime_outlined), label: Text('من ${nf(n.quietStart)}:00')),
              OutlinedButton.icon(onPressed: () => _hour(false, n), icon: const Icon(Icons.wb_twilight), label: Text('إلى ${nf(n.quietEnd)}:00')),
            ]),
            _sw('الصوت', 'صوت الإشعار الافتراضي للنظام', n.sound, (v) => ntSet({'sound': v})),
            _sw('الاهتزاز', 'اهتزاز عند وصول الإشعار', n.vibrate, (v) => ntSet({'vibrate': v})),
            const Sub('الصوت والاهتزاز يُطبَّقان عبر قنوات الإشعارات، ويمكنك ضبطها تفصيليًا من إعدادات النظام ← الإشعارات.'),
          ])),
          const SectionTitle('تجربة وتشخيص'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: () async {
              if (perm != true) await notifier.requestPermission();
              final e = await notifier.testIn(60);
              toast(e == null ? 'سيصلك إشعار بعد دقيقة (يمكنك قفل الشاشة)' : 'فشلت الجدولة: $e');
              await _check();
            }, child: const Text('إشعار مجدول بعد دقيقة')),
            OutlinedButton(onPressed: () async { if (perm != true) await notifier.requestPermission(); await notifier.testSalawat(); await _check(); }, child: const Text('تجربة الصلاة على النبي')),
            OutlinedButton(onPressed: () async { if (perm != true) await notifier.requestPermission(); await notifier.testDhikr(); await _check(); }, child: const Text('تجربة تذكير الأذكار')),
          ]),
        ],
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('تشخيص الجدولة', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Sub('إشعارات مجدولة الآن: ${pending < 0 ? '—' : nf(pending)}'),
          Sub('المنطقة الزمنية: ${notifier.tzName}'),
          if (notifier.lastError.isNotEmpty) Text('آخر خطأ: ${notifier.lastError}', style: const TextStyle(color: Color(0xFFA8332B), fontSize: 12)),
        ])),
        const SizedBox(height: 24),
      ]);
    });
  }
}
