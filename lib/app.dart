import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/notify.dart';
import 'core/player.dart';
import 'core/store.dart';
import 'core/sync.dart';
import 'core/util.dart';
import 'pages/account.dart';
import 'pages/azkar.dart';
import 'pages/challenges.dart';
import 'pages/fasting.dart';
import 'pages/home.dart';
import 'pages/khatma.dart';
import 'pages/more.dart';
import 'ui/player_sheet.dart';
import 'ui/wicons.dart';
import 'pages/notif_settings.dart';
import 'pages/reciters.dart';
import 'pages/reminders.dart';
import 'pages/ruqya.dart';
import 'pages/settings.dart';
import 'pages/tasbih.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// يفتح صفحة حسب مسارها النصي (يُستخدم من الإشعارات والاختصارات).
void openRoute(String go) {
  final parts = go.split('/');
  switch (parts[0]) {
    case 'home': tabIndex.value = 0; navKey.currentState?.popUntil((r) => r.isFirst);
    case 'reciters': tabIndex.value = 1; navKey.currentState?.popUntil((r) => r.isFirst);
    case 'azkar': tabIndex.value = 2; navKey.currentState?.popUntil((r) => r.isFirst);
    case 'fasting':
      if (parts.length > 1 && parts[1] == 'add') {
        pushPage(const FastingPage(openAdd: true));
      } else {
        tabIndex.value = 3;
        navKey.currentState?.popUntil((r) => r.isFirst);
      }
    case 'more': tabIndex.value = 4; navKey.currentState?.popUntil((r) => r.isFirst);
    case 'zikr': if (parts.length > 1) pushPage(ZikrPage(catId: parts[1]));
    case 'zfav': pushPage(const FavZikrPage());
    case 'tasbih': pushPage(const TasbihPage());
    case 'khatma': pushPage(const KhatmaPage());
    case 'challenges': pushPage(const ChallengesPage());
    case 'ruqya': pushPage(const RuqyaPage());
    case 'reminders': pushPage(const RemindersPage());
    case 'notifsettings': pushPage(const NotifSettingsPage());
    case 'settings': pushPage(const SettingsPage());
    case 'about': pushPage(const AboutPage());
    case 'account': pushPage(const AccountPage());
  }
}

class WerdApp extends StatefulWidget {
  const WerdApp({super.key});
  @override
  State<WerdApp> createState() => _WerdAppState();
}

class _WerdAppState extends State<WerdApp> with WidgetsBindingObserver {
  late final Stream<String> _settings = store.changes.where((k) => k == 'settings').asBroadcastStream();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      sync.onResume();
      // قد يكون زر «صليت» كُتب من عزلة الخلفية؛ نعيد القراءة ثم نجدّد دفعة الإشعارات القادمة
      store.reload().then((_) => notifier.schedule());
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
          title: 'وِرد',
          debugShowCheckedModeBanner: false,
          navigatorKey: navKey,
          scaffoldMessengerKey: msgKey,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          theme: buildTheme(pal, dark),
          builder: (ctx, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
              statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
              systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            ),
            child: child!,
          ),
          home: const NavShell(),
        );
      },
    );
  }
}

Widget _tabPage(int i) => switch (i) {
      0 => const HomePage(),
      1 => const RecitersPage(),
      2 => const AzkarPage(),
      3 => const FastingPage(),
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
    for (var i = 1; i < 5; i++) {
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
        for (var i = 0; i < 5; i++)
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
  static const _tabs = [
    (Icons.home, 'الرئيسية'),
    (Icons.music_note, 'القرّاء'),
    (Icons.auto_awesome, 'الأذكار'),
    (Icons.calendar_month, 'الصيام'),
    (Icons.grid_view, 'المزيد'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBody: true,
      body: const _TabHost(),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        ListenableBuilder(listenable: player, builder: (_, __) => player.cur == null ? const SizedBox.shrink() : const MiniPlayer()),
        RepaintBoundary(
          child: Container(
            padding: EdgeInsets.only(bottom: bottom),
            decoration: BoxDecoration(
              color: p.surf,
              border: Border(top: BorderSide(color: p.line)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 8, offset: const Offset(0, -1))],
            ),
            child: SizedBox(
              height: 68,
              child: ValueListenableBuilder<int>(
                valueListenable: tabIndex,
                builder: (_, sel, __) => Row(children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _tabs[i].$1,
                        label: _tabs[i].$2,
                        selected: sel == i,
                        onTap: () {
                          if (sel != i) hap.tick();
                          tabIndex.value = i;
                          navKey.currentState?.popUntil((r) => r.isFirst);
                        },
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// أيقونات فقط افتراضيًا؛ عند الاختيار يتوسّع الإطار وتظهر التسمية أسفل الأيقونة.
/// المساحة محجوزة ثابتة (لا تغيّر في التخطيط) والحركة بالألوان والشفافية فقط → سلسة بلا قفزات.
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .9 : 1,
        duration: const Duration(milliseconds: 90),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.selected ? 1 : 0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          builder: (_, t, __) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 44 + 28 * t,
              height: 32,
              decoration: BoxDecoration(color: Color.lerp(Colors.transparent, p.pc, t), borderRadius: BorderRadius.circular(16)),
              child: Icon(widget.icon, size: 24, color: Color.lerp(p.on2, p.pri, t)),
            ),
            SizedBox(
              height: 18,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 5),
                  child: Text(widget.label, maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.pri)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final t = player.cur!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(color: p.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .16), blurRadius: 30, offset: const Offset(0, 10))]),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => showPlayer(navKey.currentContext ?? context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(14)), child: Center(child: WIcon('book', size: 22, color: p.pri))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('سورة ${t.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(player.error ?? t.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.on2, fontSize: 12)),
              ])),
              IconButton(onPressed: () { hap.click(); player.toggle(); }, icon: Icon(player.playing ? Icons.pause_circle_filled : Icons.play_circle_filled, color: p.pri, size: 38)),
              IconButton(onPressed: player.next, icon: const Icon(Icons.skip_previous)),
              IconButton(onPressed: player.stop, icon: const Icon(Icons.close)),
            ]),
          ),
        ),
      ),
    );
  }
}
