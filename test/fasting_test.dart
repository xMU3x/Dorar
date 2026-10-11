import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/core/fasting.dart';
import 'package:habittracker/core/hijri_util.dart';
import 'package:habittracker/core/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  test('يوم من رمضان صيام فرض', () {
    // رمضان 1447 هـ يبدأ تقريبًا 18–19 فبراير 2026
    final f = fastInfo(DateTime(2026, 3, 5, 12));
    expect(f.h.m, 9);
    expect(f.main, 'fard');
    expect(f.fast, isTrue);
  });

  test('الاثنين يُعرض كصيام مستحب عند تفعيل القاعدة', () {
    final monday = DateTime(2026, 10, 12, 12);
    expect(fastInfo(monday).tags.any((t) => t.k == 'mt'), isTrue);
    fastUpdate((s) => s.rules['mt'] = false);
    expect(fastInfo(monday).tags.any((t) => t.k == 'mt'), isFalse);
  });

  test('يوم مخصص مرة واحدة', () {
    fastUpdate((s) => s.custom.add({'id': 1, 'title': 'نذر', 'type': 'once', 'date': '2026-10-14', 'on': true}));
    final f = fastInfo(DateTime(2026, 10, 14, 12));
    expect(f.main == 'custom' || f.main == 'sunna' || f.main == 'bid' || f.main == 'fard', isTrue);
    expect(f.tags.any((t) => t.t == 'نذر'), isTrue);
  });

  test('أشهر هجرية: عدد الأيام بين 29 و30', () {
    final h = hj(DateTime(2026, 10, 11, 12));
    final m = hmonth(h.y, h.m);
    expect(m.len, inInclusiveRange(29, 30));
    expect(m.days.first.isBefore(m.days.last), isTrue);
  });

  test('أقرب يوم صيام موجود خلال 60 يومًا', () {
    expect(nextFast(DateTime(2026, 10, 11, 12)), isNotNull);
  });
}
