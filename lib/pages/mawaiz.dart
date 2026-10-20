import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import '../core/data.dart';
import '../core/player.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

// ======================= المواعظ المسموعة (محاضرات وخطب) من مصدر نور =======================
Future<Map<String, dynamic>>? _lecF;
Future<Map<String, dynamic>> _lectures() => _lecF ??= rootBundle.loadString('assets/data/lectures.json').then((s) => jsonDecode(s) as Map<String, dynamic>);

String _dur(num s) {
  final m = (s / 60).round();
  return m >= 60 ? '${nf(m ~/ 60)} س ${nf(m % 60)} د' : '${nf(m)} د';
}

String _initials(String name) {
  final w = name.split(' ').last.replaceFirst(RegExp('^ال'), '');
  return w.isEmpty ? 'م' : String.fromCharCode(w.runes.first);
}

Future<void> _playLecture(Map<String, dynamic> sp, List items, int i) {
  final tracks = <Track>[];
  var start = 0;
  for (var k = 0; k < items.length; k++) {
    final it = items[k] as Map<String, dynamic>;
    final urls = (it['u'] as List).cast<String>();
    if (k == i) start = tracks.length;
    for (var u = 0; u < urls.length; u++) {
      tracks.add(Track(urls.length > 1 ? '${it['t']} (${u + 1})' : it['t'] as String, sp['name'] as String, urls[u], lecture: true, extra: 'مواعظ'));
    }
  }
  return player.play(tracks, start);
}

class MawaizPage extends StatefulWidget {
  const MawaizPage({super.key});
  @override
  State<MawaizPage> createState() => _MawaizPageState();
}

class _MawaizPageState extends State<MawaizPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _lectures(),
      builder: (context, s) {
        final d = s.data;
        final speakers = ((d?['speakers'] as List?) ?? []).cast<Map<String, dynamic>>();
        final groups = ((d?['groups'] as List?) ?? []).cast<Map<String, dynamic>>();
        final items = (d?['items'] as Map?)?.cast<String, dynamic>() ?? {};
        final total = speakers.fold<int>(0, (a, x) => a + ((x['count'] as num?)?.toInt() ?? 0));
        final b = bare(q);
        final hits = <(Map<String, dynamic>, int, Map<String, dynamic>)>[];
        if (b.length >= 2) {
          for (final sp in speakers) {
            final l = (items[sp['id']] as List?) ?? [];
            for (var i = 0; i < l.length && hits.length < 80; i++) {
              if (bare((l[i] as Map)['t'] as String).contains(b)) hits.add((sp, i, (l[i] as Map).cast<String, dynamic>()));
            }
          }
        }
        return PageScaffold(
          title: 'المواعظ',
          subtitle: 'محاضرات وخطب وعظية مسموعة',
          children: [
            TextField(decoration: InputDecoration(hintText: 'ابحث في ${nf(total)} محاضرة وخطبة', prefixIcon: const Icon(Icons.search)), onChanged: (v) => setState(() => q = v)),
            if (d == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            if (b.length >= 2) ...[
              const SectionTitle('النتائج'),
              if (hits.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Sub('لا توجد نتائج', align: TextAlign.center)),
              for (final h in hits)
                ItemTile(icon: Icons.play_arrow_rounded, title: h.$3['t'] as String, sub: '${h.$1['name']}${h.$3['d'] != null ? ' · ${_dur(h.$3['d'] as num)}' : ''}', onTap: () => _playLecture(h.$1, (items[h.$1['id']] as List), h.$2)),
            ] else
              for (final g in groups) ...[
                GoldTitle(g['name'] as String),
                for (final sp in speakers.where((x) => x['group'] == g['id']))
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onTap: () => pushPage(SpeakerPage(speaker: sp, items: (items[sp['id']] as List?) ?? [])),
                    child: Row(children: [
                      Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Text(_initials(sp['name'] as String), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.pri))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${['mawaiz', 'ulama', 'duroos'].contains(g['id']) ? 'الشيخ ' : ''}${sp['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        Text('${nf(sp['count'])} ${g['id'] == 'haram' ? 'خطبة' : 'مادة صوتية'}', style: TextStyle(fontSize: 11.5, color: p.on2)),
                      ])),
                      Icon(Icons.chevron_left, color: p.on2),
                    ]),
                  ),
              ],
            const Padding(padding: EdgeInsets.fromLTRB(4, 14, 4, 0), child: Sub('المحاضرات من IslamHouse (دار الإسلام) ومواعظ المشايخ من أرشيف الإنترنت.')),
          ],
        );
      },
    );
  }
}

class SpeakerPage extends StatefulWidget {
  final Map<String, dynamic> speaker;
  final List items;
  const SpeakerPage({super.key, required this.speaker, required this.items});
  @override
  State<SpeakerPage> createState() => _SpeakerPageState();
}

class _SpeakerPageState extends State<SpeakerPage> {
  String q = '';
  int limit = 60;
  @override
  Widget build(BuildContext context) {
    final b = bare(q);
    final all = [for (var i = 0; i < widget.items.length; i++) if (b.isEmpty || bare((widget.items[i] as Map)['t'] as String).contains(b)) i];
    final shown = all.take(limit).toList();
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) => PageScaffold(
        title: widget.speaker['name'] as String,
        subtitle: '${nf(widget.items.length)} مادة',
        children: [
          TextField(decoration: const InputDecoration(hintText: 'ابحث في مواد الشيخ', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() { q = v; limit = 60; })),
          const SizedBox(height: 4),
          for (final i in shown)
            Builder(builder: (_) {
              final it = widget.items[i] as Map<String, dynamic>;
              final urls = (it['u'] as List).cast<String>();
              final cur = player.cur != null && urls.contains(player.cur!.url);
              return ItemTile(
                icon: cur && player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                title: it['t'] as String,
                sub: [if (it['d'] != null) _dur(it['d'] as num), if (urls.length > 1) '${nf(urls.length)} أجزاء'].join(' · '),
                onTap: () => cur ? player.toggle() : _playLecture(widget.speaker, widget.items, i),
              );
            }),
          if (shown.length < all.length) Center(child: TextButton(onPressed: () => setState(() => limit += 60), child: const Text('عرض المزيد'))),
        ],
      ),
    );
  }
}

// ======================= المواعظ المكتوبة =======================
class WrittenMawaizPage extends StatefulWidget {
  const WrittenMawaizPage({super.key});
  @override
  State<WrittenMawaizPage> createState() => _WrittenMawaizPageState();
}

class _WrittenMawaizPageState extends State<WrittenMawaizPage> {
  String cat = 'all';
  late final Future<Map<String, dynamic>> _f = rootBundle.loadString('assets/data/mawaiz_written.json').then((s) => jsonDecode(s) as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (context, s) {
        final d = s.data;
        final cats = ((d?['CATEGORIES'] as List?) ?? []).cast<Map<String, dynamic>>();
        final types = (d?['TYPE_NAMES'] as Map?)?.cast<String, dynamic>() ?? {};
        final all = ((d?['MAWAIZ'] as List?) ?? []).cast<Map<String, dynamic>>();
        final list = cat == 'all' ? all : all.where((m) => m['cat'] == cat).toList();
        return PageScaffold(
          title: 'مواعظ مكتوبة',
          subtitle: 'آيات وأحاديث صحيحة وآثار عن السلف',
          children: [
            if (d == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            ChipRow(items: [for (final c in cats) (c['id'] as String, c['name'] as String)], selected: cat, onSelect: (v) => setState(() => cat = v)),
            for (final m in list)
              AppCard(
                margin: const EdgeInsets.only(top: 10),
                radius: 18,
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(12)), child: Text('${types[m['type']] ?? ''}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.pri))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
                  ]),
                  const SizedBox(height: 8),
                  Text(m['type'] == 'ayah' ? '﴿${m['text']}﴾' : m['text'] as String, style: const TextStyle(fontFamily: quranFont, fontSize: 19, height: 1.95)),
                  Text(m['source'] as String, style: TextStyle(fontSize: 11.5, color: p.on2)),
                  if ((m['note'] as String?)?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 6), child: Text(m['note'] as String, style: TextStyle(fontSize: 12.5, color: p.on2, height: 1.6))),
                  Row(children: [
                    IconButton(visualDensity: VisualDensity.compact, onPressed: () => copyText('${m['text']}\n— ${m['source']}'), icon: Icon(Icons.copy_outlined, size: 18, color: p.on2)),
                    IconButton(visualDensity: VisualDensity.compact, onPressed: () { hap.click(); Share.share('${m['text']}\n— ${m['source']}'); }, icon: Icon(Icons.share_outlined, size: 18, color: p.on2)),
                  ]),
                ]),
              ),
          ],
        );
      },
    );
  }
}
