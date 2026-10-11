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
    fontFamily: 'Tajawal',
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: base.copyWith(primary: p.pri, onPrimary: p.onpri, surface: p.surf, onSurface: p.on, primaryContainer: p.pc, outlineVariant: p.line),
    scaffoldBackgroundColor: p.bg,
    splashFactory: InkSparkle.splashFactory,
    extensions: [p],
    textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light).textTheme.apply(fontFamily: 'Tajawal', bodyColor: p.on, displayColor: p.on),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surf2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

const quranFont = 'AmiriQuran';
const arabicFont = 'Amiri';
final Cfg _c = cfg;
String modeSetting() => _c.get('mode') as String;
String palSetting() => _c.get('pal') as String;
