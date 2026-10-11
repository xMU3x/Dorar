import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../app.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/fasting.dart';
import '../core/hijri_util.dart';
import '../core/khatma.dart';
import '../core/notify.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'account.dart';
import 'settings.dart';

const _hadith = [
  ['إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى', 'متفق عليه · البخاري ١ ومسلم ١٩٠٧'],
  ['مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ', 'الترمذي ٢٣١٧'],
  ['لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ', 'متفق عليه · البخاري ١٣ ومسلم ٤٥'],
  ['مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ', 'متفق عليه'],
  ['الدِّينُ النَّصِيحَةُ', 'مسلم ٥٥'],
  ['أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ', 'متفق عليه · البخاري ٦٤٦٤ ومسلم ٧٨٣'],
  ['كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَنِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ', 'متفق عليه · البخاري ٦٤٠٦ ومسلم ٢٦٩٤'],
  ['تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ', 'الترمذي ١٩٥٦'],
  ['خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ', 'البخاري ٥٠٢٧'],
  ['الطُّهُورُ شَطْرُ الْإِيمَانِ', 'مسلم ٢٢٣'],
  ['مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ', 'مسلم ٢٦٩٩'],
  ['لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ', 'متفق عليه · البخاري ٦١١٤ ومسلم ٢٦٠٩'],
];

int _dayN() => DateTime.now().difference(DateTime(DateTime.now().year, 1, 0)).inDays;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(tab: 0,
      builder: (context, _) {
        final p = Pal.of(context);
        final kh = khatma(), pg = pagesToday(), st = streak();
        final goal = ((kh['goal'] as num?) ?? 5).toInt(), read = ((kh['read'] as num?) ?? 0).toInt();
        final h = _hadith[_dayN() % _hadith.length];
        final nf0 = nextFast(), rn = nextReminder(), now = DateTime.now(), hh = hj(now);
        final when = nf0 == null ? '' : nf0.inDays == 0 ? 'اليوم' : nf0.inDays == 1 ? 'غدًا' : 'بعد ${nf(nf0.inDays)} أيام';
        final fastTitle = nf0?.info.tags.where((t) => t.kind != 'eid').firstOrNull?.t ?? 'يوم صيام';
        final mq = MediaQuery.of(context);
        return Backdrop(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, mq.padding.top + 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Sub(hijriString()),
                  const Text('السلام عليكم 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ])),
                RoundIconButton(Icons.tune, () => pushPage(const SettingsPage())),
                RoundIconButton(Icons.person, () => pushPage(const AccountPage())),
              ]),
              HeroCard(
                onTap: () => openRoute('fasting'),
                margin: const EdgeInsets.only(top: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.nightlight_round, size: 20), SizedBox(width: 8), Text('الصيام القادم', style: TextStyle(fontWeight: FontWeight.w700))]),
                  const SizedBox(height: 4),
                  Text('${wdays[jsDay(now)]} · ${toAr(hh.d)} ${hmonths[hh.m - 1]} ${toAr(hh.y)} هـ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Text(nf0 == null ? 'لا توجد أيام قريبة' : fastTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  if (nf0 != null) Text('$when · ${wdays[jsDay(nf0.info.date)]} ${toAr(nf0.info.h.d)} ${hmonths[nf0.info.h.m - 1]}', style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              AppCard(
                onTap: () => openRoute('reminders'),
                child: Row(children: [
                  const IconBox(Icons.notifications),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('التذكير القادم', style: TextStyle(fontWeight: FontWeight.w700)),
                    Sub(rn == null ? 'لا توجد تذكيرات مفعّلة' : '${rn.it.title} · ${whenLabel(rn.at)}'),
                  ])),
                  Icon(Icons.chevron_left, color: p.on2),
                ]),
              ),
              AppCard(
                onTap: () => openRoute('khatma'),
                child: Row(children: [
                  Ring(v: read / 604, child: Text('${nf((read / 604 * 100).round())}%', style: const TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Sub('ختمتي الحالية'),
                    Text('${nf(read)} من ${nf(604)} صفحة', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                    Sub('ورد اليوم: ${nf(pg)}/${nf(goal)} صفحة'),
                    const SizedBox(height: 6),
                    Bar(pg / goal),
                  ])),
                ]),
              ),
              FutureBuilder(
                future: chalToday(),
                builder: (_, s) => AppCard(
                  onTap: () => openRoute('challenges'),
                  child: Row(children: [
                    const IconBox(Icons.emoji_events),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('تحديات اليوم', style: TextStyle(fontWeight: FontWeight.w700)),
                      Sub('${nf(s.data?.done ?? 0)} من ${nf(s.data?.total ?? 0)} · 🔥 ${nf(st.cur)} يوم متواصل'),
                    ])),
                    Icon(Icons.chevron_left, color: p.on2),
                  ]),
                ),
              ),
              HeroCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.auto_awesome, size: 20), SizedBox(width: 8), Text('حديث اليوم', style: TextStyle(fontWeight: FontWeight.w700))]),
                const SizedBox(height: 10),
                Text(h[0], style: const TextStyle(fontFamily: arabicFont, fontSize: 22, height: 2)),
                const SizedBox(height: 8),
                Text(h[1], style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
              FutureBuilder(
                future: data.ayahs(),
                builder: (_, s) {
                  if (!s.hasData) return const SizedBox.shrink();
                  final ay = s.data![(_dayN() * 37) % s.data!.length] as List;
                  return AppCard(child: Column(children: [
                    Row(children: [
                      const Expanded(child: Text('آية اليوم', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                      IconButton(onPressed: () async { hap.click(); final n = await data.surahName(ay[0] as int); Share.share('﴿${ay[2]}﴾\n— $n: ${ay[1]}'); }, icon: const Icon(Icons.share)),
                    ]),
                    Text('${ay[2]} ﴿${nf(ay[1] as int)}﴾', textAlign: TextAlign.center, style: const TextStyle(fontFamily: quranFont, fontSize: 24, height: 2)),
                    FutureBuilder(future: data.surahName(ay[0] as int), builder: (_, n) => Sub('${n.data ?? ''} · الآية ${nf(ay[1] as int)}', align: TextAlign.center)),
                  ]));
                },
              ),
              const SectionTitle('الوصول السريع'),
              GridView.count(
                crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .82,
                children: [
                  for (final q in const [
                    ('التسبيح', Icons.auto_awesome, 'tasbih'), ('التحديات', Icons.emoji_events, 'challenges'),
                    ('الختمة', Icons.flag, 'khatma'), ('الرقية', Icons.water_drop, 'ruqya'),
                    ('التذكيرات', Icons.notifications, 'reminders'), ('التقويم', Icons.calendar_month, 'fasting'),
                    ('القرّاء', Icons.music_note, 'reciters'), ('المزيد', Icons.grid_view, 'more'),
                  ])
                    AppCard(
                      margin: EdgeInsets.zero, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2), radius: 22,
                      onTap: () => openRoute(q.$3),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [IconBox(q.$2, size: 40), const SizedBox(height: 8), Text(q.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)]),
                    ),
                ],
              ),
              SizedBox(height: 100 + mq.padding.bottom),
            ],
          ),
        );
      },
    );
  }
}
