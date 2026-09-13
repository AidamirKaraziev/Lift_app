/// Экран «Работы» на фикстуре: что показывает и как реагирует на чипсы.
///
/// Смотрим не на вид пилюли, а на то, что лента и счётчики сходятся с
/// отбором: чипс обещает число строк, и после нажатия их должно быть ровно
/// столько.
library;

import 'package:els/screns/works/models/work_counts.dart';
import 'package:els/screns/works/models/work_filters.dart';
import 'package:els/screns/works/models/work_item.dart';
import 'package:els/screns/works/repository/fixture_works_repository.dart';
import 'package:els/screns/works/view/works_screen.dart';
import 'package:els/screns/works/widgets/work_row_tile.dart';
import 'package:els/screns/works/widgets/work_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double width = 1440}) async {
  // Высокое окно: лента ленивая, и на коротком окне часть строк не собралась
  // бы — счёт строк врал бы.
  tester.view.physicalSize = Size(width, 4000.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: WorksScreen(
        repository: FixtureWorksRepository(delay: Duration.zero),
        drawer: const Drawer(),
        tick: null,
        poll: null,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

int _rows(WidgetTester tester) => find.byType(WorkRowTile).evaluate().length;

/// Чипс по подписи — среди текстов панели, не среди пилюль строк.
Finder _chip(String label) =>
    find.descendant(of: find.byType(InkWell), matching: find.text(label));

void main() {
  final List<WorkItem> all = FixtureWorksRepository.items;
  final int live = all.where((WorkItem i) => i.isActual).length;
  final int archived = all.length - live;

  testWidgets('без отбора — все живые строки, архив спрятан', (tester) async {
    await _pump(tester);
    expect(_rows(tester), live);
    expect(find.text('в архиве'), findsNothing);
  });

  testWidgets('в ленте есть каждый статус', (tester) async {
    await _pump(tester);
    for (final WorkStatus status in WorkStatus.values) {
      expect(
        find.descendant(
          of: find.byType(WorkStub),
          matching: find.text(status.title),
        ),
        findsWidgets,
        reason: status.title,
      );
    }
  });

  testWidgets('чипс статуса сужает ленту до своего счётчика', (tester) async {
    await _pump(tester);
    final int expected = WorkCounts.count(
      all,
      const WorkFilters(),
    ).ofStatus(WorkStatus.running);

    await tester.tap(_chip('В работе').first);
    await tester.pumpAndSettle();

    expect(_rows(tester), expected);
    // Повторное нажатие снимает чипс.
    await tester.tap(_chip('В работе').first);
    await tester.pumpAndSettle();
    expect(_rows(tester), live);
  });

  testWidgets('чипс вида складывается со статусом', (tester) async {
    await _pump(tester);
    await tester.tap(_chip('Сдана').first);
    await tester.pumpAndSettle();
    await tester.tap(_chip('ТО').first);
    await tester.pumpAndSettle();

    final int expected = all
        .where(
          (WorkItem i) =>
              i.isActual &&
              i.status == WorkStatus.submitted &&
              i.kind == WorkKind.maintenance,
        )
        .length;
    expect(_rows(tester), expected);
    expect(find.textContaining('Сбросить всё (2)'), findsOneWidget);

    await tester.tap(find.textContaining('Сбросить всё (2)'));
    await tester.pumpAndSettle();
    expect(_rows(tester), live);
  });

  testWidgets('«Архив» показывает только мягко удалённые', (tester) async {
    await _pump(tester);
    await tester.tap(_chip('Архив').first);
    await tester.pumpAndSettle();

    expect(_rows(tester), archived);
    expect(find.text('в архиве'), findsNWidgets(archived));
  });

  testWidgets('поиск по объекту', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'карнавал');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final int expected = all
        .where(
          (WorkItem i) =>
              i.isActual && i.objectName.toLowerCase().contains('карнавал'),
        )
        .length;
    expect(_rows(tester), expected);
  });

  testWidgets('пустая выдача говорит про отбор, а не про базу', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'такого объекта нет');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Под отбор не подошла ни одна работа'), findsOneWidget);
    expect(_rows(tester), 0);
  });

  testWidgets('выпадашка участка отбирает по id', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Участок'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Север').last);
    await tester.pumpAndSettle();

    final int expected = all
        .where((WorkItem i) => i.isActual && i.sectionId == 2)
        .length;
    expect(_rows(tester), expected);
    expect(find.text('Участок: Север'), findsOneWidget);
  });

  testWidgets('«Мои участки» оставляет только участки прораба', (tester) async {
    await _pump(tester);
    await tester.tap(_chip('Мои участки').first);
    await tester.pumpAndSettle();

    final int expected = all
        .where(
          (WorkItem i) =>
              i.isActual &&
              FixtureWorksRepository.mySections.contains(i.sectionId),
        )
        .length;
    expect(_rows(tester), expected);
  });

  testWidgets('на телефоне строки складываются в колонку', (tester) async {
    await _pump(tester, width: 375);
    expect(_rows(tester), greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
