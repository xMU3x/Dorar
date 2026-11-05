import 'azkar.dart';
import 'data.dart';
import 'fasting.dart';
import 'store.dart';
import 'tasbih.dart';
import 'tasks.dart';
import 'util.dart';

/// تجميع نشاط يوم واحد من كل الأقسام (للتقويم والتقارير والملف الشخصي).
class DayAct {
  final DateTime d;
  final int azkar, tasks, tasksTotal, pages, tasbih;
  final bool fast, qiyam;
  const DayAct(this.d, this.azkar, this.tasks, this.tasksTotal, this.pages, this.tasbih, this.fast, this.qiyam);
  double get taskFrac => tasksTotal == 0 ? 0 : (tasks / tasksTotal).clamp(0.0, 1.0).toDouble();
  bool get tasksDoneAll => tasksTotal > 0 && tasks >= tasksTotal;

  /// درجة الاستمرارية 0..1: المهام ٤٠٪ + أذكار ٢٠٪ + قرآن ٢٠٪ + تسبيح ٢٠٪.
  double get score => (taskFrac * .4 + (azkar > 0 ? .2 : 0) + (pages > 0 ? .2 : 0) + (tasbih > 0 ? .2 : 0)).clamp(0.0, 1.0).toDouble();
  bool get any => azkar > 0 || tasks > 0 || pages > 0 || tasbih > 0 || fast || qiyam;
}

int _dayAzkar(Map c, String key) {
  final day = c[key];
  if (day is! Map) return 0;
  var n = 0;
  for (final cat in day.values) {
    if (cat is Map) {
      for (final v in cat.values) {
        n += (v as num?)?.toInt() ?? 0;
      }
    }
  }
  return n;
}

DayAct dayAct(DateTime d, [FastState? fs]) {
  final key = dkey(d);
  final c = (azkarState()['c'] as Map?) ?? const {};
  final pr = (quranState()['pagesRead'] as Map?) ?? const {};
  final F = fs ?? fastState();
  return DayAct(d, _dayAzkar(c, key), dayTasksDone(d), dayTasksTotal(d), ((pr[key] as num?) ?? 0).toInt(), tasbihDaySum('all', key), F.done[key] != null, taskDone('qiyam', d));
}

/// إجمالي كل الأذكار والتسبيح (للمستوى والملف الشخصي).
int totalAzkarAll() {
  final c = (azkarState()['c'] as Map?) ?? const {};
  var n = 0;
  for (final k in c.keys) {
    n += _dayAzkar(c, k as String);
  }
  final tot = (tasbihPeek()['total'] as Map?) ?? const {};
  for (final v in tot.values) {
    n += (v as num?)?.toInt() ?? 0;
  }
  return n;
}

int quranReadingDays() {
  final pr = (quranState()['pagesRead'] as Map?) ?? const {};
  return pr.values.where((v) => ((v as num?) ?? 0) > 0).length;
}

const levelXp = [0, 100, 250, 500, 1000, 2000, 4000, 8000, 16000];
const levelNames = ['مبتدئ', 'مواظب', 'طالب علم', 'عابد', 'ذاكر', 'قانت', 'سابق بالخيرات', 'محسن', 'عالم'];
const _ord = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع'];

({int level, String name, String ord, int from, int to, int xp}) levelOf(int xp) {
  var l = 0;
  for (var i = 0; i < levelXp.length; i++) {
    if (xp >= levelXp[i]) l = i;
  }
  final to = l + 1 < levelXp.length ? levelXp[l + 1] : levelXp.last;
  return (level: l + 1, name: levelNames[l], ord: _ord[l], from: levelXp[l], to: to, xp: xp);
}

/// درجات آخر [n] يومًا (الأقدم أولًا) لمنحنى «مستوى الاستمرارية».
List<DayAct> lastDays(int n) {
  final fs = fastState();
  final now = DateTime.now();
  return [for (var i = n - 1; i >= 0; i--) dayAct(addDays(now, -i), fs)];
}

/// أيام الصيام المسجّلة (الأحدث أولًا).
List<DateTime> fastDoneDays() {
  final out = <DateTime>[];
  for (final k in fastState().done.keys) {
    final x = k.split('-').map(int.tryParse).toList();
    if (x.length == 3 && x.every((e) => e != null)) out.add(DateTime(x[0]!, x[1]!, x[2]!, 12));
  }
  out.sort((a, b) => b.compareTo(a));
  return out;
}
