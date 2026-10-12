import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notify.dart';
import 'store.dart';

const _task = 'durar.refresh';

/// نقطة دخول مهمة الخلفية: تجدّد جدولة الإشعارات (الصلاة على النبي/الأذكار تُجدوَل على دفعات ٤٨ ساعة).
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      await store.init();
      await notifier.initBackground();
      return true;
    } catch (e) {
      debugPrint('bg refresh: $e');
      return false;
    }
  });
}

/// مهمة دورية كل ٦ ساعات يديرها النظام (WorkManager): لا خدمة دائمة ولا قفل تشغيل، فاستهلاك البطارية شبه معدوم،
/// وتضمن استمرار وصول الإشعارات حتى لو لم يُفتح التطبيق لأيام.
Future<void> registerBackgroundRefresh() async {
  try {
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      _task, _task,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.notRequired, requiresBatteryNotLow: true),
    );
  } catch (e) {
    debugPrint('workmanager: $e');
  }
}
