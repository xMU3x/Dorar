import 'data.dart' show touchActivity;
import 'store.dart';
import 'util.dart';

/// مهام اليوم — تُحفظ داخل مفتاح المزامنة الموجود `activity` تحت `tk` (تاريخ ← {معرّف: 1})،
/// فلا حاجة لأي تغيير في جدول Supabase. يُحتفظ بآخر ٦٠ يومًا فقط.
class TaskDef {
  final String id, title;
  final String? hint, route;
  final bool bonus; // نوافل: لا تدخل في إجمالي التقدّم
  const TaskDef(this.id, this.title, {this.hint, this.route, this.bonus = false});
}

class TaskSection {
  final String id, title, icon;
  final List<TaskDef> tasks;
  /// معرّف الدفعة الواحدة («تسجيل كل الصلوات دفعة واحدة») + عنوانها
  final String? groupTitle, groupBtn;
  const TaskSection(this.id, this.title, this.icon, this.tasks, {this.groupTitle, this.groupBtn});
  bool get isGroup => groupTitle != null;
}

const taskSections = <TaskSection>[
  TaskSection('athkar', 'أذكار', 'spark', [
    TaskDef('morning', 'أذكار الصباح', route: 'zikr/hisn-27'),
    TaskDef('evening', 'أذكار المساء', route: 'zikr/hisn-27e'),
    TaskDef('salawat', 'الصلاة على النبي ﷺ'),
    TaskDef('istighfar', 'الاستغفار', hint: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ'),
  ]),
  TaskSection('quran', 'قرآن', 'book', [
    TaskDef('wird', 'ورد القرآن (حزب)'),
    TaskDef('baqara', 'سورة البقرة'),
    TaskDef('shifa', 'استشفاء (الفاتحة / المعوذتين / آية الكرسي)'),
    TaskDef('tilawa', 'تلاوة'),
    TaskDef('tadabbur', 'تدبر'),
    TaskDef('tafsir', 'تفسير'),
    TaskDef('hifz', 'حفظ'),
    TaskDef('sama', 'سماع'),
    TaskDef('amal', 'عَمَل'),
  ]),
  TaskSection('salah', 'صلاة', 'mosque', [
    TaskDef('fajr', 'الفجر'),
    TaskDef('dhuhr', 'الظهر'),
    TaskDef('asr', 'العصر'),
    TaskDef('maghrib', 'المغرب'),
    TaskDef('isha', 'العشاء'),
  ], groupTitle: 'الفروض', groupBtn: 'تسجيل كل الصلوات دفعة واحدة'),
  TaskSection('other', 'أخرى', 'star', [TaskDef('sadaqa', '💰 الصدقة')]),
  TaskSection('nawafil', 'النوافل', 'mosque', [
    TaskDef('duha', 'الضحى', bonus: true),
    TaskDef('qiyam', 'قيام الليل', bonus: true),
    TaskDef('rawatib', 'نوافل الفروض', bonus: true),
  ], groupTitle: 'النوافل', groupBtn: 'تسجيل كل النوافل دفعة واحدة'),
];

Iterable<TaskDef> get _all => taskSections.expand((s) => s.tasks);
final int kTasksTotal = _all.where((t) => !t.bonus).length;

Map _tk() => (store.peekMap('activity', {'days': {}})['tk'] as Map?) ?? const {};

bool taskDone(String id, [DateTime? d]) => (((_tk()[dkey(d ?? DateTime.now())]) as Map?)?[id] ?? 0) == 1;

void taskSet(String id, bool v, [DateTime? d]) {
  if (taskDone(id, d) == v) return;
  final key = dkey(d ?? DateTime.now());
  store.upd('activity', {'days': {}}, (a) {
    a['tk'] ??= <String, dynamic>{};
    final m = a['tk'] as Map;
    m[key] ??= <String, dynamic>{};
    (m[key] as Map)[id] = v ? 1 : 0;
    if (m.length > 60) {
      final keys = m.keys.cast<String>().toList()..sort();
      for (final k in keys.take(m.length - 60)) {
        m.remove(k);
      }
    }
  });
  if (v) touchActivity();
}

void taskSetMany(Iterable<String> ids, bool v) {
  for (final id in ids) {
    taskSet(id, v);
  }
}

int tasksDone([DateTime? d]) => _all.where((t) => !t.bonus && taskDone(t.id, d)).length;
double tasksFraction() => kTasksTotal == 0 ? 0 : tasksDone() / kTasksTotal;

// ======================= مهام وعادات المستخدم =======================
/// تُحفظ داخل `activity.ct` كخريطة {معرّف: بيانات} (حذف ناعم عبر del=1 حتى لا تعود عند الدمج).
class CustomTask {
  final String id, title, time, rp, cat;
  final bool imp;
  final int wd;
  final String? date;
  const CustomTask(this.id, this.title, this.time, this.rp, this.cat, this.imp, this.wd, this.date);
  bool get isHabit => rp == 'daily' || rp == 'weekly';
}

Map _ct() => (store.peekMap('activity', {'days': {}})['ct'] as Map?) ?? const {};

List<CustomTask> customTasks() {
  final out = <CustomTask>[];
  _ct().forEach((k, v) {
    if (v is! Map || (v['del'] as num?) == 1) return;
    out.add(CustomTask(k as String, (v['t'] as String?) ?? '', (v['tm'] as String?) ?? '', (v['rp'] as String?) ?? 'daily', (v['c'] as String?) ?? 'personal', (v['i'] as num?) == 1, ((v['wd'] as num?) ?? 0).toInt(), v['dt'] as String?));
  });
  out.sort((a, b) => a.id.compareTo(b.id));
  return out;
}

bool customAppliesOn(CustomTask t, DateTime d) => switch (t.rp) {
      'daily' => true,
      'weekly' => jsDay(d) == t.wd,
      _ => t.date == dkey(d),
    };

void customAdd({required String title, String time = '', String rp = 'daily', String cat = 'personal', bool imp = false, DateTime? date}) {
  final now = date ?? DateTime.now();
  final id = 'u${DateTime.now().millisecondsSinceEpoch}';
  store.upd('activity', {'days': {}}, (a) {
    a['ct'] ??= <String, dynamic>{};
    (a['ct'] as Map)[id] = {'t': title, 'tm': time, 'rp': rp, 'c': cat, 'i': imp ? 1 : 0, 'wd': jsDay(now), 'dt': dkey(now), 'del': 0};
  });
}

void customDelete(String id) => store.upd('activity', {'days': {}}, (a) {
      final m = (a['ct'] as Map?)?[id];
      if (m is Map) m['del'] = 1;
    });

/// إجمالي مهام يوم معيّن (الأساسية بلا النوافل + مهام المستخدم المنطبقة عليه).
int dayTasksTotal([DateTime? d]) => kTasksTotal + customTasks().where((t) => customAppliesOn(t, d ?? DateTime.now())).length;

int dayTasksDone([DateTime? d]) => tasksDone(d) + customTasks().where((t) => customAppliesOn(t, d ?? DateTime.now()) && taskDone(t.id, d)).length;

/// عدد الأيام المتتالية (حتى اليوم) التي أُنجزت فيها هذه العادة.
int habitStreak(String id) {
  var d = DateTime.now();
  if (!taskDone(id, d)) d = addDays(d, -1);
  var n = 0;
  while (taskDone(id, d) && n < 60) {
    n++;
    d = addDays(d, -1);
  }
  return n;
}
