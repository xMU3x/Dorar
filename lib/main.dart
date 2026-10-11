import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/notify.dart';
import 'core/store.dart';
import 'core/sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await store.init();
  try {
    await sync.init();
  } catch (e) {
    debugPrint('sync init: $e');
  }
  notifier.onOpen = openRoute;
  runApp(const WerdApp());
  // الإشعارات بعد أول إطار حتى لا تُبطئ الإقلاع
  WidgetsBinding.instance.addPostFrameCallback((_) => notifier.init());
}
