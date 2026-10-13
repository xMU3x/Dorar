import 'package:flutter/material.dart';
import '../app.dart';
import '../core/khatma.dart';
import '../core/data.dart';
import '../core/tasks.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// بطاقة «مهام اليوم» في الرئيسية.
class TasksHomeCard extends StatelessWidget {
  const TasksHomeCard({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final d = tasksDone();
    return AppCard(
      onTap: () => pushPage(const TasksPage()),
      child: Row(children: [
        Ring(v: tasksFraction(), size: 54, stroke: 6, child: Text('${nf((tasksFraction() * 100).round())}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مهام اليوم', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Sub('${nf(d)} من ${nf(kTasksTotal)} مكتملة'),
        ])),
        Icon(Icons.chevron_left, color: p.on2),
      ]),
    );
  }
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  bool _done(TaskDef t) {
    if (taskDone(t.id)) return true;
    if (t.id == 'wird') {
      final kh = khatma();
      final goal = ((kh['goal'] as num?) ?? 5).toInt();
      return pagesToday() >= goal && goal > 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(builder: (context, _) {
      final p = Pal.of(context);
      final d = tasksDone(), tot = kTasksTotal;
      return PageScaffold(title: 'مهام اليوم', children: [
        AppCard(margin: const EdgeInsets.only(top: 6), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تقدّم اليوم', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            Sub('${nf(d)} من ${nf(tot)} مكتملة'),
          ])),
          Ring(v: tot == 0 ? 0 : d / tot, size: 64, stroke: 7, child: Text('${nf((tot == 0 ? 0 : d / tot * 100).round())}%', style: TextStyle(fontWeight: FontWeight.w700, color: p.pri))),
        ])),
        for (final s in taskSections) ..._section(context, p, s),
      ]);
    });
  }

  List<Widget> _section(BuildContext context, Pal p, TaskSection s) {
    final head = Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(children: [
        IconBox.named(s.icon, size: 30, circle: true),
        const SizedBox(width: 10),
        Text(s.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: p.line)),
      ]),
    );
    if (s.isGroup) {
      final n = s.tasks.where(taskDone2).length;
      final all = n == s.tasks.length;
      return [
        head,
        AppCard(margin: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(s.groupTitle!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            _Check(all, () { hap.click(); taskSetMany(s.tasks.map((t) => t.id), !all); }),
          ]),
          const SizedBox(height: 4),
          Sub('${nf(n)} من ${nf(s.tasks.length)}'),
          const SizedBox(height: 10),
          Row(children: [
            for (final t in s.tasks.reversed.toList().reversed)
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _MiniTask(t.title, taskDone(t.id), () { hap.click(); taskSet(t.id, !taskDone(t.id)); }, p),
              )),
          ]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () { hap.success(); taskSetMany(s.tasks.map((t) => t.id), true); },
            style: OutlinedButton.styleFrom(foregroundColor: p.ok, side: BorderSide(color: p.ok.withValues(alpha: .6))),
            child: Text('✅ ${s.groupBtn!}'),
          )),
        ])),
      ];
    }
    // أقسام عادية: بطاقتان جنب بعض للقرآن، وصفوف كاملة لغيرها
    if (s.id == 'quran') {
      final ts = s.tasks;
      final rows = <Widget>[];
      for (var i = 0; i < ts.length; i += 2) {
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: _TaskTile(ts[i], _done(ts[i]), p)),
            const SizedBox(width: 8),
            Expanded(child: i + 1 < ts.length ? _TaskTile(ts[i + 1], _done(ts[i + 1]), p) : const SizedBox.shrink()),
          ]),
        ));
      }
      return [head, ...rows];
    }
    return [head, for (final t in s.tasks) _TaskRow(t, _done(t), p)];
  }

  static bool taskDone2(TaskDef t) => taskDone(t.id);
}

class _Check extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _Check(this.on, this.onTap);
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: on ? p.pri : Colors.transparent, border: Border.all(color: on ? p.pri : p.on2.withValues(alpha: .5), width: 2)),
        child: on ? Icon(Icons.check, size: 20, color: p.onpri) : null,
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskDef t;
  final bool done;
  final Pal p;
  const _TaskRow(this.t, this.done, this.p);
  @override
  Widget build(BuildContext context) => AppCard(
        margin: const EdgeInsets.only(bottom: 8),
        color: done ? p.pc : null,
        onTap: () { done ? hap.tick() : hap.success(); taskSet(t.id, !taskDone(t.id)); },
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, decoration: done ? TextDecoration.lineThrough : null, decorationColor: p.on2)),
            if (t.hint != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(t.hint!, style: const TextStyle(fontFamily: quranFont, fontSize: 18, height: 1.9))),
          ])),
          if (t.route != null) ...[
            OutlinedButton.icon(
              onPressed: () => openRoute(t.route!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('افتح'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
            const SizedBox(width: 10),
          ],
          _Check(done, () { done ? hap.tick() : hap.success(); taskSet(t.id, !taskDone(t.id)); }),
        ]),
      );
}

class _TaskTile extends StatelessWidget {
  final TaskDef t;
  final bool done;
  final Pal p;
  const _TaskTile(this.t, this.done, this.p);
  @override
  Widget build(BuildContext context) => AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        radius: 18,
        color: done ? p.pc : null,
        borderColor: done ? p.pri : null,
        onTap: () { done ? hap.tick() : hap.click(); taskSet(t.id, !taskDone(t.id)); },
        child: SizedBox(
          height: 58,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16, height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: done ? p.pri : Colors.transparent, border: Border.all(color: done ? p.pri : p.on2, width: 1.6)),
              child: done ? Icon(Icons.check, size: 11, color: p.onpri) : null,
            ),
            const SizedBox(height: 8),
            Text(t.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: done ? p.pri : p.on)),
          ]),
        ),
      );
}

class _MiniTask extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onTap;
  final Pal p;
  const _MiniTask(this.title, this.done, this.onTap, this.p);
  @override
  Widget build(BuildContext context) => Material(
        color: done ? p.pc : p.surf2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: done ? p.pri : p.on2),
              const SizedBox(height: 4),
              FittedBox(child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: done ? p.pri : p.on))),
            ]),
          ),
        ),
      );
}
