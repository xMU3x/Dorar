import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/data.dart';
import '../core/mushaf_data.dart';
import '../core/player.dart';
import '../core/qindex.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'mushaf.dart';
import 'quran.dart' show qSurahSaved, openSurah;
import 'reciters.dart';

// ======================= تنزيلات الصوت =======================
class _Dl {
  final ValueNotifier<int> count = ValueNotifier(0);
  final Map<String, double> prog = {};
  final ValueNotifier<int> tick = ValueNotifier(0);
  Directory? _d;
  Set<String> have = {};
  bool all = false;

  Future<Directory> dir() async {
    if (_d != null) return _d!;
    final b = await getApplicationSupportDirectory();
    final d = Directory('${b.path}/qdl');
    if (!await d.exists()) await d.create(recursive: true);
    return _d = d;
  }

  Future<void> init() async {
    try {
      final d = await dir();
      have = {
        await for (final f in d.list())
          if (f is File && f.path.endsWith('.mp3') && f.lengthSync() > 10000) f.path.split('/').last.replaceAll('.mp3', ''),
      };
      count.value = have.length;
    } catch (_) {}
  }

  String key(Object rid, Object mid, int n) => '${rid}_${mid}_$n';
  Future<String?> local(Object rid, Object mid, int n) async {
    final k = key(rid, mid, n);
    if (!have.contains(k)) return null;
    return '${(await dir()).path}/$k.mp3';
  }

  Future<void> download(Object rid, Object mid, int n, String url) async {
    final k = key(rid, mid, n);
    if (have.contains(k) || prog.containsKey(k)) return;
    prog[k] = 0;
    tick.value++;
    try {
      final req = http.Request('GET', Uri.parse(url.replaceFirst('http://', 'https://')));
      final res = await http.Client().send(req).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw Exception('http ${res.statusCode}');
      final f = File('${(await dir()).path}/$k.part');
      final sink = f.openWrite();
      var got = 0;
      final total = res.contentLength ?? 0;
      await for (final c in res.stream) {
        sink.add(c);
        got += c.length;
        if (total > 0) {
          prog[k] = got / total;
          tick.value++;
        }
      }
      await sink.close();
      await f.rename('${(await dir()).path}/$k.mp3');
      have.add(k);
      count.value = have.length;
    } catch (_) {
      toast('تعذّر التحميل، تحقق من الإنترنت');
    } finally {
      prog.remove(k);
      tick.value++;
    }
  }

  Future<void> remove(String k) async {
    try {
      final f = File('${(await dir()).path}/$k.mp3');
      if (await f.exists()) await f.delete();
    } catch (_) {}
    have.remove(k);
    count.value = have.length;
    tick.value++;
  }
}

final _Dl _dl = _Dl();

/// يتيح فتح تبويب «الاستماع» من خارج الصفحة (زر الإشعار).
final ValueNotifier<String> quranSeg = ValueNotifier('mushaf');

class QuranHomePage extends StatefulWidget {
  const QuranHomePage({super.key});
  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> {
  String seg = 'mushaf', tab = 'surah', q = '';
  Map<String, dynamic>? reciter;
  int moshafIx = 0;
  late Future<Map<String, dynamic>?> _rec = loadReciters();
  String qL = '';

  @override
  void initState() {
    super.initState();
    mushaf.refreshCount();
    _dl.init();
    quranSeg.addListener(_onSeg);
  }

  void _onSeg() {
    if (mounted) setState(() => seg = quranSeg.value);
  }

  @override
  void dispose() {
    quranSeg.removeListener(_onSeg);
    super.dispose();
  }

  Widget _badge(Pal p, int n) => SizedBox(
        width: 38, height: 38,
        child: CustomPaint(painter: _DiamondPainter(p.pri.withValues(alpha: .55)), child: Center(child: Text(nf(n), style: TextStyle(color: p.pri, fontWeight: FontWeight.w800, fontSize: n > 99 ? 11 : 13)))),
      );

  Future<void> _jump() async {
    final c = TextEditingController();
    final go = await showAppSheet<int>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('الانتقال إلى صفحة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(controller: c, autofocus: true, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'من 1 إلى 604')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(c.text.trim())), child: const Text('انتقال')),
        ]));
    if (go != null) pushPage(MushafPage(page: go.clamp(1, 604)));
  }

  // ---------------- المصحف ----------------
  Widget _mushafSeg(Pal p, List surahs, QIndex? qi) {
    final last = lastMushafPage();
    String lastSurah() {
      if (qi == null) return '';
      var best = 1;
      for (var n = 1; n <= 114; n++) {
        if ((qi.surahFirstPage[n] ?? 999) <= last) best = n;
      }
      return 'سورة ${_plain(surahs[best - 1][1] as String)}';
    }

    final b = bare(q);
    final list = surahs.where((s) {
      final l = s as List;
      return b.isEmpty || bare(l[1] as String).contains(b) || '${l[0]}' == b;
    }).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: _RiwayaCard(title: 'رواية حفص', sub: 'مصحف المدينة النبوية', selected: true, onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _RiwayaCard(title: 'رواية ورش', sub: 'ملوّن للحفظ، مع التسميع', selected: false, dots: true, onTap: () => toast('رواية ورش قيد الإضافة'))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: AppCard(
            margin: EdgeInsets.zero, radius: 18, padding: const EdgeInsets.all(10),
            onTap: () => pushPage(MushafPage(page: last)),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(11)), child: Icon(Icons.menu_book_outlined, size: 20, color: p.pri)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('آخر قراءة', style: TextStyle(fontSize: 11, color: p.on2)),
                Text('الصفحة ${nf(last)}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                Text(lastSurah(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: p.on2)),
              ])),
              Icon(Icons.chevron_left, color: p.on2, size: 20),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: AppCard(
            margin: EdgeInsets.zero, radius: 18, padding: const EdgeInsets.symmetric(vertical: 10),
            onTap: _jump,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(11)), child: Icon(Icons.layers_outlined, size: 20, color: p.pri)),
              const SizedBox(height: 4),
              Text('صفحة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.pri)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      ValueListenableBuilder2(
        a: mushaf.cached, b: mushaf.downloading,
        builder: (_, n, dling) => AppCard(
          margin: EdgeInsets.zero, radius: 18, padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: p.gold.withValues(alpha: .18), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.download_rounded, size: 20, color: p.gold)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('المصحف دون إنترنت', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              Text('محفوظ ${nf(n)} من ${nf(604)} صفحة', style: TextStyle(fontSize: 11, color: p.on2)),
              const SizedBox(height: 5),
              Bar(n / 604, track: p.surf2),
            ])),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
              onPressed: n >= 604 ? null : () { if (dling) { mushaf.cancel = true; } else { mushaf.downloadAll(); toast('بدأ تحميل صفحات المصحف'); } },
              child: Text(n >= 604 ? 'مكتمل' : dling ? 'إيقاف' : 'تحميل', style: const TextStyle(fontSize: 13)),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      _SearchBox(hint: 'ابحث عن سورة أو كلمة في القرآن', onChanged: (v) => setState(() => q = v)),
      const SizedBox(height: 6),
      _UnderTabs(selected: tab, onSelect: (v) => setState(() => tab = v), items: const [('surah', 'السور'), ('juz', 'الأجزاء'), ('marks', 'العلامات')]),
      const SizedBox(height: 8),
      if (tab == 'surah') ...[
        if (b.length >= 3 && list.isEmpty) _AyahSearch(query: b, onOpen: (pg) => pushPage(MushafPage(page: pg))),
        _SurahCard(children: [
          for (var i = 0; i < list.length; i++)
            _Row(
              last: i == list.length - 1,
              lead: _badge(p, (list[i] as List)[0] as int),
              title: 'سورة ${_plain((list[i] as List)[1] as String)}',
              sub: '${(list[i] as List)[2] == 1 ? 'مكية' : 'مدنية'} · ${nf((list[i] as List)[3])} آية',
              trailing: Icon(Icons.chevron_left, color: p.on2, size: 22),
              onTap: () {
                final n = (list[i] as List)[0] as int;
                final pg = qi?.surahFirstPage[n] ?? 1;
                pushPage(MushafPage(page: pg));
              },
            ),
        ]),
      ] else if (tab == 'juz')
        _SurahCard(children: [
          for (var j = 1; j <= 30; j++)
            _Row(last: j == 30, lead: _badge(p, j), title: 'الجزء ${nf(j)}', sub: 'صفحة ${nf(juzStartPage[j - 1])}', trailing: Icon(Icons.chevron_left, color: p.on2, size: 22), onTap: () => pushPage(MushafPage(page: juzStartPage[j - 1]))),
        ])
      else
        Builder(builder: (_) {
          final bms = mushafBookmarks()..sort();
          final sm = [for (var n = 1; n <= 114; n++) if (qSurahSaved(n)) n];
          if (bms.isEmpty && sm.isEmpty) return const Padding(padding: EdgeInsets.all(34), child: Sub('لا توجد علامات بعد\nاضغط على أيقونة العلامة أثناء قراءة المصحف', align: TextAlign.center));
          return _SurahCard(children: [
            for (var i = 0; i < bms.length; i++) _Row(last: i == bms.length - 1 && sm.isEmpty, lead: Icon(Icons.bookmark, color: p.pri, size: 30), title: 'الصفحة ${nf(bms[i])}', sub: 'علامة في المصحف', trailing: Icon(Icons.chevron_left, color: p.on2, size: 22), onTap: () => pushPage(MushafPage(page: bms[i]))),
            for (var i = 0; i < sm.length; i++) _Row(last: i == sm.length - 1, lead: _badge(p, sm[i]), title: 'سورة ${_plain(surahs[sm[i] - 1][1] as String)}', sub: 'سورة محفوظة', trailing: Icon(Icons.bookmark, color: p.pri, size: 22), onTap: () => openSurah(sm[i])),
          ]);
        }),
    ]);
  }

  String _initial(String n) {
    final t = n.replaceFirst(RegExp(r'^(الشيخة|الشيخ)\s+'), '');
    return t.isEmpty ? 'م' : String.fromCharCode(t.runes.first);
  }

  String _plain(String s) => s.replaceFirst(RegExp(r'^سُورَةُ\s*'), '');

  // ---------------- الاستماع ----------------
  Map<String, dynamic>? _pick(List<Map<String, dynamic>> all) {
    if (reciter != null) return reciter;
    return all.where((r) => (r['name'] as String).contains('العفاسي')).firstOrNull ?? all.firstOrNull;
  }

  Future<void> _chooseReciter(List<Map<String, dynamic>> all) async {
    var f = '';
    final r = await showAppSheet<Map<String, dynamic>>(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          final b = bare(f);
          final list = all.where((r) => b.isEmpty || bare(r['name'] as String).contains(b)).take(80).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * .6,
            child: Column(children: [
              TextField(decoration: const InputDecoration(hintText: 'ابحث عن قارئ', prefixIcon: Icon(Icons.search)), onChanged: (v) => set(() => f = v)),
              const SizedBox(height: 8),
              Expanded(child: ListView(children: [for (final r in list) ListTile(title: Text(r['name'] as String), onTap: () => Navigator.pop(ctx, r))])),
            ]),
          );
        }));
    if (r != null) setState(() { reciter = r; moshafIx = 0; });
  }

  List<Track> _tracks(Map<String, dynamic> r, Map<String, dynamic> m, List<int> nums, List surahs) => [
        for (final n in nums) Track(_plain(surahs[n - 1][1] as String), r['name'] as String, '${m['server']}${n.toString().padLeft(3, '0')}.mp3', surah: n, extra: m['name'] as String),
      ];

  Future<void> _play(Map<String, dynamic> r, Map<String, dynamic> m, List<int> nums, int i, List surahs) async {
    final tr = _tracks(r, m, nums, surahs);
    // الملفات المحمّلة تُشغَّل من الجهاز
    final fixed = <Track>[];
    for (var k = 0; k < tr.length; k++) {
      final loc = await _dl.local(r['id'], m['id'], nums[k]);
      final t = tr[k];
      fixed.add(loc == null ? t : Track(t.title, t.sub, 'file://$loc', surah: t.surah, extra: t.extra));
    }
    player.play(fixed, i);
  }

  Widget _listenSeg(Pal p, List surahs) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _rec,
      builder: (context, s) {
        final all = ((s.data?['reciters'] as List?) ?? []).cast<Map<String, dynamic>>();
        if (s.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()));
        if (all.isEmpty) {
          return Padding(padding: const EdgeInsets.all(30), child: Column(children: [const Sub('تعذّر تحميل القرّاء، تأكد من الإنترنت.', align: TextAlign.center), TextButton(onPressed: () => setState(() => _rec = loadReciters()), child: const Text('إعادة المحاولة'))]));
        }
        final r = _pick(all)!;
        final moshaf = (r['moshaf'] as List).cast<Map<String, dynamic>>();
        final m = moshaf[moshafIx.clamp(0, moshaf.length - 1)];
        final nums = (m['surah_list'] as String).split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
        final b = bare(qL);
        final shown = [for (final n in nums) if (b.isEmpty || '$n' == b || bare(surahs[n - 1][1] as String).contains(b)) n];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppCard(
            margin: EdgeInsets.zero, radius: 20, padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('القارئ', style: TextStyle(fontSize: 11.5, color: p.on2)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _chooseReciter(all),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: p.surf2, borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        Expanded(child: Text(r['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
                        Icon(Icons.keyboard_arrow_down, color: p.on2),
                      ]),
                    ),
                  ),
                  if (moshaf.length > 1) Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ChipRow(items: [for (var i = 0; i < moshaf.length; i++) ('$i', moshaf[i]['name'] as String)], selected: '$moshafIx', onSelect: (v) => setState(() => moshafIx = int.parse(v))),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [p.pri, p.pri2], begin: Alignment.topRight, end: Alignment.bottomLeft)),
                alignment: Alignment.center,
                child: Text(_initial(r['name'] as String), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.onpri)),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: _dl.count,
                builder: (_, n, __) => _PillBtn(icon: Icons.download_done_rounded, label: 'التنزيلات', badge: n > 0 ? nf(n) : null, onTap: () => _downloadsSheet(r, m, surahs)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _PillBtn(icon: Icons.download_rounded, label: 'تحميل كل السور', onTap: () => _downloadAll(r, m, nums))),
          ]),
          const SizedBox(height: 10),
          _SearchBox(hint: 'ابحث عن سورة بالاسم أو الرقم', onChanged: (v) => setState(() => qL = v)),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: _dl.tick,
            builder: (_, __, ___) => ListenableBuilder(
              listenable: player,
              builder: (_, __) => _SurahCard(children: [
                for (var i = 0; i < shown.length; i++)
                  Builder(builder: (_) {
                    final n = shown[i];
                    final k = _dl.key(r['id'], m['id'], n);
                    final cur = player.cur?.surah == n && player.cur?.sub == r['name'];
                    final dp = _dl.prog[k];
                    return _Row(
                      last: i == shown.length - 1,
                      lead: SizedBox(width: 38, height: 38, child: CustomPaint(painter: _DiamondPainter(p.pri.withValues(alpha: .55)), child: Center(child: Text(nf(n), style: TextStyle(color: p.pri, fontWeight: FontWeight.w800, fontSize: n > 99 ? 11 : 13))))),
                      title: 'سورة ${_plain(surahs[n - 1][1] as String)}',
                      sub: '${(surahs[n - 1] as List)[2] == 1 ? 'مكية' : 'مدنية'} · ${nf((surahs[n - 1] as List)[3])} آية',
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (dp != null) SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, value: dp > 0 ? dp : null))
                        else IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _dl.have.contains(k) ? () => _dl.remove(k) : () => _dl.download(r['id'], m['id'], n, '${m['server']}${n.toString().padLeft(3, '0')}.mp3'),
                          icon: Icon(_dl.have.contains(k) ? Icons.download_done_rounded : Icons.file_download_outlined, color: _dl.have.contains(k) ? p.pri : p.on2, size: 23),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () { hap.click(); cur ? player.toggle() : _play(r, m, nums, nums.indexOf(n), surahs); },
                          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Icon(cur && player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: p.pri, size: 24)),
                        ),
                      ]),
                      onTap: () => cur ? player.toggle() : _play(r, m, nums, nums.indexOf(n), surahs),
                    );
                  }),
              ]),
            ),
          ),
        ]);
      },
    );
  }

  void _downloadAll(Map<String, dynamic> r, Map<String, dynamic> m, List<int> nums) async {
    if (_dl.all) { toast('التحميل جارٍ بالفعل'); return; }
    final ok = await confirmDialog(context, 'تحميل كل السور؟', 'سيتم تحميل ${nf(nums.length)} سورة للقارئ ${r['name']} وقد تستهلك مساحة كبيرة.', ok: 'تحميل');
    if (!ok) return;
    _dl.all = true;
    toast('بدأ التحميل، يمكنك متابعة التصفح');
    for (final n in nums) {
      if (!mounted) break;
      await _dl.download(r['id'], m['id'], n, '${m['server']}${n.toString().padLeft(3, '0')}.mp3');
    }
    _dl.all = false;
    toast('اكتمل التحميل');
  }

  void _downloadsSheet(Map<String, dynamic> r, Map<String, dynamic> m, List surahs) {
    showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
          final mine = _dl.have.where((k) => k.startsWith('${r['id']}_${m['id']}_')).map((k) => int.parse(k.split('_').last)).toList()..sort();
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('تنزيلات ${r['name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (mine.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Sub('لا توجد سور محمّلة لهذا القارئ', align: TextAlign.center)),
            for (final n in mine)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('سورة ${_plain(surahs[n - 1][1] as String)}'),
                leading: IconButton(icon: const Icon(Icons.play_arrow_rounded), onPressed: () { Navigator.pop(ctx); _play(r, m, mine, mine.indexOf(n), surahs); }),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFA8332B)), onPressed: () async { await _dl.remove(_dl.key(r['id'], m['id'], n)); set(() {}); }),
              ),
          ]);
        }));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: data.surahs(),
      builder: (context, snap) {
        final p = Pal.of(context);
        final mq = MediaQuery.of(context);
        final surahs = snap.data ?? const [];
        return FutureBuilder<QIndex>(
          future: qIndex(),
          builder: (context, qs) => Scaffold(
            backgroundColor: p.bg,
            body: ListView(
              padding: EdgeInsets.fromLTRB(14, mq.padding.top + 10, 14, mq.padding.bottom + 100),
              physics: const BouncingScrollPhysics(),
              children: [
                Row(children: [
                  const Expanded(child: Text('القرآن الكريم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                  RoundIconButton(Pal.darkNow ? Icons.light_mode_outlined : Icons.dark_mode_outlined, () { hap.tick(); cfg.set('mode', Pal.darkNow ? 'light' : 'dark'); }, light: true, tooltip: 'الوضع'),
                ]),
                const SizedBox(height: 8),
                _Seg(selected: seg, onSelect: (v) => setState(() => seg = v), items: const [('mushaf', 'المصحف', Icons.menu_book_outlined), ('listen', 'الاستماع', Icons.headphones_outlined)]),
                const SizedBox(height: 10),
                if (snap.data == null) const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator())) else if (seg == 'mushaf') _mushafSeg(p, surahs, qs.data) else _listenSeg(p, surahs),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================= مكوّنات صغيرة =======================
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> a;
  final ValueListenable<B> b;
  final Widget Function(BuildContext, A, B) builder;
  const ValueListenableBuilder2({super.key, required this.a, required this.b, required this.builder});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(valueListenable: a, builder: (c, x, _) => ValueListenableBuilder<B>(valueListenable: b, builder: (c, y, _) => builder(c, x, y)));
}

class _DiamondPainter extends CustomPainter {
  final Color c;
  const _DiamondPainter(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .14, s.height * .14, s.width * .72, s.height * .72), Radius.circular(s.width * .16));
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.rotate(.785398);
    canvas.translate(-s.width / 2, -s.height / 2);
    canvas.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = c);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DiamondPainter o) => o.c != c;
}

class _Seg extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final List<(String, String, IconData)> items;
  const _Seg({required this.selected, required this.onSelect, required this.items});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surf2, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: GestureDetector(
              onTap: () { if (it.$1 != selected) hap.select(); onSelect(it.$1); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: it.$1 == selected ? p.surf : Colors.transparent, borderRadius: BorderRadius.circular(14), boxShadow: it.$1 == selected ? softShadow(8, 2) : null),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(it.$3, size: 18, color: it.$1 == selected ? p.on : p.on2),
                  const SizedBox(width: 6),
                  Text(it.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: it.$1 == selected ? p.on : p.on2)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _RiwayaCard extends StatelessWidget {
  final String title, sub;
  final bool selected, dots;
  final VoidCallback onTap;
  const _RiwayaCard({required this.title, required this.sub, required this.selected, this.dots = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return GestureDetector(
      onTap: () { hap.tick(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 76),
        decoration: BoxDecoration(color: selected ? p.pc : p.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? p.pri : p.line, width: selected ? 1.6 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (dots) Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [for (final c in const [Color(0xFF7B3F8C), Color(0xFF2F63B5), Color(0xFF9A4A1F), Color(0xFF2F8F6F)]) Container(width: 10, height: 10, margin: const EdgeInsetsDirectional.only(end: 4), decoration: BoxDecoration(color: c, shape: BoxShape.circle))])),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: p.on2, height: 1.4)),
        ]),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 13), prefixIcon: const Icon(Icons.search, size: 22), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Pal.of(context).line))),
      );
}

class _UnderTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final List<(String, String)> items;
  const _UnderTabs({required this.selected, required this.onSelect, required this.items});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { if (it.$1 != selected) hap.select(); onSelect(it.$1); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: it.$1 == selected ? p.pri : Colors.transparent, width: 2.5))),
                child: Center(child: Text(it.$2, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: it.$1 == selected ? p.pri : p.on2))),
              ),
            ),
          ),
      ]),
    );
  }
}

class _SurahCard extends StatelessWidget {
  final List<Widget> children;
  const _SurahCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final Widget lead, trailing;
  final String title, sub;
  final bool last;
  final VoidCallback onTap;
  const _Row({required this.lead, required this.title, required this.sub, required this.trailing, required this.last, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return InkWell(
      onTap: () { hap.tick(); onTap(); },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: p.line))),
        child: Row(children: [
          lead,
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: p.on2)),
          ])),
          trailing,
        ]),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  const _PillBtn({required this.icon, required this.label, this.badge, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Material(
      color: p.surf,
      shape: StadiumBorder(side: BorderSide(color: p.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () { hap.tick(); onTap(); },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: p.pri),
            const SizedBox(width: 6),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)))),
            if (badge != null) Container(margin: const EdgeInsetsDirectional.only(start: 6), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1), decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Text(badge!, style: TextStyle(fontSize: 11, color: p.pri, fontWeight: FontWeight.w800))),
          ]),
        ),
      ),
    );
  }
}

/// بحث في نص الآيات (يظهر عند عدم وجود سورة مطابقة).
class _AyahSearch extends StatelessWidget {
  final String query;
  final void Function(int page) onOpen;
  const _AyahSearch({required this.query, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return FutureBuilder<List>(
      future: data.ayahs(),
      builder: (context, s) {
        final hits = <List>[];
        for (final a in (s.data ?? const [])) {
          final l = a as List;
          if (hits.length < 25 && bare(l[2] as String).contains(query)) hits.add(l);
        }
        if (hits.isEmpty) return const Padding(padding: EdgeInsets.all(30), child: Sub('لا نتائج', align: TextAlign.center));
        return _SurahCard(children: [
          for (var i = 0; i < hits.length; i++)
            InkWell(
              onTap: () => onOpen((hits[i][4] as num).toInt()),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: i == hits.length - 1 ? null : Border(bottom: BorderSide(color: p.line))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hits[i][2] as String, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: quranFont, fontSize: 18, height: 1.9)),
                  Text('سورة رقم ${nf(hits[i][0])} · آية ${nf(hits[i][1])} · صفحة ${nf(hits[i][4])}', style: TextStyle(fontSize: 11, color: p.on2)),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
