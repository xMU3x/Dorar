import 'package:flutter/material.dart';
import '../core/store.dart';

/// ألوان التطبيق (أخضر/عنابي × فاتح/داكن) — مطابقة لمتغيرات css/app.css.
class Pal extends ThemeExtension<Pal> {
  final Color bg, surf, surf2, on, on2, pri, pri2, onpri, pc, line, gold, ok;
  final List<Color> hero;
  const Pal(this.bg, this.surf, this.surf2, this.on, this.on2, this.pri, this.pri2, this.onpri, this.pc, this.line, this.gold, this.ok, this.hero);

  static Pal of(BuildContext c) => Theme.of(c).extension<Pal>()!;

  /// هل الوضع الداكن مفعّل حاليًا (يُستخدم لإلغاء الظلال الفاتحة في الداكن).
  static bool darkNow = false;

  static Pal make(bool dark, String pal) {
    darkNow = dark;
    switch (pal) {
      case 'burgundy':
        return dark
            ? const Pal(Color(0xFF150D0F), Color(0xFF20141A), Color(0xFF2B1C22), Color(0xFFF4E9EA), Color(0xFFB09DA1), Color(0xFFE58AA0), Color(0xFFC96A82), Color(0xFF3A0C18), Color(0xFF4A2230), Color(0xFF38262D), Color(0xFFD9B766), Color(0xFF3E7D4F), [Color(0xFF000000), Color(0xFF1A0A0E), Color(0xFF6B1D30)])
            : const Pal(Color(0xFFFBF7F3), Color(0xFFFFFDFB), Color(0xFFF1E7E4), Color(0xFF2B1C1F), Color(0xFF8C7B7E), Color(0xFF7B2336), Color(0xFF5A1626), Color(0xFFFFFFFF), Color(0xFFF0DEE1), Color(0xFFEADDD9), Color(0xFFB08D3C), Color(0xFF3E7D4F), [Color(0xFF000000), Color(0xFF1A0A0E), Color(0xFF7B2336)]);
      case 'blue':
        return _tint(dark, const Color(0xFF1D4E89), const Color(0xFF143A68), const Color(0xFFDCE8F5), const [Color(0xFF0F2F57), Color(0xFF1D5A9A), Color(0xFF15477C)]);
      case 'purple':
        return _tint(dark, const Color(0xFF5B3E96), const Color(0xFF45307A), const Color(0xFFE6DDF3), const [Color(0xFF2F2058), Color(0xFF5B3E96), Color(0xFF47317F)]);
      case 'brown':
        return _tint(dark, const Color(0xFF8A4B14), const Color(0xFF6E3C0F), const Color(0xFFF1E2D0), const [Color(0xFF4A2A0C), Color(0xFF8A4B14), Color(0xFF6E3C0F)]);
      default:
        // هوية دُرَر: أخضر غابي عميق + كريمي دافئ + ذهبي (مطابقة للتصميم الجديد)
        return dark
            ? const Pal(Color(0xFF0C1412), Color(0xFF141F1C), Color(0xFF1A2824), Color(0xFFE7EEEB), Color(0xFF8F9E99), Color(0xFF45BBA1), Color(0xFF2FA088), Color(0xFF06221C), Color(0xFF16332C), Color(0xFF22322E), Color(0xFFD8B25C), Color(0xFF3C9A66), [Color(0xFF0C302A), Color(0xFF134A40), Color(0xFF1D6B5C)])
            : const Pal(Color(0xFFF7F3E8), Color(0xFFFFFDF8), Color(0xFFF1ECDD), Color(0xFF10261E), Color(0xFF6F7C74), Color(0xFF0C4A38), Color(0xFF083B2D), Color(0xFFFFFFFF), Color(0xFFDCEBDD), Color(0xFFEBE4D0), Color(0xFFD9A63B), Color(0xFF22804F), [Color(0xFF0B3B2D), Color(0xFF14543F), Color(0xFF0E4434)]);
    }
  }

  /// ألوان مشتقة من لون أساسي واحد (أزرق/بنفسجي/بني) فوق نفس الخلفية الكريمية/الداكنة.
  static Pal _tint(bool dark, Color pri, Color pri2, Color pc, List<Color> hero) {
    if (!dark) {
      return Pal(const Color(0xFFF7F3E8), const Color(0xFFFFFDF8), const Color(0xFFF1ECDD), const Color(0xFF16201C), const Color(0xFF6F7670), pri, pri2, Colors.white, pc, const Color(0xFFEBE4D0), const Color(0xFFD9A63B), const Color(0xFF22804F), hero);
    }
    Color lift(Color c, double l) => HSLColor.fromColor(c).withLightness(l).withSaturation(.5).toColor();
    return Pal(const Color(0xFF0E1213), const Color(0xFF171D1F), const Color(0xFF212A2C), const Color(0xFFEDF0EE), const Color(0xFFA3AFAB), lift(pri, .72), lift(pri, .62), const Color(0xFF0B1418), lift(pri, .2), const Color(0xFF2A3437), const Color(0xFFD9B96B), const Color(0xFF3C9A66), hero);
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: p.line)),
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

/// ظل ناعم للبطاقات؛ يُلغى في الوضع الداكن حتى لا يظهر هالة بيضاء حول البانلات.
List<BoxShadow> softShadow([double blur = 14, double dy = 4]) =>
    Pal.darkNow ? const <BoxShadow>[] : [BoxShadow(color: const Color(0x12503C1E), blurRadius: blur, offset: Offset(0, dy))];
