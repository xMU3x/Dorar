import 'package:flutter_test/flutter_test.dart';
import 'package:dorar/core/tasks.dart';

void main() {
  test('إجمالي المهام ١٩ والنوافل إضافية', () {
    expect(kTasksTotal, 19);
    expect(taskSections.last.tasks.every((t) => t.bonus), isTrue);
  });
}
