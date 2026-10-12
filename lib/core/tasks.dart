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

void taskSet(String id, bool v) {
  if (taskDone(id) == v) return;
  store.upd('activity', {'days': {}}, (a) {
    a['tk'] ??= <String, dynamic>{};
    final m = a['tk'] as Map;
    m[todayKey()] ??= <String, dynamic>{};
    (m[todayKey()] as Map)[id] = v ? 1 : 0;
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
