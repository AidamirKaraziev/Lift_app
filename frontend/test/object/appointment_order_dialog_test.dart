/// Диалог приказа о назначении: что показывает и что отдаёт по «Скачать PDF».
///
/// Сети здесь нет — черновик берётся из фикстуры, а «Скачать PDF» получает
/// правки через колбэк.
library;

import 'package:els/screns/object/appointment_order/fixture_appointment_order.dart';
import 'package:els/screns/object/appointment_order/model/appointment_order_draft.dart';
import 'package:els/screns/object/appointment_order/view/appointment_order_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpDialog(
  WidgetTester tester,
  AppointmentOrderDraft draft, {
  Future<void> Function(AppointmentOrderDraft)? onDownload,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const <Locale>[Locale('ru', '')],
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showAppointmentOrderDialog(
              context,
              draft: draft,
              onDownload: onDownload,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('полный расклад: люди, два лифта, обе кнопки', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    await _pumpDialog(
      tester,
      buildAppointmentOrderFixture(AppointmentOrderFixture.full),
    );

    expect(find.text('Приказ о назначении'), findsOneWidget);
    expect(find.text('Петров Иван Сергеевич'), findsOneWidget);
    expect(find.text('Смирнов Алексей Владимирович'), findsOneWidget);
    expect(find.text('Лифт Пассажирский, Wellmaks, г/п 400 кг.'), findsOneWidget);
    expect(find.text('Лифт Пассажирский, Wellmaks, г/п 630 кг.'), findsOneWidget);
    expect(find.text('13.09.2026'), findsOneWidget);
    expect(find.text('Скачать PDF'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('нет механика — сказано словами', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    await _pumpDialog(
      tester,
      buildAppointmentOrderFixture(AppointmentOrderFixture.noMechanic),
    );

    expect(find.text('Электромеханик не закреплён за объектом'), findsOneWidget);
    expect(find.text('Петров Иван Сергеевич'), findsOneWidget);
  });

  testWidgets('«Скачать PDF» отдаёт черновик с правками', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    AppointmentOrderDraft? sent;
    await _pumpDialog(
      tester,
      buildAppointmentOrderFixture(AppointmentOrderFixture.full),
      onDownload: (AppointmentOrderDraft d) async => sent = d,
    );

    await tester.enterText(find.widgetWithText(TextField, '').first, '17');
    await tester.tap(find.text('Скачать PDF'));
    await tester.pumpAndSettle();

    expect(sent, isNotNull);
    expect(sent!.number, '17');
    expect(sent!.city, 'Краснодар');
    expect(sent!.lifts, hasLength(2));
  });

  test('fromObjectMap берёт из карточки адрес, людей и лифт', () {
    final AppointmentOrderDraft draft = AppointmentOrderDraft.fromObjectMap(
      <String, dynamic>{
        'address': 'ул. Кожевенная, 66',
        'load_capacity': 400,
        'factory_model_id': <String, dynamic>{
          'model': 'Wellmaks',
          'type_object_id': <String, dynamic>{'name': 'Лифт Пассажирский'},
        },
        'foreman_id': <String, dynamic>{'name': 'Петров И. С.'},
        'mechanic_id': null,
      },
    );

    expect(draft.address, 'ул. Кожевенная, 66');
    expect(draft.foreman?.fullName, 'Петров И. С.');
    expect(draft.mechanic, isNull);
    expect(draft.lifts.single.line, 'Лифт Пассажирский, Wellmaks, г/п 400 кг.');
    expect(draft.number, isEmpty);
  });
}
