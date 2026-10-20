import 'package:flutter/material.dart';

/// حاوية الترويسة (بعد حذف الصور العلوية لم يبقَ سوى المحتوى).
class SkylineHeader extends StatelessWidget {
  final double height;
  final Widget? child;
  final List<Color> colors; // للتوافق مع الشيفرة القديمة (غير مستخدمة)
  final double radius;
  final bool showSun;
  final bool arch; // إطار قوس بفوانيس
  final bool day; // نهار فاتح (الرئيسية)
  final bool beads; // سبحة وسجادة (التسبيح)
  final bool scrim; // تعتيم خفيف أعلى الصورة لوضوح النص
  final String? asset;
  const SkylineHeader({super.key, required this.height, this.child, this.colors = const [], this.radius = 0, this.showSun = true, this.arch = false, this.day = false, this.beads = false, this.scrim = true, this.asset});

  @override
  Widget build(BuildContext context) => SizedBox(height: height, width: double.infinity, child: child);
}
