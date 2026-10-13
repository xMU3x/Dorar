import 'hijri_util.dart';
import 'store.dart';
import 'util.dart';

const ruleDefaults = {'mt': true, 'bid': true, 'ashura': true, 'arafah': true, 'dhul': true, 'shawwal': true};
const ruleLabels = [
  ['mt', 'الاثنين والخميس'], ['bid', 'الأيام البيض (١٣–١٥ من كل شهر)'], ['ashura', 'تاسوعاء وعاشوراء'],
  ['arafah', 'يوم عرفة'], ['dhul', 'التسع الأوائل من ذي الحجة'], ['shawwal', 'ست من شوّال'],
];
const kindLabels = {'fard': 'صيام فرض', 'sunna': 'صيام مستحب', 'bid': 'الأيام البيض', 'eid': 'يُمنع صيامه', 'custom': 'أيامي', 'mt': 'اثنين وخميس'};

class FastTag {
  final String k, kind, t, note;
  FastTag(this.k, this.kind, this.t, this.note);
}

class FastInfo {
  final Hj h;
  final DateTime date;
  final List<FastTag> tags;
  final String main;
  final bool eid, fast, done;
  FastInfo(this.h, this.date, this.tags, this.main, this.eid, this.fast, this.done);
}

class FastState {
  Map<String, dynamic> rules;
  List<Map<String, dynamic>> custom;
  Map<String, dynamic> done;
  FastState(this.rules, this.custom, this.done);
}

FastState fastState() {
  final f = store.peekMap('fast');
  return FastState(
    {...ruleDefaults, ...Map<String, dynamic>.from((f['rules'] as Map?) ?? {})},
    [for (final c in (f['custom'] as List?) ?? []) Map<String, dynamic>.from(c as Map)],
    Map<String, dynamic>.from((f['done'] as Map?) ?? {}),
  );
}

void fastUpdate(void Function(FastState) fn) {
  final s = fastState();
  fn(s);
  store.set('fast', {'rules': s.rules, 'custom': s.custom, 'done': s.done});
}

FastInfo fastInfo(DateTime date, [FastState? st]) {
  final F = st ?? fastState();
  final R = F.rules;
  final h = hj(date);
  final dw = jsDay(noon(date));
  final key = dkey(date);
  final isDh = h.m == 12;
  final tags = <FastTag>[];
  void add(String k, String kind, String t, String note) => tags.add(FastTag(k, kind, t, note));
  if (h.m == 9) add('ram', 'fard', 'يوم من رمضان', 'صيام واجب على كل مسلم بالغ قادر');
  if (h.m == 10 && h.d == 1) add('fitr', 'eid', 'عيد الفطر', 'يحرم صيام هذا اليوم');
  if (isDh && h.d == 10) add('adha', 'eid', 'عيد الأضحى', 'يحرم صيام هذا اليوم');
  if (isDh && h.d >= 11 && h.d <= 13) add('tashreeq', 'eid', 'أيام التشريق', 'نُهي عن صيامها إلا لمن لم يجد الهدي');
  if (R['ashura'] == true && h.m == 1 && (h.d == 9 || h.d == 10)) {
    add('ashura', 'sunna', h.d == 10 ? 'يوم عاشوراء' : 'تاسوعاء', 'صيام عاشوراء يكفّر السنة الماضية، ويُستحب صيام يوم قبله');
  }
  if (R['arafah'] == true && isDh && h.d == 9) add('arafah', 'sunna', 'يوم عرفة', 'يكفّر السنة الماضية والباقية لغير الحاج');
  if (R['dhul'] == true && isDh && h.d >= 1 && h.d <= 8) add('dhul', 'sunna', 'من عشر ذي الحجة', 'العمل الصالح فيها أحب إلى الله، ويُستحب الصيام');
  if (R['shawwal'] == true && h.m == 10 && h.d >= 2 && h.d <= 7) add('shawwal', 'sunna', 'من ست شوّال', 'من صام رمضان ثم أتبعه ستًّا من شوال كان كصيام الدهر');
  if (R['bid'] == true && h.m != 9 && h.d >= 13 && h.d <= 15 && !(isDh && h.d == 13)) add('bid', 'bid', 'من الأيام البيض', 'صيام ثلاثة أيام من كل شهر: ١٣ و١٤ و١٥');
  final mt = R['mt'] == true && (dw == 1 || dw == 4) && !tags.any((t) => t.kind == 'eid' || t.kind == 'fard');
  if (mt) add('mt', 'mt', dw == 1 ? 'صيام الاثنين' : 'صيام الخميس', 'تُعرض الأعمال يومي الاثنين والخميس');
  final custom = F.custom.where((c) {
    if (c['on'] == false) return false;
    switch (c['type']) {
      case 'once': return c['date'] == key;
      case 'week': return ((c['wd'] as List?) ?? []).contains(dw);
      case 'month': return (c['hd'] as num?)?.toInt() == h.d;
      case 'year': return (c['hm'] as num?)?.toInt() == h.m && (c['hd'] as num?)?.toInt() == h.d;
    }
    return false;
  }).toList();
  for (final c in custom) {
    add('c${c['id']}', 'custom', (c['title'] as String?)?.isNotEmpty == true ? c['title'] as String : 'يوم صيام', 'يوم أضفته أنت');
  }
  final eid = tags.any((t) => t.kind == 'eid');
  final fard = tags.any((t) => t.kind == 'fard');
  final main = eid ? 'eid' : fard ? 'fard' : tags.any((t) => t.kind == 'sunna') ? 'sunna' : tags.any((t) => t.kind == 'bid') ? 'bid' : custom.isNotEmpty ? 'custom' : mt ? 'mt' : '';
  return FastInfo(h, date, tags, main, eid, !eid && tags.isNotEmpty, F.done[key] != null);
}

bool isFastDay(DateTime d) => fastInfo(d).fast;

({FastInfo info, int inDays})? nextFast([DateTime? from, int n = 60]) {
  from ??= DateTime.now();
  final st = fastState();
  for (var i = 0; i < n; i++) {
    final d = addDays(from, i);
    final f = fastInfo(d, st);
    if (f.fast && !(i == 0 && f.done)) return (info: f, inDays: i);
  }
  return null;
}

/// نسبة التقدّم نحو يوم الصيام القادم: (الأيام المنقضية منذ آخر صيام) ÷ (المدة بين آخر صيام والقادم).
/// - يُبحث عن آخر يوم صيام حتى ١٤ يومًا للخلف؛ إن لم يوجد تُعتبر المدة ٧ أيام على الأقل.
/// - اليوم نفسه = ١٠٠٪، والنتيجة محصورة بين ٠ و١.
double fastProgress(int inDays) {
  if (inDays <= 0) return 1;
  final st = fastState();
  final now = DateTime.now();
  var back = 1;
  while (back <= 14 && !fastInfo(addDays(now, -back), st).fast) {
    back++;
  }
  final span = back > 14 ? (inDays < 7 ? 7 : inDays) : back + inDays;
  final elapsed = span - inDays;
  return (elapsed / span).clamp(0.0, 1.0).toDouble();
}

class Season {
  final String k, name;
  final DateTime st, en;
  final int d1, d2;
  Season(this.k, this.name, this.st, this.en, this.d1, this.d2);
}

String? _seasonsKey;
List<Season> _seasonsCache = const [];

List<Season> seasons() {
  final today = noon(DateTime.now());
  final ck = '${dkey(today)}|${cfg.get('hijriAdj')}';
  if (_seasonsKey == ck) return _seasonsCache;
  final h = hj(today);
  final out = <Season>[];
  const S = [
    ['ramadan', 'شهر رمضان', 9, 1, 0], ['last10', 'العشر الأواخر وليلة القدر', 9, 21, 0], ['fitr', 'عيد الفطر', 10, 1, 1],
    ['six', 'ست من شوّال', 10, 2, 0], ['dhul', 'عشر ذي الحجة', 12, 1, 10], ['arafah', 'يوم عرفة', 12, 9, 9],
    ['adha', 'عيد الأضحى', 12, 10, 10], ['ashura', 'تاسوعاء وعاشوراء', 1, 9, 10], ['shaban', 'شهر شعبان', 8, 1, 0],
  ];
  for (final y in [h.y, h.y + 1]) {
    for (final s in S) {
      final m = s[2] as int, d1 = s[3] as int, d2 = s[4] as int;
      final M = hmonth(y, m);
      if (M.days.isEmpty) continue;
      final e = d2 != 0 ? d2 : M.len;
      final st = d1 - 1 < M.days.length ? M.days[d1 - 1] : null;
      final en = M.days[(e < M.len ? e : M.len) - 1];
      if (st == null || en.isBefore(today)) continue;
      out.add(Season(s[0] as String, s[1] as String, st, en, d1, e < M.len ? e : M.len));
    }
  }
  for (var i = 0; i < 2; i++) {
    final m0 = h.m + i;
    final y = h.y + (m0 > 12 ? 1 : 0);
    final m = ((m0 - 1) % 12) + 1;
    if (m == 9) continue;
    final M = hmonth(y, m);
    if (M.days.length >= 15 && !M.days[14].isBefore(today)) {
      out.add(Season('bid', 'الأيام البيض', M.days[12], M.days[14], 13, 15));
      break;
    }
  }
  out.sort((a, b) => a.st.compareTo(b.st));
  _seasonsKey = ck;
  return _seasonsCache = out.take(6).toList();
}
