import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'azkar.dart';
import 'fasting.dart';
import 'notify_plan.dart';
import 'salawat.dart';
import 'store.dart';
import 'util.dart';

const _allDays = [0, 1, 2, 3, 4, 5, 6];
const kActionSalat = 'salat_ok';
const _sigKey = '_nt_sig';

enum _Ch { remind, salawat, dhikr }

const _chBase = {_Ch.remind: 'werd_remind_v3', _Ch.salawat: 'durar_salawat_v2', _Ch.dhikr: 'werd_dhikr_v1'};
const _chName = {_Ch.remind: 'التذكيرات والأذكار', _Ch.salawat: 'الصلاة على النبي ﷺ', _Ch.dhikr: 'تذكير الأذكار ونهاية الوقت'};
const _chDesc = {
  _Ch.remind: 'أذكار الصباح والمساء والنوم وورد القرآن وتذكيراتك الخاصة',
  _Ch.salawat: 'تذكير دوري بالصلاة على النبي ﷺ مع زر «صليت»',
  _Ch.dhikr: 'تذكير بالأذكار المتبقية وتنبيه قبل نهاية وقت الورد',
};

/// معرّف القناة: الأساس عند (صوت+اهتزاز) وإلا لاحقة، لأن إعدادات القناة لا تتغير بعد إنشائها في أندرويد 8+.
String _chId(_Ch c, NtPrefs p) {
  final sv = p.sound && p.vibrate ? '' : '_${p.sound ? 's' : 'x'}${p.vibrate ? 'v' : 'x'}';
  // قناة الصلاة على النبي تتنوّع بالنغمة ووضع الصامت لأن إعدادات القناة لا تتغيّر بعد إنشائها
  if (c == _Ch.salawat) return '${_chBase[c]}_${p.salSound}_${p.silentMode ? 'a' : 'n'}$sv';
  return '${_chBase[c]}$sv';
}
const _variants = ['', '_sx', '_xv', '_xx'];

NtPrefs ntPrefs() => NtPrefs.from(store.peekMap('settings')['nt']);

/// يحفظ جزءًا من إعدادات الإشعارات داخل مفتاح المزامنة `settings` ثم يعيد الجدولة (دون تكرار).
void ntSet(Map<String, dynamic> patch) {
  store.upd('settings', {}, (s) {
    final cur = Map<String, dynamic>.from((s['nt'] as Map?) ?? {});
    cur.addAll(patch);
    s['nt'] = cur;
  });
  notifier.schedule();
}

/// يُستدعى من عزلة الخلفية عند الضغط على زر «صليت» في الإشعار والتطبيق مغلق.
@pragma('vm:entry-point')
Future<void> notifBackground(NotificationResponse r) async {
  if (r.actionId != kActionSalat) return;
  await store.init();
  await store.reload();
  await _confirmSalat(r.id ?? 0);
}

/// تأكيد «صليت» مرة واحدة لكل إشعار (حتى لو وصل الحدث من عزلتين).
Future<void> _confirmSalat(int nid) async {
  final last = (store.get('_nt_last_ok') as num?)?.toInt();
  if (last == nid && nid != 0) return;
  store.set('_nt_last_ok', nid, quiet: true);
  salawatAdd();
}

/// التذكيرات الجاهزة (قابلة لتعديل الوقت والأيام والتفعيل) — مطابقة لـ js/notify.js.
final List<Map<String, dynamic>> reminderDefaults = [
  {'id': 'morning', 'n': 1, 'title': 'أذكار الصباح', 'body': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ. ابدأ يومك بذكر الله', 'icon': 'sun', 'time': '06:00', 'days': _allDays, 'on': true, 'go': 'zikr/hisn-27'},
  {'id': 'evening', 'n': 2, 'title': 'أذكار المساء', 'body': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ. اختم نهارك بالأذكار', 'icon': 'sunset', 'time': '17:00', 'days': _allDays, 'on': true, 'go': 'zikr/hisn-27e'},
  {'id': 'sleep', 'n': 3, 'title': 'أذكار النوم', 'body': 'باسمك اللهم أموت وأحيا. لا تنم قبل أذكار النوم', 'icon': 'moon', 'time': '22:30', 'days': _allDays, 'on': true, 'go': 'zikr/hisn-28'},
  {'id': 'wird', 'n': 4, 'title': 'ورد القرآن', 'body': 'وردك اليوم ينتظرك، ولو صفحة واحدة', 'icon': 'book', 'time': '21:00', 'days': _allDays, 'on': true, 'go': 'khatma'},
  {'id': 'chal', 'n': 5, 'title': 'تحديات اليوم', 'body': 'تحدٍّ واحد يكفي لتحافظ على سلسلتك', 'icon': 'check', 'time': '20:00', 'days': _allDays, 'on': true, 'go': 'challenges'},
  {'id': 'kahf', 'n': 6, 'title': 'سورة الكهف', 'body': 'يوم الجمعة · سورة الكهف وكثرة الصلاة على النبي ﷺ', 'icon': 'book', 'time': '09:00', 'days': [5], 'on': false, 'go': 'khatma'},
  {'id': 'qiyam', 'n': 7, 'title': 'قيام الليل', 'body': 'الثلث الأخير من الليل · وقت الدعاء والاستغفار', 'icon': 'moon', 'time': '03:30', 'days': _allDays, 'on': false},
  {'id': 'fast', 'n': 8, 'title': 'تذكير الصيام', 'body': 'غدًا يوم صيام، انوِ الصيام من الليل', 'icon': 'moon', 'time': '20:00', 'days': _allDays, 'on': false, 'go': 'fasting', 'special': 'fast'},
];

Map<String, dynamic> _rs() {
  final r = store.getMap('reminders', {'o': {}, 'custom': [], 'seq': 100});
  r['o'] ??= {};
  r['custom'] ??= [];
  return r;
}

void _upR(void Function(Map<String, dynamic>) fn) {
  final r = _rs();
  fn(r);
  store.set('reminders', r);
}

class Reminder {
  final Map<String, dynamic> m;
  final bool custom;
  Reminder(this.m, this.custom);
  String get id => m['id'] as String;
  String get title => (m['title'] as String?) ?? '';
  String get body => (m['body'] as String?) ?? '';
  String get icon => (m['icon'] as String?) ?? 'bell';
  String get time => (m['time'] as String?) ?? '08:00';
  bool get on => m['on'] == true;
  String? get go => m['go'] as String?;
  bool get special => m['special'] == 'fast';
  List<int> get days => [for (final d in (m['days'] as List?) ?? _allDays) (d as num).toInt()];
  int get nid => custom ? ((m['nid'] as num?)?.toInt() ?? 101) : (m['n'] as int);
}

List<Reminder> remindersDefault() {
  final o = Map<String, dynamic>.from(_rs()['o'] as Map);
  return [for (final d in reminderDefaults) Reminder({...d, ...Map<String, dynamic>.from((o[d['id']] as Map?) ?? {})}, false)];
}

List<Reminder> remindersCustom() => [
      for (final c in (_rs()['custom'] as List)) Reminder({'icon': 'bell', 'days': _allDays, ...Map<String, dynamic>.from(c as Map)}, true),
    ];

List<Reminder> remindersAll() => [...remindersDefault(), ...remindersCustom()];

({int h, int m}) parseTime(String t) {
  final p = t.split(':');
  return (h: int.parse(p[0]), m: int.parse(p[1]));
}

String fmtTime(String time) {
  final t = parseTime(time);
  final h12 = t.h % 12 == 0 ? 12 : t.h % 12;
  return '${nf(h12)}:${nf(pad(t.m))} ${t.h >= 12 ? 'م' : 'ص'}';
}

String daysLabel(List<int> days) {
  if (days.length == 7) return 'كل يوم';
  if (days.isEmpty) return 'بدون أيام';
  if (days.length == 2 && days.contains(1) && days.contains(4)) return 'الاثنين والخميس';
  if (days.length == 1) return wdays[days[0]];
  final s = [...days]..sort((a, b) => ((a + 1) % 7).compareTo((b + 1) % 7));
  return s.map((d) => wdays[d].replaceFirst('ال', '')).join('، ');
}

String fastBody(DateTime d) {
  final f = fastInfo(d);
  final t = f.tags.where((x) => x.kind != 'eid').firstOrNull;
  return t != null ? 'غدًا ${t.t} — انوِ الصيام من الليل' : 'غدًا يوم صيام، انوِ الصيام من الليل';
}

/// المواعيد القادمة لتذكير معيّن.
List<DateTime> occurrences(Reminder it, {DateTime? from, int days = 8}) {
  from ??= DateTime.now();
  final t = parseTime(it.time);
  final out = <DateTime>[];
  for (var i = 0; i < days; i++) {
    final d = DateTime(from.year, from.month, from.day + i, t.h, t.m);
    if (!d.isAfter(from)) continue;
    if (it.special) {
      if (isFastDay(addDays(d, 1))) out.add(d);
    } else if (it.days.contains(jsDay(d))) {
      out.add(d);
    }
  }
  return out;
}

({Reminder it, DateTime at})? nextReminder() {
  final now = DateTime.now();
  ({Reminder it, DateTime at})? best;
  for (final it in remindersAll().where((x) => x.on)) {
    final o = occurrences(it, from: now, days: it.special ? 30 : 8).firstOrNull;
    if (o != null && (best == null || o.isBefore(best.at))) best = (it: it, at: o);
  }
  return best;
}

String whenLabel(DateTime at) {
  final df = dayDiff(DateTime.now(), at);
  return '${df == 0 ? 'اليوم' : df == 1 ? 'غدًا' : wdays[jsDay(at)]} ${fmtTime('${pad(at.hour)}:${pad(at.minute)}')}';
}

void reminderUpdate(Reminder it, Map<String, dynamic> patch) {
  _upR((r) {
    if (it.custom) {
      final c = (r['custom'] as List).cast<Map>().where((x) => x['id'] == it.id).firstOrNull;
      c?.addAll(patch);
    } else {
      final o = Map<String, dynamic>.from((r['o'] as Map)[it.id] as Map? ?? {});
      (r['o'] as Map)[it.id] = {...o, ...patch};
    }
  });
  notifier.schedule();
}

void reminderAddCustom(Map<String, dynamic> c) {
  _upR((r) {
    r['seq'] = ((r['seq'] as num?)?.toInt() ?? 100) + 1;
    (r['custom'] as List).add({'id': 'c${DateTime.now().millisecondsSinceEpoch}', 'nid': r['seq'], 'on': true, ...c});
  });
  notifier.schedule();
}

void reminderRemove(String id) {
  _upR((r) => r['custom'] = (r['custom'] as List).where((c) => (c as Map)['id'] != id).toList());
  notifier.schedule();
}

void reminderReset(Reminder it) {
  _upR((r) => (r['o'] as Map).remove(it.id));
  notifier.schedule();
}

class Notifier {
  final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String _chKey = '';
  String tzName = 'UTC';
  String lastError = '';
  Future<void>? _running;
  bool _dirty = false;
  void Function(String route)? onOpen;

  AndroidFlutterLocalNotificationsPlugin? get _android => _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final n = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(n));
      tzName = n;
    } catch (e) {
      debugPrint('tz: $e');
      // بديل: أول منطقة زمنية لها نفس إزاحة الجهاز الحالية (بدلها تبقى UTC فتتأخر الإشعارات ساعات)
      final off = DateTime.now().timeZoneOffset;
      for (final l in tz.timeZoneDatabase.locations.values) {
        if (l.name.contains('/') && tz.TZDateTime.now(l).timeZoneOffset == off) {
          tz.setLocalLocation(l);
          tzName = '${l.name} (تقديري)';
          break;
        }
      }
    }
    await _p.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('ic_stat_durar')),
      onDidReceiveNotificationResponse: (r) async {
        if (r.actionId == kActionSalat) {
          await _confirmSalat(r.id ?? 0);
          return;
        }
        final go = r.payload;
        if (go != null && go.isNotEmpty) onOpen?.call(go);
      },
      onDidReceiveBackgroundNotificationResponse: notifBackground,
    );
    await _ensureChannels(ntPrefs());
    _ready = true;
    final launch = await _p.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true && launch?.notificationResponse?.payload != null && launch?.notificationResponse?.actionId == null) {
      Future.delayed(const Duration(milliseconds: 600), () => onOpen?.call(launch!.notificationResponse!.payload!));
    }
    await schedule();
  }

  /// تهيئة خفيفة داخل عزلة الخلفية (WorkManager) لتجديد دفعة الإشعارات القادمة دون فتح التطبيق.
  Future<void> initBackground() async {
    tzdata.initializeTimeZones();
    try {
      final n = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(n));
      tzName = n;
    } catch (_) {}
    await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings('ic_stat_durar')));
    _ready = true;
    await schedule();
  }

  // ---------- الأذونات وقيود البطارية ----------
  Future<bool> notificationsAllowed() async => (await _android?.areNotificationsEnabled()) ?? false;
  Future<bool> requestPermission() async => (await _android?.requestNotificationsPermission()) ?? false;
  Future<bool> exactAllowed() async => (await _android?.canScheduleExactNotifications()) ?? false;
  Future<void> requestExact() async => _android?.requestExactAlarmsPermission();

  /// هل التطبيق مستثنى من توفير البطارية؟ (يمنع النظام من تأخير/إلغاء التنبيهات)
  Future<bool> batteryIgnored() async {
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestBatteryIgnore() async {
    try {
      return (await Permission.ignoreBatteryOptimizations.request()).isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('openSettings: $e');
    }
  }

  // ---------- القنوات ----------
  Future<void> _ensureChannels(NtPrefs p) async {
    final key = '${p.sound}${p.vibrate}${p.salSound}${p.silentMode}';
    if (key == _chKey) return;
    final a = _android;
    if (a == null) return;
    for (final c in _Ch.values) {
      final cur = _chId(c, p);
      final sal = c == _Ch.salawat;
      await a.createNotificationChannel(AndroidNotificationChannel(
        cur, _chName[c]!,
        description: _chDesc[c],
        importance: Importance.high,
        playSound: p.sound,
        sound: sal && p.salSound != 'sys' ? RawResourceAndroidNotificationSound(p.salSound) : null,
        // «التذكير بالوضع الصامت»: الصوت يمرّ عبر قناة المنبّه فيُسمع حتى في الصامت
        audioAttributesUsage: sal && p.silentMode ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        enableVibration: p.vibrate,
      ));
      if (!sal) {
        for (final v in _variants) {
          final id = '${_chBase[c]}$v';
          if (id != cur) await a.deleteNotificationChannel(id);
        }
      } else {
        for (final ch in await a.getNotificationChannels() ?? <AndroidNotificationChannel>[]) {
          if ((ch.id.startsWith('werd_salawat_') || ch.id.startsWith('durar_salawat_v2')) && ch.id != cur) await a.deleteNotificationChannel(ch.id);
        }
      }
    }
    _chKey = key;
  }

  NotificationDetails _det(_Ch c, NtPrefs p, String body, {bool salatAction = false}) => NotificationDetails(
        android: AndroidNotificationDetails(
          _chId(c, p), _chName[c]!,
          channelDescription: _chDesc[c],
          importance: Importance.high,
          priority: Priority.high,
          playSound: p.sound,
          sound: c == _Ch.salawat && p.salSound != 'sys' ? RawResourceAndroidNotificationSound(p.salSound) : null,
          audioAttributesUsage: c == _Ch.salawat && p.silentMode ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
          enableVibration: p.vibrate,
          category: AndroidNotificationCategory.reminder,
          icon: 'ic_stat_durar',
          color: const Color(0xFF7B2336),
          styleInformation: BigTextStyleInformation(body),
          actions: salatAction ? const [AndroidNotificationAction(kActionSalat, 'صليت ﷺ', cancelNotification: true)] : null,
        ),
      );

  // ---------- إشعارات فورية (تجربة) ----------
  Future<void> test() async {
    final p = ntPrefs();
    await _ensureChannels(p);
    const b = 'هذا إشعار تجريبي ✅ التذكيرات تعمل';
    await _p.show(1, 'دُرَر', b, _det(_Ch.remind, p, b), payload: 'home');
  }

  Future<void> testSalawat() async {
    final p = ntPrefs();
    await _ensureChannels(p);
    await _p.show(2 + DateTime.now().millisecondsSinceEpoch % 100000, _salTitle, _salBody, _det(_Ch.salawat, p, _salBody, salatAction: true), payload: 'tasbih');
  }

  Future<void> testDhikr() async {
    final p = ntPrefs();
    await _ensureChannels(p);
    final s = stageAt(DateTime.now());
    final b = 'حِصْنُ المُسْلِم • ${stageTitle(s)} — بقي من وردك ما تيسّر، افتح الأذكار.';
    await _p.show(3, stageTitle(s), b, _det(_Ch.dhikr, p, b), payload: stageRoute(s));
  }

  static const _salTitle = 'الصلاة على النبي ﷺ';
  String get _salBody => kSalFormulas[ntPrefs().formula] ?? kSalFormulas[2]!;

  tz.TZDateTime _nextWeekly(int wd, int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    while (jsDay(DateTime(d.year, d.month, d.day)) != wd || !d.isAfter(now)) {
      d = tz.TZDateTime(tz.local, d.year, d.month, d.day + 1, h, m);
    }
    return d;
  }

  // ---------- الجدولة ----------
  /// تسلسل الاستدعاءات: أي تعديل أثناء جدولة جارية يُدمج في دورة واحدة تالية (لا تكرار ولا تداخل).
  Future<void> schedule() {
    if (!_ready) return Future.value();
    _dirty = true;
    return _running ??= _drain().whenComplete(() => _running = null);
  }

  Future<void> _drain() async {
    while (_dirty) {
      _dirty = false;
      try {
        await _scheduleOnce();
      } catch (e) {
        lastError = '$e';
        debugPrint('schedule: $e');
      }
    }
  }

  /// يجدول إشعارًا بعد [sec] ثانية عبر نفس مسار المنبّهات (يكشف مشاكل الجدولة التي لا يكشفها زر التجربة الفوري).
  /// يرجع نص الخطأ أو null عند النجاح.
  Future<String?> testIn(int sec) async {
    try {
      final p = ntPrefs();
      await _ensureChannels(p);
      final exact = await exactAllowed();
      const b = 'وصل هذا الإشعار من المجدول ✅ الجدولة تعمل';
      await _p.zonedSchedule(
        4, 'دُرَر', b, tz.TZDateTime.now(tz.local).add(Duration(seconds: sec)), _det(_Ch.remind, p, b),
        androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'home',
      );
      return null;
    } catch (e) {
      lastError = '$e';
      return '$e';
    }
  }

  Future<int> pendingCount() async => (await _p.pendingNotificationRequests()).length;

  /// أي مراحل الأذكار اكتملت اليوم (لتخطّي تذكيرها).
  Future<Map<Stage, bool>> _doneToday() async {
    final out = <Stage, bool>{};
    for (final s in Stage.values) {
      try {
        final pr = await azkarProgress(stageCat(s));
        out[s] = pr.total > 0 && pr.done >= pr.total;
      } catch (_) {
        out[s] = false;
      }
    }
    return out;
  }

  Future<List<_Plan>> _plans(NtPrefs p, bool exact) async {
    final mode = exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    final m = exact ? 'e' : 'i';
    final out = <_Plan>[];
    final rc = _chId(_Ch.remind, p);

    // 1) التذكيرات الأسبوعية (جاهزة + مخصّصة) والصيام
    for (final it in remindersAll().where((x) => x.on)) {
      final t = parseTime(it.time);
      if (it.special) {
        var i = 0;
        for (final at in occurrences(it, days: 30)) {
          final body = fastBody(addDays(at, 1));
          out.add(_Plan(500 + i++, it.title, body, _Ch.remind, it.go, tz.TZDateTime.from(at, tz.local), mode, false, 'f|${it.title}|$body|${at.millisecondsSinceEpoch}|${it.go}|$rc|$m'));
        }
        continue;
      }
      for (final wd in it.days) {
        out.add(_Plan(it.nid * 10 + wd, it.title, it.body, _Ch.remind, it.go, _nextWeekly(wd, t.h, t.m), mode, true, 'w|${it.title}|${it.body}|${it.time}|$wd|${it.go}|$rc|$m'));
      }
    }

    // 2) إشعارات الأذكار والصلاة على النبي (مستخرجة من Athar)
    if (p.master) {
      final now = DateTime.now();
      final done = await _doneToday();
      final today = dkey(now);
      bool isDone(DateTime day, Stage s) => dkey(day) == today && (done[s] ?? false);
      final sc = _chId(_Ch.salawat, p), dc = _chId(_Ch.dhikr, p);

      for (final at in salawatTimes(p, now)) {
        out.add(_Plan(slotId(kIdSalawat, at), _salTitle, _salBody, _Ch.salawat, 'tasbih', tz.TZDateTime.from(at, tz.local), mode, false, 's|${at.millisecondsSinceEpoch}|$sc|$m|${p.formula}', salatAction: true));
      }
      for (final e in dhikrTimes(p, now, isDone: isDone)) {
        final body = 'حِصْنُ المُسْلِم • بقي من ${stageTitle(e.stage)} ما تيسّر، افتح الأذكار.';
        out.add(_Plan(slotId(kIdDhikr, e.at), stageTitle(e.stage), body, _Ch.dhikr, stageRoute(e.stage), tz.TZDateTime.from(e.at, tz.local), mode, false, 'd|${e.at.millisecondsSinceEpoch}|${e.stage.name}|$dc|$m'));
      }
      for (final e in closingTimes(p, now, isDone: isDone)) {
        out.add(_Plan(slotId(kIdClosing, e.at), 'باقي ١٥ دقيقة على ورد ${stageName(e.stage)}', 'أتمّ ما تيسّر من أذكارك قبل أن ينتهي الوقت المفضّل.', _Ch.dhikr, stageRoute(e.stage), tz.TZDateTime.from(e.at, tz.local), mode, false, 'c|${e.at.millisecondsSinceEpoch}|${e.stage.name}|$dc|$m'));
      }
      for (final at in fridayEveTimes(p, now)) {
        out.add(_Plan(slotId(kIdFriday, at), 'أقبلت ليلة الجمعة المباركة 🌿', 'قال ﷺ: «أَكْثِرُوا عَلَيَّ مِنَ الصَّلَاةِ فِيهَا». افتح دُرَر للصلاة على النبي.', _Ch.salawat, 'tasbih', tz.TZDateTime.from(at, tz.local), mode, false, 'g|${at.millisecondsSinceEpoch}|$sc|$m'));
      }
    }
    // حد أمان: نظام أندرويد يسمح بنحو 500 منبّه لكل تطبيق (التذكيرات الأسبوعية أولًا)
    return out.length > 450 ? out.sublist(0, 450) : out;
  }

  /// يوفّق المجدول مع الحالة المطلوبة: يلغي ما لم يعد مطلوبًا، ولا يعيد جدولة ما لم يتغيّر، ويستبدل المتغيّر بنفس المعرّف (فلا تكرار).
  Future<void> _scheduleOnce() async {
    final p = ntPrefs();
    await _ensureChannels(p);
    final exact = await exactAllowed();
    final plans = await _plans(p, exact);
    final want = {for (final x in plans) x.id: x};
    final pending = {for (final r in await _p.pendingNotificationRequests()) r.id};
    final old = store.getMap(_sigKey);
    for (final id in pending) {
      if (!want.containsKey(id)) await _p.cancel(id);
    }
    final next = <String, String>{};
    for (final x in plans) {
      if (pending.contains(x.id) && old['${x.id}'] == x.sig) {
        next['${x.id}'] = x.sig;
        continue;
      }
      try {
        await _p.zonedSchedule(
          x.id, x.title, x.body, x.at, _det(x.ch, p, x.body, salatAction: x.salatAction),
          androidScheduleMode: x.mode,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: x.weekly ? DateTimeComponents.dayOfWeekAndTime : null,
          payload: x.go,
        );
        next['${x.id}'] = x.sig;
      } catch (e) {
        lastError = '$e';
        debugPrint('zonedSchedule ${x.id}: $e');
      }
    }
    store.set(_sigKey, next, quiet: true);
  }

  /// أقرب موعد قادم من إشعارات الأذكار/الصلاة (للعرض في صفحة الإعدادات).
  ({String title, DateTime at})? nextAthkar() {
    final p = ntPrefs();
    final now = DateTime.now();
    final c = <({String title, DateTime at})>[
      for (final at in salawatTimes(p, now, max: 1)) (title: _salTitle, at: at),
      for (final e in dhikrTimes(p, now, max: 1)) (title: stageTitle(e.stage), at: e.at),
      for (final e in closingTimes(p, now)) (title: 'نهاية ورد ${stageName(e.stage)}', at: e.at),
      for (final at in fridayEveTimes(p, now, weeks: 1)) (title: 'ليلة الجمعة', at: at),
    ];
    if (c.isEmpty) return null;
    c.sort((a, b) => a.at.compareTo(b.at));
    return c.first;
  }
}

class _Plan {
  final int id;
  final String title, body, sig;
  final _Ch ch;
  final String? go;
  final tz.TZDateTime at;
  final AndroidScheduleMode mode;
  final bool weekly, salatAction;
  _Plan(this.id, this.title, this.body, this.ch, this.go, this.at, this.mode, this.weekly, this.sig, {this.salatAction = false});
}

final Notifier notifier = Notifier();
