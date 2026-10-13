import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/azkar.dart';
import '../core/data.dart';
import '../core/store.dart';
import '../core/tasks.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

// [الاسم، السورة، من آية، إلى آية، عدد التكرار]
const _ruqya = [
  ['سورة الفاتحة', 1, 1, 7, 1], ['أول سورة البقرة', 2, 1, 5, 1], ['آية الكرسي', 2, 255, 255, 1], ['خواتيم سورة البقرة', 2, 284, 286, 1],
  ['سورة الإخلاص', 112, 1, 4, 3], ['سورة الفلق', 113, 1, 5, 3], ['سورة الناس', 114, 1, 6, 3],
];
const _basmala = 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ';

class RuqyaPage extends StatefulWidget {
  const RuqyaPage({super.key});
  @override
  State<RuqyaPage> createState() => _RuqyaPageState();
}

class _RuqyaPageState extends State<RuqyaPage> {
  final done = <int, int>{};
  final keys = List.generate(_ruqya.length, (_) => GlobalKey());
  int rounds = 0;

  bool _ok(int i) => (done[i] ?? 0) >= (_ruqya[i][4] as int);

  void _tap(int i) {
    final rep = _ruqya[i][4] as int, n = done[i] ?? 0;
    if (n >= rep) { hap.error(); return; }
    setState(() => done[i] = n + 1);
    if (n + 1 < rep) { hap.click(); return; }
    hap.success();
    touchActivity();
    if (List.generate(_ruqya.length, _ok).every((x) => x)) {
      setState(() => rounds++);
      taskSet('shifa', true);
      if (doneSoundOn()) SystemSound.play(SystemSoundType.alert);
      toast('أتممت الرقية، شفاك الله وعافاك 🤍');
      return;
    }
    if (!autoNextOn()) return;
    // ننتقل تلقائيًا إلى البطاقة غير المكتملة التالية
    var j = i + 1;
    while (j < _ruqya.length && _ok(j)) { j++; }
    if (j >= _ruqya.length) { j = List.generate(_ruqya.length, (x) => x).where((x) => !_ok(x)).firstOrNull ?? -1; }
    if (j < 0) return;
    Future.delayed(const Duration(milliseconds: 380), () {
      final c = keys[j].currentContext;
      if (c != null && mounted) Scrollable.ensureVisible(c, alignment: .04, duration: const Duration(milliseconds: 520), curve: Curves.easeInOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mq = MediaQuery.of(context);
    final fs = ((cfg.get('zfs') as num?) ?? 28).toDouble();
    return FutureBuilder(
      future: data.quran(),
      builder: (context, s) {
        final q = s.data;
        final nDone = List.generate(_ruqya.length, _ok).where((x) => x).length;
        return Scaffold(
          backgroundColor: p.bg,
          body: Column(children: [
            Container(
              padding: EdgeInsets.fromLTRB(12, mq.padding.top + 8, 12, 10),
              decoration: BoxDecoration(color: p.bg, border: Border(bottom: BorderSide(color: p.line, width: 2))),
              child: Row(children: [
                _hb(p, Icons.arrow_forward, () => Navigator.of(context).maybePop()),
                const Expanded(child: Text('الرقية الشرعية', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
                _hb(p, Icons.refresh, () => setState(done.clear)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14, 14, 14, mq.padding.bottom + 110),
                physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  Row(children: [
                    Icon(Icons.history, size: 20, color: p.on2),
                    const SizedBox(width: 6),
                    Text('عدد مرات القراءة: ${nf(rounds)}', style: TextStyle(color: p.on2, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${nf(nDone)} / ${nf(_ruqya.length)}', style: TextStyle(color: p.pri, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Bar(nDone / _ruqya.length),
                  if (q == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
                  if (q != null)
                    for (var i = 0; i < _ruqya.length; i++)
                      Builder(builder: (_) {
                        final r = _ruqya[i];
                        final surah = r[1] as int, a = r[2] as int, b = r[3] as int, rep = r[4] as int;
                        final text = (q['ayahs'] as List).where((x) => x[0] == surah && x[1] >= a && x[1] <= b).map((x) => '${x[2]} ﴿${nf(x[1] as int)}﴾').join(' ');
                        final n = done[i] ?? 0, ok = n >= rep;
                        return KeyedSubtree(
                          key: keys[i],
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: ok ? .62 : 1,
                            child: AppCard(
                              margin: const EdgeInsets.only(top: 14),
                              radius: 30,
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                              color: ok ? p.pc : p.surf,
                              onTap: () => _tap(i),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                Text(r[0] as String, textAlign: TextAlign.center, style: TextStyle(color: p.pri, fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(_basmala, textAlign: TextAlign.center, style: TextStyle(fontFamily: quranFont, fontSize: fs * .78, fontWeight: FontWeight.w700, color: p.gold, height: 1.9)),
                                Text(text, textAlign: TextAlign.center, style: TextStyle(fontFamily: quranFont, fontSize: fs, height: 2.1, color: p.on)),
                                const SizedBox(height: 12),
                                Row(children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                                    child: Container(
                                      key: ValueKey('$n/$rep'),
                                      width: 58, height: 58, alignment: Alignment.center,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? p.pri : p.surf2),
                                      child: ok ? Icon(Icons.check, color: p.onpri, size: 28) : Text(nf(rep - n), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: p.pri)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(rep == 1 ? 'يُقال مرة واحدة' : 'يُقال ${nf(rep)} مرات', style: TextStyle(color: p.on2, fontSize: 14.5))),
                                ]),
                              ]),
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _hb(Pal p, IconData i, VoidCallback f) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: Material(
          color: p.surf, shape: CircleBorder(side: BorderSide(color: p.line)),
          child: InkWell(customBorder: const CircleBorder(), onTap: () { hap.tick(); f(); }, child: SizedBox(width: 42, height: 42, child: Icon(i, size: 21, color: p.on))),
        ),
      );
}
