import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/core/hijri_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habittracker/core/store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  test('التاريخ الهجري مطابق لـ ICU (أم القرى): 2026-10-11 = 30 ربيع الآخر 1448', () {
    final h = hj(DateTime(2026, 10, 11, 12));
    expect((h.y, h.m, h.d), (1448, 4, 30));
  });

  test('بداية الأشهر من الجدول', () {
    expect(hj(DateTime(2026, 10, 12, 12)).d, 1); // 1 جمادى الأولى 1448
    expect(hj(DateTime(2026, 10, 12, 12)).m, 5);
  });

  test('شهر هجري كامل 29 أو 30 يومًا', () {
    final m = hmonth(1448, 4);
    expect(m.len == 29 || m.len == 30, isTrue);
    expect(hj(m.days.first).d, 1);
  });
}
