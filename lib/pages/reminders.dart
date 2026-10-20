import 'package:flutter/material.dart';
import '../app.dart';
import '../core/notify.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/wicons.dart';

const _dayl = [('س', 6), ('ح', 0), ('ن', 1), ('ث', 2), ('ر', 3), ('خ', 4), ('ج', 5)];
const _icons = ['bell', 'sun', 'moon', 'book', 'spark', 'water', 'hand', 'fire', 'flag'];

/// صفحة التذكيرات — مطابقة لـ js/reminders.js (بطاقة التذكير القادم + بطاقات التذكيرات + لوح التعديل).
class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});
  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool? perm, exact;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final a = await notifier.notificationsAllowed();
    final b = await notifier.exactAllowed();
    if (mounted) setState(() { perm = a; exact = b; });
  }

  Future<void> edit(Reminder? it) async {
    final p = Pal.of(context);
    final title = TextEditingController(text: it?.title ?? ''), body = TextEditingController(text: it?.body ?? '');
    var time = it?.time ?? '08:00';
    var icon = it?.icon ?? 'bell';
    final days = <int>{...(it?.days ?? [0, 1, 2, 3, 4, 5, 6])};
    final isCustom = it == null || it.custom;
    final ok = await showAppSheet<String>(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          Widget quick(String l, List<int> d) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChipRow(items: [('x', l)], selected: '', onSelect: (_) => set(() { days..clear()..addAll(d); })),
              );
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it == null ? 'تذكير جديد' : 'تعديل التذكير', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (isCustom) ...[
              TextField(controller: title, maxLength: 40, decoration: const InputDecoration(hintText: 'عنوان التذكير (مثال: صلاة الضحى)', counterText: '')),
              const SizedBox(height: 10),
              TextField(controller: body, maxLength: 90, decoration: const InputDecoration(hintText: 'نص الإشعار (اختياري)', counterText: '')),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final k in _icons)
                  GestureDetector(
                    onTap: () { hap.tick(); set(() => icon = k); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46, height: 36,
                      decoration: BoxDecoration(color: icon == k ? p.pc : p.surf, borderRadius: BorderRadius.circular(12), border: Border.all(color: icon == k ? p.pri : p.line)),
                      child: Center(child: WIcon(k, size: 20, color: icon == k ? p.pri : p.on)),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
            ] else
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Sub(it.title)),
            Material(
              color: p.pc,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () async {
                  final t = parseTime(time);
                  final r = await showTimePicker(context: ctx, initialTime: TimeOfDay(hour: t.h, minute: t.m));
                  if (r != null) set(() => time = '${pad(r.hour)}:${pad(r.minute)}');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(children: [
                    const Text('الوقت', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Directionality(textDirection: TextDirection.ltr, child: Text(fmtTime(time), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: p.pri2))),
                  ]),
                ),
              ),
            ),
            if (it?.special != true) ...[
              const Padding(padding: EdgeInsets.fromLTRB(2, 14, 2, 8), child: Sub('الأيام')),
              Row(children: [
                for (final d in _dayl)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () { hap.tick(); set(() => days.contains(d.$2) ? days.remove(d.$2) : days.add(d.$2)); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 44,
                          decoration: BoxDecoration(color: days.contains(d.$2) ? p.pri : p.surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: days.contains(d.$2) ? p.pri : p.line, width: 1.5)),
                          child: Center(child: Text(d.$1, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: days.contains(d.$2) ? p.onpri : p.on))),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Row(children: [quick('كل يوم', [0, 1, 2, 3, 4, 5, 6]), quick('الاثنين والخميس', [1, 4]), quick('الجمعة', [5])]),
            ],
            const SizedBox(height: 18),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const SizedBox(width: double.infinity, child: Center(child: Text('حفظ')))),
            if (it != null) const SizedBox(height: 10),
            if (it != null && it.custom)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA8332B), foregroundColor: Colors.white, elevation: 0),
                onPressed: () => Navigator.pop(ctx, 'del'),
                child: const SizedBox(width: double.infinity, child: Center(child: Text('حذف التذكير'))),
              ),
            if (it != null && !it.custom)
              OutlinedButton(onPressed: () => Navigator.pop(ctx, 'reset'), child: const SizedBox(width: double.infinity, child: Center(child: Text('استعادة الإعدادات الافتراضية')))),
          ]);
        }));
    if (ok == null || !mounted) return;
    if (ok == 'del') {
      final sure = await confirmDialog(context, 'حذف التذكير؟', it!.title, ok: 'حذف', danger: true);
      if (sure) reminderRemove(it.id);
      return;
    }
    if (ok == 'reset') { reminderReset(it!); return; }
    final d = days.toList()..sort();
    if (d.isEmpty && it?.special != true) { toast('اختر يومًا واحدًا على الأقل'); return; }
    if (it == null) {
      if (title.text.trim().isEmpty) { toast('اكتب عنوان التذكير'); return; }
      reminderAddCustom({'title': title.text.trim(), 'body': body.text.trim(), 'icon': icon, 'time': time, 'days': d});
    } else {
      reminderUpdate(it, {'time': time, 'days': d, 'on': true, if (it.custom) 'title': title.text.trim(), if (it.custom) 'body': body.text.trim(), if (it.custom) 'icon': icon});
    }
    if (perm != true) { await notifier.requestPermission(); _check(); }
    hap.success();
    toast(it == null ? 'تمت إضافة التذكير' : 'تم الحفظ');
  }

  Widget card(Reminder it, Pal p, Pal dark) {
    final t = fmtTime(it.time).split(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        margin: EdgeInsets.zero,
        radius: 26,
        borderWidth: 1.5,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => edit(it),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: it.on ? 1 : .6,
          child: Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Center(child: WIcon(it.icon, size: 24, color: p.pri2 == p.pri ? p.pri : (isDarkPal(p) ? p.pri : p.pri2)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Sub(it.special ? 'قبل يوم الصيام' : daysLabel(it.days)),
            ])),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(t[0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text(t.length > 1 ? t[1] : '', style: TextStyle(fontSize: 12, color: p.on2)),
              ]),
            ),
            const SizedBox(width: 6),
            Switch(
              value: it.on,
              onChanged: (v) async {
                hap.click();
                if (v && perm != true) {
                  final g = await notifier.requestPermission();
                  if (!g) toast('اسمح بالإشعارات من إعدادات النظام أولًا');
                  _check();
                }
                reminderUpdate(it, {'on': v});
              },
            ),
          ]),
        ),
      ),
    );
  }

  bool isDarkPal(Pal p) => p.bg.computeLuminance() < .3;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) {
        final p = Pal.of(context);
        final nx = nextReminder();
        final on = remindersAll().where((x) => x.on).length;
        final cust = remindersCustom();
        return PageScaffold(
          title: 'التذكيرات',
          fab: FloatingActionButton.extended(onPressed: () { hap.click(); edit(null); }, icon: WIcon('add', color: p.onpri), label: const Text('تذكير جديد')),
          children: [
            RHero(
              kicker: 'التذكير القادم',
              title: nx == null ? 'لا توجد تذكيرات مفعّلة' : nx.it.title,
              when: nx == null ? 'فعّل تذكيرًا من القائمة' : whenLabel(nx.at),
              actions: [
                PillB('إشعار تجريبي', () async { if (perm != true) await notifier.requestPermission(); await notifier.test(); await _check(); toast('أرسلنا إشعارًا تجريبيًا الآن'); }, icon: 'send'),
                PillB('${nf(on)} مفعّل', () {}, icon: 'check', outlined: true),
              ],
            ),
            if (perm == false)
              AppCard(
                margin: const EdgeInsets.only(top: 12),
                borderColor: p.gold,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('الإشعارات غير مفعّلة', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Padding(padding: EdgeInsets.fromLTRB(0, 4, 0, 10), child: Sub('اسمح بالإشعارات حتى تصلك التذكيرات في مواعيدها.')),
                  FilledButton(onPressed: () async { await notifier.requestPermission(); await _check(); notifier.schedule(); }, child: const SizedBox(width: double.infinity, child: Center(child: Text('السماح بالإشعارات')))),
                ]),
              )
            else if (exact == false)
              AppCard(
                margin: const EdgeInsets.only(top: 12),
                borderColor: p.gold,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('التنبيه الدقيق غير مفعّل', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Padding(padding: EdgeInsets.fromLTRB(0, 4, 0, 10), child: Sub('فعّل «المنبهات والتذكيرات» لتصل التذكيرات في موعدها بالضبط.')),
                  FilledButton(onPressed: () async { await notifier.requestExact(); await _check(); notifier.schedule(); }, child: const SizedBox(width: double.infinity, child: Center(child: Text('فتح الإعداد')))),
                ]),
              ),
            ItemTile(iconName: 'fav', title: 'الصلاة على النبي ﷺ', sub: 'تذكير مسموع، الصيغة والنغمة، تكثيف الجمعة', onTap: () => openRoute('notifsettings')),
            ItemTile(iconName: 'book', title: 'إعدادات الأذكار', sub: 'تذكير الأذكار، قرب نهاية الوقت، الانتقال التلقائي', onTap: () => openRoute('notifsettings/athkar')),
            const GoldTitle('الأذكار والعبادة', sub: 'اضغط على التذكير لتعديل أيامه ووقته'),
            for (final it in remindersDefault()) card(it, p, p),
            const GoldTitle('تذكيراتي'),
            if (cust.isEmpty)
              AppCard(
                margin: EdgeInsets.zero,
                radius: 26,
                borderWidth: 1.5,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                onTap: () => edit(null),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(children: [
                    Container(width: 56, height: 56, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Center(child: WIcon('alarmadd', size: 24, color: p.pri))),
                    const SizedBox(height: 8),
                    const Text('أضف تذكيرك الخاص', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Sub('صلاة الضحى، الاستغفار، قيام الليل… اختر ما يناسبك.', align: TextAlign.center),
                  ]),
                ),
              )
            else
              for (final it in cust) card(it, p, p),
          ],
        );
      },
    );
  }
}
