import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

Future<dynamic> _json(String path) async => jsonDecode(await rootBundle.loadString(path));

// ======================= المكتبة (كتب إسلامية) =======================
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String cat = 'all', q = '';
  int limit = 40;
  late final Future<dynamic> _f = _json('assets/data/library.json');

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) toast('تعذّر فتح الرابط');
  }

  void _sheet(List b) {
    final p = Pal.of(context);
    final files = (b[5] as List).cast<List>();
    showAppSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(b[1] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.4)),
          Text(b[2] as String, style: TextStyle(color: p.on2, fontSize: 13)),
          const SizedBox(height: 10),
          Text(b[4] as String, style: const TextStyle(fontSize: 13.5, height: 1.8)),
          const SizedBox(height: 14),
          for (final f in files)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                onPressed: () { Navigator.pop(ctx); _open(f[0] as String); },
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                label: Text(files.length > 1 ? (((f.length > 2 ? f[2] : '') as String).isNotEmpty ? f[2] as String : 'فتح الملف') : 'فتح الكتاب (PDF)'),
              ),
            ),
          OutlinedButton.icon(onPressed: () { Share.share('${b[1]}\n${files.first[0]}'); }, icon: const Icon(Icons.share_outlined, size: 18), label: const Text('مشاركة')),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return FutureBuilder<dynamic>(
      future: _f,
      builder: (context, s) {
        final d = s.data as Map<String, dynamic>?;
        final cats = ((d?['cats'] as List?) ?? []).cast<List>();
        final books = ((d?['b'] as List?) ?? []).cast<List>();
        final b = bare(q);
        final list = [for (final x in books) if ((cat == 'all' || x[3] == cat) && (b.isEmpty || bare(x[1] as String).contains(b) || bare(x[2] as String).contains(b))) x];
        final shown = list.take(limit).toList();
        return PageScaffold(
          title: 'المكتبة',
          subtitle: '${nf(books.length)} كتابًا من IslamHouse',
          children: [
            TextField(decoration: const InputDecoration(hintText: 'ابحث بعنوان الكتاب أو المؤلف', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() { q = v; limit = 40; })),
            const SizedBox(height: 10),
            if (d == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            ChipRow(items: [('all', 'الكل'), for (final c in cats) (c[0] as String, c[1] as String)], selected: cat, onSelect: (v) => setState(() { cat = v; limit = 40; })),
            for (final x in shown)
              AppCard(
                margin: const EdgeInsets.only(top: 8),
                radius: 16,
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                onTap: () => _sheet(x),
                child: Row(children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(11)), child: Icon(Icons.local_library_outlined, size: 20, color: p.pri)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(x[1] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.35)),
                    Text(x[2] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: p.on2)),
                  ])),
                  Icon(Icons.chevron_left, color: p.on2, size: 20),
                ]),
              ),
            if (shown.length < list.length) Center(child: TextButton(onPressed: () => setState(() => limit += 40), child: const Text('عرض المزيد'))),
            if (d != null && list.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Sub('لا نتائج', align: TextAlign.center)),
          ],
        );
      },
    );
  }
}

// ======================= قصص الأنبياء =======================
class AnbiyaPage extends StatelessWidget {
  const AnbiyaPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return FutureBuilder<dynamic>(
      future: _json('assets/data/anbiya.json'),
      builder: (context, s) {
        final list = ((s.data as List?) ?? []).cast<Map<String, dynamic>>();
        return PageScaffold(
          title: 'قصص الأنبياء',
          subtitle: 'من القرآن والسنة الصحيحة دون إسرائيليات',
          children: [
            if (s.data == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            for (final n in list)
              AppCard(
                margin: const EdgeInsets.only(top: 8),
                radius: 16,
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                onTap: () => pushPage(_StoryPage(story: n)),
                child: Row(children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(11)), child: Icon(Icons.history_edu_rounded, size: 20, color: p.pri)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['name'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text((n['sub'] as String?) ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: p.on2)),
                  ])),
                  Icon(Icons.chevron_left, color: p.on2, size: 20),
                ]),
              ),
          ],
        );
      },
    );
  }
}

class _StoryPage extends StatelessWidget {
  final Map<String, dynamic> story;
  const _StoryPage({required this.story});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final body = ((story['body'] as List?) ?? []).cast<String>();
    final lessons = ((story['lessons'] as List?) ?? []).cast<String>();
    final refs = ((story['refs'] as List?) ?? []).map((e) => '$e').toList();
    return PageScaffold(
      title: story['name'] as String,
      subtitle: story['sub'] as String?,
      children: [
        for (final t in body)
          t.startsWith('﴿')
              ? Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: p.pc.withValues(alpha: .6), borderRadius: BorderRadius.circular(14)),
                  child: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontFamily: quranFont, fontSize: 20, height: 2)),
                )
              : Padding(padding: const EdgeInsets.only(top: 10), child: Text(t, style: const TextStyle(fontSize: 15, height: 1.9))),
        if (lessons.isNotEmpty) ...[
          const GoldTitle('من الدروس والعبر'),
          for (final l in lessons) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle_outline, size: 18, color: p.pri), const SizedBox(width: 8), Expanded(child: Text(l, style: const TextStyle(fontSize: 14, height: 1.7)))])),
        ],
        if (refs.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Sub('المراجع: ${refs.join('، ')}')),
      ],
    );
  }
}

// ======================= الحديث =======================
const _books = [
  ('bukhari', 'صحيح البخاري', 'الإمام محمد بن إسماعيل البخاري', true),
  ('muslim', 'صحيح مسلم', 'الإمام مسلم بن الحجاج', true),
  ('nawawi', 'الأربعون النووية', 'الإمام النووي', false),
  ('riyad', 'رياض الصالحين', 'الإمام النووي', false),
];

class HadithPage extends StatelessWidget {
  const HadithPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return PageScaffold(
      title: 'الحديث',
      subtitle: 'كتب الحديث دون إنترنت',
      actions: [RoundIconButton(Icons.star_outline_rounded, () => pushPage(const _HadithFavPage()), light: true, tooltip: 'المحفوظات')],
      children: [
        for (final b in _books)
          AppCard(
            margin: const EdgeInsets.only(top: 10),
            radius: 18,
            padding: const EdgeInsets.all(12),
            onTap: () => pushPage(_BookPage(id: b.$1, name: b.$2, split: b.$4)),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.import_contacts_rounded, size: 22, color: p.pri)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                Text(b.$3, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.on2)),
              ])),
              Icon(Icons.chevron_left, color: p.on2),
            ]),
          ),
      ],
    );
  }
}

List<String> _hfav() => [for (final x in (store.peek('hadithFav', []) as List?) ?? const []) '$x'];
void _toggleFav(String k) {
  final f = _hfav();
  f.contains(k) ? f.remove(k) : f.insert(0, k);
  store.set('hadithFav', f);
}

class _BookPage extends StatefulWidget {
  final String id, name;
  final bool split;
  const _BookPage({required this.id, required this.name, required this.split});
  @override
  State<_BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<_BookPage> {
  Map<String, dynamic>? idx;
  int? ch;
  List hadiths = [];
  int limit = 30;
  String q = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _json(widget.split ? 'assets/hadith/${widget.id}/index.json' : 'assets/hadith/${widget.id}.json').then((d) {
      if (!mounted) return;
      final m = d as Map<String, dynamic>;
      setState(() => idx = m);
      final c = (m['c'] as List).cast<List>();
      if (c.length == 1) _openChapter((c.first[0] as num).toInt());
    });
  }

  Future<void> _openChapter(int c) async {
    setState(() { ch = c; loading = true; limit = 30; });
    List l;
    if (widget.split) {
      final a = await _json('assets/hadith/${widget.id}/$c.json') as List;
      l = [for (final x in a) [x[0], c, x[1]]];
    } else {
      l = [for (final h in (idx!['h'] as List)) if ((h as List)[1] == c) h];
    }
    if (mounted) setState(() { hadiths = l; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final chapters = ((idx?['c'] as List?) ?? []).cast<List>();
    if (ch == null) {
      return PageScaffold(
        title: widget.name,
        subtitle: (idx?['a'] as String?),
        children: [
          if (idx == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          for (final c in chapters)
            AppCard(
              margin: const EdgeInsets.only(top: 8),
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onTap: () => _openChapter((c[0] as num).toInt()),
              child: Row(children: [
                Expanded(child: Text(c[1] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4))),
                if (c.length > 2) Text(nf(c[2]), style: TextStyle(fontSize: 12, color: p.on2)),
                Icon(Icons.chevron_left, color: p.on2, size: 20),
              ]),
            ),
        ],
      );
    }
    final b = bare(q);
    final list = b.isEmpty ? hadiths : hadiths.where((h) => bare((h as List)[2] as String).contains(b)).toList();
    final shown = list.take(limit).toList();
    final title = chapters.where((c) => c[0] == ch).map((c) => c[1] as String).firstOrNull ?? widget.name;
    return StoreBuilder(builder: (context, _) => PageScaffold(
      title: title,
      subtitle: widget.name,
      children: [
        TextField(decoration: const InputDecoration(hintText: 'ابحث داخل هذا الباب', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() { q = v; limit = 30; })),
        if (loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
        for (final h in shown) _HadithCard(book: widget.id, bookName: widget.name, h: h as List, split: widget.split),
        if (shown.length < list.length) Center(child: TextButton(onPressed: () => setState(() => limit += 30), child: const Text('عرض المزيد'))),
      ],
    ));
  }
}

class _HadithCard extends StatelessWidget {
  final String book, bookName;
  final List h;
  final bool split;
  const _HadithCard({required this.book, required this.bookName, required this.h, required this.split});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final k = '$book:${h[0]}${split ? ':${h[1]}' : ''}';
    final fav = _hfav().contains(k);
    final text = h[2] as String;
    return AppCard(
      margin: const EdgeInsets.only(top: 10),
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(10)), child: Text(nf(h[0]), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.pri))),
          const SizedBox(width: 8),
          Text(bookName, style: TextStyle(fontSize: 11.5, color: p.on2)),
        ]),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontFamily: arabicFont, fontSize: 18, height: 2)),
        Row(children: [
          IconButton(visualDensity: VisualDensity.compact, onPressed: () { hap.tick(); _toggleFav(k); }, icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded, size: 21, color: fav ? p.gold : p.on2)),
          IconButton(visualDensity: VisualDensity.compact, onPressed: () => copyText('$text\n\n— $bookName، رقم ${h[0]}'), icon: Icon(Icons.copy_outlined, size: 18, color: p.on2)),
          IconButton(visualDensity: VisualDensity.compact, onPressed: () { hap.click(); Share.share('$text\n\n— $bookName، رقم ${h[0]}'); }, icon: Icon(Icons.share_outlined, size: 18, color: p.on2)),
        ]),
      ]),
    );
  }
}

class _HadithFavPage extends StatelessWidget {
  const _HadithFavPage();
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, _) {
        final favs = _hfav();
        return PageScaffold(
          title: 'المحفوظات',
          subtitle: 'أحاديث حفظتها',
          children: [
            if (favs.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Sub('لم تحفظ أحاديث بعد\nاضغط النجمة على أي حديث', align: TextAlign.center)),
            for (final k in favs) _FavItem(k: k),
          ],
        );
      },
    );
  }
}

class _FavItem extends StatelessWidget {
  final String k;
  const _FavItem({required this.k});
  Future<List?> _load() async {
    final x = k.split(':');
    final book = x[0], n = int.tryParse(x[1]) ?? 0;
    final b = _books.firstWhere((e) => e.$1 == book);
    if (b.$4) {
      final ch = int.tryParse(x.length > 2 ? x[2] : '') ?? 0;
      final a = await _json('assets/hadith/$book/$ch.json') as List;
      final h = a.cast<List>().where((e) => e[0] == n).firstOrNull;
      return h == null ? null : [b.$2, h[0], ch, h[1], true];
    }
    final d = await _json('assets/hadith/$book.json') as Map<String, dynamic>;
    final h = (d['h'] as List).cast<List>().where((e) => e[0] == n).firstOrNull;
    return h == null ? null : [b.$2, h[0], h[1], h[2], false];
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List?>(
        future: _load(),
        builder: (context, s) {
          final r = s.data;
          if (r == null) return const SizedBox.shrink();
          return _HadithCard(book: k.split(':')[0], bookName: r[0] as String, h: [r[1], r[2], r[3]], split: r[4] as bool);
        },
      );
}
