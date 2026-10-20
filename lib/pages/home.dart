import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import '../app.dart';
import '../core/azkar.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/fasting.dart';
import '../core/hijri_util.dart';
import '../core/khatma.dart';
import '../core/mawaiz.dart';
import '../core/notify.dart';
import '../core/tasbih.dart';
import '../core/tasks.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

/// ما يظهر في إشعار الجرس العائم.
class _Due {
  final String title, body, route;
  final IconData icon;
  const _Due(this.title, this.body, this.route, this.icon);
}

class _HomePageState extends State<HomePage> {
  late Future<Mawaz> _mw = randomMawaz();
  Mawaz? _cur;
  bool _bell = false;
  Timer? _bellTimer;
  int _libCount = 0;

  @override
  void initState() {
    super.initState();
    // إشعار الجرس العائم عند فتح التطبيق
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _showBell();
    });
    rootBundle.loadString('assets/data/library.json').then((r) {
      final b = (jsonDecode(r) as Map<String, dynamic>)['b'] as List;
      if (mounted) setState(() => _libCount = b.length);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _bellTimer?.cancel();
    super.dispose();
  }

  void _showBell() {
    _bellTimer?.cancel();
    setState(() => _bell = true);
    _bellTimer = Timer(const Duration(seconds: 9), () {
      if (mounted) setState(() => _bell = false);
    });
  }

  /// الذكر الذي عليه الدور حسب الوقت، وإلا التذكير القادم.
  _Due _due() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 11) return const _Due('حان وقت أذكار الصباح', 'ابدأ يومك بذكر الله', 'azkar', Icons.wb_twilight);
    if (h >= 15 && h < 20) return const _Due('حان وقت أذكار المساء', 'اختم نهارك بذكر الله', 'azkar', Icons.nightlight_round);
    if (h >= 21 || h < 3) return const _Due('حان وقت أذكار النوم', 'نَم على ذكر الله', 'azkar', Icons.bedtime_outlined);
    final rn = nextReminder();
    if (rn != null) return _Due('التذكير القادم: ${rn.it.title}', whenLabel(rn.at), 'reminders', Icons.notifications_active_outlined);
    return const _Due('اذكر الله', 'سبّح الله وسبّح معه', 'tasbih', Icons.auto_awesome);
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      tab: 0,
      builder: (context, _) {
        final p = Pal.of(context);
        final kh = khatma(), pg = pagesToday(), st = streak();
        final goal = ((kh['goal'] as num?) ?? 5).toInt(), read = ((kh['read'] as num?) ?? 0).toInt();
        final nf0 = nextFast();
        final mq = MediaQuery.of(context);
        final dTot = dayTasksTotal(), dDone = dayTasksDone();
        final tf = dTot == 0 ? 0.0 : (dDone / dTot).clamp(0.0, 1.0).toDouble();
        final tsb = tasbihDaySum('all');
        final due = _due();
        return Backdrop(
          child: Stack(children: [
            ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, mq.padding.top + 10, 16, 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Flexible(child: Text('السلام عليكم', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.25))),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 18)),
                        ]),
                        Text('طاب يومك ووفقك الله', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.on2)),
                      ]),
                    ),
                    RoundIconButton(Icons.notifications_none_rounded, _showBell, light: true, tooltip: 'تنبيه الذكر'),
                    RoundIconButton(Icons.person_outline_rounded, () => openRoute('profile'), light: true, tooltip: 'الملف الشخصي'),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Align(alignment: AlignmentDirectional.centerStart, child: _DateChip(onTap: () => openRoute('calendar'))),
                    const SizedBox(height: 10),
                    _FastHero(nx: nf0, onTap: () => openRoute('fasting')),
                    const SizedBox(height: 10),
                    FutureBuilder(
                      future: chalToday(),
                      builder: (_, s) {
                        final tot = s.data?.total ?? 0, dn = s.data?.done ?? 0;
                        return Column(children: [
                          _TwoRow(
                            _Tile(icon: Icons.checklist_rounded, title: 'المهام والعادات', line: '${nf(dDone)} من ${nf(dTot)} مكتملة', bar: tf, onTap: () => openRoute('tasks')),
                            _Tile(icon: Icons.emoji_events_outlined, title: 'تحديات اليوم', line: '${nf(dn)} من ${nf(tot)}', bar: tot == 0 ? 0 : dn / tot, extra: '${nf(st.cur)} أيام متواصلة', onTap: () => openRoute('challenges')),
                          ),
                          _TwoRow(
                            _Tile(icon: Icons.menu_book_rounded, title: 'ختمة القرآن', line: '${nf(read)} من ${nf(604)} صفحة', bar: read / 604, extra: 'ورد اليوم ${nf(pg)}/${nf(goal)}', onTap: () => openRoute('khatma')),
                            _Tile(icon: Icons.auto_awesome, title: 'التسبيح', line: 'اليوم: ${nf(tsb)} تسبيحة', onTap: () => openRoute('tasbih')),
                          ),
                          _TwoRow(
                            _Tile(icon: Icons.import_contacts_rounded, title: 'الحديث', line: 'البخاري ومسلم والأربعون', onTap: () => openRoute('hadith')),
                            _Tile(icon: Icons.local_library_outlined, title: 'المكتبة', line: _libCount == 0 ? 'كتب إسلامية' : '${nf(_libCount)} كتابًا', onTap: () => openRoute('library')),
                          ),
                          _TwoRow(
                            _Tile(icon: Icons.history_edu_rounded, title: 'قصص الأنبياء', line: 'من القرآن والسنة', onTap: () => openRoute('anbiya')),
                            _Tile(icon: Icons.format_quote_rounded, title: 'مواعظ مكتوبة', line: 'آيات وأحاديث وآثار', onTap: () => openRoute('mawaizw')),
                          ),
                        ]);
                      },
                    ),
                    FutureBuilder<Mawaz>(
                      future: _mw,
                      builder: (_, s) {
                        if (!s.hasData) return const SizedBox.shrink();
                        _cur = s.data;
                        return _MawazCard(m: s.data!, onMore: () => setState(() => _mw = randomMawaz(not: _cur)));
                      },
                    ),
                    SizedBox(height: 90 + mq.padding.bottom),
                  ]),
                ),
              ],
            ),
            // إشعار الجرس العائم
            Positioned(
              top: mq.padding.top + 58,
              left: 14,
              right: 14,
              child: IgnorePointer(
                ignoring: !_bell,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  offset: _bell ? Offset.zero : const Offset(0, -.4),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 260),
                    opacity: _bell ? 1 : 0,
                    child: Material(
                      color: p.surf,
                      elevation: Pal.darkNow ? 0 : 8,
                      shadowColor: Colors.black38,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          hap.tick();
                          setState(() => _bell = false);
                          openRoute(due.route);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: p.pri.withValues(alpha: .55), width: 1.3)),
                          child: Row(children: [
                            Container(width: 40, height: 40, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Icon(due.icon, color: p.pri, size: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                Text(due.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.3)),
                                Text(due.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.on2)),
                              ]),
                            ),
                            IconButton(visualDensity: VisualDensity.compact, onPressed: () => setState(() => _bell = false), icon: Icon(Icons.close, size: 18, color: p.on2)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// صفّ من بلاطتين متساويتين في الارتفاع.
class _TwoRow extends StatelessWidget {
  final Widget a, b;
  const _TwoRow(this.a, this.b);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)])),
      );
}

/// كبسولة التاريخ الهجري المصغّرة.
class _DateChip extends StatelessWidget {
  final VoidCallback onTap;
  const _DateChip({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final d = DateTime.now();
    final h0 = hj(d);
    final h = '${wdays[jsDay(d)]} ${nf(h0.d)} ${hmonths[h0.m - 1]} ${nf(h0.y)}هـ';
    return Material(
      color: p.surf,
      shape: StadiumBorder(side: BorderSide(color: p.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () { hap.tick(); onTap(); },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_month_outlined, size: 15, color: p.pri),
            const SizedBox(width: 6),
            Flexible(child: Text(h, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
          ]),
        ),
      ),
    );
  }
}

/// بطاقة «الصيام القادم» مصغّرة بدون دائرة النسبة.
class _FastHero extends StatelessWidget {
  final ({FastInfo info, int inDays})? nx;
  final VoidCallback onTap;
  const _FastHero({required this.nx, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final n = nx;
    final days = n?.inDays ?? 0;
    final v = n == null ? 0.0 : fastProgress(days);
    final title = n == null ? 'لا توجد أيام قريبة' : (n.info.tags.where((t) => t.kind != 'eid').firstOrNull?.t ?? 'يوم صيام');
    final left = n == null ? '' : days == 0 ? 'اليوم' : days == 1 ? 'متبقٍ يوم واحد' : days == 2 ? 'متبقٍ يومان' : 'متبقٍ ${nf(days)} أيام';
    final when = n == null ? '' : '${days == 0 ? 'اليوم' : days == 1 ? 'غدًا' : 'بعد ${nf(days)} أيام'} · ${wdays[jsDay(n.info.date)]} ${nf(n.info.date.day)} ${gmonths[n.info.date.month - 1]}';
    const gold = Color(0xFFE2B85B);
    return GestureDetector(
      onTap: () { hap.tick(); onTap(); },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [p.hero[0], p.hero[1]]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.nightlight_round, color: gold, size: 20),
            const SizedBox(width: 8),
            const Text('الصيام القادم', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (left.isNotEmpty) Text(left, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.3)),
          if (n != null) ...[
            const SizedBox(height: 2),
            Text(when, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11.5)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: v, minHeight: 5, backgroundColor: Colors.white.withValues(alpha: .22), valueColor: const AlwaysStoppedAnimation(gold))),
          ],
        ]),
      ),
    );
  }
}

/// بلاطة موحّدة: أيقونة مناسبة + عنوان + سطر + شريط تقدّم اختياري.
class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, line;
  final String? extra;
  final double? bar;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.line, this.extra, this.bar, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      radius: 18,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: p.pri, size: 19)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.25))),
        ]),
        const SizedBox(height: 6),
        Text(line, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.on2, fontSize: 11.5, height: 1.35)),
        if (bar != null) Padding(padding: const EdgeInsets.only(top: 6), child: Bar(bar!, track: p.surf2)),
        if (extra != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(extra!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: p.on2))),
      ]),
    );
  }
}

/// بطاقة «موعظة اليوم» مصغّرة بلا رسومات خلفية.
class _MawazCard extends StatelessWidget {
  final Mawaz m;
  final VoidCallback onMore;
  const _MawazCard({required this.m, required this.onMore});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final full = '${m.text}\n— ${m.source}';
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Container(
          key: ValueKey(m.text),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
          decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line), boxShadow: softShadow()),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.format_quote_rounded, color: p.gold, size: 20),
              const SizedBox(width: 6),
              const Expanded(child: Text('موعظة اليوم', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
              IconButton(visualDensity: VisualDensity.compact, onPressed: () => copyText(full), icon: Icon(Icons.copy_outlined, size: 18, color: p.on2)),
              IconButton(visualDensity: VisualDensity.compact, onPressed: () { hap.click(); Share.share(full); }, icon: Icon(Icons.share_outlined, size: 18, color: p.on2)),
              IconButton(visualDensity: VisualDensity.compact, onPressed: onMore, icon: Icon(Icons.autorenew, size: 18, color: p.on2)),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 2),
              child: Text(m.kind == 'hadith' ? '« ${m.text} »' : m.text, style: const TextStyle(fontFamily: quranFont, fontSize: 18, height: 1.9)),
            ),
            Padding(padding: const EdgeInsets.only(top: 2, left: 6), child: Text('المصدر: ${m.source}', style: TextStyle(color: p.on2, fontSize: 11.5))),
            if (m.tip.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6, left: 6, bottom: 4), child: Text(m.tip, style: TextStyle(color: p.on2, fontSize: 12.5, height: 1.6))),
          ]),
        ),
      ),
    );
  }
}
