import 'package:flutter/material.dart';
import '../app.dart';
import '../core/player.dart';
import '../core/util.dart';
import 'theme.dart';
import 'widgets.dart';

/// وجهات الشريط السفلي (المعرّف ← أيقونة وتسمية).
const Map<String, (IconData, String)> kNavDefs = {
  'home': (Icons.home_rounded, 'الرئيسية'),
  'tasks': (Icons.check_circle_outline_rounded, 'المهام'),
  'quran': (Icons.menu_book_rounded, 'القرآن'),
  'azkar': (Icons.auto_awesome, 'الأذكار'),
  'fasting': (Icons.nightlight_round, 'الصيام'),
  'more': (Icons.grid_view_rounded, 'المزيد'),
};

/// التبويبات الرئيسية بالترتيب (الفهرس = tabIndex).
const kMainTabs = ['home', 'tasks', 'quran', 'azkar', 'fasting', 'more'];

/// ينتقل لوجهة الشريط: تبويب رئيسي أو صفحة فرعية.
void goNav(String id) {
  final i = kMainTabs.indexOf(id);
  navKey.currentState?.popUntil((r) => r.isFirst);
  if (i >= 0) {
    tabIndex.value = i;
    return;
  }
  openRoute(id);
}

/// شريط التنقل السفلي: أيقونات فقط، والمختارة وحدها تظهر باسمها داخل كبسولة.
class AppNavBar extends StatelessWidget {
  final List<String> ids;
  final String selected;
  final ValueChanged<String> onTap;
  const AppNavBar({super.key, required this.ids, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.only(bottom: bottom),
        decoration: BoxDecoration(
          color: p.surf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: p.line)),
          boxShadow: softShadow(16, -3),
        ),
        child: SizedBox(
          height: 60,
          child: Row(children: [
            for (final id in ids)
              Expanded(
                flex: id == selected ? 30 : 20,
                child: _NavItem(icon: kNavDefs[id]!.$1, label: kNavDefs[id]!.$2, selected: id == selected, onTap: () => onTap(id)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final c = widget.selected ? p.pri : p.on2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .92 : 1,
        duration: const Duration(milliseconds: 90),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: widget.selected ? 10 : 6),
            decoration: BoxDecoration(color: widget.selected ? p.pc : Colors.transparent, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, size: 22, color: c),
              if (widget.selected) ...[
                const SizedBox(width: 5),
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.label, maxLines: 1, style: TextStyle(fontSize: 12.5, height: 1.1, fontWeight: FontWeight.w800, color: c)))),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// لم يعد للصفحات الفرعية شريط خاص: الشريط الرئيسي ثابت في الأسفل.
Widget pageNav(String sel) => const SizedBox.shrink();
