import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/core/tasks.dart';

void main() {
  test('إجمالي المهام ١٩ والنوافل إضافية', () {
    expect(kTasksTotal, 19);
    expect(taskSections.last.tasks.every((t) => t.bonus), isTrue);
  });
}
