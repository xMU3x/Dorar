import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app.dart';
import 'core/background.dart';
import 'core/notify.dart';
import 'core/store.dart';
import 'core/sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // خدمة تشغيل الصوت في الخلفية + إشعار التحكم (تعمل فقط أثناء التشغيل)
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.werd.habittracker.audio',
      androidNotificationChannelName: 'تشغيل القرآن',
      androidNotificationChannelDescription: 'التحكم في تشغيل القرآن من شريط الإشعارات',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_stat_durar',
      notificationColor: const Color(0xFF7B2336),
    );
  } catch (e) {
    debugPrint('audio background: $e');
  }
  await store.init();
  try {
    await sync.init();
  } catch (e) {
    debugPrint('sync init: $e');
  }
  notifier.onOpen = openRoute;
  runApp(const WerdApp());
  // الإشعارات بعد أول إطار حتى لا تُبطئ الإقلاع
  WidgetsBinding.instance.addPostFrameCallback((_) {
    notifier.init();
    registerBackgroundRefresh();
  });
}
