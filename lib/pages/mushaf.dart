import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/data.dart';
import '../core/mushaf_data.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

export '../core/mushaf_data.dart' show lastMushafPage;

const _ord = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر', 'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر', 'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون', 'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون', 'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون'];

int? _parseNum(String t) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final r in t.runes) {
    final ch = String.fromCharCode(r);
    final i = ar.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return int.tryParse(b.toString().trim());
}

/// قارئ المصحف بصفحاته الـ٦٠٤ (خط QCF2 لمصحف المدينة)، بنفس تقسيم السطور والزخارف.
class MushafPage extends StatefulWidget {
  final int page;
  const MushafPage({super.key, this.page = 1});
  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late final PageController _pc = PageController(initialPage: widget.page.clamp(1, 604) - 1);
  late int _cur = widget.page.clamp(1, 604);
  bool _bars = true;

  @override
  void initState() {
    super.initState();
    mushaf.refreshCount();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _jump() async {
    final c = TextEditingController();
    final go = await showAppSheet<int>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('الانتقال إلى صفحة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(controller: c, autofocus: true, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'من ١ إلى ٦٠٤')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(ctx, _parseNum(c.text)), child: const Text('انتقال')),
        ]));
    if (go != null) _pc.jumpToPage(go.clamp(1, 604) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final dark = Pal.darkNow;
    final bg = dark ? p.bg : const Color(0xFFFEFAF2);
    final mq = MediaQuery.of(context);
    final bm = mushafBookmarks().contains(_cur);
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _bars = !_bars),
          child: PageView.builder(
            controller: _pc,
            itemCount: 604,
            onPageChanged: (i) {
              setState(() => _cur = i + 1);
              setLastMushafPage(i + 1);
              touchActivity();
              // تهيئة الصفحة التالية مسبقًا
              for (final k in [i + 2, i + 3, i + 4, i]) {
                if (k >= 1 && k <= 604) unawaited(mushaf.ensureFont(k));
              }
            },
            itemBuilder: (_, i) => _PageBody(page: i + 1, bg: bg, dark: dark),
          ),
        ),
        // شريط علوي يظهر/يختفي بالنقر
        Positioned(
          top: 0, left: 0, right: 0,
          child: IgnorePointer(
            ignoring: !_bars,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _bars ? 1 : 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(10, mq.padding.top + 4, 10, 6),
                color: bg.withValues(alpha: .94),
                child: Row(children: [
                  RoundIconButton(Icons.arrow_forward, () => Navigator.of(context).maybePop(), light: true, tooltip: 'رجوع'),
                  const Spacer(),
                  RoundIconButton(bm ? Icons.bookmark : Icons.bookmark_border, () { toggleMushafBookmark(_cur); setState(() {}); toast(bm ? 'أُزيلت العلامة' : 'تمت إضافة علامة'); }, light: true, tooltip: 'علامة'),
                  RoundIconButton(Icons.format_list_numbered, _jump, light: true, tooltip: 'انتقال لصفحة'),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PageBody extends StatefulWidget {
  final int page;
  final Color bg;
  final bool dark;
  const _PageBody({required this.page, required this.bg, required this.dark});
  @override
  State<_PageBody> createState() => _PageBodyState();
}

class _PageBodyState extends State<_PageBody> {
  late Future<bool> _font = mushaf.ensureFont(widget.page);
  late final Future<List> _lines = mushaf.lines(widget.page);
  late final Future<List<MushafMeta>> _meta = mushaf.meta();
  List<String> _surahNames = const [];

  @override
  void initState() {
    super.initState();
    data.surahs().then((s) {
      if (mounted) setState(() => _surahNames = [for (final x in s) ((x as List)[1] as String).replaceFirst(RegExp(r'^سُورَةُ\s*'), '')]);
    });
  }

  String _name(int n) => n >= 1 && n <= _surahNames.length ? _surahNames[n - 1] : '';

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final ink = widget.dark ? const Color(0xFFE9E4D3) : const Color(0xFF14110C);
    final gold = widget.dark ? const Color(0xFFC9AE72) : const Color(0xFFA8895A);
    final mq = MediaQuery.of(context);
    return FutureBuilder<List>(
      future: Future.wait([_lines, _meta]),
      builder: (context, snap) {
        if (!snap.hasData) return Container(color: widget.bg, child: const Center(child: CircularProgressIndicator()));
        final lines = snap.data![0] as List;
        final meta = (snap.data![1] as List<MushafMeta>)[widget.page - 1];
        final firstSurah = meta.ranges.isEmpty ? 1 : meta.ranges.first[0];
        return Container(
          color: widget.bg,
          padding: EdgeInsets.fromLTRB(14, mq.padding.top + 8, 14, mq.padding.bottom + 6),
          child: Column(children: [
            Row(children: [
              Text('الجزء ${_ord[meta.juz - 1]}', style: TextStyle(fontSize: 14, color: gold, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_name(firstSurah), style: TextStyle(fontSize: 14, color: gold, fontWeight: FontWeight.w700)),
            ]),
            Expanded(
              child: FutureBuilder<bool>(
                future: _font,
                builder: (context, fs) {
                  if (fs.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                  if (fs.data != true) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.cloud_off_outlined, size: 40, color: p.on2),
                        const SizedBox(height: 10),
                        Text('تعذّر تحميل خط الصفحة ${nf(widget.page)}', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('يلزم الاتصال بالإنترنت مرة واحدة لتحميل الصفحة', style: TextStyle(color: p.on2, fontSize: 12)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: () => setState(() => _font = mushaf.ensureFont(widget.page)), child: const Text('إعادة المحاولة')),
                      ]),
                    );
                  }
                  return _Lines(page: widget.page, lines: lines, ink: ink, gold: gold, name: _name, bg: widget.bg);
                },
              ),
            ),
            SizedBox(
              height: 40,
              // الصفحات الفردية: الشارة يمين، الزوجية: يسار (كما في المصحف المطبوع)
              child: Row(textDirection: widget.page.isOdd ? TextDirection.rtl : TextDirection.ltr, children: [
                _PagePill(label: nf(widget.page), hizb: meta.hizbStart ? 'الحزب ${nf(meta.hizb)}' : null, gold: gold, ink: ink, bg: widget.bg),
                const Spacer(),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _PagePill extends StatelessWidget {
  final String label;
  final String? hizb;
  final Color gold, ink, bg;
  const _PagePill({required this.label, required this.gold, required this.ink, required this.bg, this.hizb});
  @override
  Widget build(BuildContext context) {
    Widget cell(String t, {bool wide = false}) => Container(
          padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 14, vertical: 4),
          decoration: BoxDecoration(color: Color.alphaBlend(gold.withValues(alpha: .16), bg), border: Border.all(color: gold.withValues(alpha: .7), width: 1)),
          child: Text(t, style: TextStyle(fontSize: 12.5, color: ink, fontWeight: FontWeight.w700)),
        );
    // كبسولة زخرفية: [رقم الصفحة | الحزب] بإطار مزدوج
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: gold, width: 1.2)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(mainAxisSize: MainAxisSize.min, textDirection: TextDirection.rtl, children: [
          if (hizb != null) cell(hizb!, wide: true),
          cell(label),
        ]),
      ),
    );
  }
}

/// بانر اسم السورة الزخرفي (إطار بيج بزهرتين جانبيتين وخرطوشة وسطى).
class _BannerPainter extends CustomPainter {
  final Color gold;
  final bool dark;
  _BannerPainter(this.gold, this.dark);
  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width, h = sz.height;
    final base = dark ? const Color(0xFF3A3326) : const Color(0xFFE6D8BC);
    final inner = dark ? const Color(0xFF2A251B) : const Color(0xFFF0E8DA);
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = gold;
    final outer = RRect.fromRectAndRadius(Rect.fromLTWH(1, 1, w - 2, h - 2), const Radius.circular(8));
    canvas.drawRRect(outer, Paint()..color = base);
    canvas.drawRRect(outer, line);
    canvas.drawRRect(outer.deflate(4), Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = gold.withValues(alpha: .6));
    // الخرطوشة الوسطى (مضلّعة الأطراف)
    final cw = w * .42, x0 = (w - cw) / 2, n = h * .22;
    final path = Path()
      ..moveTo(x0 - n, h / 2)
      ..lineTo(x0, 5)
      ..lineTo(x0 + cw, 5)
      ..lineTo(x0 + cw + n, h / 2)
      ..lineTo(x0 + cw, h - 5)
      ..lineTo(x0, h - 5)
      ..close();
    canvas.drawPath(path, Paint()..color = inner);
    canvas.drawPath(path, line);
    // زهرتان جانبيتان
    void flower(double cx) {
      final cy = h / 2;
      final r = h * .30;
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = inner.withValues(alpha: .85));
      canvas.drawCircle(Offset(cx, cy), r, line);
      for (var i = 0; i < 8; i++) {
        final a = i * 3.14159265 / 4;
        final c = Offset(cx + r * .52 * _cos(a), cy + r * .52 * _sin(a));
        canvas.drawOval(Rect.fromCenter(center: c, width: r * .5, height: r * .78), Paint()..style = PaintingStyle.stroke..strokeWidth = .9..color = gold);
      }
      canvas.drawCircle(Offset(cx, cy), r * .2, Paint()..color = gold.withValues(alpha: .8));
    }

    flower(w * .14);
    flower(w * .86);
  }

  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(covariant _BannerPainter o) => o.gold != gold || o.dark != dark;
}

/// أسطر الصفحة: كلمات موزّعة بالتساوي (ضبط الأسطر) والأسطر القصيرة تُوسَّط.
class _Lines extends StatelessWidget {
  final int page;
  final List lines;
  final Color ink, gold, bg;
  final String Function(int) name;
  const _Lines({required this.page, required this.lines, required this.ink, required this.gold, required this.name, required this.bg});

  double _natural(List words, double size) {
    final tp = TextPainter(
      text: TextSpan(text: words.map((w) => (w as List)[0] as String).join(), style: TextStyle(fontFamily: mushafFamily(page), fontSize: size)),
      textDirection: TextDirection.rtl,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final wordLines = [for (final l in lines) if (l is List && l.isNotEmpty && l.first is List) l];
      final unit = h / 15.4; // ارتفاع السطر المعياري
      var widest = 1.0;
      for (final l in wordLines) {
        widest = widest < _natural(l, 100) ? _natural(l, 100) : widest;
      }
      final size = (w / widest * 100).clamp(10.0, unit * .88);
      final rows = <Widget>[];
      for (final l in lines) {
        final list = l as List;
        if (list.isNotEmpty && list.first == 'h') {
          rows.add(Container(
            height: unit * 1.45,
            margin: EdgeInsets.symmetric(vertical: unit * .1),
            child: CustomPaint(
              painter: _BannerPainter(gold, Pal.darkNow),
              child: Center(child: Text('سُورَةُ ${name((list[1] as num).toInt())}', style: TextStyle(fontFamily: arabicFont, fontSize: unit * .66, color: ink, fontWeight: FontWeight.w700))),
            ),
          ));
        } else if (list.isNotEmpty && list.first == 'b') {
          rows.add(SizedBox(height: unit * 1.05, child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', style: TextStyle(fontFamily: quranFont, fontSize: unit * .62, color: ink))))));
        } else {
          final nat = _natural(list, size);
          final target = widest * size / 100;
          final full = nat >= target * .9;
          final tstyle = TextStyle(fontFamily: mushafFamily(page), fontSize: size, color: ink, height: 1.0);
          rows.add(SizedBox(
            height: unit,
            child: Center(
              child: SizedBox(
                width: full ? target : null,
                child: Row(
                  mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: full ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                  children: [for (final wd in list) Text((wd as List)[0] as String, style: tstyle, textDirection: TextDirection.rtl)],
                ),
              ),
            ),
          ));
        }
      }
      final single = page <= 2;
      return single
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: rows))
          : Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: rows);
    });
  }
}
