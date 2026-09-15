/// Карточка работы из единой ленты «Работы».
///
/// Нажатие на строку ведёт в карточку той же работы; у ТО в ней чек-лист и
/// дефекты, у заявки — задание; «Проверил» из карточки отмечает строку в
/// ленте под ней.
library;

import 'package:els/bloc/user_bloc/user_bloc.dart';
import 'package:els/foreman/defects/defect_card_screen.dart';
import 'package:els/foreman/defects/defect_entry.dart';
import 'package:els/foreman/defects/defects_repository.dart';
import 'package:els/foreman/defects/work_defects_section.dart';
import 'package:els/screns/in_progress_works/models/order_details.dart';
import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/in_progress_works/widgets/work_card_body.dart';
import 'package:els/screns/works/models/work_item.dart';
import 'package:els/screns/works/repository/fixture_works_repository.dart';
import 'package:els/screns/works/view/work_item_card_screen.dart';
import 'package:els/screns/works/view/works_screen.dart';
import 'package:els/screns/works/widgets/work_row_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDetails extends WorkDetailsRepository {
  const _FakeDetails();

  @override
  Future<WorkDetails> fetchDetails(int actId) async => WorkDetails(
    id: actId,
    checklist: const WorkChecklist(
      title: 'ТО',
      steps: <ChecklistStep>[
        ChecklistStep(id: 1, title: 'Проверка табличек', done: true),
        ChecklistStep(id: 2, title: 'Осмотр канатов', done: false),
      ],
    ),
    mainMechanicId: 5,
  );

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async => WorkPhotos.empty;

  @override
  Future<OrderDetails> fetchOrder(int orderId) async => OrderDetails(
    id: orderId,
    taskText: 'Скрипит дверь',
    categoryName: 'Двери',
  );

  @override
  Future<OrderPhotos> fetchOrderPhotos(int orderId) async =>
      const OrderPhotos(<String>[]);

  @override
  Future<Performer> fetchPerformer(int userId) async =>
      Performer(id: userId, name: 'Смирнов А.', phone: '+7 921 000-00-00');
}

class _FakeDefects extends DefectsRepository {
  const _FakeDefects();

  @override
  Future<List<DefectEntry>> byActFact(int actFactId) async => const <DefectEntry>[
    DefectEntry(
      id: 1,
      title: 'Износ ролика',
      source: DefectSource.checklistStep,
      state: DefectState.created,
    ),
  ];

  @override
  Future<List<DefectEntry>> byOrder(int orderId) async => const <DefectEntry>[
    DefectEntry(
      id: 2,
      title: 'Обрыв цепи безопасности',
      source: DefectSource.order,
      state: DefectState.created,
      description: 'Найден при разборе заявки.',
    ),
  ];

  @override
  Future<DefectEntry> byId(int id) async =>
      (await byOrder(0)).firstWhere((DefectEntry e) => e.id == id);
}

Future<void> _pump(WidgetTester tester, {double width = 1440}) async {
  tester.view.physicalSize = Size(width, 4000.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    BlocProvider<UserBloc>(
      create: (_) => UserBloc(),
      child: MaterialApp(
        home: WorksScreen(
          repository: FixtureWorksRepository(delay: Duration.zero),
          drawer: const Drawer(),
          detailsRepository: const _FakeDetails(),
          defectsRepository: const _FakeDefects(),
          tick: null,
          poll: null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Строка ленты по номеру работы.
Finder _row(WorkItem item) => find.ancestor(
  of: find.text(item.number),
  matching: find.byType(WorkRowTile),
);

WorkItem _first(bool Function(WorkItem) test) => FixtureWorksRepository.items
    .firstWhere((WorkItem i) => i.isActual && test(i));

Future<void> _open(WidgetTester tester, WorkItem item) async {
  await tester.ensureVisible(_row(item));
  // По названию объекта, а не по строке целиком: центр строки может прийтись
  // на кнопку действия.
  await tester.tap(
    find.descendant(of: _row(item), matching: find.text(item.objectName)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('нажатие на ТО открывает карточку с чек-листом и дефектами', (
    tester,
  ) async {
    await _pump(tester);
    final WorkItem to = _first(
      (WorkItem i) =>
          i.kind == WorkKind.maintenance && i.status == WorkStatus.accepted,
    );
    await _open(tester, to);

    expect(find.byType(WorkItemCardScreen), findsOneWidget);
    expect(find.text(to.number), findsOneWidget);
    expect(find.text(to.objectName), findsOneWidget);
    expect(find.text('Проверка табличек'), findsOneWidget);
    expect(find.byType(WorkDefectsSection), findsOneWidget);
    expect(find.text('Износ ролика'), findsOneWidget);
    // Не закрыта — отмечать нечего.
    expect(find.text('Проверил'), findsNothing);
  });

  testWidgets('у заявки — задание, а не чек-лист', (tester) async {
    await _pump(tester);
    final WorkItem order = _first(
      (WorkItem i) =>
          i.kind == WorkKind.breakdown && i.status == WorkStatus.running,
    );
    await _open(tester, order);

    expect(find.byType(WorkOrderBlock), findsOneWidget);
    expect(find.text('Скрипит дверь'), findsOneWidget);
    expect(find.byType(WorkChecklistBlock), findsNothing);
  });

  testWidgets('у заявки есть дефекты, и по строке открывается акт', (
    tester,
  ) async {
    await _pump(tester);
    final WorkItem order = _first(
      (WorkItem i) =>
          i.kind == WorkKind.breakdown && i.status == WorkStatus.running,
    );
    await _open(tester, order);

    expect(find.byType(WorkDefectsSection), findsOneWidget);
    expect(find.text('Обрыв цепи безопасности'), findsOneWidget);
    // Акт ТО у заявки не спрашивается.
    expect(find.text('Износ ролика'), findsNothing);

    await tester.tap(find.text('Обрыв цепи безопасности'));
    await tester.pumpAndSettle();

    expect(find.byType(DefectCardScreen), findsOneWidget);
    expect(find.text('Найден при разборе заявки.'), findsOneWidget);
  });

  testWidgets('«Проверил» в карточке отмечает строку ленты', (tester) async {
    await _pump(tester);
    final WorkItem done = _first(
      (WorkItem i) => i.status == WorkStatus.submitted && !i.reviewed,
    );
    await _open(tester, done);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Проверил'));
    await tester.pumpAndSettle();
    expect(find.text('Проверено'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Проверил'), findsNothing);

    // Назад — строка уже отмечена, кнопки «Проверил» у неё нет.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    final WorkRowTile row = tester.widget(_row(done));
    expect(row.item.reviewed, isTrue);
  });

  testWidgets('на телефоне карточка складывается в колонку', (tester) async {
    await _pump(tester, width: 400);
    final WorkItem to = _first((WorkItem i) => i.kind == WorkKind.maintenance);
    await _open(tester, to);

    expect(find.byType(WorkItemCardScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
