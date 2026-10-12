import 'package:flutter/material.dart';
import '../core/store.dart';

/// ألوان التطبيق (أخضر/عنابي × فاتح/داكن) — مطابقة لمتغيرات css/app.css.
class Pal extends ThemeExtension<Pal> {
  final Color bg, surf, surf2, on, on2, pri, pri2, onpri, pc, line, gold, ok;
  final List<Color> hero;
  const Pal(this.bg, this.surf, this.surf2, this.on, this.on2, this.pri, this.pri2, this.onpri, this.pc, this.line, this.gold, this.ok, this.hero);

  static Pal of(BuildContext c) => Theme.of(c).extension<Pal>()!;

  static Pal make(bool dark, String pal) {
    if (pal == 'green') {
      return dark
          ? const Pal(Color(0xFF0E1612), Color(0xFF16211B), Color(0xFF202D26), Color(0xFFE8F0E6), Color(0xFF9BAD9F), Color(0xFF8FD0A8), Color(0xFF6FB98B), Color(0xFF08301C), Color(0xFF223A2E), Color(0xFF2A3A31), Color(0xFFD6B764), Color(0xFF2F7D4F), [Color(0xFF0F3328), Color(0xFF1F5A44), Color(0xFF133E30)])
          : const Pal(Color(0xFFF6F4EC), Color(0xFFFFFFFF), Color(0xFFECEBDD), Color(0xFF17261E), Color(0xFF66756B), Color(0xFF2F6B52), Color(0xFF1E4D3B), Color(0xFFFFFFFF), Color(0xFFE3EEDC), Color(0xFFE5E1CE), Color(0xFFB3923F), Color(0xFF2F7D4F), [Color(0xFF17453A), Color(0xFF2A6E55), Color(0xFF1C5442)]);
    }
    return dark
        ? const Pal(Color(0xFF150D0F), Color(0xFF20141A), Color(0xFF2B1C22), Color(0xFFF4E9EA), Color(0xFFB09DA1), Color(0xFFE58AA0), Color(0xFFC96A82), Color(0xFF3A0C18), Color(0xFF4A2230), Color(0xFF38262D), Color(0xFFD9B766), Color(0xFF3E7D4F), [Color(0xFF000000), Color(0xFF1A0A0E), Color(0xFF6B1D30)])
        : const Pal(Color(0xFFFBF7F3), Color(0xFFFFFDFB), Color(0xFFF1E7E4), Color(0xFF2B1C1F), Color(0xFF8C7B7E), Color(0xFF7B2336), Color(0xFF5A1626), Color(0xFFFFFFFF), Color(0xFFF0DEE1), Color(0xFFEADDD9), Color(0xFFB08D3C), Color(0xFF3E7D4F), [Color(0xFF000000), Color(0xFF1A0A0E), Color(0xFF7B2336)]);
  }

  @override
  Pal copyWith() => this;
  @override
  Pal lerp(ThemeExtension<Pal>? other, double t) => other is Pal ? (t < .5 ? this : other) : this;
}

bool isDark(BuildContext c, String mode) => mode == 'dark' || (mode == 'auto' && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

ThemeData buildTheme(Pal p, bool dark) {
  final base = ColorScheme.fromSeed(seedColor: p.pri, brightness: dark ? Brightness.dark : Brightness.light);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'PlexArabic',
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: base.copyWith(primary: p.pri, onPrimary: p.onpri, surface: p.surf, onSurface: p.on, primaryContainer: p.pc, outlineVariant: p.line),
    scaffoldBackgroundColor: p.bg,
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    extensions: [p],
    textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light).textTheme.apply(fontFamily: 'PlexArabic', bodyColor: p.on, displayColor: p.on),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.pri, foregroundColor: p.onpri, minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20), shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: 'PlexArabic', fontSize: 14, fontWeight: FontWeight.w700),
        elevation: 3, shadowColor: p.pri.withValues(alpha: .55),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.pri, minimumSize: const Size(0, 46), padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: p.pri, width: 1.5), shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: 'PlexArabic', fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.pri, textStyle: const TextStyle(fontFamily: 'PlexArabic', fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.pri, foregroundColor: p.onpri, elevation: 6, highlightElevation: 3,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20), extendedIconLabelSpacing: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedTextStyle: const TextStyle(fontFamily: 'PlexArabic', fontSize: 15, fontWeight: FontWeight.w700),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? p.onpri : p.on2),
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? p.pri : p.surf2),
      trackOutlineColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? p.pri : p.on2),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.on, contentTextStyle: TextStyle(fontFamily: 'PlexArabic', color: p.bg, fontSize: 14),
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surf, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surf, surfaceTintColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.pri),
    sliderTheme: SliderThemeData(activeTrackColor: p.pri, inactiveTrackColor: p.surf2, thumbColor: p.pri, overlayColor: p.pri.withValues(alpha: .12), trackHeight: 6),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surf,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: p.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: p.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: p.pri)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

const quranFont = 'AmiriQuran';
const arabicFont = 'Amiri';
final Cfg _c = cfg;
String modeSetting() => _c.get('mode') as String;
String palSetting() => _c.get('pal') as String;
