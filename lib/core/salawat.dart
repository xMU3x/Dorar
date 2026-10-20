import 'store.dart';
import 'util.dart';

// عدّاد «صليت على النبي ﷺ» — يُحفظ داخل مفتاح المزامنة الموجود `activity` تحت `sal` (تاريخ → عدد)،
// فيُدمج بين الأجهزة بأكبر رقم لكل يوم دون أي تغيير في جدول Supabase.
int _n(Object? v) => (v as num?)?.toInt() ?? 0;

Map<dynamic, dynamic> _sal() => (store.peekMap('activity', {'days': {}})['sal'] as Map?) ?? const {};

const int kFridayTarget = 500; // friday_target_count الافتراضي في Athar

int salawatOn(DateTime d) => _n(_sal()[dkey(d)]);
int salawatToday() => salawatOn(DateTime.now());

int salawatWeek() {
  final now = DateTime.now();
  var t = 0;
  for (var i = 0; i < 7; i++) {
    t += salawatOn(DateTime(now.year, now.month, now.day - i));
  }
  return t;
}

int salawatMonth() {
  final pre = dkey(DateTime.now()).substring(0, 8);
  var t = 0;
  _sal().forEach((k, v) {
    if ((k as String).startsWith(pre)) t += _n(v);
  });
  return t;
}

int salawatTotal() => _sal().values.fold<int>(0, (a, b) => a + _n(b));

void salawatAdd([int n = 1]) => store.upd('activity', {'days': {}}, (a) {
      a['sal'] ??= <String, dynamic>{};
      final m = a['sal'] as Map;
      m[todayKey()] = _n(m[todayKey()]) + n;
    });
