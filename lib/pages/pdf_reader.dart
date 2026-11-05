import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// قارئ الكتب (PDF) داخل التطبيق: يُنزِّل الكتاب مرة واحدة ويحفظه على الجهاز ثم يعرضه
/// (فيعمل دون إنترنت في المرات التالية)، بنفس لغة تصميم دُرَر مع وضع قراءة ليلي.
class PdfReaderPage extends StatefulWidget {
  final String url, title;
  const PdfReaderPage({super.key, required this.url, required this.title});
  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  final ValueNotifier<double?> _prog = ValueNotifier(0);
  final PdfViewerController _ctl = PdfViewerController();
  late Future<File> _file = _fetch();
  int _page = 1, _total = 0;
  bool _night = false;

  String get _name => 'b${widget.url.hashCode.toUnsigned(32).toRadixString(16)}.pdf';
  String get _pageKey => 'pdfp_${widget.url.hashCode.toUnsigned(32).toRadixString(16)}';

  @override
  void initState() {
    super.initState();
    _night = Pal.darkNow;
  }

  @override
  void dispose() {
    _prog.dispose();
    super.dispose();
  }

  Future<File> _fetch() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/books');
    if (!await dir.exists()) await dir.create(recursive: true);
    final f = File('${dir.path}/$_name');
    if (await f.exists() && await f.length() > 2000) return f;
    final req = http.Request('GET', Uri.parse(widget.url.replaceFirst('http://', 'https://')));
    final client = http.Client();
    try {
      final res = await client.send(req).timeout(const Duration(seconds: 40));
      if (res.statusCode != 200) throw Exception('http ${res.statusCode}');
      final part = File('${f.path}.part');
      final sink = part.openWrite();
      var got = 0;
      final total = res.contentLength ?? 0;
      await for (final c in res.stream) {
        sink.add(c);
        got += c.length;
        _prog.value = total > 0 ? got / total : null;
      }
      await sink.close();
      await part.rename(f.path);
      return f;
    } finally {
      client.close();
    }
  }

  void _retry() => setState(() {
        _prog.value = 0;
        _file = _fetch();
      });

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, mq.padding.top + 10, 16, 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.35)),
                if (_total > 0) Text('صفحة ${nf(_page)} من ${nf(_total)}', style: TextStyle(fontSize: 12, color: p.on2)),
              ]),
            ),
            RoundIconButton(_night ? Icons.light_mode_outlined : Icons.dark_mode_outlined, () => setState(() => _night = !_night), tooltip: 'وضع القراءة'),
            RoundIconButton(Icons.share_outlined, () => Share.share('${widget.title}\n${widget.url}'), tooltip: 'مشاركة'),
            RoundIconButton(Icons.arrow_forward, () => Navigator.of(context).maybePop(), tooltip: 'رجوع'),
          ]),
        ),
        if (_total > 1) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Bar((_page / _total).clamp(0.0, 1.0).toDouble(), track: p.surf2)),
        Expanded(
          child: FutureBuilder<File>(
            future: _file,
            builder: (context, s) {
              if (s.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.cloud_off_outlined, size: 44, color: p.on2),
                      const SizedBox(height: 10),
                      const Text('تعذّر تحميل الكتاب', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Sub('تأكد من الإنترنت. يلزم الاتصال مرة واحدة فقط ثم يُحفظ الكتاب للقراءة دون إنترنت.', align: TextAlign.center),
                      const SizedBox(height: 14),
                      FilledButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                    ]),
                  ),
                );
              }
              if (s.connectionState != ConnectionState.done) {
                return Center(
                  child: ValueListenableBuilder<double?>(
                    valueListenable: _prog,
                    builder: (_, v, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: v == 0 ? null : v, strokeWidth: 5)),
                      const SizedBox(height: 14),
                      Text(v == null || v == 0 ? 'جارٍ تحميل الكتاب…' : 'جارٍ التحميل ${nf((v * 100).round())}٪', style: TextStyle(color: p.on2, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                );
              }
              final start = ((store.peekMap('quran', {})[_pageKey] as num?) ?? 1).toInt();
              Widget viewer = PdfViewer.file(
                s.data!.path,
                controller: _ctl,
                initialPageNumber: start < 1 ? 1 : start,
                params: PdfViewerParams(
                  backgroundColor: p.surf2,
                  margin: 8,
                  onViewerReady: (doc, c) {
                    if (mounted) setState(() => _total = doc.pages.length);
                  },
                  onPageChanged: (n) {
                    if (n == null || !mounted) return;
                    setState(() => _page = n);
                    store.upd('quran', {'fav': [], 'marks': [], 'hl': {}, 'last': 1, 'pagesRead': {}}, (q) => q[_pageKey] = n, quiet: true);
                  },
                ),
              );
              if (_night) {
                // عكس الألوان لقراءة مريحة ليلًا
                viewer = ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]),
                  child: viewer,
                );
              }
              return ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), child: viewer);
            },
          ),
        ),
      ]),
    );
  }
}
