/// Диалог приказа о назначении: что показывает и что отдаёт по «Скачать PDF».
///
/// Сети здесь нет — черновик берётся из фикстуры, а «Скачать PDF» получает
/// правки через колбэк; он же изображает долгую сборку и ошибку ручки.
library;

import 'dart:async';

import 'package:els/screns/object/appointment_order/fixture_appointment_order.dart';
import 'package:els/screns/object/appointment_order/model/appointment_order_draft.dart';
import 'package:els/screns/object/appointment_order/repository/appointment_order_repository.dart';
import 'package:els/screns/object/appointment_order/view/appointment_order_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpDialog(
  WidgetTester tester,
  AppointmentOrderDraft draft, {
  Future<void> Function(AppointmentOrderDraft)? onDownload,
}) async {
  final Future<void> Function(AppointmentOrderDraft) download =
      onDownload ?? (AppointmentOrderDraft _) async {};
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
              onDownload: download,
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

  testWidgets('пока PDF собирается — кнопка выключена и крутит индикатор',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    final Completer<void> building = Completer<void>();
    int calls = 0;
    await _pumpDialog(
      tester,
      buildAppointmentOrderFixture(AppointmentOrderFixture.full),
      onDownload: (AppointmentOrderDraft _) {
        calls++;
        return building.future;
      },
    );

    await tester.tap(find.text('Скачать PDF'));
    await tester.pump();

    expect(find.text('Собираем PDF…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final ElevatedButton button = tester.widget(
      find.ancestor(
        of: find.text('Собираем PDF…'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);

    building.complete();
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Скачать PDF'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ошибка ручки — текст в диалоге, правки на месте',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    await _pumpDialog(
      tester,
      buildAppointmentOrderFixture(AppointmentOrderFixture.full),
      onDownload: (AppointmentOrderDraft _) async {
        throw const AppointmentOrderException('Объект не найден');
      },
    );

    await tester.enterText(find.widgetWithText(TextField, '').first, '17');
    await tester.tap(find.text('Скачать PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Объект не найден'), findsOneWidget);
    expect(find.text('Приказ о назначении'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('Скачать PDF'), findsOneWidget);
  });
}
