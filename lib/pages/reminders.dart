import 'package:flutter/material.dart';
import '../core/notify.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

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
    final title = TextEditingController(text: it?.title ?? ''), body = TextEditingController(text: it?.body ?? '');
    var time = it?.time ?? '08:00';
    final days = <int>{...(it?.days ?? [0, 1, 2, 3, 4, 5, 6])};
    final isCustom = it == null || it.custom;
    final ok = await showAppSheet<String>(context, (ctx) => StatefulBuilder(builder: (ctx, set) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it == null ? 'تذكير جديد' : it.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (isCustom) ...[
            TextField(controller: title, decoration: const InputDecoration(hintText: 'العنوان')),
            const SizedBox(height: 10),
            TextField(controller: body, decoration: const InputDecoration(hintText: 'النص')),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () async {
              final t = parseTime(time);
              final r = await showTimePicker(context: ctx, initialTime: TimeOfDay(hour: t.h, minute: t.m));
              if (r != null) set(() => time = '${pad(r.hour)}:${pad(r.minute)}');
            },
            icon: const Icon(Icons.access_time_rounded), label: Text(fmtTime(time)),
          ),
          const SizedBox(height: 10),
          if (it?.special != true) Wrap(spacing: 6, children: [for (var i = 0; i < 7; i++) FilterChip(label: Text(wdays[i].replaceFirst('ال', '')), selected: days.contains(i), onSelected: (s) => set(() => s ? days.add(i) : days.remove(i)))]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('حفظ'))),
            if (it != null) const SizedBox(width: 8),
            if (it != null) OutlinedButton(onPressed: () => Navigator.pop(ctx, it.custom ? 'del' : 'reset'), child: Text(it.custom ? 'حذف' : 'الافتراضي')),
          ]),
        ])));
    if (ok == null) return;
    if (ok == 'del') { reminderRemove(it!.id); return; }
    if (ok == 'reset') { reminderReset(it!); return; }
    final d = days.toList()..sort();
    if (it == null) {
      if (title.text.trim().isEmpty) { toast('اكتب عنوان التذكير'); return; }
      reminderAddCustom({'title': title.text.trim(), 'body': body.text.trim(), 'icon': 'bell', 'time': time, 'days': d});
    } else {
      reminderUpdate(it, {'time': time, 'days': d, if (it.custom) 'title': title.text.trim(), if (it.custom) 'body': body.text.trim()});
    }
    hap.success();
  }

  Widget tile(Reminder it, Pal p) => AppCard(
        margin: const EdgeInsets.only(top: 10),
        radius: 24,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        onTap: () => edit(it),
        child: Row(children: [
          IconBox(iconOf(it.icon)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Sub('${fmtTime(it.time)} · ${it.special ? 'قبل يوم الصيام' : daysLabel(it.days)}'),
          ])),
          Switch(value: it.on, onChanged: (v) { hap.tick(); reminderUpdate(it, {'on': v}); }),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) {
        final p = Pal.of(context);
        final nx = nextReminder();
        return PageScaffold(
          title: 'التذكيرات',
          fab: FloatingActionButton.extended(onPressed: () => edit(null), icon: const Icon(Icons.add_rounded), label: const Text('تذكير جديد')),
          children: [
            HeroCard(margin: const EdgeInsets.only(top: 6), child: Row(children: [
              const Icon(Icons.notifications_active_rounded, size: 32),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('التذكير القادم', style: TextStyle(color: Colors.white70)),
                Text(nx == null ? 'لا توجد تذكيرات مفعّلة' : nx.it.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                if (nx != null) Text(whenLabel(nx.at), style: const TextStyle(color: Colors.white70)),
              ])),
            ])),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('حالة الإشعارات', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Row(children: [Icon(perm == true ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: perm == true ? p.ok : const Color(0xFFA8332B), size: 20), const SizedBox(width: 8), Text(perm == true ? 'الإشعارات مسموحة' : 'الإشعارات غير مفعّلة')]),
              Row(children: [Icon(exact == true ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: exact == true ? p.ok : p.on2, size: 20), const SizedBox(width: 8), Text(exact == true ? 'التنبيه الدقيق مسموح' : 'التنبيه الدقيق غير مفعّل (قد يتأخر التذكير قليلًا)')]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                if (perm != true) FilledButton(onPressed: () async { await notifier.requestPermission(); await _check(); await notifier.schedule(); }, child: const Text('السماح بالإشعارات')),
                if (exact != true) OutlinedButton(onPressed: () async { await notifier.requestExact(); await _check(); await notifier.schedule(); }, child: const Text('تفعيل التنبيه الدقيق')),
                OutlinedButton(onPressed: () async { if (perm != true) await notifier.requestPermission(); await notifier.test(); await _check(); }, child: const Text('تجربة تذكير')),
              ]),
            ])),
            const SectionTitle('تذكيرات جاهزة'),
            for (final it in remindersDefault()) tile(it, p),
            if (remindersCustom().isNotEmpty) const SectionTitle('تذكيراتي'),
            for (final it in remindersCustom()) tile(it, p),
            const Padding(padding: EdgeInsets.all(16), child: Sub('على هواتف هواوي وشاومي فعّل «التشغيل التلقائي» و«بلا قيود» للتطبيق حتى تصل التذكيرات والتطبيق مغلق.', align: TextAlign.center)),
          ],
        );
      },
    );
  }
}
