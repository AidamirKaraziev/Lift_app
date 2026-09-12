/// Число непросмотренных у пункта меню «Работы».
///
/// Проверяется то, что решает макет: ноль не показывается, сотни
/// сворачиваются в «99+», число меняется само вслед за значением.
library;

import 'package:els/helper/count_chip.dart';
import 'package:els/screns/submitted_works/unreviewed_counter.dart';
import 'package:els/screns/works/widgets/unreviewed_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: UnreviewedChip())),
  );
}

void main() {
  setUp(() => unreviewedWorksCount.value = 0);

  testWidgets('есть непросмотренные — одна серая таблетка с числом',
      (WidgetTester tester) async {
    unreviewedWorksCount.value = 11;
    await _pump(tester);

    expect(find.text('11'), findsOneWidget);
    expect(find.byType(CountChip), findsOneWidget);
  });

  testWidgets('всё проверено — в меню пусто, а не ноль',
      (WidgetTester tester) async {
    await _pump(tester);

    expect(find.byType(CountChip), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('сотня сворачивается в «99+»', (WidgetTester tester) async {
    unreviewedWorksCount.value = 137;
    await _pump(tester);

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('число меняется само, вслед за значением',
      (WidgetTester tester) async {
    unreviewedWorksCount.value = 4;
    await _pump(tester);

    unreviewedWorksCount.value = 3;
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);

    unreviewedWorksCount.value = 0;
    await tester.pump();
    expect(find.byType(CountChip), findsNothing);
  });
}
