import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/ui/theme.dart';
import 'package:habittracker/ui/widgets.dart';

void main() {
  testWidgets('عناصر الواجهة الأساسية تُرسم في وضع RTL', (tester) async {
    final p = Pal.make(false, 'green');
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      theme: buildTheme(p, false),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Column(children: [
            Ring(v: .5, child: Text('50%')),
            Bar(.3),
            AppCard(child: Text('بطاقة')),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('بطاقة'), findsOneWidget);
  });
}
