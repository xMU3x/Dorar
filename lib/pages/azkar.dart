import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/azkar.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/store.dart';
import '../core/util.dart';
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

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});
  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      tab: 2,
      builder: (context, _) => FutureBuilder(
        future: data.categories(),
        builder: (context, snap) {
          final cats = snap.data ?? [];
          final p = Pal.of(context);
          final b = bare(q);
          final morning = cats.where((c) => c['id'] == kMorningCat).firstOrNull;
          final evening = cats.where((c) => c['id'] == kEveningCat).firstOrNull;
          final found = b.isEmpty ? <Map<String, dynamic>>[] : cats.where((c) => bare(catTitle(c)).contains(b)).toList();
          final others = cats.where((c) => !isMainCat(c['id'] as String)).length;
          return PageScaffold(
            title: 'الأذكار',
            back: false,
            actions: [RoundIconButton(Icons.favorite, () => pushPage(const FavZikrPage()), tooltip: 'المفضلة')],
            children: [
              TextField(decoration: const InputDecoration(hintText: 'ابحث عن ذكر أو دعاء...', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => q = v)),
              if (b.isEmpty) ...[
                const GoldTitle('أذكار اليوم', sub: 'اضغط على الذكر ليكتمل العدّاد وينتقل للتالي'),
                Row(children: [
                  Expanded(child: morning == null ? const SizedBox.shrink() : CatSquare(morning)),
                  const SizedBox(width: 12),
                  Expanded(child: evening == null ? const SizedBox.shrink() : CatSquare(evening)),
                ]),
                AppCard(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  radius: 22,
                  onTap: () => pushPage(const MoreAzkarPage()),
                  child: Row(children: [
                    const IconBox(Icons.grid_view_rounded, size: 46),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('المزيد من الأذكار', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Sub('${nf(others)} قسمًا: النوم والاستيقاظ والصلاة والسفر والدعاء وغيرها'),
                    ])),
                    Icon(Icons.chevron_left, color: p.on2),
                  ]),
                ),
              ] else ...[
                ...catGrid(found),
                ..._hitWidgets(_textHits(cats, b)),
                if (found.isEmpty && _textHits(cats, b).isEmpty) const Padding(padding: EdgeInsets.all(40), child: Sub('لا نتائج', align: TextAlign.center)),
              ],
            ],
          );
        },
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
          Widget hb(IconData i, VoidCallback f, String tip) => Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Material(
                  color: p.surf, shape: CircleBorder(side: BorderSide(color: p.line)),
                  child: InkWell(customBorder: const CircleBorder(), onTap: () { hap.tick(); f(); }, child: Tooltip(message: tip, child: SizedBox(width: 42, height: 42, child: Icon(i, size: 21, color: p.on)))),
                ),
              );
          return Scaffold(
            backgroundColor: p.bg,
            body: Column(children: [
              Container(
                padding: EdgeInsets.fromLTRB(12, mq.padding.top + 8, 12, 10),
                decoration: BoxDecoration(color: p.bg, border: Border(bottom: BorderSide(color: p.line, width: 2))),
                child: Row(children: [
                  hb(Icons.arrow_forward, () => Navigator.of(context).maybePop(), 'رجوع'),
                  Expanded(child: Text(catTitle(c), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
                  hb(Icons.text_fields, fontSheet, 'الخط'),
                  hb(Icons.star, () => pushPage(const FavZikrPage()), 'المفضلة'),
                  hb(Icons.refresh, () async {
                    if (await confirmDialog(context, 'إعادة تعيين العداد؟', 'سيتم تصفير تقدّمك في هذا القسم.', ok: 'إعادة', danger: true)) zikrResetCat(widget.catId);
                  }, 'إعادة'),
                ]),
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
