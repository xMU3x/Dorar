import 'package:flutter/services.dart';
import 'store.dart';

String pad(int n) => n.toString().padLeft(2, '0');
String dkey(DateTime d) => '${d.year}-${pad(d.month)}-${pad(d.day)}';
String todayKey() => dkey(DateTime.now());
const _arDigits = '٠١٢٣٤٥٦٧٨٩';
String toAr(Object n) => n.toString().replaceAllMapped(RegExp(r'\d'), (m) => _arDigits[int.parse(m[0]!)]);

/// رقم حسب إعداد «الأرقام العربية».
String nf(Object n) => cfg.get('arDigits') == true ? toAr(n) : n.toString();

/// يوم الأسبوع بترقيم JavaScript: 0 = الأحد.
int jsDay(DateTime d) => d.weekday % 7;
DateTime noon(DateTime d) => DateTime(d.year, d.month, d.day, 12);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n, 12);
int dayDiff(DateTime a, DateTime b) => (noon(b).difference(noon(a)).inHours / 24).round();

const wdays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
const gmonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const hmonths = ['محرّم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوّال', 'ذو القعدة', 'ذو الحجة'];

final RegExp _diac = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

/// تجريد النص من التشكيل وتوحيد الحروف للبحث.
String bare(String s) => s
    .replaceAll(_diac, '')
    .replaceAll(RegExp('[آأإٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه');

const juzStartPage = [1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];
int juzOfPage(int p) {
  var j = 1;
  for (var i = 0; i < juzStartPage.length; i++) {
    if (p >= juzStartPage[i]) j = i + 1;
  }
  return j;
}

/// اهتزاز أصلي (يحترم إعداد الاهتزاز).
class Hap {
  bool _on(bool force) => force || cfg.get('vibrate') == true;
  void tick([bool force = false]) { if (_on(force)) HapticFeedback.selectionClick(); }
  void select([bool force = false]) => tick(force);
  void click([bool force = false]) { if (_on(force)) HapticFeedback.lightImpact(); }
  void heavy([bool force = false]) { if (_on(force)) HapticFeedback.heavyImpact(); }
  void success([bool force = false]) {
    if (!_on(force)) return;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 90), HapticFeedback.mediumImpact);
    Future.delayed(const Duration(milliseconds: 180), HapticFeedback.lightImpact);
  }
  void error([bool force = false]) {
    if (!_on(force)) return;
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 120), HapticFeedback.vibrate);
  }
}

final Hap hap = Hap();
