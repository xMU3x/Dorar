import 'package:flutter/material.dart';
import '../app.dart';
import '../core/notify.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) {
        final adj = ((cfg.get('hijriAdj') as num?) ?? 0).toInt();
        Widget sw(String k, String t, String s) => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Sub(s), value: cfg.get(k) == true, onChanged: (v) { hap.tick(); cfg.set(k, v); });
        return PageScaffold(title: 'الإعدادات', children: [
          const SectionTitle('المظهر'),
          AppCard(margin: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('الوضع', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ChipRow(items: const [('auto', 'تلقائي'), ('light', 'فاتح'), ('dark', 'داكن')], selected: cfg.get('mode') as String, onSelect: (v) => cfg.set('mode', v)),
            const SizedBox(height: 14),
            const Text('اللون', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ChipRow(items: const [('burgundy', 'عنابي'), ('green', 'أخضر')], selected: cfg.get('pal') as String, onSelect: (v) => cfg.set('pal', v)),
            sw('arDigits', 'الأرقام العربية', '١٢٣ بدل 123'),
          ])),
          const SectionTitle('التفاعل والتاريخ'),
          AppCard(margin: EdgeInsets.zero, child: Column(children: [
            sw('vibrate', 'الاهتزاز', 'اهتزاز خفيف عند اللمس والتنقل'),
            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تصحيح التاريخ الهجري', style: TextStyle(fontWeight: FontWeight.w700)), Sub('لموافقة الرؤية في بلدك')])),
              IconButton(onPressed: () { cfg.set('hijriAdj', (adj - 1).clamp(-2, 2)); notifier.schedule(); }, icon: const Icon(Icons.remove_circle_outline)),
              Text(nf(adj), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(onPressed: () { cfg.set('hijriAdj', (adj + 1).clamp(-2, 2)); notifier.schedule(); }, icon: const Icon(Icons.add_circle_outline)),
            ]),
          ])),
          const SectionTitle('روابط'),
          ItemTile(icon: Icons.notifications, title: 'التذكيرات', onTap: () => openRoute('reminders')),
          ItemTile(icon: Icons.favorite, title: 'الصلاة على النبي ﷺ', onTap: () => openRoute('notifsettings')),
          ItemTile(icon: Icons.menu_book, title: 'إعدادات الأذكار', onTap: () => openRoute('notifsettings/athkar')),
          ItemTile(icon: Icons.person, title: 'حسابي والمزامنة', onTap: () => openRoute('account')),
          ItemTile(icon: Icons.info_outline, title: 'عن التطبيق', onTap: () => openRoute('about')),
        ]);
      },
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageScaffold(title: 'عن التطبيق', children: [
      const SizedBox(height: 20),
      Center(child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.asset('assets/brand/app_icon.png', width: 96, height: 96))),
      const SizedBox(height: 12),
      const Center(child: Text('درر', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700))),
      const Padding(padding: EdgeInsets.all(12), child: Sub('كل أدواتك الإسلامية في مكان واحد: الأذكار والتذكيرات والصيام والتقويم الهجري والتحديات.', align: TextAlign.center)),
      AppCard(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المصادر', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Sub('الأذكار: حصن المسلم (hisnmuslim.com). القرآن الكريم: مصحف المدينة. الصوتيات: mp3quran.net. التقويم الهجري: أم القرى مع تصحيح الرؤية.'),
      ])),
      const AppCard(child: Sub('الإصدار 3.4.0 · تطبيق Flutter أصلي')),
    ]);
  }
}
