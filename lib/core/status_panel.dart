import 'dart:async';
import 'data.dart';
import 'fasting.dart';
import 'khatma.dart';
import 'notify.dart';
import 'store.dart';
import 'tasks.dart';
import 'util.dart';

bool statusPanelEnabled() => cfg.get('statusPanel') != false;

Timer? _deb;

/// يحدّث إشعار اللوحة الثابتة (بعد تأخير قصير لتجميع التغييرات).
void refreshStatusPanel({bool now = false}) {
  _deb?.cancel();
  _deb = Timer(now ? Duration.zero : const Duration(seconds: 3), _run);
}

Future<void> _run() async {
  if (!statusPanelEnabled()) {
    await notifier.hideStatusPanel();
    return;
  }
  final nx = nextFast();
  final String title;
  if (nx == null) {
    title = 'دُرَر · لا صيام قريب';
  } else {
    final t = nx.info.tags.where((x) => x.kind != 'eid').firstOrNull?.t ?? 'يوم صيام';
    title = nx.inDays == 0 ? 'صيام اليوم: $t' : nx.inDays == 1 ? 'متبقٍ يوم واحد على $t' : nx.inDays == 2 ? 'متبقٍ يومان على $t' : 'متبقٍ ${nf(nx.inDays)} أيام على $t';
  }
  final kh = khatma();
  final goal = ((kh['goal'] as num?) ?? 5).toInt();
  final body = 'المهام ${nf(dayTasksDone())}/${nf(dayTasksTotal())} · الورد ${nf(pagesToday())}/${nf(goal)} صفحات';
  await notifier.showStatusPanel(title, body);
}
