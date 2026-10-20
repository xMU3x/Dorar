import 'dart:async';
import 'package:audio_service/audio_service.dart' show AudioService;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/notify.dart';
import 'core/status_panel.dart';
import 'core/player.dart';
import 'core/store.dart';
import 'core/sync.dart';
import 'core/util.dart';
import 'pages/account.dart';
import 'pages/calendar.dart';
import 'pages/profile.dart';
import 'pages/quran.dart';
import 'pages/azkar.dart';
import 'pages/challenges.dart';
import 'pages/fasting.dart';
import 'pages/home.dart';
import 'pages/khatma.dart';
import 'pages/more.dart';
import 'pages/mawaiz.dart';
import 'pages/library.dart';
import 'pages/mushaf.dart';
import 'ui/player_sheet.dart';
import 'pages/notif_settings.dart';
import 'pages/reciters.dart';
import 'pages/reminders.dart';
import 'pages/ruqya.dart';
import 'pages/settings.dart';
import 'pages/tasks.dart';
import 'pages/tasbih.dart';
import 'ui/nav.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// يفتح صفحة حسب مسارها النصي (يُستخدم من الإشعارات والاختصارات).
void openRoute(String go) {
  final parts = go.split('/');
  void tab(int i) {
    tabIndex.value = i;
    navKey.currentState?.popUntil((r) => r.isFirst);
  }

  void page(Widget w) {
    navKey.currentState?.popUntil((r) => r.isFirst);
    pushPage(w);
  }

  switch (parts[0]) {
    case 'home': tab(0);
    case 'tasks': tab(1);
    case 'quran': tab(2);
    case 'listen':
      quranSeg.value = 'listen';
      tab(2);
    case 'azkar': tab(3);
    case 'fasting':
      if (parts.length > 1 && parts[1] == 'add') fastAddReq.value++;
      tab(4);
    case 'more': tab(5);
    case 'calendar': page(const CalendarReportsPage());
    case 'reports':
      calTab.value = 'reports';
      page(const CalendarReportsPage());
    case 'stats':
      calTab.value = 'stats';
      page(const CalendarReportsPage());
    case 'ach':
      calTab.value = 'ach';
      page(const CalendarReportsPage());
    case 'reciters': page(const RecitersPage());
    case 'zikr': if (parts.length > 1) pushPage(ZikrPage(catId: parts[1]));
    case 'zfav': pushPage(const FavZikrPage());
    case 'tasbih': page(const TasbihPage());
    case 'khatma': page(const KhatmaPage());
    case 'challenges': pushPage(const ChallengesPage());
    case 'ruqya': pushPage(const RuqyaPage());
    case 'moreazkar': pushPage(const MoreAzkarPage());
    case 'player': showPlayer(navKey.currentContext!);
    case 'reminders': pushPage(const RemindersPage());
    case 'notifsettings': pushPage(NotifSettingsPage(initialTab: parts.length > 1 && parts[1] == 'athkar' ? 1 : 0));
    case 'settings': pushPage(const SettingsPage());
    case 'about': pushPage(const AboutPage());
    case 'profile': page(const ProfilePage());
    case 'account': pushPage(const AccountPage());
    case 'mawaiz': page(const MawaizPage());
    case 'mawaizw': page(const WrittenMawaizPage());
    case 'hadith': page(const HadithPage());
    case 'library': page(const LibraryPage());
    case 'anbiya': page(const AnbiyaPage());
    case 'mushaf': page(MushafPage(page: parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : lastMushafPage()));
  }
}

class DorarApp extends StatefulWidget {
  const DorarApp({super.key});
  @override
  State<DorarApp> createState() => _DorarAppState();
}

class _DorarAppState extends State<DorarApp> with WidgetsBindingObserver {
  late final Stream<String> _settings = store.changes.where((k) => k == 'settings').asBroadcastStream();

  StreamSubscription<bool>? _clickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // الضغط على إشعار تشغيل القرآن يفتح المشغّل بملء الشاشة
    try {
      _clickSub = AudioService.notificationClicked.listen((c) {
        if (c && player.cur != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = navKey.currentContext;
            if (ctx != null) showPlayer(ctx);
          });
        }
      });
    } catch (e) {
      debugPrint('notificationClicked: $e');
    }
  }

  @override
  void dispose() {
    _clickSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      sync.onResume();
      // قد يكون زر «صليت» كُتب من عزلة الخلفية؛ نعيد القراءة ثم نجدّد دفعة الإشعارات القادمة
      store.reload().then((_) {
        notifier.schedule();
        refreshStatusPanel(now: true);
      });
    }
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _settings,
      builder: (context, _) {
        final dark = isDark(context, modeSetting());
        final pal = Pal.make(dark, palSetting());
        return MaterialApp(
          title: 'Dorar',
          debugShowCheckedModeBanner: false,
          navigatorKey: navKey,
          scaffoldMessengerKey: msgKey,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          theme: buildTheme(pal, dark),
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(textScaler: MediaQuery.of(ctx).textScaler.clamp(minScaleFactor: .9, maxScaleFactor: 1.0)),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
              statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
              systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            ),
            child: child!,
          )),
          home: const NavShell(),
        );
      },
    );
  }
}

Widget _tabPage(int i) => switch (i) {
      0 => const HomePage(),
      1 => const TasksPage(),
      2 => const QuranHomePage(),
      3 => const AzkarPage(),
      4 => const FastingPage(),
      _ => const MorePage(),
    };

/// يبني كل تبويب مرة واحدة فقط (عند أول زيارة أو في الخلفية بعد الإقلاع) ويُبقيه حيًّا،
/// فيصبح التنقّل بين التبويبات فوريًا بدل إعادة البناء كل مرة، مع تلاشٍ سريع للتبويب الجديد.
class _TabHost extends StatefulWidget {
  const _TabHost();
  @override
  State<_TabHost> createState() => _TabHostState();
}

class _TabHostState extends State<_TabHost> with SingleTickerProviderStateMixin {
  final Set<int> _built = {0};
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: 1);
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    tabIndex.addListener(_onTab);
    // تدفئة التبويبات تدريجيًا بعد الإقلاع (واحد كل ثانية تقريبًا) حتى لا يظهر تأخير عند أول زيارة
    for (var i = 1; i < 6; i++) {
      Future.delayed(Duration(milliseconds: 700 + i * 700), () {
        if (mounted && !_built.contains(i)) setState(() => _built.add(i));
      });
    }
  }

  @override
  void dispose() {
    tabIndex.removeListener(_onTab);
    _c.dispose();
    super.dispose();
  }

  void _onTab() {
    final i = tabIndex.value;
    if (i == _idx) return;
    setState(() {
      _idx = i;
      _built.add(i);
    });
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _idx,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < 6; i++)
          if (_built.contains(i))
            RepaintBoundary(child: FadeTransition(opacity: i == _idx ? _fade : const AlwaysStoppedAnimation<double>(1), child: _tabPage(i)))
          else
            const SizedBox.shrink(),
      ],
    );
  }
}

class NavShell extends StatelessWidget {
  const NavShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: const _TabHost(),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        ListenableBuilder(listenable: player, builder: (_, __) => player.cur == null ? const SizedBox.shrink() : const MiniPlayer()),
        ValueListenableBuilder<int>(
          valueListenable: tabIndex,
          builder: (_, sel, __) => AppNavBar(
            ids: kMainTabs,
            selected: kMainTabs[sel],
            onTap: (id) {
              final i = kMainTabs.indexOf(id);
              if (sel != i) hap.tick();
              tabIndex.value = i;
              navKey.currentState?.popUntil((r) => r.isFirst);
            },
          ),
        ),
      ]),
    );
  }
}

String _fmt(Duration d) {
  final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
  return h > 0 ? '$h:${pad(m)}:${pad(s)}' : '${pad(m)}:${pad(s)}';
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final t = player.cur!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(24), border: Border.all(color: p.line), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .14), blurRadius: 26, offset: const Offset(0, 8))]),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showPlayer(navKey.currentContext ?? context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset('assets/brand/app_icon.png', width: 56, height: 56, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(player.error ?? t.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.on2, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    builder: (_, ds) => StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (_, ps) {
                        final d = ds.data?.inMilliseconds ?? 0, v = ps.data?.inMilliseconds ?? 0;
                        return Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(children: [
                            Text(_fmt(Duration(milliseconds: v)), style: TextStyle(fontSize: 10.5, color: p.on2)),
                            const SizedBox(width: 6),
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: d <= 0 ? 0 : (v / d).clamp(0, 1).toDouble(), minHeight: 4, backgroundColor: p.surf2, valueColor: AlwaysStoppedAnimation(p.pri)))),
                            const SizedBox(width: 6),
                            Text(_fmt(Duration(milliseconds: d)), style: TextStyle(fontSize: 10.5, color: p.on2)),
                          ]),
                        );
                      },
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 4),
              IconButton(visualDensity: VisualDensity.compact, onPressed: player.prev, icon: const Icon(Icons.skip_previous, size: 26)),
              GestureDetector(
                onTap: () { hap.click(); player.toggle(); },
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.pri),
                  child: player.loading ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 3, color: p.onpri)) : Icon(player.playing ? Icons.pause : Icons.play_arrow, color: p.onpri, size: 28),
                ),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: player.next, icon: const Icon(Icons.skip_next, size: 26)),
              IconButton(visualDensity: VisualDensity.compact, onPressed: player.stop, icon: Icon(Icons.close, color: p.on2, size: 22)),
            ]),
          ),
        ),
      ),
    );
  }
}
