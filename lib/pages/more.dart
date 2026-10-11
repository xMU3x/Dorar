import 'package:flutter/material.dart';
import '../app.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class MoreItem {
  final String id, title, sub, icon, go;
  final bool full;
  const MoreItem(this.id, this.title, this.sub, this.icon, this.go, {this.full = false});
}

class MoreCat {
  final String id, title;
  final List<MoreItem> items;
  const MoreCat(this.id, this.title, this.items);
}

/// أضف صفحة جديدة بسطر واحد هنا (مطابق لـ W.more.categories في تطبيق الويب).
const moreCategories = [
  MoreCat('daily', 'العبادة اليومية', [
    MoreItem('reminders', 'التذكيرات', 'تنبيهات الأذكار', 'bell', 'reminders'),
    MoreItem('challenges', 'التحديات', 'أهدافك وإنجازاتك', 'trophy', 'challenges'),
    MoreItem('tasbih', 'التسبيح', 'سبحة إلكترونية', 'spark', 'tasbih'),
    MoreItem('khatma', 'خطة الختمة', 'تابع وردك اليومي', 'flag', 'khatma'),
  ]),
  MoreCat('dua', 'القرآن والدعاء', [
    MoreItem('ruqya', 'الرقية الشرعية', 'آيات وأذكار', 'water', 'ruqya'),
    MoreItem('zfav', 'الأذكار المفضلة', 'ما حفظته من الأذكار', 'fav', 'zfav'),
  ]),
  MoreCat('fast', 'الصيام والتقويم', [
    MoreItem('cal', 'التقويم الهجري', 'أيام الصيام والمواسم', 'cal', 'fasting'),
    MoreItem('fnext', 'إضافة يوم صيام', 'أيام مخصّصة بتكرار', 'add', 'fasting/add'),
  ]),
  MoreCat('app', 'الحساب والتطبيق', [
    MoreItem('account', 'حسابي والمزامنة', 'احفظ تقدّمك على أي جهاز', 'user', 'account', full: true),
    MoreItem('settings', 'الإعدادات', 'المظهر والاهتزاز والتاريخ الهجري', 'tune', 'settings', full: true),
    MoreItem('about', 'عن التطبيق', 'المصادر والإصدار', 'info', 'about', full: true),
  ]),
];

List<T> _sortBy<T>(List<T> arr, List order, String Function(T) key) {
  if (order.isEmpty) return arr;
  int ix(String id) { final i = order.indexOf(id); return i < 0 ? 999 : i; }
  return [...arr]..sort((a, b) => ix(key(a)).compareTo(ix(key(b))));
}

Map<String, dynamic> _ms() {
  final m = store.getMap('more', {'hide': [], 'ord': {}, 'cats': []});
  m['hide'] ??= [];
  m['ord'] ??= {};
  m['cats'] ??= [];
  return m;
}

void _upM(void Function(Map<String, dynamic>) fn) {
  final m = _ms();
  fn(m);
  store.set('more', m);
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});
  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool edit = false;

  void _move(String key, List<String> ids, String id, int d) {
    final i = ids.indexOf(id), j = i + d;
    if (j < 0 || j >= ids.length) return;
    ids.insert(j, ids.removeAt(i));
    hap.tick();
    _upM((m) => (m['ord'] as Map)[key] = ids);
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(tab: 4,
      builder: (context, _) {
        final p = Pal.of(context);
        final m = _ms();
        final hide = ((m['hide'] as List?) ?? []).cast<String>();
        final ord = Map<String, dynamic>.from(m['ord'] as Map);
        final catOrder = ((ord['_cats'] as List?) ?? []).cast<String>();
        final cats = _sortBy<MoreCat>(moreCategories.toList(), catOrder, (c) => c.id);
        return PageScaffold(
          title: 'المزيد',
          back: false,
          actions: [RoundIconButton(edit ? Icons.check_rounded : Icons.sort_rounded, () => setState(() => edit = !edit), tooltip: 'ترتيب')],
          children: [
            for (final c in cats) ...[
              if (edit || c.items.any((i) => !hide.contains(i.id))) SectionTitle(c.title),
              ...() {
                final order = ((ord[c.id] as List?) ?? []).cast<String>();
                final items = _sortBy<MoreItem>(c.items.toList(), order, (i) => i.id);
                final ids = items.map((e) => e.id).toList();
                return [
                  for (final it in items)
                    if (edit || !hide.contains(it.id))
                      Opacity(
                        opacity: hide.contains(it.id) ? .45 : 1,
                        child: ItemTile(
                          icon: iconOf(it.icon), title: it.title, sub: it.sub,
                          onTap: edit ? null : () => openRoute(it.go),
                          trailing: edit
                              ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(onPressed: () => _move(c.id, [...ids], it.id, -1), icon: const Icon(Icons.keyboard_arrow_up_rounded)),
                                  IconButton(onPressed: () => _move(c.id, [...ids], it.id, 1), icon: const Icon(Icons.keyboard_arrow_down_rounded)),
                                  IconButton(onPressed: () { hap.tick(); _upM((mm) { final h = ((mm['hide'] as List)).cast<String>().toList(); h.contains(it.id) ? h.remove(it.id) : h.add(it.id); mm['hide'] = h; }); }, icon: Icon(hide.contains(it.id) ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: p.pri)),
                                ])
                              : null,
                        ),
                      ),
                ];
              }(),
            ],
          ],
        );
      },
    );
  }
}
