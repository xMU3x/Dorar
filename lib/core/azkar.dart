import 'data.dart';
import 'store.dart';
import 'util.dart';

Map<String, dynamic> azkarState() => store.peekMap('azkar', {'fav': [], 'c': {}});

int zikrCount(String cat, int zid, [String? date]) {
  final c = (azkarState()['c'] as Map?) ?? {};
  final v = (((c[date ?? todayKey()] as Map?)?[cat] as Map?)?['$zid'] as num?)?.toInt();
  return v ?? 0;
}

void zikrSet(String cat, int zid, int v) => store.upd('azkar', {'fav': [], 'c': {}}, (a) {
      a['c'] ??= {};
      final c = a['c'] as Map;
      c[todayKey()] ??= <String, dynamic>{};
      final day = c[todayKey()] as Map;
      day[cat] ??= <String, dynamic>{};
      (day[cat] as Map)['$zid'] = v < 0 ? 0 : v;
    });

void zikrResetCat(String cat) => store.upd('azkar', {'fav': [], 'c': {}}, (a) {
      ((a['c'] as Map?)?[todayKey()] as Map?)?.remove(cat);
    });

bool zikrIsFav(String key) => ((azkarState()['fav'] as List?) ?? []).contains(key);
void zikrToggleFav(String key) => store.upd('azkar', {'fav': [], 'c': {}}, (a) {
      final f = List<dynamic>.from((a['fav'] as List?) ?? []);
      f.contains(key) ? f.remove(key) : f.add(key);
      a['fav'] = f;
    });

Future<({int done, int total})> azkarProgress(String catId) async {
  final cats = await data.categories();
  final c = cats.where((x) => x['id'] == catId).firstOrNull;
  if (c == null) return (done: 0, total: 0);
  var d = 0;
  final list = (c['azkar'] as List).cast<Map<String, dynamic>>();
  for (final z in list) {
    if (zikrCount(catId, z['id'] as int) >= ((z['count'] as num?)?.toInt() ?? 1)) d++;
  }
  return (done: d, total: list.length);
}
