import 'package:flutter/material.dart';
import '../core/data.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

// [الاسم، السورة، من آية، إلى آية، عدد التكرار]
const _ruqya = [
  ['سورة الفاتحة', 1, 1, 7, 1], ['أول سورة البقرة', 2, 1, 5, 1], ['آية الكرسي', 2, 255, 255, 1], ['خواتيم سورة البقرة', 2, 284, 286, 1],
  ['سورة الإخلاص', 112, 1, 4, 3], ['سورة الفلق', 113, 1, 5, 3], ['سورة الناس', 114, 1, 6, 3],
];

class RuqyaPage extends StatefulWidget {
  const RuqyaPage({super.key});
  @override
  State<RuqyaPage> createState() => _RuqyaPageState();
}

class _RuqyaPageState extends State<RuqyaPage> {
  final done = <int, int>{};
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return FutureBuilder(
      future: data.quran(),
      builder: (context, s) {
        final q = s.data;
        return PageScaffold(
          title: 'الرقية الشرعية',
          actions: [RoundIconButton(Icons.refresh_rounded, () => setState(done.clear))],
          children: [
            if (q == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            if (q != null)
              for (var i = 0; i < _ruqya.length; i++)
                Builder(builder: (_) {
                  final r = _ruqya[i];
                  final surah = r[1] as int, a = r[2] as int, b = r[3] as int, rep = r[4] as int;
                  final text = (q['ayahs'] as List).where((x) => x[0] == surah && x[1] >= a && x[1] <= b).map((x) => '${x[2]} ﴿${nf(x[1] as int)}﴾').join(' ');
                  final basmala = (surah != 1 && a == 1 && surah != 9) ? '${q['basmala']} ' : '';
                  final n = done[i] ?? 0, ok = n >= rep;
                  return AppCard(
                    margin: const EdgeInsets.only(top: 10),
                    color: ok ? p.pc : p.surf,
                    onTap: () {
                      if (ok) { hap.error(); return; }
                      setState(() => done[i] = n + 1);
                      (n + 1 >= rep) ? hap.success() : hap.click();
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r[0] as String, style: TextStyle(color: p.pri, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('$basmala$text', style: const TextStyle(fontFamily: quranFont, fontSize: 24, height: 2.1)),
                      const SizedBox(height: 6),
                      Align(alignment: AlignmentDirectional.centerEnd, child: CircleAvatar(radius: 24, backgroundColor: ok ? p.pri : p.pc, child: ok ? Icon(Icons.check_rounded, color: p.onpri) : Text(nf(rep - n), style: TextStyle(color: p.pri, fontWeight: FontWeight.w700, fontSize: 18)))),
                    ]),
                  );
                }),
          ],
        );
      },
    );
  }
}
