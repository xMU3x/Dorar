import 'package:flutter/material.dart';
import '../app.dart';
import '../core/store.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/wicons.dart';

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
  MoreCat('reports', 'التقارير', [
    MoreItem('reports', 'التقارير', 'ملخّص نشاطك', 'cal', 'reports'),
    MoreItem('stats', 'الإحصائيات', 'أرقامك في نظرة', 'info', 'stats'),
    MoreItem('ach', 'الإنجازات', 'أوسمتك وإنجازاتك', 'trophy', 'ach'),
    MoreItem('cal', 'التقويم', 'الهجري والميلادي', 'cal', 'calendar'),
  ]),
  MoreCat('mawaiz', 'المواعظ', [
    MoreItem('mawaiz', 'مواعظ ومحاضرات', 'محاضرات وخطب مسموعة لكبار المشايخ', 'music', 'mawaiz', full: true),
    MoreItem('mawaizw', 'مواعظ مكتوبة', 'آيات وأحاديث وآثار', 'book', 'mawaizw', full: true),
  ]),
  MoreCat('daily', 'العبادة اليومية', [
    MoreItem('reminders', 'التذكيرات', 'تنبيهات الأذكار', 'bell', 'reminders'),
    MoreItem('challenges', 'التحديات', 'أهدافك وإنجازاتك', 'trophy', 'challenges'),
    MoreItem('tasbih', 'التسبيح', 'سبحة إلكترونية', 'spark', 'tasbih'),
    MoreItem('khatma', 'خطة الختمة', 'تابع وردك اليومي', 'flag', 'khatma'),
    MoreItem('tasks', 'المهام والعادات', 'نظّم يومك', 'check', 'tasks'),
  ]),
  MoreCat('dua', 'القرآن والعلم', [
    MoreItem('ruqya', 'الرقية الشرعية', 'آيات وأذكار', 'water', 'ruqya'),
    MoreItem('zfav', 'الأذكار المفضلة', 'ما حفظته من الأذكار', 'fav', 'zfav'),
    MoreItem('hadith', 'الحديث', 'الصحيحان والأربعون', 'book', 'hadith'),
    MoreItem('library', 'المكتبة', 'كتب إسلامية', 'book', 'library'),
    MoreItem('anbiya', 'قصص الأنبياء', 'من القرآن والسنة', 'book', 'anbiya'),
  ]),
  MoreCat('fast', 'الصيام', [
    MoreItem('fasting', 'الصيام', 'أيام الصيام وإحصاءاتك', 'moon', 'fasting'),
    MoreItem('fnext', 'إضافة يوم صيام', 'أيام مخصّصة بتكرار', 'add', 'fasting/add'),
  ]),
  MoreCat('app', 'الحساب والتطبيق', [
    MoreItem('profile', 'الملف الشخصي', 'مستواك والمظهر والتفاعل', 'user', 'profile', full: true),
    MoreItem('account', 'النسخ الاحتياطي والمزامنة', 'احفظ تقدّمك على أي جهاز', 'sync', 'account', full: true),
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
    return StoreBuilder(tab: 5,
      builder: (context, _) {
        final m = _ms();
        final hide = ((m['hide'] as List?) ?? []).cast<String>();
        final ord = Map<String, dynamic>.from(m['ord'] as Map);
        final catOrder = ((ord['_cats'] as List?) ?? []).cast<String>();
        final cats = _sortBy<MoreCat>(moreCategories.toList(), catOrder, (c) => c.id);
        return PageScaffold(
          title: 'المزيد',
          back: false,
          actions: [RoundIconButton(edit ? Icons.check : Icons.sort, () => setState(() => edit = !edit), tooltip: 'ترتيب')],
          children: [
            for (final c in cats) ...[
              if (edit || c.items.any((i) => !hide.contains(i.id))) GoldTitle(c.title),
              ...() {
                final order = ((ord[c.id] as List?) ?? []).cast<String>();
                final items = _sortBy<MoreItem>(c.items.toList(), order, (i) => i.id);
                final ids = items.map((e) => e.id).toList();
                final vis = [for (final it in items) if (edit || !hide.contains(it.id)) it];
                if (!edit) {
                  final halves = vis.where((e) => !e.full).toList(), fulls = vis.where((e) => e.full).toList();
                  return <Widget>[
                    for (var i = 0; i < halves.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Expanded(child: _Mc(halves[i], half: true)),
                          const SizedBox(width: 12),
                          Expanded(child: i + 1 < halves.length ? _Mc(halves[i + 1], half: true) : const SizedBox.shrink()),
                        ]),
                      ),
                    for (final it in fulls) Padding(padding: const EdgeInsets.only(bottom: 10), child: _Mc(it)),
                  ];
                }
                return <Widget>[
                  for (final it in vis)
                    Opacity(
                      opacity: hide.contains(it.id) ? .45 : 1,
                      child: ItemTile(
                        iconName: it.icon, title: it.title, sub: it.sub,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(onPressed: () => _move(c.id, [...ids], it.id, -1), icon: const Icon(Icons.keyboard_arrow_up)),
                          IconButton(onPressed: () => _move(c.id, [...ids], it.id, 1), icon: const Icon(Icons.keyboard_arrow_down)),
                          IconButton(onPressed: () { hap.tick(); _upM((mm) { final h = ((mm['hide'] as List)).cast<String>().toList(); h.contains(it.id) ? h.remove(it.id) : h.add(it.id); mm['hide'] = h; }); }, icon: Icon(hide.contains(it.id) ? Icons.visibility_off : Icons.visibility)),
                        ]),
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

/// بطاقة «المزيد» (.mc): دائرة أيقونة 46 + عنوان + وصف، بإطار 1.5 وزوايا 26.
class _Mc extends StatelessWidget {
  final MoreItem it;
  final bool half;
  const _Mc(this.it, {this.half = false});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final dark = p.bg.computeLuminance() < .3;
    final ic = Container(width: 38, height: 38, decoration: BoxDecoration(color: p.pc, shape: BoxShape.circle), child: Center(child: WIcon(it.icon, size: 20, color: dark ? p.pri : p.pri2)));
    final tx = Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: half ? 13 : 14, fontWeight: FontWeight.w700, height: 1.3)),
      Text(it.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: p.on2, height: 1.35)),
    ]));
    return AppCard(
      margin: EdgeInsets.zero,
      radius: 18,
      padding: const EdgeInsets.all(10),
      onTap: () => openRoute(it.go),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: half ? 44 : 0),
        child: half ? Row(children: [tx, ic]) : Row(children: [ic, const SizedBox(width: 12), tx, WIcon('chev', color: p.on2)]),
      ),
    );
  }
}
