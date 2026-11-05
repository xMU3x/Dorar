import 'package:flutter_test/flutter_test.dart';
import 'package:dorar/core/salawat.dart';
import 'package:dorar/core/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  test('عدّاد صليت: اليوم/الأسبوع/الشهر/الكل داخل مفتاح activity', () {
    expect(salawatToday(), 0);
    salawatAdd();
    salawatAdd(4);
    expect(salawatToday(), 5);
    expect(salawatWeek(), 5);
    expect(salawatMonth(), 5);
    expect(salawatTotal(), 5);
    expect(store.getMap('activity')['sal'], isA<Map>());
    expect(store.meta['activity'], isNotNull); // يُزامَن بالمفتاح الموجود دون تغيير الجدول
  });

  test('لا يمسّ بيانات النشاط والسلسلة الموجودة', () {
    store.set('activity', {'days': {'2026-01-01': 1}, 'best': 3});
    salawatAdd();
    final a = store.getMap('activity');
    expect((a['days'] as Map)['2026-01-01'], 1);
    expect(a['best'], 3);
  });
}
