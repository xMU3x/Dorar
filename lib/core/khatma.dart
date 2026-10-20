import 'data.dart';
import 'store.dart';
import 'util.dart';

Map<String, dynamic> khatma() => store.peekMap('khatma', {'read': 0, 'goal': 5, 'done': 0, 'start': todayKey(), 'last': null});

/// يرجع true إذا أُتمّت ختمة كاملة.
bool khatmaAdd(int n) {
  var finished = false;
  store.upd('khatma', {'read': 0, 'goal': 5, 'done': 0, 'start': todayKey()}, (k) {
    k['last'] = n;
    k['lt'] = DateTime.now().millisecondsSinceEpoch;
    k['read'] = ((k['read'] as num?) ?? 0).toInt() + n;
    if ((k['read'] as int) >= 604) {
      k['read'] = 0;
      k['done'] = ((k['done'] as num?) ?? 0).toInt() + 1;
      k['start'] = todayKey();
      finished = true;
    }
  });
  addPages(n);
  return finished;
}

void khatmaUndo() {
  final k = khatma();
  final n = ((k['last'] as num?) ?? 0).toInt();
  if (n == 0) return;
  store.upd('khatma', {}, (z) {
    final r = ((z['read'] as num?) ?? 0).toInt() - n;
    z['read'] = r < 0 ? 0 : r;
    z['last'] = 0;
  });
  addPages(-n);
}
