import 'package:flutter/material.dart';
import '../core/data.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// نص السورة بخط المصحف (يُفتح من «فتح السورة» في المشغّل).
class SurahPage extends StatelessWidget {
  final int surah;
  const SurahPage(this.surah, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return FutureBuilder(
      future: Future.wait([data.ayahs(), data.surahName(surah), data.quran()]),
      builder: (context, s) {
        if (!s.hasData) return const PageScaffold(title: 'السورة', children: [Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))]);
        final ay = (s.data![0] as List).where((a) => (a as List)[0] == surah).toList();
        final name = s.data![1] as String;
        final basmala = (s.data![2] as Map)['basmala'] as String?;
        final spans = <InlineSpan>[];
        for (final a in ay) {
          final l = a as List;
          spans.add(TextSpan(text: '${l[2]} '));
          spans.add(TextSpan(text: '﴿${toAr(l[1] as int)}﴾ ', style: TextStyle(color: p.gold, fontSize: 18)));
        }
        return PageScaffold(title: 'سورة $name', children: [
          if (basmala != null && surah != 1 && surah != 9) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(basmala, textAlign: TextAlign.center, style: const TextStyle(fontFamily: quranFont, fontSize: 26, height: 2))),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Text.rich(TextSpan(children: spans), textAlign: TextAlign.justify, style: const TextStyle(fontFamily: quranFont, fontSize: 26, height: 2.2)),
          ),
        ]);
      },
    );
  }
}
