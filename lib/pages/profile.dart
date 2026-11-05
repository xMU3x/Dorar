import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../app.dart';
import '../core/data.dart';
import '../core/notify.dart';
import '../core/status_panel.dart';
import '../core/reports.dart';
import '../core/store.dart';
import '../core/sync.dart';
import '../core/tasks.dart';
import '../core/util.dart';
import '../ui/nav.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// الملف الشخصي: بيانات الحساب، الإحصاءات، المستوى، الإعدادات العامة، المظهر، معلومات التطبيق.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _pals = [('green', Color(0xFF0C4A38)), ('blue', Color(0xFF2B63C8)), ('purple', Color(0xFF6A4BB5)), ('brown', Color(0xFFA85A12)), ('burgundy', Color(0xFF7B2336))];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (_, __) => StoreBuilder(builder: (context, _) {
        final p = Pal.of(context);
        final u = sync.user;
        final meta = u?.userMetadata ?? {};
        final email = u?.email ?? '';
        final name = u == null ? 'ضيف' : (meta['full_name'] ?? meta['name'] ?? (email.isNotEmpty ? email.split('@').first : 'م')).toString();
        final xp = totalAzkarAll();
        final lv = levelOf(xp);
        final lvV = lv.to == lv.from ? 1.0 : ((xp - lv.from) / (lv.to - lv.from)).clamp(0.0, 1.0).toDouble();
        final tf = dayTasksTotal() == 0 ? 0.0 : dayTasksDone() / dayTasksTotal();
        final mode = cfg.get('mode') as String, pal = cfg.get('pal') as String;
        Widget row(IconData ic, String t, String s, VoidCallback f) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
              child: ListTile(
                onTap: () { hap.tick(); f(); },
                leading: Icon(ic, color: p.pri, size: 28),
                title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                subtitle: Text(s, style: TextStyle(color: p.on2, fontSize: 12.5)),
                trailing: Icon(Icons.chevron_left, color: p.on2),
              ),
            );
        return PageScaffold(
          title: 'الملف الشخصي',
          subtitle: 'رحلتك الإيمانية ... مستمرة',
          children: [
            AppCard(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(children: [
                Row(children: [
                  CircleAvatar(radius: 32, backgroundColor: p.pri, child: Icon(Icons.person, size: 38, color: p.pc)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      Text(u == null ? 'غير مسجّل الدخول' : email, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.on2, fontSize: 12.5)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: StatTile(Icons.schedule, '${nf((tf * 100).round())}%', 'تحقيق الأهداف')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(Icons.star_rounded, nf(streak().cur), 'أيام متتالية', color: const Color(0xFFE0A030))),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(Icons.menu_book_rounded, nf(quranReadingDays()), 'أيام قراءة القرآن')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(Icons.bar_chart_rounded, nf(xp), 'إجمالي الأذكار')),
                ]),
              ]),
            ),
            // المستوى
            GestureDetector(
              onTap: () => showAppSheet(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('مستويات الذكر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    for (var i = 0; i < levelNames.length; i++)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 14, backgroundColor: i + 1 <= lv.level ? p.pri : p.surf2, child: Text(nf(i + 1), style: TextStyle(fontSize: 12, color: i + 1 <= lv.level ? p.onpri : p.on2))),
                        title: Text(levelNames[i], style: TextStyle(fontWeight: i + 1 == lv.level ? FontWeight.w800 : FontWeight.w500)),
                        trailing: Text('${nf(levelXp[i])}+', style: TextStyle(color: p.on2)),
                      ),
                  ])),
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [p.hero[0], p.hero[1]]), borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  Stack(alignment: Alignment.center, children: [
                    const Icon(Icons.brightness_7_rounded, size: 70, color: Color(0xFFE2B85B)),
                    Icon(Icons.mosque, size: 28, color: p.hero[0]),
                    Positioned(bottom: 2, right: 2, child: CircleAvatar(radius: 11, backgroundColor: p.hero[0], child: Text(nf(lv.level), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)))),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('المستوى ${lv.ord}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                      Text(lv.name, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: lvV, minHeight: 7, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Color(0xFFE2B85B))))),
                        const SizedBox(width: 10),
                        Text('${nf(xp)} / ${nf(lv.to)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ]),
                  ),
                  const Icon(Icons.chevron_left, color: Colors.white),
                ]),
              ),
            ),
            // النسخة المميزة
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [p.hero[0], p.hero[2]]), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2B85B), width: 1.4)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.workspace_premium, color: Color(0xFFE2B85B)), SizedBox(width: 6), Text('النسخة المميزة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))]),
                    const SizedBox(height: 4),
                    const Text('احصل على جميع المميزات والموضوعات الحصرية', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5)),
                  ]),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE2B85B), foregroundColor: const Color(0xFF3A2A06)),
                  onPressed: () => toast('النسخة المميزة قريبًا'),
                  icon: const Icon(Icons.workspace_premium, size: 20),
                  label: const Text('ترقية الآن'),
                ),
              ]),
            ),
            // الإعدادات العامة
            AppCard(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
              child: Column(children: [
                Padding(padding: const EdgeInsets.only(bottom: 10, right: 4, left: 4), child: SecHead('الإعدادات العامة', icon: Icons.settings)),
                row(Icons.notifications_none, 'الإشعارات', 'إدارة أوقات الأذكار والتنبيهات', () => openRoute('reminders')),
                row(Icons.event_note, 'الهدف اليومي', 'تخصيص أهدافك اليومية', () => _goal(context)),
                row(Icons.language, 'اللغة', 'العربية', () => toast('التطبيق متاح بالعربية حاليًا')),
                row(Icons.cloud_upload_outlined, 'النسخ الاحتياطي والمزامنة', 'حفظ بياناتك عبر السحابة', () => openRoute('account')),
              ]),
            ),
            // المظهر
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SecHead('المظهر', icon: Icons.palette),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 6,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('لون التطبيق', style: TextStyle(color: p.on2, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final c in _pals)
                          GestureDetector(
                            onTap: () { hap.select(); cfg.set('pal', c.$1); },
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: c.$2, shape: BoxShape.circle, border: Border.all(color: pal == c.$1 ? p.pri : Colors.transparent, width: 2.5)),
                              child: pal == c.$1 ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                            ),
                          ),
                      ]),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 7,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('المظهر', style: TextStyle(color: p.on2, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(children: [
                        for (final m in const [('light', 'فاتح', Icons.wb_sunny), ('dark', 'داكن', Icons.nightlight_round), ('auto', 'تلقائي', Icons.brightness_6)])
                          Expanded(
                            child: GestureDetector(
                              onTap: () { hap.select(); cfg.set('mode', m.$1); },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(color: mode == m.$1 ? p.pc : p.surf2.withValues(alpha: .7), borderRadius: BorderRadius.circular(14), border: Border.all(color: mode == m.$1 ? p.pri : Colors.transparent, width: 1.6)),
                                child: Column(children: [Icon(m.$3, size: 22, color: m.$1 == 'light' ? const Color(0xFFE0A030) : p.pri), const SizedBox(height: 2), Text(m.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
                              ),
                            ),
                          ),
                      ]),
                    ]),
                  ),
                ]),
              ]),
            ),
            // التفاعل والتاريخ
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SecHead('التفاعل والتاريخ', icon: Icons.touch_app_outlined),
                const SizedBox(height: 6),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('الاهتزاز', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Sub('اهتزاز خفيف عند اللمس والتنقل'), value: cfg.get('vibrate') == true, onChanged: (v) { hap.tick(true); cfg.set('vibrate', v); }),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('لوحة اليوم الثابتة', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Sub('إشعار ثابت بمتبقي الصيام ومهام اليوم'), value: statusPanelEnabled(), onChanged: (v) { hap.tick(); cfg.set('statusPanel', v); refreshStatusPanel(now: true); }),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('الأرقام العربية', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Sub('١٢٣ بدل 123'), value: cfg.get('arDigits') == true, onChanged: (v) { hap.tick(); cfg.set('arDigits', v); }),
                Builder(builder: (_) {
                  final adj = ((cfg.get('hijriAdj') as num?) ?? 0).toInt();
                  return Row(children: [
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تصحيح التاريخ الهجري', style: TextStyle(fontWeight: FontWeight.w700)), Sub('لموافقة الرؤية في بلدك')])),
                    IconButton(onPressed: () { cfg.set('hijriAdj', (adj - 1).clamp(-2, 2)); notifier.schedule(); }, icon: const Icon(Icons.remove_circle_outline)),
                    Text(nf(adj), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    IconButton(onPressed: () { cfg.set('hijriAdj', (adj + 1).clamp(-2, 2)); notifier.schedule(); }, icon: const Icon(Icons.add_circle_outline)),
                  ]);
                }),
              ]),
            ),
            // معلومات التطبيق
            AppCard(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
              child: Column(children: [
                Padding(padding: const EdgeInsets.only(bottom: 10, right: 4, left: 4), child: SecHead('معلومات التطبيق', icon: Icons.info)),
                row(Icons.info, 'عن التطبيق', 'النسخة 3.5.0', () => openRoute('about')),
                row(Icons.star, 'تقييم التطبيق', 'ساعدنا بتقييم التطبيق', () => toast('شكرًا لك! سيتوفر التقييم عند النشر في المتجر')),
                row(Icons.share, 'مشاركة التطبيق', 'شارك الخير مع الآخرين', () => Share.share('جرّب تطبيق دُرَر للأذكار والقرآن والختمة والصيام والتقويم الهجري.')),
              ]),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _goal(BuildContext context) async {
    final k = khatmaGoal();
    final c = TextEditingController(text: '$k');
    final ok = await showAppSheet<bool>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('هدف القرآن اليومي (صفحات)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: c, keyboardType: TextInputType.number, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ]));
    if (ok == true) store.upd('khatma', {}, (z) => z['goal'] = (int.tryParse(c.text) ?? 5).clamp(1, 604));
  }
}

int khatmaGoal() => ((store.peekMap('khatma', {'goal': 5})['goal'] as num?) ?? 5).toInt();
