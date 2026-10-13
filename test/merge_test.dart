import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/core/merge.dart';

void main() {
  test('الأرقام: أكبر قيمة', () => expect(mergeValues(5, 9), 9));
  test('المصفوفات: اتحاد بلا تكرار', () {
    expect(mergeValues([1, 2, 'a'], [2, 3, 'a']), [1, 2, 'a', 3]);
  });
  test('الخرائط: دمج متداخل', () {
    final r = mergeValues({'c': {'d1': 3}, 'fav': ['x']}, {'c': {'d1': 7, 'd2': 1}, 'fav': ['y']}) as Map;
    expect((r['c'] as Map)['d1'], 7);
    expect((r['c'] as Map)['d2'], 1);
    expect(r['fav'], ['x', 'y']);
  });
  test('null يأخذ القيمة الأخرى', () => expect(mergeValues(null, 'v'), 'v'));
}
