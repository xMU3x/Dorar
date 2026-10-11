import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'fasting.dart';
import 'store.dart';
import 'util.dart';

const _allDays = [0, 1, 2, 3, 4, 5, 6];
const _channelId = 'werd_remind_v3';

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
  void Function(String route)? onOpen;

  AndroidFlutterLocalNotificationsPlugin? get _android => _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (e) {
      debugPrint('tz: $e');
    }
    await _p.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (r) {
        final go = r.payload;
        if (go != null && go.isNotEmpty) onOpen?.call(go);
      },
    );
    await _android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId, 'التذكيرات والأذكار',
      description: 'أذكار الصباح والمساء والنوم وورد القرآن وغيرها',
      importance: Importance.high,
    ));
    _ready = true;
    final launch = await _p.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true && launch?.notificationResponse?.payload != null) {
      Future.delayed(const Duration(milliseconds: 600), () => onOpen?.call(launch!.notificationResponse!.payload!));
    }
    await schedule();
  }

  Future<bool> notificationsAllowed() async => (await _android?.areNotificationsEnabled()) ?? false;
  Future<bool> requestPermission() async => (await _android?.requestNotificationsPermission()) ?? false;
  Future<bool> exactAllowed() async => (await _android?.canScheduleExactNotifications()) ?? false;
  Future<void> requestExact() async => _android?.requestExactAlarmsPermission();

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, 'التذكيرات والأذكار',
            channelDescription: 'تذكيرات وِرد', importance: Importance.high, priority: Priority.high, icon: '@mipmap/ic_launcher'),
      );

  Future<void> test() async {
    await _p.show(1, 'وِرد', 'هذا إشعار تجريبي ✅ التذكيرات تعمل', _details, payload: 'home');
  }

  tz.TZDateTime _nextWeekly(int wd, int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    while (jsDay(DateTime(d.year, d.month, d.day)) != wd || !d.isAfter(now)) {
      d = tz.TZDateTime(tz.local, d.year, d.month, d.day + 1, h, m);
    }
    return d;
  }

  /// يعيد جدولة كل التذكيرات: أسبوعيًا لكل يوم مختار، وتذكير الصيام بتواريخ محددة.
  Future<void> schedule() async {
    if (!_ready) return;
    try {
      await _p.cancelAll();
      final exact = await exactAllowed();
      final mode = exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
      for (final it in remindersAll().where((x) => x.on)) {
        final t = parseTime(it.time);
        if (it.special) {
          var i = 0;
          for (final at in occurrences(it, days: 30)) {
            final z = tz.TZDateTime.from(at, tz.local);
            await _p.zonedSchedule(500 + i++, it.title, fastBody(addDays(at, 1)), z, _details,
                androidScheduleMode: mode,
                uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
                payload: it.go);
          }
          continue;
        }
        for (final wd in it.days) {
          await _p.zonedSchedule(it.nid * 10 + wd, it.title, it.body, _nextWeekly(wd, t.h, t.m), _details,
              androidScheduleMode: mode,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              payload: it.go);
        }
      }
    } catch (e) {
      debugPrint('schedule: $e');
    }
  }
}

final Notifier notifier = Notifier();
