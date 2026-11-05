import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../core/data.dart';
import '../core/khatma.dart';
import '../core/player.dart';
import '../core/qindex.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/skyline.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'reciters.dart';
export 'quran_home.dart';

// ======================= حالة القرآن (تُحفظ داخل المفتاح المتزامن quran) =======================
List<String> _qs(String k) => [for (final x in (quranState()[k] as List?) ?? const []) '$x'];
bool qIsFav(int s, int a) => _qs('fav').contains('$s:$a');
bool qIsMark(int s, int a) => _qs('marks').contains('$s:$a');
bool qSurahSaved(int s) => _qs('sm').contains('$s');

void _qToggle(String key, String v) => store.upd('quran', {'fav': [], 'marks': [], 'hl': {}, 'last': 1, 'pagesRead': {}}, (q) {
      final l = [for (final x in (q[key] as List?) ?? const []) '$x'];
      l.contains(v) ? l.remove(v) : l.add(v);
      q[key] = l;
    });

String? qNote(int s, int a) => ((quranState()['notes'] as Map?)?['$s:$a']) as String?;
int qProg(int s) => (((quranState()['prog'] as Map?)?['$s']) as num?)?.toInt() ?? 0;
void _setProg(int s, int a) => store.upd('quran', {'fav': [], 'marks': [], 'hl': {}, 'last': 1, 'pagesRead': {}}, (q) {
      q['prog'] ??= <String, dynamic>{};
      final m = q['prog'] as Map;
      if (a > ((m['$s'] as num?)?.toInt() ?? 0)) m['$s'] = a;
      q['last'] = s;
    });

// ======================= فتح المصحف =======================
void openSurah(int s, [int ayah = 1]) => pushPage(SurahReaderPage(surah: s, ayah: ayah));

Future<void> openJuz(int j) async {
  final q = await qIndex();
  final st = q.juzStart[j];
  if (st != null) openSurah(st.$1, st.$2);
}

Future<void> openPage(int pg) async {
  final q = await qIndex();
  final st = q.pageStart[pg.clamp(1, 604)];
  if (st != null) openSurah(st.$1, st.$2);
}

String _plain(String s) => s.replaceFirst(RegExp(r'^سُورَةُ\s*'), '');
String _ayahWord(int n) => n == 2 ? 'آيتان' : (n >= 3 && n <= 10) ? 'آيات' : 'آية';

Future<String> ayahTextOf(int s, int a) async {
  final surahs = await data.surahs(), ays = await data.ayahs();
  var off = 0;
  for (var i = 0; i < s - 1; i++) { off += (surahs[i][3] as num).toInt(); }
  return (ays[off + a - 1] as List)[2] as String;
}

// الشاشة الرئيسية للقرآن (المصحف / الاستماع) في quran_home.dart

class _OctPainter extends CustomPainter {
  final Color c;
  _OctPainter(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final ctr = s.center(Offset.zero), r = s.width / 2 - 2;
    Path star(double rad) {
      final p = Path();
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8 - math.pi / 2, rr = i.isEven ? rad : rad * .84;
        final o = ctr + Offset(rr * math.cos(a), rr * math.sin(a));
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    canvas.drawPath(star(r), Paint()..color = c);
    canvas.drawPath(star(r), Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = const Color(0xFFD9A63B));
  }

  @override
  bool shouldRepaint(_OctPainter o) => o.c != c;
}

// ======================= إعدادات القارئ =======================
double _qfs() => ((cfg.get('qfs') as num?) ?? 28).toDouble();
String _qfont() => (cfg.get('qfont') as String?) ?? quranFont;
String _qpage() => (cfg.get('qpage') as String?) ?? 'cream';
bool _qflow() => cfg.get('qflow') != false;

({Color bg, Color fg, Color hl}) _pageColors(String k) => switch (k) {
      'white' => (bg: const Color(0xFFFFFFFF), fg: const Color(0xFF111111), hl: const Color(0xFFDCEEDD)),
      'sepia' => (bg: const Color(0xFFF3E6CC), fg: const Color(0xFF3B2A14), hl: const Color(0xFFE6D2A6)),
      'night' => (bg: const Color(0xFF0F1A16), fg: const Color(0xFFE6EFE9), hl: const Color(0xFF1F3A2D)),
      _ => (bg: const Color(0xFFFFFCF3), fg: const Color(0xFF10261E), hl: const Color(0xFFDDEBD6)),
    };

void readerSettings(BuildContext context) {
  showAppSheet(context, (ctx) => StatefulBuilder(builder: (ctx, set) {
        final p = Pal.of(ctx);
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إعدادات القراءة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            const Text('حجم الخط'),
            Expanded(child: Slider(value: _qfs().clamp(20, 44), min: 20, max: 44, divisions: 12, onChanged: (v) { cfg.set('qfs', v.round()); set(() {}); })),
            Text(nf(_qfs().round())),
          ]),
          const Text('نوع الخط'),
          const SizedBox(height: 6),
          ChipRow(items: const [(quranFont, 'مصحف'), (arabicFont, 'نسخ')], selected: _qfont(), onSelect: (v) { cfg.set('qfont', v); set(() {}); }),
          const SizedBox(height: 12),
          const Text('لون الصفحة'),
          const SizedBox(height: 8),
          Row(children: [
            for (final c in const [('cream', 'كريمي'), ('white', 'أبيض'), ('sepia', 'سيبيا'), ('night', 'ليلي')])
              Expanded(
                child: GestureDetector(
                  onTap: () { cfg.set('qpage', c.$1); set(() {}); },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: _pageColors(c.$1).bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _qpage() == c.$1 ? p.pri : p.line, width: _qpage() == c.$1 ? 2.4 : 1)),
                    child: Center(child: Text(c.$2, style: TextStyle(color: _pageColors(c.$1).fg, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
          ]),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('نص متصل (مثل المصحف)'), subtitle: const Sub('أو آية بآية في أسطر مستقلة'), value: _qflow(), onChanged: (v) { cfg.set('qflow', v); set(() {}); }),
        ]);
      }));
}

// ======================= قارئ السورة =======================
class SurahReaderPage extends StatefulWidget {
  final int surah, ayah;
  const SurahReaderPage({super.key, required this.surah, this.ayah = 1});
  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  late int surah = widget.surah;
  late int sel = widget.ayah;
  final Map<int, GlobalKey> _keys = {};
  final List<TapGestureRecognizer> _recs = [];
  bool _scrolled = false;
  Future<List>? _f;

  Future<List> _load() => Future.wait([data.ayahs(), data.surahs(), data.quran(), qIndex()]);

  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  @override
  void dispose() {
    for (final r in _recs) { r.dispose(); }
    super.dispose();
  }

  void _select(int a) {
    hap.tick();
    setState(() => sel = a);
    _setProg(surah, a);
    touchActivity();
  }

  Future<void> _tafsir(int a) async {
    final text = await ayahTextOf(surah, a);
    if (!mounted) return;
    showAppSheet(context, (ctx) {
      final p = Pal.of(ctx);
      return FutureBuilder<String>(
        future: () async {
          try {
            final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/$surah:$a/ar.muyassar')).timeout(const Duration(seconds: 12));
            if (r.statusCode == 200) return ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['data'] as Map)['text'] as String;
          } catch (_) {}
          return '';
        }(),
        builder: (_, s) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('التفسير الميسّر · آية ${nf(a)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontFamily: quranFont, fontSize: 22, height: 2)),
          Divider(color: p.line),
          if (s.connectionState != ConnectionState.done) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
          else if ((s.data ?? '').isEmpty) const Sub('تعذّر تحميل التفسير. تأكد من الإنترنت ثم أعد المحاولة.')
          else Text(s.data!, style: const TextStyle(fontSize: 17, height: 1.9)),
        ]),
      );
    });
  }

  Future<void> _note(int a) async {
    final c = TextEditingController(text: qNote(surah, a) ?? '');
    final ok = await showAppSheet<bool>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('ملاحظة على الآية ${nf(a)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(controller: c, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب ملاحظتك أو تدبّرك...')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ]));
    if (ok != true) return;
    store.upd('quran', {'fav': [], 'marks': [], 'hl': {}, 'last': 1, 'pagesRead': {}}, (q) {
      q['notes'] ??= <String, dynamic>{};
      final m = q['notes'] as Map;
      c.text.trim().isEmpty ? m.remove('$surah:$a') : m['$surah:$a'] = c.text.trim();
    });
    toast('تم الحفظ');
  }

  void _more(BuildContext context, List surahs, QIndex qi, int cnt) {
    final pages = (qi.surahLastPage[surah]! - qi.surahFirstPage[surah]! + 1);
    showAppSheet(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('المزيد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.done_all), title: const Text('تمت قراءة السورة'), onTap: () { Navigator.pop(ctx); _setProg(surah, cnt); toast('تم تسجيل إتمام السورة'); setState(() {}); }),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag), title: Text('إضافة ${nf(pages)} صفحة إلى الختمة'), onTap: () { Navigator.pop(ctx); if (khatmaAdd(pages)) toast('أتممت ختمة كاملة!'); else toast('تمت إضافة الصفحات إلى ختمتك'); }),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.headphones), title: const Text('الاستماع بصوت قارئ'), onTap: () { Navigator.pop(ctx); pushPage(const RecitersPage()); }),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.skip_next), title: const Text('السورة التالية'), onTap: () { Navigator.pop(ctx); if (surah < 114) setState(() { surah++; sel = 1; _scrolled = false; _keys.clear(); }); }),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.skip_previous), title: const Text('السورة السابقة'), onTap: () { Navigator.pop(ctx); if (surah > 1) setState(() { surah--; sel = 1; _scrolled = false; _keys.clear(); }); }),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mq = MediaQuery.of(context);
    return StoreBuilder(builder: (context, _) {
      return FutureBuilder<List>(
        future: _f,
        builder: (context, snap) {
          if (!snap.hasData) return Scaffold(backgroundColor: p.bg, body: const Center(child: CircularProgressIndicator()));
          final all = snap.data![0] as List, surahs = snap.data![1] as List, basmala = (snap.data![2] as Map)['basmala'] as String?, qi = snap.data![3] as QIndex;
          final ay = all.where((a) => (a as List)[0] == surah).toList();
          final cnt = ay.length;
          final name = _plain(surahs[surah - 1][1] as String);
          final cur = ay[(sel - 1).clamp(0, cnt - 1)] as List;
          final pc = _pageColors(_qpage());
          final fs = _qfs(), font = _qfont();
          for (final r in _recs) { r.dispose(); }
          _recs.clear();
          final spans = <InlineSpan>[];
          for (final a in ay) {
            final l = a as List, n = (l[1] as num).toInt();
            final rec = TapGestureRecognizer()..onTap = () => _select(n);
            _recs.add(rec);
            final isSel = n == sel;
            spans.add(TextSpan(text: '${l[2]} ', recognizer: rec, style: TextStyle(backgroundColor: isSel ? pc.hl : null)));
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => _select(n),
                child: Container(
                  key: _keys.putIfAbsent(n, () => GlobalKey()),
                  width: fs * 1.3, height: fs * 1.3,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD9A63B), width: 2), color: isSel ? pc.hl : null),
                  child: Text(toAr(n), style: TextStyle(fontFamily: arabicFont, fontSize: fs * .5, fontWeight: FontWeight.w700, color: pc.fg, height: 1)),
                ),
              ),
            ));
            spans.add(TextSpan(text: _qflow() ? ' ' : '\n'));
          }
          if (!_scrolled) {
            _scrolled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final c = _keys[widget.surah == surah ? widget.ayah : 1]?.currentContext;
              if (c != null && (widget.ayah > 1)) Scrollable.ensureVisible(c, alignment: .25, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
            });
          }
          final pg = (qi.ayahPages[surah]![(sel - 1).clamp(0, cnt - 1)]);
          final hh = mq.padding.top + 62;
          Widget tb(IconData i, String t, VoidCallback f, {bool on = false}) => Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () { hap.tick(); f(); },
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: on ? p.pc : p.surf2.withValues(alpha: .7), borderRadius: BorderRadius.circular(15)), child: Icon(i, color: p.pri, size: 24)),
                    const SizedBox(height: 3),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(t, style: TextStyle(fontSize: 11.5, color: p.on2))),
                  ]),
                ),
              );
          Widget card(Widget c) => Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3))]),
                child: c,
              );
          return Scaffold(
            backgroundColor: p.bg,
            body: Stack(children: [
              Positioned(
                top: 0, left: 0, right: 0, height: hh,
                child: SkylineHeader(
                  height: hh, arch: true,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, mq.padding.top + 10, 14, 0),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      RoundIconButton(Icons.more_vert, () => _more(context, surahs, qi, cnt), light: true),
                      RoundIconButton(Icons.settings_outlined, () => readerSettings(context), light: true),
                      const Spacer(),
                      RoundIconButton(qSurahSaved(surah) ? Icons.bookmark : Icons.bookmark_border, () => _qToggle('sm', '$surah'), light: true),
                      RoundIconButton(Icons.arrow_forward, () => Navigator.of(context).maybePop(), light: true),
                    ]),
                  ),
                ),
              ),
              Positioned.fill(
                top: hh,
                child: Container(
                  decoration: BoxDecoration(color: pc.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: Column(children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(14, 14, 14, 24),
                          child: Column(children: [
                            if (basmala != null && surah != 1 && surah != 9) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(basmala, textAlign: TextAlign.center, style: TextStyle(fontFamily: arabicFont, fontSize: fs * 1.15, color: pc.fg, fontWeight: FontWeight.w700))),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: RichText(textAlign: _qflow() ? TextAlign.justify : TextAlign.right, textDirection: TextDirection.rtl, text: TextSpan(style: TextStyle(fontFamily: font, fontSize: fs, height: 2.15, color: pc.fg), children: spans)),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(18)),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('نهاية سورة $name', style: TextStyle(fontWeight: FontWeight.w800, color: p.pri)),
                                  Sub(qProg(surah) >= cnt ? 'أتممت قراءة هذه السورة 🤍' : 'علّم السورة كمقروءة لتتابع تقدّمك'),
                                ])),
                                FilledButton(onPressed: () { _setProg(surah, cnt); toast('تقبّل الله منك'); }, child: const Text('تمت القراءة')),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              // لافتة اسم السورة
              Positioned(
                top: hh - 62, left: 28, right: 28,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFFCF3), borderRadius: BorderRadius.circular(34), border: Border.all(color: const Color(0xFFD9A63B), width: 2), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 5))]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('سُورَةُ $name', style: const TextStyle(fontFamily: arabicFont, fontSize: 27, fontWeight: FontWeight.w700, color: Color(0xFF10261E), height: 1.3)),
                    Text('الجزء ${nf(cur[3])} - الصفحة ${nf(pg)}', style: const TextStyle(fontSize: 13.5, color: Color(0xFF6F7C74))),
                  ]),
                ),
              ),
            ]),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                card(Row(children: [
                  tb(Icons.edit_note, 'ملاحظات', () => _note(sel), on: qNote(surah, sel) != null),
                  tb(Icons.menu_book_outlined, 'التفسير', () => _tafsir(sel)),
                  tb(Icons.copy, 'النسخ', () async { final t = await ayahTextOf(surah, sel); copyText('﴿$t﴾ [$name: ${nf(sel)}]'); }),
                  tb(Icons.share, 'المشاركة', () async { final t = await ayahTextOf(surah, sel); Share.share('﴿$t﴾ [$name: ${nf(sel)}]'); }),
                  tb(qIsMark(surah, sel) ? Icons.bookmark : Icons.bookmark_border, 'العلامات', () => _qToggle('marks', '$surah:$sel'), on: qIsMark(surah, sel)),
                  tb(qIsFav(surah, sel) ? Icons.favorite : Icons.favorite_border, 'المفضلة', () => _qToggle('fav', '$surah:$sel'), on: qIsFav(surah, sel)),
                ])),
                ListenableBuilder(
                  listenable: player,
                  builder: (_, __) {
                    final t = player.cur;
                    if (t == null) {
                      return Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: OutlinedButton.icon(onPressed: () => pushPage(const RecitersPage()), icon: const Icon(Icons.headphones), label: const Text('استمع بصوت قارئ')));
                    }
                    return card(Row(children: [
                      const SizedBox(width: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/brand/app_icon.png', width: 48, height: 48)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('سورة ${t.title}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text(t.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.on2))])),
                      IconButton(onPressed: player.prev, icon: const Icon(Icons.skip_previous)),
                      GestureDetector(onTap: () { hap.click(); player.toggle(); }, child: Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: p.pri), child: Icon(player.playing ? Icons.pause : Icons.play_arrow, color: p.onpri))),
                      IconButton(onPressed: player.next, icon: const Icon(Icons.skip_next)),
                    ]));
                  },
                ),
                card(Row(children: [
                  tb(Icons.nightlight_round, 'الوضع الليلي', () => cfg.set('qpage', _qpage() == 'night' ? 'cream' : 'night'), on: _qpage() == 'night'),
                  tb(Icons.text_fields, 'حجم الخط', () => readerSettings(context)),
                  tb(Icons.format_list_bulleted, 'نوع الخط', () => cfg.set('qfont', _qfont() == quranFont ? arabicFont : quranFont)),
                  tb(Icons.palette_outlined, 'ألوان الصفحة', () => readerSettings(context)),
                  tb(Icons.menu_book_rounded, 'تبديل المصحف', () => cfg.set('qflow', !_qflow())),
                  tb(Icons.grid_view_rounded, 'المزيد', () => _more(context, surahs, qi, cnt)),
                ])),
              ]),
            ),
          );
        },
      );
    });
  }
}
