import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'pages/reciters.dart';
import 'pages/reminders.dart';
import 'pages/ruqya.dart';
import 'pages/settings.dart';
import 'pages/tasbih.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

final ValueNotifier<int> tabIndex = ValueNotifier(0);

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
    if (s == AppLifecycleState.resumed) sync.onResume();
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

/// تبويب واحد فقط يُبنى في كل مرة (أخف بكثير من بناء كل التبويبات وإبقائها حيّة).
Widget _tabPage(int i) => switch (i) {
      0 => const HomePage(),
      1 => const RecitersPage(),
      2 => const AzkarPage(),
      3 => const FastingPage(),
      _ => const MorePage(),
    };

class NavShell extends StatelessWidget {
  const NavShell({super.key});
  static const _tabs = [
    (Icons.home_rounded, 'الرئيسية'),
    (Icons.music_note_rounded, 'القرّاء'),
    (Icons.auto_awesome_rounded, 'الأذكار'),
    (Icons.calendar_month_rounded, 'الصيام'),
    (Icons.grid_view_rounded, 'المزيد'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBody: true,
      body: ValueListenableBuilder<int>(
        valueListenable: tabIndex,
        builder: (_, i, __) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(i), child: _tabPage(i)),
        ),
      ),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        ListenableBuilder(listenable: player, builder: (_, __) => player.cur == null ? const SizedBox.shrink() : const MiniPlayer()),
        Container(
          padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + bottom),
          decoration: BoxDecoration(color: p.surf.withValues(alpha: .97), border: Border(top: BorderSide(color: p.line))),
          child: ValueListenableBuilder<int>(
            valueListenable: tabIndex,
            builder: (_, sel, __) => Row(children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(child: _NavItem(icon: _tabs[i].$1, label: _tabs[i].$2, selected: sel == i, onTap: () {
                  if (sel != i) hap.tick();
                  tabIndex.value = i;
                  navKey.currentState?.popUntil((r) => r.isFirst);
                })),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// أيقونات فقط افتراضيًا، وعند الاختيار تظهر الأيقونة مع اسمها أسفلها.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 22 : 10, vertical: 5),
              decoration: BoxDecoration(color: selected ? p.pc : Colors.transparent, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, size: 26, color: selected ? p.pri : p.on2),
            ),
            if (selected) Padding(padding: const EdgeInsets.only(top: 2), child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.pri))),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: p.pc, borderRadius: BorderRadius.circular(24), border: Border.all(color: p.line)),
      child: Row(children: [
        IconButton(onPressed: () { hap.click(); player.toggle(); }, icon: Icon(player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: p.pri, size: 30)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(player.error ?? t.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.on2, fontSize: 12)),
        ])),
        IconButton(onPressed: player.prev, icon: const Icon(Icons.skip_next_rounded)),
        IconButton(onPressed: player.next, icon: const Icon(Icons.skip_previous_rounded)),
        IconButton(onPressed: player.stop, icon: const Icon(Icons.close_rounded)),
      ]),
    );
  }
}
