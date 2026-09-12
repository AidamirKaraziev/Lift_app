/// Карточка «Топ сотрудников» показывает оба переключателя любой роли: с
/// 2026-09-12 рейтинг прорабов открыт и прорабу, и ветки по роли в виджете
/// больше нет. Тест держит это: если кто-то вернёт `isAdmin`, «Прорабы» у
/// прораба пропадут.
library;

import 'package:els/helper/session.dart';
import 'package:els/screns/home/top_employees/models/top_employees_report.dart';
import 'package:els/screns/home/top_employees/repository/top_employees_repository.dart';
import 'package:els/screns/home/top_employees/top_employees.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Отвечает пустым отчётом и запоминает, кого просили ранжировать.
class _StubRepository extends TopEmployeesRepository {
  const _StubRepository(this.requestedKinds);

  final List<EmployeeKind> requestedKinds;

  @override
  Future<TopEmployeesReport> fetch({
    required int year,
    required int month,
    EmployeeKind kind = EmployeeKind.mechanic,
    EmployeeOrder order = EmployeeOrder.best,
    int limit = 5,
    int offset = 0,
    int? divisionId,
    int? organizationId,
    int? companyId,
  }) async {
    requestedKinds.add(kind);
    return TopEmployeesReport(
      year: year,
      month: month,
      totalCount: 0,
      rankedCount: 0,
      minWorks: 3,
      items: const <EmployeeScoreItem>[],
    );
  }
}

Future<List<EmployeeKind>> _pump(WidgetTester tester, int role) async {
  idUserTest = role;
  final List<EmployeeKind> kinds = <EmployeeKind>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: TopEmployees(repository: _StubRepository(kinds)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return kinds;
}

void main() {
  tearDown(() => idUserTest = 0);

  for (final int role in <int>[Roles.foreman, Roles.admin]) {
    testWidgets('роль $role видит оба переключателя', (WidgetTester tester) async {
      await _pump(tester, role);

      expect(find.text('Лучшие'), findsOneWidget);
      expect(find.text('Худшие'), findsOneWidget);
      expect(find.text('Механики'), findsOneWidget);
      expect(find.text('Прорабы'), findsOneWidget);
    });
  }

  testWidgets('прораб переключается на рейтинг прорабов',
      (WidgetTester tester) async {
    final List<EmployeeKind> kinds = await _pump(tester, Roles.foreman);
    expect(kinds, <EmployeeKind>[EmployeeKind.mechanic]);

    await tester.tap(find.text('Прорабы'));
    await tester.pumpAndSettle();

    expect(kinds.last, EmployeeKind.foreman);
  });
}
