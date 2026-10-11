import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/core/challenges.dart';

void main() {
  test('بداية الأسبوع السبت', () {
    // 2026-10-11 أحد → السبت السابق 2026-10-10
    expect(weekStart(DateTime(2026, 10, 11)).day, 10);
    expect(weekStart(DateTime(2026, 10, 10)).day, 10);
    expect(weekStart(DateTime(2026, 10, 9)).day, 3);
  });

  test('مفاتيح الفترات', () {
    final d = DateTime(2026, 10, 11);
    expect(periodKey('day', d), '2026-10-11');
    expect(periodKey('week', d), 'w2026-10-10');
    expect(periodKey('month', d), 'm2026-10');
  });

  test('أيام الفترة', () {
    expect(periodDays('week', DateTime(2026, 10, 11)).length, 7);
    expect(periodDays('month', DateTime(2026, 2, 5)).length, 28);
  });

  test('الاختيار المُبذَّر ثابت وبالعدد المطلوب', () {
    final a = seededPick(List.generate(20, (i) => i), '2026-10-11', 5);
    final b = seededPick(List.generate(20, (i) => i), '2026-10-11', 5);
    expect(a, b);
    expect(a.length, 5);
    expect(a.toSet().length, 5);
    expect(seededPick(List.generate(20, (i) => i), '2026-10-12', 5), isNot(a));
  });
}
