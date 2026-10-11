import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/data.dart';
import '../core/player.dart';
import '../core/util.dart';
import '../ui/widgets.dart';

const _api = 'https://www.mp3quran.net/api/v3/';
Map<String, dynamic>? _cache;

Future<Map<String, dynamic>?> loadReciters() async {
  if (_cache != null) return _cache;
  try {
    final r = await http.get(Uri.parse('${_api}reciters?language=ar')).timeout(const Duration(seconds: 15));
    if (r.statusCode == 200) return _cache = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  } catch (_) {}
  return null;
}

class RecitersPage extends StatefulWidget {
  const RecitersPage({super.key});
  @override
  State<RecitersPage> createState() => _RecitersPageState();
}

class _RecitersPageState extends State<RecitersPage> {
  late Future<Map<String, dynamic>?> f = loadReciters();
  String q = '';
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: f,
      builder: (context, s) {
        final all = ((s.data?['reciters'] as List?) ?? []).cast<Map<String, dynamic>>();
        final b = bare(q);
        final list = all.where((r) => b.isEmpty || bare(r['name'] as String).contains(b)).take(120).toList();
        return PageScaffold(title: 'القرآن صوتيًا', back: false, children: [
          TextField(decoration: const InputDecoration(hintText: 'ابحث عن قارئ', prefixIcon: Icon(Icons.search_rounded)), onChanged: (v) => setState(() => q = v)),
          if (s.connectionState != ConnectionState.done) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          if (s.connectionState == ConnectionState.done && s.data == null)
            Padding(padding: const EdgeInsets.all(30), child: Column(children: [const Sub('تعذّر الاتصال. تأكد من الإنترنت ثم أعد المحاولة.', align: TextAlign.center), TextButton(onPressed: () => setState(() => f = loadReciters()), child: const Text('إعادة المحاولة'))])),
          for (final r in list)
            ItemTile(
              icon: Icons.music_note_rounded, title: r['name'] as String,
              sub: ((r['moshaf'] as List).isEmpty ? '' : ((r['moshaf'] as List).first as Map)['name'] as String) + ((r['moshaf'] as List).length > 1 ? ' · +${(r['moshaf'] as List).length - 1}' : ''),
              onTap: () => pushPage(ReciterPage(reciter: r)),
            ),
        ]);
      },
    );
  }
}

class ReciterPage extends StatefulWidget {
  final Map<String, dynamic> reciter;
  const ReciterPage({super.key, required this.reciter});
  @override
  State<ReciterPage> createState() => _ReciterPageState();
}

class _ReciterPageState extends State<ReciterPage> {
  int mi = 0;
  @override
  Widget build(BuildContext context) {
    final r = widget.reciter;
    final moshaf = (r['moshaf'] as List).cast<Map<String, dynamic>>();
    final m = moshaf[mi];
    final nums = (m['surah_list'] as String).split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
    return FutureBuilder(
      future: data.surahs(),
      builder: (context, s) {
        final names = s.data;
        String nameOf(int n) => names == null ? 'سورة $n' : (names[n - 1][1] as String).replaceFirst(RegExp(r'^سُورَةُ\s*'), '');
        final tracks = [for (final n in nums) Track(nameOf(n), r['name'] as String, '${m['server']}${n.toString().padLeft(3, '0')}.mp3')];
        return PageScaffold(title: r['name'] as String, children: [
          if (moshaf.length > 1) ChipRow(items: [for (var i = 0; i < moshaf.length; i++) ('$i', moshaf[i]['name'] as String)], selected: '$mi', onSelect: (v) => setState(() => mi = int.parse(v))) else Sub(m['name'] as String),
          for (var i = 0; i < nums.length; i++)
            ItemTile(
              icon: Icons.play_circle_outline_rounded, title: nameOf(nums[i]), sub: 'سورة رقم ${nf(nums[i])}',
              onTap: () { hap.click(); player.play(tracks, i); touchActivity(); },
              trailing: const SizedBox.shrink(),
            ),
        ]);
      },
    );
  }
}
