import 'package:flutter_test/flutter_test.dart';
import 'package:dorar/core/tasks.dart';

void main() {
  test('قوالب المهام الأساسية: الفروض خمسة والنوافل إضافية', () {
    final salah = taskSections.firstWhere((s) => s.id == 'salah');
    expect(salah.tasks.length, 5);
    expect(taskSections.last.tasks.every((t) => t.bonus), isTrue);
  });
}
