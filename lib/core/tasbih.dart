import 'store.dart';
import 'util.dart';

const tasbihDefaults = [
  ['subhanh', 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 100],
  ['subhan', 'سُبْحَانَ اللَّهِ', 33],
  ['hamd', 'الْحَمْدُ لِلَّهِ', 33],
  ['akbar', 'اللَّهُ أَكْبَرُ', 34],
  ['istighfar', 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ', 100],
  ['tahlil', 'لَا إِلَهَ إِلَّا اللَّهُ', 100],
  ['salawat', 'اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ وَسَلِّمْ', 100],
];

Map<String, dynamic> tasbihDefault() => {
      'items': [for (final x in tasbihDefaults) {'id': x[0], 'text': x[1], 'goal': x[2]}],
      'cur': 'subhan', 'n': {}, 'total': {}, 'rounds': {}, 'day': {},
    };

Map<String, dynamic> tasbihState() {
  final v = store.get('tasbih');
  return v is Map ? Map<String, dynamic>.from(v) : tasbihDefault();
}

Map<String, dynamic> tasbihPeek() {
  final v = store.peek('tasbih');
  return v is Map<String, dynamic> ? v : tasbihDefault();
}

void tasbihUpdate(void Function(Map<String, dynamic>) fn, {bool quiet = false}) {
  final t = tasbihState();
  fn(t);
  store.set('tasbih', t, quiet: quiet);
}

int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

int tasbihDaySum(dynamic ids, [String? date]) {
  final d = ((tasbihPeek()['day'] as Map?)?[date ?? todayKey()] as Map?) ?? {};
  if (ids == 'all') return d.values.fold<int>(0, (a, b) => a + _i(b));
  return (ids as List).fold<int>(0, (a, k) => a + _i(d[k]));
}

/// لمسة واحدة على حالة موجودة في الذاكرة (بدون قراءة/كتابة تخزين). يرجع true عند اكتمال الجولة.
bool tasbihTapIn(Map<String, dynamic> t, String id, int goal) {
  final n = t['n'] as Map, total = t['total'] as Map, rounds = t['rounds'] as Map;
  final day = t['day'] as Map;
  final nn = _i(n[id]) + 1;
  total[id] = _i(total[id]) + 1;
  day[todayKey()] ??= <String, dynamic>{};
  final dd = day[todayKey()] as Map;
  dd[id] = _i(dd[id]) + 1;
  if (nn >= goal) {
    n[id] = 0;
    rounds[id] = _i(rounds[id]) + 1;
    return true;
  }
  n[id] = nn;
  return false;
}

/// ينفّذ لمسة واحدة ويحفظها. يرجع true إذا اكتملت الجولة.
bool tasbihTap(String id, int goal) {
  var done = false;
  tasbihUpdate((t) => done = tasbihTapIn(t, id, goal), quiet: true);
  return done;
}
