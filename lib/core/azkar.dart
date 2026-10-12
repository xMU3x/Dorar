import 'data.dart';
import 'tasks.dart';
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

/// الأقسام الأساسية المعروضة منفصلة، وكل ما عداها يذهب إلى «المزيد من الأذكار».
const kMorningCat = 'hisn-27', kEveningCat = 'hisn-27e';
bool isMainCat(String id) => id == kMorningCat || id == kEveningCat;

/// عنوان العرض: قسم الصباح في البيانات اسمه «الصباح والمساء» فنعرضه «أذكار الصباح».
String catTitle(Map<String, dynamic> c) => switch (c['id']) { kMorningCat => 'أذكار الصباح', kEveningCat => 'أذكار المساء', _ => c['title'] as String };

({int done, int total}) azkarProgressOf(Map<String, dynamic> c) {
  final id = c['id'] as String;
  final list = (c['azkar'] as List).cast<Map<String, dynamic>>();
  var d = 0;
  for (final z in list) {
    if (zikrCount(id, z['id'] as int) >= ((z['count'] as num?)?.toInt() ?? 1)) d++;
  }
  return (done: d, total: list.length);
}

Future<({int done, int total})> azkarProgress(String catId) async {
  final cats = await data.categories();
  final c = cats.where((x) => x['id'] == catId).firstOrNull;
  if (c == null) return (done: 0, total: 0);
  return azkarProgressOf(c);
}

/// عدد مرات إتمام القسم كاملًا اليوم («عدد مرات القراءة»).
int zikrReads(String cat) => ((((azkarState()['r'] as Map?)?[todayKey()] as Map?)?[cat] as num?)?.toInt()) ?? 0;

void zikrAddRead(String cat) => store.upd('azkar', {'fav': [], 'c': {}}, (a) {
      a['r'] ??= <String, dynamic>{};
      final r = a['r'] as Map;
      r[todayKey()] ??= <String, dynamic>{};
      final d = r[todayKey()] as Map;
      d[cat] = ((d[cat] as num?)?.toInt() ?? 0) + 1;
      if (r.length > 30) {
        final ks = r.keys.cast<String>().toList()..sort();
        for (final k in ks.take(r.length - 30)) {
          r.remove(k);
        }
      }
    });

/// تصفير كل أذكار اليوم (زر «تصفير» في إعدادات الأذكار).
void zikrResetAll() => store.upd('azkar', {'fav': [], 'c': {}}, (a) {
      (a['c'] as Map?)?.remove(todayKey());
      (a['r'] as Map?)?.remove(todayKey());
    });

/// عند إتمام الصباح/المساء تُسجَّل مهمة اليوم المقابلة تلقائيًا.
void zikrCatCompleted(String cat) {
  zikrAddRead(cat);
  if (cat == kMorningCat) taskSet('morning', true);
  if (cat == kEveningCat) taskSet('evening', true);
}

bool autoNextOn() => cfg.get('autoNext') != false;
bool doneSoundOn() => cfg.get('doneSound') != false;

// فضل الأذكار الأساسية (من حصن المسلم) — يظهر في الصندوق الملوّن تحت الذكر.
const _fadl = <int, String>{
  75: 'من قالها حين يصبح أجير من الجن حتى يمسي، ومن قالها حين يمسي أجير منهم حتى يصبح.',
  76: 'من قالها حين يصبح وحين يمسي كفته من كل شيء (الإخلاص والمعوذتين).',
  79: 'سيد الاستغفار: من قالها موقنًا بها حين يمسي فمات من ليلته دخل الجنة، ومن قالها موقنًا بها حين يصبح فمات من يومه دخل الجنة.',
  80: 'من قالها أربع مرات أعتقه الله من النار.',
  86: 'من قالها ثلاثًا حين يصبح وحين يمسي لم يضره شيء.',
  87: 'من قالها حين يصبح وحين يمسي كان حقًّا على الله أن يرضيه يوم القيامة.',
  91: 'من قالها حين يصبح وحين يمسي مائة مرة لم يأتِ أحد يوم القيامة بأفضل مما جاء به إلا أحد قال مثل ذلك أو زاد عليه.',
  92: 'من قالها عشر مرات كان كمن أعتق أربعة أنفس من ولد إسماعيل.',
  93: 'من قالها مائة مرة كانت له عدل عشر رقاب، وكُتبت له مائة حسنة، ومُحيت عنه مائة سيئة، وكانت له حرزًا من الشيطان يومه حتى يمسي.',
};
const _fadlSleep = <int, String>{
  100: 'من قرأها إذا أوى إلى فراشه لم يزل عليه من الله حافظ، ولا يقربه شيطان حتى يصبح.',
  101: 'من قرأ بالآيتين من آخر سورة البقرة في ليلة كفتاه.',
};

String? zikrFadl(String cat, int id) {
  if (cat == 'hisn-28') return _fadlSleep[id];
  if (cat == kMorningCat || cat == kEveningCat) {
    if (id == 97) return cat == kEveningCat ? 'من قالها ثلاث مرات حين يمسي لم تضره حُمَة تلك الليلة.' : null;
    return _fadl[id];
  }
  return null;
}
