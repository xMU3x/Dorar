import 'azkar.dart';
import 'data.dart';
import 'store.dart';
import 'tasbih.dart';
import 'util.dart';

const chalCats = {
  'quran': ['القرآن'], 'dhikr': ['ذكر'], 'prayer': ['صلاة'], 'good': ['أعمال خير'],
  'manners': ['أخلاق'], 'habits': ['عادات يومية'], 'self': ['تطوير النفس'], 'worship': ['عبادة'],
};
const periodPoints = {'day': 10, 'week': 30, 'month': 100};
const periodName = {'day': 'تحديات اليوم', 'week': 'تحديات الأسبوع', 'month': 'أهداف الشهر'};

/// بداية الأسبوع: السبت.
DateTime weekStart(DateTime d) {
  final x = DateTime(d.year, d.month, d.day, 12);
  return DateTime(x.year, x.month, x.day - ((jsDay(x) + 1) % 7), 12);
}

String periodKey(String p, [DateTime? d]) {
  d ??= DateTime.now();
  if (p == 'day') return dkey(d);
  if (p == 'week') return 'w${dkey(weekStart(d))}';
  return 'm${dkey(d).substring(0, 7)}';
}

List<String> periodDays(String p, [DateTime? d]) {
  final t = DateTime(d?.year ?? DateTime.now().year, d?.month ?? DateTime.now().month, d?.day ?? DateTime.now().day, 12);
  if (p == 'day') return [dkey(t)];
  if (p == 'week') {
    final s = weekStart(t);
    return [for (var i = 0; i < 7; i++) dkey(DateTime(s.year, s.month, s.day + i, 12))];
  }
  final out = <String>[];
  var x = DateTime(t.year, t.month, 1, 12);
  while (x.month == t.month) {
    out.add(dkey(x));
    x = DateTime(x.year, x.month, x.day + 1, 12);
  }
  return out;
}

/// اختيار مُبذَّر ثابت لكل فترة (مطابق لخوارزمية تطبيق الويب).
List<T> seededPick<T>(List<T> arr, String seed, int n) {
  var s = 0;
  for (final c in seed.runes) {
    s = (s * 31 + c) & 0xFFFFFFFF;
  }
  final a = List<T>.of(arr);
  for (var i = a.length - 1; i > 0; i--) {
    s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
    final j = s % (i + 1);
    final t = a[i];
    a[i] = a[j];
    a[j] = t;
  }
  return a.take(n).toList();
}

class ChalItem {
  final Map<String, dynamic> c;
  final int? v;
  final int t;
  final bool ok;
  ChalItem(this.c, this.v, this.t, this.ok);
}

const _tmap = {
  'subhan': ['subhan', 'subhanh'], 'hamd': ['hamd'], 'akbar': ['akbar'],
  'istighfar': ['istighfar'], 'tahlil': ['tahlil'], 'salawat': ['salawat'],
};
const _zmap = {'morning': 'hisn-27', 'evening': 'hisn-27e', 'sleep': 'hisn-28'};

Map<String, dynamic> chalState() => store.peekMap('challenges', {'done': {}});

Future<int?> _autoVal(Map<String, dynamic> c, String p) async {
  final auto = c['auto'] as String?;
  if (auto == null) return null;
  final days = periodDays(p);
  if (auto == 'pages') {
    final pr = (quranState()['pagesRead'] as Map?) ?? {};
    return days.fold<int>(0, (a, d) => a + ((pr[d] as num?)?.toInt() ?? 0));
  }
  if (auto.startsWith('tasbeeh:')) {
    final key = auto.substring(8);
    final ids = key == 'all' ? 'all' : _tmap[key];
    if (ids == null) return 0;
    return days.fold<int>(0, (a, d) => a + tasbihDaySum(ids, d));
  }
  if (auto.startsWith('azkar:')) {
    final id = _zmap[auto.substring(6)];
    final cat = (await data.categories()).where((x) => x['id'] == id).firstOrNull;
    if (cat == null || id == null) return 0;
    final list = (cat['azkar'] as List).cast<Map<String, dynamic>>();
    return days.where((d) => list.every((z) => zikrCount(id, z['id'] as int, d) >= ((z['count'] as num?)?.toInt() ?? 1))).length;
  }
  return null;
}

Future<List<Map<String, dynamic>>> chalPick(String p) async {
  final all = (await data.challenges()).where((c) => c['period'] == p).toList();
  return seededPick(all, periodKey(p), p == 'day' ? 5 : p == 'week' ? 3 : 2);
}

Future<List<ChalItem>> chalStateFor(String p) async {
  final done = (chalState()['done'] as Map?) ?? {};
  final pk = periodKey(p);
  final out = <ChalItem>[];
  for (final c in await chalPick(p)) {
    final v = await _autoVal(c, p);
    final t = (c['target'] as num?)?.toInt() ?? 1;
    out.add(ChalItem(c, v, t, done['${c['id']}:$pk'] != null || (v != null && v >= t)));
  }
  return out;
}

Future<({int done, int total})> chalToday() async {
  final s = await chalStateFor('day');
  return (done: s.where((x) => x.ok).length, total: s.length);
}

/// يثبّت إنجاز التحديات التلقائية. يرجع عدد المنجز حديثًا.
Future<int> chalCheck() async {
  var got = 0;
  for (final p in ['day', 'week', 'month']) {
    final s = await chalStateFor(p);
    final pk = periodKey(p);
    for (final x in s) {
      final key = '${x.c['id']}:$pk';
      if (x.ok && ((chalState()['done'] as Map?) ?? {})[key] == null) {
        store.upd('challenges', {'done': {}}, (z) {
          z['done'] ??= {};
          (z['done'] as Map)[key] = DateTime.now().millisecondsSinceEpoch;
        });
        got++;
      }
    }
  }
  return got;
}

void chalToggle(String key) => store.upd('challenges', {'done': {}}, (z) {
      z['done'] ??= {};
      final d = z['done'] as Map;
      d.containsKey(key) ? d.remove(key) : d[key] = DateTime.now().millisecondsSinceEpoch;
    });

({int n, int pts}) chalTotal() {
  final d = ((chalState()['done'] as Map?) ?? {});
  var pts = 0;
  for (final k in d.keys) {
    final pk = (k as String).split(':').last;
    pts += pk.startsWith('w') ? 30 : pk.startsWith('m') ? 100 : 10;
  }
  return (n: d.length, pts: pts);
}

List<(String, bool)> achievements(({int n, int pts}) tot, ({int cur, int best}) st) {
  final pr = (quranState()['pagesRead'] as Map?) ?? {};
  final pages = pr.values.fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0));
  final tasb = ((tasbihPeek()['total'] as Map?) ?? {}).values.fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0));
  return [
    ('إنجاز ١٠ تحديات', tot.n >= 10), ('إنجاز ٥٠ تحديًا', tot.n >= 50), ('إنجاز ١٠٠ تحدٍّ', tot.n >= 100),
    ('نشاط ٣ أيام متتالية', st.best >= 3), ('نشاط ٧ أيام متتالية', st.best >= 7), ('نشاط ٣٠ يومًا متتالية', st.best >= 30),
    ('قراءة ١٠٠ صفحة', pages >= 100), ('١٠٠٠ تسبيحة', tasb >= 1000),
  ];
}
