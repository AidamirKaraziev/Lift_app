/// Черновик приказа ↔ JSON ручек `draft` и `pdf`.
///
/// Ответ как в снимке `backend/tests/snapshots/openapi_surface.json`: строки
/// без данных приходят `null`, дата — секундами полуночи по UTC.
library;

import 'package:els/screns/object/appointment_order/model/appointment_order_draft.dart';
import 'package:flutter_test/flutter_test.dart';

final int _midnight =
    DateTime.utc(2026, 9, 15).millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> _response() => <String, dynamic>{
      'number': '',
      'date': _midnight,
      'city': '',
      'address': 'Краснодарский край, г. Краснодар, ул. Кожевенная, 66',
      'organization': 'ООО «Лифтсервис»',
      'signer_position': 'Генеральный директор',
      'signer_name': 'Кузнецов Д. А.',
      'foreman': <String, dynamic>{
        'full_name': 'Петров Иван Сергеевич',
        'position': 'прораба сервисного участка',
      },
      'mechanic': null,
      'lifts': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'Лифт Пассажирский',
          'brand': 'Wellmaks',
          'load_capacity_kg': 400,
        },
      ],
    };

void main() {
  test('fromJson: поля, null → пусто, дата — день по UTC', () {
    final AppointmentOrderDraft draft =
        AppointmentOrderDraft.fromJson(_response());

    expect(draft.date, DateTime(2026, 9, 15));
    expect(draft.organization, 'ООО «Лифтсервис»');
    expect(draft.signerName, 'Кузнецов Д. А.');
    expect(draft.foreman?.fullName, 'Петров Иван Сергеевич');
    expect(draft.foreman?.position, AppointmentPerson.foremanPosition);
    expect(draft.mechanic, isNull);
    expect(draft.lifts.single.line, 'Лифт Пассажирский, Wellmaks, г/п 400 кг.');
  });

  test('fromJson: без организации и лифтов — пустые строки, не null', () {
    final AppointmentOrderDraft draft = AppointmentOrderDraft.fromJson(
      <String, dynamic>{
        'date': _midnight,
        'address': null,
        'organization': null,
        'signer_position': null,
        'signer_name': null,
        'foreman': null,
        'mechanic': null,
        'lifts': <Object>[],
      },
    );

    expect(draft.address, isEmpty);
    expect(draft.organization, isEmpty);
    expect(draft.signerPosition, isEmpty);
    expect(draft.foreman, isNull);
    expect(draft.lifts, isEmpty);
  });

  test('toJson: тот же формат, что у ответа; дата — секунды полуночи UTC', () {
    final AppointmentOrderDraft edited = AppointmentOrderDraft.fromJson(
      _response(),
    ).copyWith(number: '17', city: 'Краснодар', date: DateTime(2026, 9, 20, 15, 30));

    final Map<String, dynamic> json = edited.toJson();

    expect(json['number'], '17');
    expect(json['city'], 'Краснодар');
    expect(json['date'], DateTime.utc(2026, 9, 20).millisecondsSinceEpoch ~/ 1000);
    expect(json['signer_position'], 'Генеральный директор');
    expect(json['foreman'], <String, dynamic>{
      'full_name': 'Петров Иван Сергеевич',
      'position': 'прораба сервисного участка',
    });
    expect(json['mechanic'], isNull);
    expect(json['lifts'], <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'Лифт Пассажирский',
        'brand': 'Wellmaks',
        'load_capacity_kg': 400,
      },
    ]);
  });
}
