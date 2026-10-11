import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/core/store.dart';
import 'package:habittracker/core/tasbih.dart';
import 'package:habittracker/core/khatma.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  test('store: set/get/upd وطابع المزامنة', () {
    store.set('khatma', {'read': 3});
    expect((store.get('khatma') as Map)['read'], 3);
    expect(store.meta['khatma'], isNotNull);
    store.upd('khatma', {}, (k) => k['read'] = 10);
    expect(store.getMap('khatma')['read'], 10);
  });

  test('store: applyRemote يحفظ طابع السيرفر ولا يرفعه', () {
    store.applyRemote('azkar', {'fav': []}, 12345);
    expect(store.meta['azkar'], 12345);
    expect(store.has('azkar'), isTrue);
  });

  test('إعدادات افتراضية', () {
    expect(cfg.get('vibrate'), true);
    cfg.set('pal', 'burgundy');
    expect(cfg.get('pal'), 'burgundy');
  });

  test('التسبيح: اكتمال الجولة وتصفير العدّاد', () {
    var done = false;
    for (var i = 0; i < 33; i++) {
      done = tasbihTap('subhan', 33);
    }
    expect(done, isTrue);
    final t = tasbihState();
    expect((t['n'] as Map)['subhan'], 0);
    expect((t['rounds'] as Map)['subhan'], 1);
    expect((t['total'] as Map)['subhan'], 33);
    expect(tasbihDaySum('all'), 33);
  });

  test('الختمة: الإضافة والتراجع', () {
    khatmaAdd(10);
    expect(khatma()['read'], 10);
    khatmaUndo();
    expect(khatma()['read'], 0);
  });

  test('الختمة: إتمام 604 صفحة تزيد عدّاد الختمات', () {
    var finished = false;
    for (var i = 0; i < 31; i++) {
      finished = khatmaAdd(20) || finished;
    }
    expect(finished, isTrue);
    expect(khatma()['done'], 1);
  });
}
