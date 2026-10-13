import 'package:hijri/hijri_calendar.dart';
import 'hijri_table.dart';
import 'store.dart';
import 'util.dart';

class Hj {
  final int y, m, d;
  const Hj(this.y, this.m, this.d);
}

class HMonth {
  final int y, m, len;
  final DateTime start;
  final List<DateTime> days;
  HMonth(this.y, this.m, this.start, this.len, this.days);
}

final Map<String, Hj> _hjCache = {};
final Map<String, HMonth> _mCache = {};
int _adj() => ((cfg.get('hijriAdj') as num?) ?? 0).toInt();

/// تاريخ هجري (أم القرى) لتاريخ ميلادي، مع تصحيح الرؤية من الإعدادات.
Hj hj([DateTime? date, int? adj]) {
  final g = addDays(date ?? DateTime.now(), adj ?? _adj());
  final k = dkey(g);
  return _hjCache[k] ??= _fromTable(g) ??
      () {
        final h = HijriCalendar.fromDate(g);
        return Hj(h.hYear, h.hMonth, h.hDay);
      }();
}

/// بحث ثنائي في جدول أم القرى (نفس نتائج Intl في الويب)؛ null خارج النطاق.
Hj? _fromTable(DateTime g) {
  final day = DateTime.utc(g.year, g.month, g.day).millisecondsSinceEpoch ~/ 86400000;
  if (day < kHijriMonthStarts.first || day >= kHijriMonthStarts.last + 29) return null;
  var lo = 0, hi = kHijriMonthStarts.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (kHijriMonthStarts[mid] <= day) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return Hj(kHijriFirstYear + lo ~/ 12, lo % 12 + 1, day - kHijriMonthStarts[lo] + 1);
}

int _hidx(Hj h) => h.y * 12 + h.m - 1;

/// أيام شهر هجري كاملة.
HMonth hmonth(int y, int m) {
  final key = '$y-$m-${_adj()}';
  final c = _mCache[key];
  if (c != null) return c;
  final t = y * 12 + m - 1;
  final today = DateTime.now();
  final h0 = hj(today);
  var g = addDays(today, ((t - _hidx(h0)) * 29.530588).round() - (h0.d - 1));
  for (var i = 0; i < 80; i++) {
    final h = hj(g);
    final x = _hidx(h);
    if (x > t) {
      g = addDays(g, -((x - t) * 28).clamp(1, 25));
    } else if (x < t) {
      g = addDays(g, ((t - x) * 28).clamp(1, 25));
    } else if (h.d > 1) {
      g = addDays(g, -(h.d - 1));
    } else {
      break;
    }
  }
  final days = <DateTime>[];
  var x = g;
  while (_hidx(hj(x)) == t && days.length < 31) {
    days.add(x);
    x = addDays(x, 1);
  }
  return _mCache[key] = HMonth(y, m, g, days.length, days);
}

String hijriString([DateTime? date]) {
  final h = hj(date);
  final ar = cfg.get('arDigits') == true;
  return '${ar ? toAr(h.d) : h.d} ${hmonths[h.m - 1]} ${ar ? toAr(h.y) : h.y} هـ';
}
