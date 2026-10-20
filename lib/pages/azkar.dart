import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/azkar.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/player.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../app.dart';
import '../ui/skyline.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

IconData catIcon(String? i) => switch (i) {
      'wb_sunny' => Icons.wb_sunny_rounded,
      'nightlight_round' || 'bedtime' => Icons.nightlight_round,
      'mosque' => Icons.mosque,
      'water_drop' => Icons.water_drop,
      'home' => Icons.home,
      'flight' || 'route' => Icons.place,
      'restaurant' => Icons.restaurant,
      'healing' => Icons.healing,
      'thunderstorm' => Icons.thunderstorm,
      'checkroom' => Icons.checkroom,
      _ => Icons.auto_awesome,
    };

/// مربّع قسم: دائرة تقدّم بالنسبة المئوية + الاسم + عدد المكتمل.
class CatSquare extends StatelessWidget {
  final Map<String, dynamic> cat;
  const CatSquare(this.cat, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final pr = azkarProgressOf(cat);
    final v = pr.total == 0 ? 0.0 : pr.done / pr.total;
    final full = pr.total > 0 && pr.done >= pr.total;
    return AspectRatio(
      aspectRatio: .98,
      child: AppCard(
        margin: EdgeInsets.zero,
        radius: 26,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        color: full ? p.pc : null,
        borderColor: full ? p.pri : null,
        onTap: () => pushPage(ZikrPage(catId: cat['id'] as String)),
        child: Stack(children: [
          PositionedDirectional(top: 0, end: 0, child: Icon(catIcon(cat['icon'] as String?), size: 20, color: p.gold)),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Ring(
                v: v, size: 74, stroke: 7, color: full ? p.ok : p.pri, track: p.surf2,
                child: full ? Icon(Icons.check, color: p.ok, size: 30) : Text('${nf((v * 100).round())}%', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.pri)),
              ),
              const SizedBox(height: 10),
              Text(catTitle(cat), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
              const SizedBox(height: 2),
              Sub('${nf(pr.done)} من ${nf(pr.total)}'),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// شبكة مربعات بعمودين (بدون تمرير داخلي).
List<Widget> catGrid(List<Map<String, dynamic>> cats) {
  final rows = <Widget>[];
  for (var i = 0; i < cats.length; i += 2) {
    rows.add(Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        Expanded(child: CatSquare(cats[i])),
        const SizedBox(width: 12),
        Expanded(child: i + 1 < cats.length ? CatSquare(cats[i + 1]) : const SizedBox.shrink()),
      ]),
    ));
  }
  return rows;
}

typedef _Hit = (Map<String, dynamic>, Map<String, dynamic>);

List<_Hit> _textHits(List<Map<String, dynamic>> cats, String b) {
  final hits = <_Hit>[];
  if (b.length <= 2) return hits;
  for (final c in cats) {
    for (final z in (c['azkar'] as List).cast<Map<String, dynamic>>()) {
      if (hits.length < 25 && bare(z['text'] as String).contains(b)) hits.add((c, z));
    }
  }
  return hits;
}

List<Widget> _hitWidgets(List<_Hit> hits) => [
      if (hits.isNotEmpty) const SectionTitle('في كل الأذكار'),
      for (final h in hits)
        AppCard(
          margin: const EdgeInsets.only(top: 10), radius: 22,
          onTap: () => pushPage(ZikrPage(catId: h.$1['id'] as String)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_clean((h.$2['text'] as String).length > 120 ? '${(h.$2['text'] as String).substring(0, 120)}…' : h.$2['text'] as String), style: const TextStyle(fontFamily: quranFont, fontSize: 18, height: 1.9)),
            Sub(catTitle(h.$1)),
          ]),
        ),
    ];

const _prayerIds = {'hisn-8', 'hisn-9', 'hisn-12', 'hisn-13', 'hisn-14', 'hisn-15', 'hisn-16', 'hisn-17', 'hisn-18', 'hisn-19', 'hisn-20', 'hisn-21', 'hisn-22', 'hisn-23', 'hisn-24', 'hisn-26'};
const _afterId = 'hisn-25', _sleepId = 'hisn-28';

/// مجموع تكرارات القسم: المطلوب والمنجز (كل تكرار يُحسب).
({int total, int done}) _reps(String catId, List<Map<String, dynamic>> list) {
  var t = 0, d = 0;
  for (final z in list) {
    final tg = (z['count'] as num?)?.toInt() ?? 1;
    t += tg;
    final n = zikrCount(catId, z['id'] as int);
    d += n > tg ? tg : n;
  }
  return (total: t, done: d);
}

/// زيادة/إنقاص عدّاد ذكر من القائمة المختصرة (نفس منطق صفحة القراءة الكاملة).
void _bumpIn(String catId, List<Map<String, dynamic>> list, Map<String, dynamic> z, int delta) {
  final id = z['id'] as int, t = (z['count'] as num?)?.toInt() ?? 1, n0 = zikrCount(catId, id);
  if (delta > 0 && n0 >= t) { hap.error(); return; }
  if (delta < 0 && n0 <= 0) return;
  bool allDone() => list.every((x) => zikrCount(catId, x['id'] as int) >= ((x['count'] as num?)?.toInt() ?? 1));
  final wasAll = allDone();
  zikrSet(catId, id, n0 + delta);
  touchActivity();
  final done = zikrCount(catId, id) >= t;
  if (delta > 0) {
    done ? hap.success() : hap.click();
    if (done) {
      chalCheck();
      if (allDone() && !wasAll) {
        zikrCatCompleted(catId);
        if (doneSoundOn()) SystemSound.play(SystemSoundType.alert);
        toast('أتممت الورد، تقبّل الله منك 🤍');
      }
    }
  } else {
    hap.tick();
  }
}

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});
  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  String tab = 'morning', q = '';
  bool evening = false, searching = false;

  String _catFor(String t) => switch (t) { 'morning' => evening ? kEveningCat : kMorningCat, _ => _sleepId };

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      tab: 3,
      builder: (context, _) => FutureBuilder(
        future: data.categories(),
        builder: (context, snap) {
          final cats = snap.data ?? [];
          final p = Pal.of(context);
          final mq = MediaQuery.of(context);
          final b = bare(q);
          final listTab = tab == 'morning' || tab == 'sleep';
          final cat = listTab ? cats.where((c) => c['id'] == _catFor(tab)).firstOrNull : null;
          final list = cat == null ? <Map<String, dynamic>>[] : (cat['azkar'] as List).cast<Map<String, dynamic>>();
          final r = cat == null ? (total: 0, done: 0) : _reps(cat['id'] as String, list);
          final v = r.total == 0 ? 0.0 : r.done / r.total;
          final gridCats = switch (tab) {
            'prayer' => cats.where((c) => _prayerIds.contains(c['id']) || c['id'] == _afterId).toList(),
            'other' => cats.where((c) => !isMainCat(c['id'] as String) && !_prayerIds.contains(c['id']) && c['id'] != _afterId && c['id'] != _sleepId).toList(),
            _ => <Map<String, dynamic>>[],
          };
          final found = b.isEmpty ? <Map<String, dynamic>>[] : cats.where((c) => bare(catTitle(c)).contains(b)).toList();
          final label = switch (tab) { 'morning' => evening ? 'أذكار المساء' : 'أذكار الصباح', _ => 'أذكار النوم' };
          final sub = switch (tab) { 'morning' => evening ? 'اختم يومك بذكر الله' : 'ابدأ يومك بذكر الله', _ => 'نَم على ذكر الله' };
          final tabIcon = switch (tab) { 'morning' => evening ? Icons.nightlight_round : Icons.wb_twilight, _ => Icons.nightlight_round };
          return PageScaffold(
            title: 'الأذكار',
            subtitle: 'قرباً من الله في كل لحظة',
            back: false,
            actions: [
              RoundIconButton(Icons.search, () => setState(() { searching = !searching; q = ''; }), tooltip: 'بحث'),
              RoundIconButton(Icons.favorite, () => pushPage(const FavZikrPage()), tooltip: 'المفضلة'),
            ],
            children: [
              if (searching) ...[
                TextField(autofocus: true, decoration: const InputDecoration(hintText: 'ابحث عن ذكر أو دعاء...', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => q = v)),
                ...catGrid(found),
                ..._hitWidgets(_textHits(cats, b)),
                if (b.isNotEmpty && found.isEmpty && _textHits(cats, b).isEmpty) const Padding(padding: EdgeInsets.all(40), child: Sub('لا نتائج', align: TextAlign.center)),
              ] else ...[
                TabPills(
                  selected: tab,
                  onSelect: (t) => setState(() => tab = t),
                  items: const [('morning', 'أذكار الصباح والمساء', Icons.wb_twilight), ('sleep', 'أذكار النوم', Icons.nightlight_outlined), ('prayer', 'أذكار الصلاة', Icons.mosque_outlined), ('other', 'أذكار أخرى', Icons.grid_view)],
                ),
                if (listTab && cat != null) ...[
                  if (tab == 'morning')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Align(alignment: AlignmentDirectional.centerStart, child: SegToggle(items: const [('m', 'صباحًا'), ('e', 'مساءً')], selected: evening ? 'e' : 'm', onSelect: (x) => setState(() => evening = x == 'e'))),
                    ),
                  // بطاقة التقدّم
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.gold.withValues(alpha: .45), width: 1.2), boxShadow: softShadow()),
                    child: Row(children: [
                      Ring(v: v, size: 62, stroke: 7, track: p.surf2, child: Text('${nf((v * 100).round())}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.3)),
                          Text(sub, style: TextStyle(fontSize: 12, color: p.on2)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(child: Bar(v, track: p.surf2)),
                            const SizedBox(width: 8),
                            Text('${nf(r.done)} من ${nf(r.total)}', style: TextStyle(fontSize: 11.5, color: p.on2)),
                          ]),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Icon(tabIcon, size: 30, color: p.gold),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _MiniStat(Icons.autorenew, nf(r.total - r.done), 'متبقي')),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniStat(Icons.check_circle, nf(r.done), 'مكتمل اليوم', color: p.ok)),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniStat(Icons.bar_chart_rounded, nf(r.total), 'إجمالي الأذكار')),
                  ]),
                  const SizedBox(height: 12),
                  for (var i = 0; i < list.length; i++) _ZikrNurCard(z: list[i], catId: cat['id'] as String, list: list),
                ] else if (!listTab) ...[
                  Padding(padding: const EdgeInsets.only(top: 14), child: SecHead(tab == 'prayer' ? 'أذكار الصلاة' : 'أذكار أخرى', icon: tab == 'prayer' ? Icons.mosque_outlined : Icons.grid_view_rounded)),
                  if (snap.connectionState != ConnectionState.done) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
                  ...catGrid(gridCats),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color? color;
  const _MiniStat(this.icon, this.value, this.label, {this.color});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: color ?? p.pri),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 12.5, color: p.on2))),
      ]),
    );
  }
}

/// بطاقة ذكر بأسلوب نور: عنوان اختياري، النص، المصدر، نسخ، وزر عدّاد.
class _ZikrNurCard extends StatelessWidget {
  final Map<String, dynamic> z;
  final String catId;
  final List<Map<String, dynamic>> list;
  const _ZikrNurCard({required this.z, required this.catId, required this.list});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final id = z['id'] as int, t = (z['count'] as num?)?.toInt() ?? 1, n = zikrCount(catId, id), done = n >= t;
    final raw = z['text'] as String;
    final (isQ, text) = _splitQuran(raw);
    final title = z['title'] as String?;
    final src = ((z['source'] as String?) ?? '').trim();
    final fav = zikrIsFav('$catId:$id');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: done ? .62 : 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 8),
          decoration: BoxDecoration(color: done ? p.pc : p.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: done ? p.pri.withValues(alpha: .4) : p.line), boxShadow: softShadow()),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (title != null && title.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.pri))),
            Text(isQ ? '﴿ $text ﴾' : text, textAlign: isQ ? TextAlign.center : TextAlign.start, style: const TextStyle(fontFamily: quranFont, fontSize: 20, height: 1.9)),
            if (src.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(src, style: TextStyle(fontSize: 11, color: p.on2, height: 1.4))),
            const SizedBox(height: 6),
            Row(children: [
              IconButton(visualDensity: VisualDensity.compact, onPressed: () => copyText(raw), icon: Icon(Icons.copy_outlined, size: 19, color: p.on2), tooltip: 'نسخ'),
              IconButton(visualDensity: VisualDensity.compact, onPressed: () => zikrToggleFav('$catId:$id'), icon: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 19, color: fav ? const Color(0xFFD64A5A) : p.on2), tooltip: 'المفضلة'),
              IconButton(visualDensity: VisualDensity.compact, onPressed: n > 0 ? () => _bumpIn(catId, list, z, -1) : null, icon: Icon(Icons.remove_circle_outline, size: 19, color: p.on2), tooltip: 'إنقاص'),
              const Spacer(),
              GestureDetector(
                onTap: () => _bumpIn(catId, list, z, done ? -1 : 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: done ? p.ok : p.pri, borderRadius: BorderRadius.circular(18)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(done ? Icons.check : Icons.touch_app_outlined, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(done ? 'تم' : '${nf(n)} من ${nf(t)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// صف ذكر مختصر: رقم، نص مقتطع + المصدر، عدّاد، أزرار +/−، قائمة ⋮ (التخطيط كما في التصميم).
class _ZikrRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> z;
  final String catId;
  final List<Map<String, dynamic>> list;
  final bool last;
  const _ZikrRow({required this.index, required this.z, required this.catId, required this.list, required this.last});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final id = z['id'] as int, t = (z['count'] as num?)?.toInt() ?? 1, n = zikrCount(catId, id), done = n >= t;
    final raw = z['text'] as String;
    final (_, text) = _splitQuran(raw);
    var short = text.length > 46 ? '${text.substring(0, 46).trim()} …' : text;
    final src = ((z['source'] as String?) ?? '').split('·').last.trim();
    final srcShort = RegExp(r'^(حصن|رواه|متفق)').hasMatch(src) ? src : ((z['source'] as String?)?.split('·').first.trim() ?? '');
    final fav = zikrIsFav('$catId:$id');
    if (short.isEmpty) short = '…';
    return Container(
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: p.line))),
      child: InkWell(
        onTap: () => pushPage(ZikrPage(catId: catId)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 4, 12),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: p.surf2, shape: BoxShape.circle), child: Text(nf(index), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.on2))),
              const SizedBox(width: 10),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(short, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: quranFont, fontSize: 19, fontWeight: FontWeight.w700, height: 1.6, color: done ? p.on2 : p.on)),
                    Text(srcShort, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.on2)),
                  ]),
                ),
              ),
              if (!done)
                GestureDetector(
                  onTap: () => _bumpIn(catId, list, z, -1),
                  child: Container(width: 44, height: 44, decoration: BoxDecoration(color: p.surf2, shape: BoxShape.circle), child: Icon(Icons.remove, size: 20, color: n > 0 ? p.on2 : p.on2.withValues(alpha: .35))),
                ),
              SizedBox(width: 64, child: Center(child: Text('${nf(n)}/${nf(t)}', style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)))),
              GestureDetector(
                onTap: done ? () => _bumpIn(catId, list, z, -1) : () => _bumpIn(catId, list, z, 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: done ? p.ok : p.pri),
                  child: Icon(done ? Icons.check : Icons.add, color: Colors.white, size: 26),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: p.on2),
                onSelected: (v) {
                  switch (v) {
                    case 'copy': copyText(raw);
                    case 'share': Share.share(text);
                    case 'fav': zikrToggleFav('$catId:$id');
                    case 'open': pushPage(ZikrPage(catId: catId));
                    case 'reset': zikrSet(catId, id, 0);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'open', child: Text('قراءة كاملة')),
                  const PopupMenuItem(value: 'copy', child: Text('نسخ')),
                  const PopupMenuItem(value: 'share', child: Text('مشاركة')),
                  PopupMenuItem(value: 'fav', child: Text(fav ? 'إزالة من المفضلة' : 'إضافة للمفضلة')),
                  const PopupMenuItem(value: 'reset', child: Text('تصفير العدّاد')),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// زر «تشغيل … كاملة»: يفتح قراءة القسم كاملًا؛ وترس الإعدادات يفتح إعدادات الأذكار.
class _PlayAllBar extends StatelessWidget {
  final String label;
  final VoidCallback onPlay, onSettings;
  const _PlayAllBar({required this.label, required this.onPlay, required this.onSettings});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Material(
      color: p.pri,
      elevation: 6,
      shadowColor: p.pri.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 58,
        child: Stack(alignment: Alignment.center, children: [
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () { hap.tick(); onPlay(); },
            child: Center(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow_rounded, color: p.onpri, size: 30),
                  const SizedBox(width: 10),
                  Text(label, style: TextStyle(color: p.onpri, fontSize: 16.5, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
          Positioned(right: 8, child: IconButton(onPressed: () { hap.tick(); onSettings(); }, icon: Icon(Icons.settings_outlined, color: p.onpri), tooltip: 'إعدادات الأذكار')),
        ]),
      ),
    );
  }
}

/// «المزيد من الأذكار»: كل الأقسام عدا الصباح والمساء، بنفس الأسلوب والتقسيمة.
class MoreAzkarPage extends StatefulWidget {
  const MoreAzkarPage({super.key});
  @override
  State<MoreAzkarPage> createState() => _MoreAzkarPageState();
}

class _MoreAzkarPageState extends State<MoreAzkarPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) => FutureBuilder(
        future: data.categories(),
        builder: (context, snap) {
          final cats = (snap.data ?? []).where((c) => !isMainCat(c['id'] as String)).toList();
          final b = bare(q);
          final list = b.isEmpty ? cats : cats.where((c) => bare(catTitle(c)).contains(b)).toList();
          return PageScaffold(
            title: 'المزيد من الأذكار',
            actions: [RoundIconButton(Icons.favorite, () => pushPage(const FavZikrPage()), tooltip: 'المفضلة')],
            children: [
              TextField(decoration: const InputDecoration(hintText: 'ابحث في الأقسام والأذكار...', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => q = v)),
              if (snap.connectionState != ConnectionState.done) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              ...catGrid(list),
              ..._hitWidgets(_textHits(cats, b)),
            ],
          );
        },
      ),
    );
  }
}

const _zsteps = [18, 21, 24, 27, 30, 33, 36, 39, 42];
const _basmala = 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ';

/// يزيل أقواس الحصن «(( ))» من النص.
String _clean(String t) => t.replaceAll('((', '').replaceAll('))', '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// يستخرج نص القرآن من الذكر إن كان آية/سورة: (isQuran، النص المعروض).
(bool, String) _splitQuran(String text) {
  final a = text.indexOf('﴿'), z = text.lastIndexOf('﴾');
  if (a < 0 || z <= a) return (false, _clean(text));
  final pre = bare(text.substring(0, a)).replaceAll('اعوذ بالله من الشيطان الرجيم', '').replaceAll('بسم الله الرحمن الرحيم', '').trim();
  if (pre.isNotEmpty) return (false, _clean(text));
  final inner = text.substring(a + 1, z).replaceAll('*', ' ۝ ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return (true, inner);
}

class ZikrPage extends StatefulWidget {
  final String catId;
  const ZikrPage({super.key, required this.catId});
  @override
  State<ZikrPage> createState() => _ZikrPageState();
}

class _ZikrPageState extends State<ZikrPage> {
  bool hideDone = false;
  final Map<int, GlobalKey> _keys = {};
  List<Map<String, dynamic>> _list = [];

  GlobalKey _k(int id) => _keys.putIfAbsent(id, () => GlobalKey());
  int _target(Map<String, dynamic> z) => (z['count'] as num?)?.toInt() ?? 1;
  bool _isDone(Map<String, dynamic> z) => zikrCount(widget.catId, z['id'] as int) >= _target(z);

  void bump(Map<String, dynamic> z, int delta) {
    final id = z['id'] as int, t = _target(z), n0 = zikrCount(widget.catId, id);
    if (delta > 0 && n0 >= t) { hap.error(); return; }
    if (delta < 0 && n0 <= 0) return;
    final wasAll = _list.isNotEmpty && _list.every(_isDone);
    zikrSet(widget.catId, id, n0 + delta);
    touchActivity();
    final done = zikrCount(widget.catId, id) >= t;
    if (delta > 0) {
      done ? hap.success() : hap.click();
      if (done) {
        chalCheck();
        final allNow = _list.every(_isDone);
        if (allNow && !wasAll) {
          zikrCatCompleted(widget.catId);
          if (doneSoundOn()) SystemSound.play(SystemSoundType.alert);
          toast('أتممت الورد، تقبّل الله منك 🤍');
        } else if (autoNextOn()) {
          _goNext(id);
        }
      }
    } else {
      hap.tick();
    }
  }

  /// بعد اكتمال عدّاد ذكر ينتقل التمرير تلقائيًا إلى الذكر غير المكتمل التالي.
  void _goNext(int fromId) {
    final i = _list.indexWhere((x) => x['id'] == fromId);
    Map<String, dynamic>? nx;
    for (var j = i + 1; j < _list.length; j++) {
      if (!_isDone(_list[j])) { nx = _list[j]; break; }
    }
    nx ??= _list.where((x) => !_isDone(x)).firstOrNull;
    if (nx == null) return;
    final id = nx['id'] as int;
    Future.delayed(const Duration(milliseconds: 380), () {
      final c = _keys[id]?.currentContext;
      if (c != null && mounted) Scrollable.ensureVisible(c, alignment: .04, duration: const Duration(milliseconds: 520), curve: Curves.easeInOutCubic);
    });
  }

  Future<void> fontSheet() async {
    await showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          final cur = _zsteps.reduce((a, b) => ((b - (cfg.get('zfs') as num)).abs() < (a - (cfg.get('zfs') as num)).abs()) ? b : a);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('حجم الخط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Padding(padding: const EdgeInsets.all(16), child: Text('بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ', style: TextStyle(fontFamily: quranFont, fontSize: cur.toDouble()))),
            Row(children: [
              const Text('أ', style: TextStyle(fontSize: 15)),
              Expanded(child: Slider(value: _zsteps.indexOf(cur).toDouble(), min: 0, max: 8, divisions: 8, onChanged: (v) { hap.tick(); cfg.set('zfs', _zsteps[v.round()]); set(() {}); })),
              const Text('أ', style: TextStyle(fontSize: 26)),
            ]),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('الانتقال التلقائي للذكر التالي'), subtitle: const Sub('فور إكمال العدد المطلوب'), value: autoNextOn(), onChanged: (v) { cfg.set('autoNext', v); set(() {}); }),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('إخفاء الأذكار المكتملة'), value: hideDone, onChanged: (v) { setState(() => hideDone = v); set(() {}); }),
          ]);
        }));
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) => FutureBuilder(
        future: data.categories(),
        builder: (context, snap) {
          final p = Pal.of(context);
          final c = snap.data?.where((x) => x['id'] == widget.catId).firstOrNull;
          if (c == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          _list = (c['azkar'] as List).cast<Map<String, dynamic>>();
          final fs = ((cfg.get('zfs') as num?) ?? 28).toDouble();
          final done = _list.where(_isDone).length;
          final shown = hideDone ? _list.where((z) => !_isDone(z)).toList() : _list;
          final mq = MediaQuery.of(context);
          return Scaffold(
            backgroundColor: p.bg,
            body: Column(children: [
              SkylineHeader(
                height: mq.padding.top + 84,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, mq.padding.top + 10, 12, 8),
                  child: Row(children: [
                    const SizedBox(width: 4),
                    Expanded(child: Text(catTitle(c), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    RoundIconButton(Icons.refresh, () async {
                      if (await confirmDialog(context, 'إعادة تعيين العداد؟', 'سيتم تصفير تقدّمك في هذا القسم.', ok: 'إعادة', danger: true)) zikrResetCat(widget.catId);
                    }, tooltip: 'إعادة', light: true),
                    RoundIconButton(Icons.star, () => pushPage(const FavZikrPage()), tooltip: 'المفضلة', light: true),
                    RoundIconButton(Icons.text_fields, fontSheet, tooltip: 'الخط', light: true),
                    RoundIconButton(Icons.arrow_forward, () => Navigator.of(context).maybePop(), tooltip: 'رجوع', light: true),
                  ]),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, mq.padding.bottom + 110),
                  physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  children: [
                    Row(children: [
                      Icon(Icons.history, size: 20, color: p.on2),
                      const SizedBox(width: 6),
                      Text('عدد مرات القراءة: ${nf(zikrReads(widget.catId))}', style: TextStyle(color: p.on2, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${nf(done)} / ${nf(_list.length)}', style: TextStyle(color: p.pri, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    Bar(_list.isEmpty ? 0 : done / _list.length),
                    if (shown.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Sub('كل أذكار هذا القسم مكتملة', align: TextAlign.center)),
                    for (final z in shown)
                      KeyedSubtree(
                        key: _k(z['id'] as int),
                        child: _ZikrCard(z: z, catId: widget.catId, fs: fs, p: p, onTap: () => bump(z, 1), onUndo: () => bump(z, -1)),
                      ),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _ZikrCard extends StatelessWidget {
  final Map<String, dynamic> z;
  final String catId;
  final double fs;
  final Pal p;
  final VoidCallback onTap, onUndo;
  const _ZikrCard({required this.z, required this.catId, required this.fs, required this.p, required this.onTap, required this.onUndo});
  @override
  Widget build(BuildContext context) {
    final id = z['id'] as int, t = (z['count'] as num?)?.toInt() ?? 1, n = zikrCount(catId, id), done = n >= t;
    final fav = zikrIsFav('$catId:$id');
    final raw = z['text'] as String;
    final (isQ, text) = _splitQuran(raw);
    final fadl = zikrFadl(catId, id);
    final src = (z['source'] as String?) ?? '';
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: done ? .62 : 1,
      child: AppCard(
        margin: const EdgeInsets.only(top: 14),
        radius: 30,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        onTap: onTap,
        color: done ? p.pc : p.surf,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (isQ) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(_basmala, textAlign: TextAlign.center, style: TextStyle(fontFamily: quranFont, fontSize: fs * .78, fontWeight: FontWeight.w700, color: p.gold, height: 1.8))),
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontFamily: quranFont, fontSize: fs, height: 2.1, color: p.on)),
          if (fadl != null)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: p.pc.withValues(alpha: .7), borderRadius: BorderRadius.circular(20)),
              child: Text(fadl, style: TextStyle(fontSize: 14.5, height: 1.8, color: p.on2)),
            ),
          if (src.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                Icon(Icons.menu_book, size: 17, color: p.on2.withValues(alpha: .7)),
                const SizedBox(width: 6),
                Expanded(child: Text(src, style: TextStyle(fontSize: 12.5, color: p.on2.withValues(alpha: .85)))),
              ]),
            ),
          const SizedBox(height: 12),
          Row(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Container(
                key: ValueKey('$n/$t'),
                width: 58, height: 58, alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: done ? p.pri : p.surf2),
                child: done ? Icon(Icons.check, color: p.onpri, size: 28) : Text(nf(t - n), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: p.pri)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(t == 1 ? 'يُقال مرة واحدة' : t == 2 ? 'يُقال مرتين' : 'يُقال ${nf(t)} مرات', style: TextStyle(color: p.on2, fontSize: 14.5))),
            IconButton(visualDensity: VisualDensity.compact, onPressed: n > 0 ? onUndo : null, icon: Icon(Icons.undo, color: p.on2, size: 20)),
            IconButton(visualDensity: VisualDensity.compact, onPressed: () => copyText(raw), icon: Icon(Icons.copy, color: p.on2, size: 19)),
            IconButton(visualDensity: VisualDensity.compact, onPressed: () { hap.click(); Share.share(text); }, icon: Icon(Icons.share, color: p.on2, size: 19)),
            IconButton(visualDensity: VisualDensity.compact, onPressed: () { zikrToggleFav('$catId:$id'); hap.click(); }, icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: p.pri, size: 21)),
          ]),
        ]),
      ),
    );
  }
}

class FavZikrPage extends StatelessWidget {
  const FavZikrPage({super.key});
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) => FutureBuilder(
        future: data.categories(),
        builder: (context, snap) {
          final cats = snap.data ?? [];
          final favs = ((azkarState()['fav'] as List?) ?? []).cast<String>();
          final rows = <(Map<String, dynamic>, Map<String, dynamic>)>[];
          for (final k in favs) {
            final parts = k.split(':');
            final c = cats.where((x) => x['id'] == parts[0]).firstOrNull;
            final z = c == null ? null : (c['azkar'] as List).cast<Map<String, dynamic>>().where((x) => '${x['id']}' == parts[1]).firstOrNull;
            if (c != null && z != null) rows.add((c, z));
          }
          return PageScaffold(title: 'أذكارك المفضلة', children: [
            if (rows.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Sub('لا يوجد أذكار مفضلة بعد\nاضغط على القلب في أي ذكر لإضافته هنا', align: TextAlign.center)),
            for (final r in rows)
              AppCard(margin: const EdgeInsets.only(top: 10), radius: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_splitQuran(r.$2['text'] as String).$2, textAlign: TextAlign.center, style: const TextStyle(fontFamily: quranFont, fontSize: 22, height: 2)),
                const SizedBox(height: 4),
                Sub(catTitle(r.$1)),
              ])),
          ]);
        },
      ),
    );
  }
}
