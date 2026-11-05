import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'store.dart';
import 'util.dart';

/// بيانات القرآن والأذكار والتحديات من ملفات المشروع الأصلية (assets/data).
Map<String, dynamic> _decode(String s) => jsonDecode(s) as Map<String, dynamic>;

class Data {
  Future<Map<String, dynamic>> _load(String n) async {
    final raw = await rootBundle.loadString('assets/data/$n.json');
    // ملفات كبيرة (القرآن ≈ 1.5MB): فك الترميز في isolate حتى لا تتجمّد الواجهة
    return compute(_decode, raw);
  }

  // نفس كائن الـ Future يُعاد في كل مرة حتى لا تعيد FutureBuilder بناء الواجهة من الصفر
  Future<List<Map<String, dynamic>>>? _catsF;
  Future<Map<String, dynamic>>? _quranF;
  Future<List<Map<String, dynamic>>>? _chalF;
  Future<List>? _ayahsF, _surahsF;

  Future<List<Map<String, dynamic>>> categories() => _catsF ??= _load('azkar').then((m) => (m['categories'] as List).cast<Map<String, dynamic>>());
  Future<Map<String, dynamic>> quran() => _quranF ??= _load('quran');
  Future<List<Map<String, dynamic>>> challenges() => _chalF ??= _load('challenges').then((m) => (m['challenges'] as List).cast<Map<String, dynamic>>());

  /// آية: [surah, ayah, text, juz, page, hizbQuarter, sajda]
  Future<List> ayahs() => _ayahsF ??= quran().then((q) => q['ayahs'] as List);
  Future<List> surahs() => _surahsF ??= quran().then((q) => q['surahs'] as List);
  Future<String> surahName(int n) async => ((await surahs())[n - 1][1] as String).replaceFirst(RegExp(r'^سُورَةُ\s*'), '');
}

final Data data = Data();

// ---------- النشاط والسلسلة ----------
void touchActivity() {
  // يكفي تسجيل اليوم مرة واحدة (السلسلة تعتمد على وجود اليوم فقط) — يتجنّب كتابة التخزين عند كل لمسة
  final days = store.peekMap('activity')['days'];
  if (days is Map && days[todayKey()] != null) return;
  store.upd('activity', {'days': {}}, (a) {
    a['days'] ??= {};
    final d = a['days'] as Map;
    d[todayKey()] = ((d[todayKey()] as num?) ?? 0) + 1;
  });
}

({int cur, int best}) streak() {
  final a = store.peekMap('activity', {'days': {}});
  final days = (a['days'] as Map?) ?? {};
  var d = DateTime.now();
  var n = 0;
  if (days[dkey(d)] == null) d = d.subtract(const Duration(days: 1));
  while (days[dkey(d)] != null) {
    n++;
    d = d.subtract(const Duration(days: 1));
  }
  final b = ((a['best'] as num?) ?? 0).toInt();
  return (cur: n, best: n > b ? n : b);
}

Map<String, dynamic> quranState() => store.peekMap('quran', {'fav': [], 'marks': [], 'hl': {}, 'last': 1, 'pagesRead': {}});
int pagesToday() => (((quranState()['pagesRead'] as Map?) ?? {})[todayKey()] as num?)?.toInt() ?? 0;
void addPages(int n) {
  store.upd('quran', {}, (q) {
    q['pagesRead'] ??= {};
    final p = q['pagesRead'] as Map;
    final cur = (p[todayKey()] as num?)?.toInt() ?? 0;
    p[todayKey()] = (cur + n) < 0 ? 0 : cur + n;
  });
  touchActivity();
}
