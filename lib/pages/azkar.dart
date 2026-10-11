import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/azkar.dart';
import '../core/challenges.dart';
import '../core/data.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

IconData _catIcon(String? i) => switch (i) {
      'wb_sunny' => Icons.wb_sunny,
      'nightlight_round' || 'bedtime' => Icons.nightlight_round,
      'mosque' => Icons.mosque,
      'water_drop' => Icons.water_drop,
      'home' => Icons.home,
      'flight' => Icons.place,
      _ => Icons.auto_awesome,
    };

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});
  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(tab: 2,
      builder: (context, _) => FutureBuilder(
        future: data.categories(),
        builder: (context, snap) {
          final cats = snap.data ?? [];
          final hour = DateTime.now().hour;
          final hid = hour >= 15 || hour < 3 ? 'hisn-27e' : 'hisn-27';
          final hc = cats.where((c) => c['id'] == hid).firstOrNull;
          final b = bare(q);
          final list = b.isEmpty ? cats : cats.where((c) => bare(c['title'] as String).contains(b)).toList();
          final hits = <(Map<String, dynamic>, Map<String, dynamic>)>[];
          if (b.length > 2) {
            for (final c in cats) {
              for (final z in (c['azkar'] as List).cast<Map<String, dynamic>>()) {
                if (hits.length < 25 && bare(z['text'] as String).contains(b)) hits.add((c, z));
              }
            }
          }
          return PageScaffold(
            title: 'الأذكار',
            back: false,
            actions: [RoundIconButton(Icons.favorite, () => pushPage(const FavZikrPage()), tooltip: 'المفضلة')],
            children: [
              if (hc != null)
                FutureBuilder(
                  future: azkarProgress(hid),
                  builder: (_, pr) => HeroCard(
                    onTap: () => pushPage(ZikrPage(catId: hid)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(hid == 'hisn-27e' ? Icons.nightlight_round : Icons.wb_sunny),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${nf((hc['azkar'] as List).length)} من الأذكار', style: const TextStyle(color: Colors.white70)),
                          Text(hc['title'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      Bar(pr.data == null || pr.data!.total == 0 ? 0 : pr.data!.done / pr.data!.total, color: Colors.white, track: Colors.white24),
                    ]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: TextField(decoration: const InputDecoration(hintText: 'ابحث عن ذكر أو دعاء...', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => q = v)),
              ),
              for (final c in list)
                ItemTile(icon: _catIcon(c['icon'] as String?), title: c['title'] as String, sub: '${nf((c['azkar'] as List).length)} ${(c['azkar'] as List).length == 1 ? 'ذكر' : 'أذكار'}', onTap: () => pushPage(ZikrPage(catId: c['id'] as String))),
              if (hits.isNotEmpty) const SectionTitle('في كل الأذكار'),
              for (final h in hits)
                AppCard(margin: const EdgeInsets.only(top: 10), radius: 22, onTap: () => pushPage(ZikrPage(catId: h.$1['id'] as String)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((h.$2['text'] as String).length > 120 ? '${(h.$2['text'] as String).substring(0, 120)}…' : h.$2['text'] as String, style: const TextStyle(fontFamily: arabicFont, fontSize: 17, height: 1.9)),
                  Sub(h.$1['title'] as String),
                ])),
            ],
          );
        },
      ),
    );
  }
}

const _zsteps = [18, 21, 24, 27, 30, 33, 36, 39, 42];

class ZikrPage extends StatefulWidget {
  final String catId;
  const ZikrPage({super.key, required this.catId});
  @override
  State<ZikrPage> createState() => _ZikrPageState();
}

class _ZikrPageState extends State<ZikrPage> {
  bool hideDone = false;

  void bump(Map<String, dynamic> z, int delta) {
    final id = z['id'] as int, t = (z['count'] as num?)?.toInt() ?? 1, n0 = zikrCount(widget.catId, id);
    if (delta > 0 && n0 >= t) { hap.error(); return; }
    if (delta < 0 && n0 <= 0) return;
    zikrSet(widget.catId, id, n0 + delta);
    touchActivity();
    final done = zikrCount(widget.catId, id) >= t;
    if (delta > 0) {
      done ? hap.success() : hap.click();
      if (done) chalCheck();
    } else {
      hap.tick();
    }
  }

  Future<void> fontSheet() async {
    await showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          final cur = _zsteps.reduce((a, b) => ((b - (cfg.get('zfs') as num)).abs() < (a - (cfg.get('zfs') as num)).abs()) ? b : a);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('حجم الخط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Padding(padding: const EdgeInsets.all(16), child: Text('بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ', style: TextStyle(fontFamily: arabicFont, fontSize: cur.toDouble()))),
            Row(children: [
              const Text('أ', style: TextStyle(fontSize: 15)),
              Expanded(child: Slider(value: _zsteps.indexOf(cur).toDouble(), min: 0, max: 8, divisions: 8, onChanged: (v) { hap.tick(); cfg.set('zfs', _zsteps[v.round()]); set(() {}); })),
              const Text('أ', style: TextStyle(fontSize: 26)),
            ]),
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
          final list = (c['azkar'] as List).cast<Map<String, dynamic>>();
          final fs = ((cfg.get('zfs') as num?) ?? 28).toDouble();
          final done = list.where((z) => zikrCount(widget.catId, z['id'] as int) >= ((z['count'] as num?)?.toInt() ?? 1)).length;
          final shown = hideDone ? list.where((z) => zikrCount(widget.catId, z['id'] as int) < ((z['count'] as num?)?.toInt() ?? 1)).toList() : list;
          return PageScaffold(
            title: c['title'] as String,
            actions: [
              RoundIconButton(Icons.text_fields, fontSheet, tooltip: 'حجم الخط'),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) async {
                  if (v == 0) setState(() => hideDone = !hideDone);
                  if (v == 1 && await confirmDialog(context, 'إعادة تعيين العداد؟', 'سيتم تصفير تقدّمك في هذا القسم.', ok: 'إعادة', danger: true)) zikrResetCat(widget.catId);
                },
                itemBuilder: (_) => [PopupMenuItem(value: 0, child: Text(hideDone ? 'إظهار المكتملة' : 'إخفاء المكتملة')), const PopupMenuItem(value: 1, child: Text('إعادة تعيين العداد'))],
              ),
            ],
            children: [
              AppCard(margin: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Bar(list.isEmpty ? 0 : done / list.length), const SizedBox(height: 8), Sub('أنجزت ${nf(done)} من ${nf(list.length)}')])),
              const Padding(padding: EdgeInsets.only(top: 10), child: Sub('اضغط على الذكر نفسه لإنقاص العدّاد', align: TextAlign.center)),
              if (shown.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Sub('كل أذكار هذا القسم مكتملة', align: TextAlign.center)),
              for (final z in shown)
                _ZikrCard(
                  z: z, catId: widget.catId, fs: fs, p: p,
                  onTap: () => bump(z, 1),
                  onUndo: () => bump(z, -1),
                ),
            ],
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
    final text = z['text'] as String;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: done ? .6 : 1,
      child: AppCard(
        margin: const EdgeInsets.only(top: 10),
        onTap: onTap,
        color: done ? p.pc : p.surf,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: TextStyle(fontFamily: arabicFont, fontSize: fs, height: 2)),
          if ((z['source'] as String?)?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 6), child: Sub(z['source'] as String)),
          const SizedBox(height: 6),
          Row(children: [
            IconButton(onPressed: () => copyText(text), icon: Icon(Icons.copy, color: p.on2, size: 20)),
            IconButton(onPressed: () { hap.click(); Share.share(text); }, icon: Icon(Icons.share, color: p.on2, size: 20)),
            const Spacer(),
            IconButton(onPressed: n > 0 ? onUndo : null, icon: Icon(Icons.undo, color: p.on2, size: 20)),
            IconButton(onPressed: () { zikrToggleFav('$catId:$id'); hap.click(); }, icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: p.pri, size: 22)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Container(
                key: ValueKey('$n/$t'),
                width: 52, height: 52, alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: done ? p.pri : p.pc),
                child: done ? Icon(Icons.check, color: p.onpri) : Text(nf(t - n), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: p.pri)),
              ),
            ),
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
              AppCard(margin: const EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.$2['text'] as String, style: const TextStyle(fontFamily: arabicFont, fontSize: 22, height: 2)),
                Sub(r.$1['title'] as String),
              ])),
          ]);
        },
      ),
    );
  }
}
