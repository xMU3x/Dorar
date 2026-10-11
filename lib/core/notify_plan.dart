// قواعد جدولة إشعارات الأذكار والصلاة على النبي ﷺ — دوال نقيّة (بدون Flutter) قابلة للاختبار.
// القيم مأخوذة من تحليل Athar 1.45 (HesnService / SalawatScheduler / DhikrRepository):
//   • مراحل الأذكار: صباح 04:30–15:00، مساء 15:00–22:00، نوم 22:00–04:30.
//   • تنبيه قرب نهاية المرحلة: قبلها بـ ١٥ دقيقة.
//   • الصلاة على النبي الدورية: افتراضيًا كل ١٥ دقيقة، وفي الجمعة (تعزيز) كل ١٠ دقائق.
//   • تذكير الأذكار الدوري: افتراضيًا كل ٢٠ دقيقة.
//   • ساعات الهدوء: افتراضيًا من ٢٣ إلى ٥.

enum Stage { morning, evening, sleep }

const int kMorningStart = 270; // 04:30
const int kEveningStart = 900; // 15:00
const int kSleepStart = 1320; // 22:00
const int kClosingLeadMin = 15;

/// أقصى عدد إشعارات مفرَدة تُجدوَل مسبقًا لكل نوع (تُجدَّد عند فتح التطبيق/عودته).
const int kMaxBatch = 48;
const int kHorizonHours = 48;

/// معرّفات الإشعارات المفرَدة: base + (دقائق منذ Unix epoch) فتكون ثابتة لنفس الموعد (لا تكرار).
const int kIdSalawat = 1000000000;
const int kIdDhikr = 1100000000;
const int kIdClosing = 1200000000;
const int kIdFriday = 1300000000;

int slotId(int base, DateTime at) => base + at.millisecondsSinceEpoch ~/ 60000;

Stage stageAt(DateTime t) {
  final m = t.hour * 60 + t.minute;
  if (m >= kMorningStart && m < kEveningStart) return Stage.morning;
  if (m >= kEveningStart && m < kSleepStart) return Stage.evening;
  return Stage.sleep;
}

/// تاريخ «يوم الذكر» للمرحلة: أذكار النوم بعد منتصف الليل تُحسب لليوم السابق.
DateTime stageDay(DateTime t) {
  final m = t.hour * 60 + t.minute;
  final d = DateTime(t.year, t.month, t.day);
  return m < kMorningStart ? d.subtract(const Duration(days: 1)) : d;
}

String stageName(Stage s) => switch (s) { Stage.morning => 'الصباح', Stage.evening => 'المساء', Stage.sleep => 'النوم' };
String stageTitle(Stage s) => 'أذكار ${stageName(s)}';
String stageRoute(Stage s) => switch (s) { Stage.morning => 'zikr/hisn-27', Stage.evening => 'zikr/hisn-27e', Stage.sleep => 'zikr/hisn-28' };
String stageCat(Stage s) => switch (s) { Stage.morning => 'hisn-27', Stage.evening => 'hisn-27e', Stage.sleep => 'hisn-28' };

/// إعدادات الإشعارات (تُحفظ داخل مفتاح المزامنة الموجود `settings` تحت `nt`).
class NtPrefs {
  final bool master, periodic, dhikr, closing, friday, fridayBoost, quiet, sound, vibrate;
  final int interval, dhikrMin, fridayInterval, quietStart, quietEnd;
  const NtPrefs({
    this.master = true,
    this.periodic = false,
    this.interval = 15,
    this.dhikr = false,
    this.dhikrMin = 20,
    this.closing = true,
    this.friday = true,
    this.fridayBoost = false,
    this.fridayInterval = 10,
    this.quiet = false,
    this.quietStart = 23,
    this.quietEnd = 5,
    this.sound = true,
    this.vibrate = true,
  });

  factory NtPrefs.from(Object? raw) {
    final m = raw is Map ? raw : const {};
    bool b(String k, bool d) => m[k] is bool ? m[k] as bool : d;
    int i(String k, int d, int lo, int hi) => m[k] is num ? (m[k] as num).toInt().clamp(lo, hi).toInt() : d;
    return NtPrefs(
      master: b('master', true),
      periodic: b('periodic', false),
      interval: i('interval', 15, 5, 720),
      dhikr: b('dhikr', false),
      dhikrMin: i('dhikrMin', 20, 5, 720),
      closing: b('closing', true),
      friday: b('friday', true),
      fridayBoost: b('fridayBoost', false),
      fridayInterval: i('fridayInterval', 10, 5, 720),
      quiet: b('quiet', false),
      quietStart: i('quietStart', 23, 0, 23),
      quietEnd: i('quietEnd', 5, 0, 23),
      sound: b('sound', true),
      vibrate: b('vibrate', true),
    );
  }

  /// هل الساعة داخل ساعات الهدوء؟ (تدعم المدى الذي يعبر منتصف الليل)
  bool isQuiet(DateTime t) {
    if (!quiet || quietStart == quietEnd) return false;
    final h = t.hour;
    return quietStart < quietEnd ? (h >= quietStart && h < quietEnd) : (h >= quietStart || h < quietEnd);
  }

  int salawatIntervalAt(DateTime t) => (fridayBoost && t.weekday == DateTime.friday) ? fridayInterval : interval;
}

/// أول موعد بعد [from] يقع على شبكة منتظمة كل [stepMin] دقيقة منذ منتصف الليل.
DateTime nextGrid(DateTime from, int stepMin) {
  final mins = from.hour * 60 + from.minute;
  var n = (mins ~/ stepMin + 1) * stepMin;
  var t = DateTime(from.year, from.month, from.day, 0, n);
  while (!t.isAfter(from)) {
    n += stepMin;
    t = DateTime(from.year, from.month, from.day, 0, n);
  }
  return t;
}

/// مواعيد الصلاة على النبي ﷺ الدورية القادمة.
List<DateTime> salawatTimes(NtPrefs p, DateTime now, {int max = kMaxBatch}) {
  if (!p.master || !p.periodic) return const [];
  final end = now.add(const Duration(hours: kHorizonHours));
  final out = <DateTime>[];
  var t = nextGrid(now, p.salawatIntervalAt(now));
  while (t.isBefore(end) && out.length < max) {
    if (!p.isQuiet(t)) out.add(t);
    t = nextGrid(t, p.salawatIntervalAt(t));
  }
  return out;
}

/// مواعيد تذكير الأذكار الدوري. [isDone] يُستعمل لتخطّي مرحلة اكتملت اليوم.
List<({DateTime at, Stage stage})> dhikrTimes(NtPrefs p, DateTime now, {bool Function(DateTime day, Stage s)? isDone, int max = kMaxBatch}) {
  if (!p.master || !p.dhikr) return const [];
  final end = now.add(const Duration(hours: kHorizonHours));
  final out = <({DateTime at, Stage stage})>[];
  var t = nextGrid(now, p.dhikrMin);
  while (t.isBefore(end) && out.length < max) {
    final s = stageAt(t);
    if (!p.isQuiet(t) && !(isDone?.call(stageDay(t), s) ?? false)) out.add((at: t, stage: s));
    t = nextGrid(t, p.dhikrMin);
  }
  return out;
}

/// تنبيهات «باقي ١٥ دقيقة على نهاية ورد …» للأيام الثلاثة القادمة.
List<({DateTime at, Stage stage})> closingTimes(NtPrefs p, DateTime now, {bool Function(DateTime day, Stage s)? isDone}) {
  if (!p.master || !p.closing) return const [];
  final out = <({DateTime at, Stage stage})>[];
  for (var i = 0; i < 4; i++) {
    final d = DateTime(now.year, now.month, now.day + i);
    final ends = <(Stage, DateTime)>[
      (Stage.morning, DateTime(d.year, d.month, d.day, 0, kEveningStart - kClosingLeadMin)),
      (Stage.evening, DateTime(d.year, d.month, d.day, 0, kSleepStart - kClosingLeadMin)),
      // نهاية مرحلة النوم 04:30 من اليوم التالي → التنبيه 04:15 (يُحسب ليوم d)
      (Stage.sleep, DateTime(d.year, d.month, d.day + 1, 0, kMorningStart - kClosingLeadMin)),
    ];
    for (final e in ends) {
      final at = e.$2;
      if (!at.isAfter(now) || p.isQuiet(at)) continue;
      if (isDone?.call(d, e.$1) ?? false) continue;
      out.add((at: at, stage: e.$1));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

/// إشعار «أقبلت ليلة الجمعة»: مساء الخميس (افتراضي 18:00) للأسابيع القادمة.
List<DateTime> fridayEveTimes(NtPrefs p, DateTime now, {int hour = 18, int weeks = 3}) {
  if (!p.master || !p.friday) return const [];
  final out = <DateTime>[];
  for (var i = 0; i < weeks * 7 + 7 && out.length < weeks; i++) {
    final d = DateTime(now.year, now.month, now.day + i, hour);
    if (d.weekday == DateTime.thursday && d.isAfter(now) && !p.isQuiet(d)) out.add(d);
  }
  return out;
}
