import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/core/notify_plan.dart';

void main() {
  test('مراحل الأذكار حسب Athar: صباح 04:30 / مساء 15:00 / نوم 22:00', () {
    expect(stageAt(DateTime(2026, 10, 12, 4, 29)), Stage.sleep);
    expect(stageAt(DateTime(2026, 10, 12, 4, 30)), Stage.morning);
    expect(stageAt(DateTime(2026, 10, 12, 14, 59)), Stage.morning);
    expect(stageAt(DateTime(2026, 10, 12, 15, 0)), Stage.evening);
    expect(stageAt(DateTime(2026, 10, 12, 21, 59)), Stage.evening);
    expect(stageAt(DateTime(2026, 10, 12, 22, 0)), Stage.sleep);
  });

  test('الإعدادات الافتراضية والقراءة الآمنة', () {
    final d = NtPrefs.from(null);
    expect(d.master, isTrue);
    expect(d.periodic, isFalse);
    expect(d.interval, 15);
    expect(d.dhikrMin, 20);
    expect(d.fridayInterval, 10);
    final p = NtPrefs.from({'interval': 1, 'quietStart': 99, 'periodic': 'x'});
    expect(p.interval, 5); // يُقيَّد بالحد الأدنى
    expect(p.quietStart, 23);
    expect(p.periodic, isFalse);
  });

  test('ساعات الهدوء تعبر منتصف الليل', () {
    const p = NtPrefs(quiet: true, quietStart: 23, quietEnd: 5);
    expect(p.isQuiet(DateTime(2026, 10, 12, 23, 30)), isTrue);
    expect(p.isQuiet(DateTime(2026, 10, 12, 2, 0)), isTrue);
    expect(p.isQuiet(DateTime(2026, 10, 12, 5, 0)), isFalse);
    expect(p.isQuiet(DateTime(2026, 10, 12, 12, 0)), isFalse);
    expect(const NtPrefs(quiet: false).isQuiet(DateTime(2026, 10, 12, 2)), isFalse);
  });

  test('الشبكة المنتظمة تعطي أول موعد بعد الآن', () {
    expect(nextGrid(DateTime(2026, 10, 12, 10, 7), 15), DateTime(2026, 10, 12, 10, 15));
    expect(nextGrid(DateTime(2026, 10, 12, 10, 15), 15), DateTime(2026, 10, 12, 10, 30));
    expect(nextGrid(DateTime(2026, 10, 12, 23, 50), 30), DateTime(2026, 10, 13, 0, 0));
  });

  test('الصلاة الدورية: مفعّلة فقط، بلا هدوء، وبحد أقصى', () {
    final now = DateTime(2026, 10, 12, 10, 0);
    expect(salawatTimes(const NtPrefs(periodic: false), now), isEmpty);
    expect(salawatTimes(const NtPrefs(master: false, periodic: true), now), isEmpty);
    final l = salawatTimes(const NtPrefs(periodic: true, interval: 60), now);
    expect(l.first, DateTime(2026, 10, 12, 11, 0));
    expect(l.length, lessThanOrEqualTo(kMaxBatch));
    final q = salawatTimes(const NtPrefs(periodic: true, interval: 60, quiet: true, quietStart: 23, quietEnd: 5), now);
    expect(q.any((t) => t.hour >= 23 || t.hour < 5), isFalse);
    // المعرّفات ثابتة لنفس الموعد وفريدة بين المواعيد
    expect(slotId(kIdSalawat, l[0]), slotId(kIdSalawat, DateTime(2026, 10, 12, 11, 0)));
    expect({for (final t in l) slotId(kIdSalawat, t)}.length, l.length);
  });

  test('تعزيز الجمعة يغيّر الفاصل يوم الجمعة فقط', () {
    const p = NtPrefs(periodic: true, interval: 60, fridayBoost: true, fridayInterval: 10);
    final fri = DateTime(2026, 10, 16, 10, 0); // الجمعة
    expect(fri.weekday, DateTime.friday);
    expect(p.salawatIntervalAt(fri), 10);
    expect(p.salawatIntervalAt(DateTime(2026, 10, 15, 10)), 60);
    expect(salawatTimes(p, fri).first, DateTime(2026, 10, 16, 10, 10));
  });

  test('تذكير الأذكار يتخطى المرحلة المكتملة', () {
    final now = DateTime(2026, 10, 12, 6, 0);
    const p = NtPrefs(dhikr: true, dhikrMin: 60);
    final all = dhikrTimes(p, now);
    expect(all.first.stage, Stage.morning);
    final skip = dhikrTimes(p, now, isDone: (d, s) => s == Stage.morning && d == DateTime(2026, 10, 12));
    expect(skip.where((e) => e.at.day == 12 && e.stage == Stage.morning), isEmpty);
    expect(skip.isNotEmpty, isTrue);
  });

  test('تنبيه نهاية الوقت قبل ١٥ دقيقة من نهاية كل مرحلة', () {
    final now = DateTime(2026, 10, 12, 8, 0);
    final l = closingTimes(const NtPrefs(), now);
    expect(l.first.stage, Stage.morning);
    expect(l.first.at, DateTime(2026, 10, 12, 14, 45));
    expect(l[1].at, DateTime(2026, 10, 12, 21, 45));
    expect(l[2].at, DateTime(2026, 10, 13, 4, 15));
    expect(closingTimes(const NtPrefs(closing: false), now), isEmpty);
    final done = closingTimes(const NtPrefs(), now, isDone: (d, s) => s == Stage.morning && d == DateTime(2026, 10, 12));
    expect(done.first.stage, Stage.evening);
  });

  test('ليلة الجمعة: مساء الخميس القادم', () {
    final l = fridayEveTimes(const NtPrefs(), DateTime(2026, 10, 12, 9, 0)); // الاثنين
    expect(l.first, DateTime(2026, 10, 15, 18, 0));
    expect(l.every((d) => d.weekday == DateTime.thursday), isTrue);
    expect(fridayEveTimes(const NtPrefs(friday: false), DateTime(2026, 10, 12)), isEmpty);
  });
}
