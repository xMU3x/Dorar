import 'data.dart';

/// فهرس سريع للمصحف: أول آية لكل جزء/صفحة وحدود كل سورة (يُبنى مرة واحدة من assets/data/quran.json).
class QIndex {
  final Map<int, (int, int)> pageStart = {}; // صفحة ← (سورة، آية)
  final Map<int, (int, int)> juzStart = {};
  final Map<int, int> juzEndSurah = {};
  final Map<int, int> surahFirstPage = {}, surahLastPage = {}, surahJuz = {};
  /// أرقام آيات كل سورة بصفحاتها: surah ← قائمة صفحات الآيات.
  final Map<int, List<int>> ayahPages = {};
}

Future<QIndex>? _qf;
Future<QIndex> qIndex() => _qf ??= data.ayahs().then((ays) {
      final q = QIndex();
      for (final a in ays) {
        final l = a as List;
        final s = l[0] as int, ay = l[1] as int, j = l[3] as int, pg = l[4] as int;
        q.pageStart.putIfAbsent(pg, () => (s, ay));
        q.juzStart.putIfAbsent(j, () => (s, ay));
        q.juzEndSurah[j] = s;
        q.surahFirstPage.putIfAbsent(s, () => pg);
        q.surahLastPage[s] = pg;
        q.surahJuz.putIfAbsent(s, () => j);
        (q.ayahPages[s] ??= []).add(pg);
      }
      return q;
    });
