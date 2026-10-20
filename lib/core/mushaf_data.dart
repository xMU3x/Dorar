import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'store.dart';

/// مصحف المدينة بخطوط QCF2 (خط لكل صفحة). بيانات الصفحات مضمّنة في assets/mushaf،
/// والخطوط تُحمَّل عند الحاجة وتُحفظ على الجهاز (مثل تطبيق نور).
const _fontUrls = [
  'https://verses.quran.foundation/fonts/quran/hafs/v2/ttf/p%d.ttf',
  'https://verses.quran.foundation/fonts/quran/hafs/v2/woff2/p%d.woff2',
];

String mushafFamily(int p) => 'QCF2_P$p';

class MushafMeta {
  final int juz, hizb;
  final bool hizbStart;
  final List<List<int>> ranges; // [سورة، من آية، إلى آية]
  const MushafMeta(this.juz, this.hizb, this.hizbStart, this.ranges);
}

class MushafStore {
  final Map<int, List> _pages = {};
  final Set<int> _loaded = {};
  final Map<int, Future<bool>> _pending = {};
  List<MushafMeta>? _meta;
  Directory? _dir;
  bool cancel = false;

  /// عدد الصفحات المحفوظة على الجهاز.
  final ValueNotifier<int> cached = ValueNotifier(0);
  final ValueNotifier<bool> downloading = ValueNotifier(false);

  Future<Directory> _fontDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/qcf');
    if (!await d.exists()) await d.create(recursive: true);
    return _dir = d;
  }

  Future<void> refreshCount() async {
    try {
      final d = await _fontDir();
      var n = 0;
      await for (final f in d.list()) {
        if (f is File && f.path.contains('/p') && f.lengthSync() > 1000) n++;
      }
      cached.value = n;
    } catch (_) {}
  }

  Future<List<MushafMeta>> meta() async {
    if (_meta != null) return _meta!;
    final raw = jsonDecode(await rootBundle.loadString('assets/data/pages.json')) as List;
    _meta = [
      for (final e in raw)
        MushafMeta(
          ((e as List)[1] as num).toInt(),
          ((e[3] as List)[0] as num).toInt(),
          (e[3] as List)[1] == 1,
          [for (final r in (e[0] as List)) [for (final x in (r as List)) (x as num).toInt()]],
        ),
    ];
    return _meta!;
  }

  /// أسطر الصفحة: كل عنصر إمّا ["h", سورة] أو ["b"] أو قائمة كلمات [[رموز، "س:آ"], ...].
  Future<List> lines(int p) async {
    final hit = _pages[p];
    if (hit != null) return hit;
    final l = jsonDecode(await rootBundle.loadString('assets/mushaf/$p.json')) as List;
    if (_pages.length > 12) _pages.remove(_pages.keys.first);
    return _pages[p] = l;
  }

  Future<File> _file(int p, String ext) async => File('${(await _fontDir()).path}/p$p.$ext');

  /// يضمن تحميل خط الصفحة (من الجهاز أو الإنترنت). يعيد false عند الفشل.
  Future<bool> ensureFont(int p, {bool allowNet = true}) {
    if (_loaded.contains(p)) return Future.value(true);
    return _pending[p] ??= _ensure(p, allowNet).whenComplete(() => _pending.remove(p));
  }

  Future<bool> _ensure(int p, bool allowNet) async {
    try {
      Uint8List? bytes;
      for (final ext in ['ttf', 'woff2']) {
        final f = await _file(p, ext);
        if (await f.exists() && await f.length() > 1000) {
          bytes = await f.readAsBytes();
          break;
        }
      }
      if (bytes == null && allowNet) {
        for (var i = 0; i < _fontUrls.length && bytes == null; i++) {
          try {
            final r = await http.get(Uri.parse(_fontUrls[i].replaceFirst('%d', '$p'))).timeout(const Duration(seconds: 25));
            if (r.statusCode == 200 && r.bodyBytes.length > 1000) {
              bytes = r.bodyBytes;
              final f = await _file(p, i == 0 ? 'ttf' : 'woff2');
              await f.writeAsBytes(bytes, flush: true);
              cached.value = cached.value + 1;
            }
          } catch (_) {}
        }
      }
      if (bytes == null) return false;
      final loader = FontLoader(mushafFamily(p))..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      _loaded.add(p);
      return true;
    } catch (e) {
      debugPrint('mushaf font $p: $e');
      return false;
    }
  }

  /// تحميل كل الصفحات للقراءة دون إنترنت (٤ متوازية).
  Future<void> downloadAll() async {
    if (downloading.value) return;
    cancel = false;
    downloading.value = true;
    var next = 1;
    Future<void> worker() async {
      while (!cancel) {
        final p = next++;
        if (p > 604) return;
        await ensureFont(p);
      }
    }

    try {
      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    } finally {
      downloading.value = false;
      await refreshCount();
    }
  }
}

final MushafStore mushaf = MushafStore();

int lastMushafPage() => ((store.peekMap('quran', {})['mpage'] as num?) ?? 1).toInt().clamp(1, 604);

void setLastMushafPage(int p) => store.upd('quran', {'fav': [], 'marks': [], 'hl': {}, 'last': 1, 'pagesRead': {}}, (q) => q['mpage'] = p, quiet: true);

List<int> mushafBookmarks() => [for (final x in (store.peekMap('quran', {})['mbm'] as List?) ?? const []) (x as num).toInt()];

void toggleMushafBookmark(int p) => store.upd('quran', {'fav': [], 'marks': [], 'hl': {}, 'last': 1, 'pagesRead': {}}, (q) {
      final l = [for (final x in (q['mbm'] as List?) ?? const []) (x as num).toInt()];
      l.contains(p) ? l.remove(p) : l.add(p);
      q['mbm'] = l;
    });
