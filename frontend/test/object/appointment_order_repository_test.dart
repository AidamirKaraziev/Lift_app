/// Адреса ручек приказа, тело `pdf` и ошибки словами.
///
/// Сети нет: подменяются `send`/`post`, и проверяется, куда ушёл запрос, что
/// в нём лежало и что репозиторий достал из ответа.
library;

import 'dart:convert';

import 'package:els/screns/object/appointment_order/model/appointment_order_draft.dart';
import 'package:els/screns/object/appointment_order/repository/appointment_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

AppointmentOrderRepository _repository(
  Object? data, {
  int status = 200,
  List<Uri>? seen,
  List<Object>? bodies,
}) {
  final String body = jsonEncode(<String, Object?>{'data': data});
  return AppointmentOrderRepository(
    send: (Uri uri) async {
      seen?.add(uri);
      return http.Response.bytes(utf8.encode(body), status);
    },
    post: (Uri uri, Object payload) async {
      seen?.add(uri);
      bodies?.add(payload);
      return http.Response.bytes(utf8.encode(body), status);
    },
  );
}

final Map<String, dynamic> _draftJson = <String, dynamic>{
  'number': '',
  'date': DateTime(2026, 9, 15).millisecondsSinceEpoch ~/ 1000,
  'city': '',
  'address': 'ул. Кожевенная, 66',
  'organization': 'ООО «Лифтсервис»',
  'signer_position': 'Генеральный директор',
  'signer_name': 'Кузнецов Д. А.',
  'foreman': <String, dynamic>{
    'full_name': 'Петров Иван Сергеевич',
    'position': 'прораба сервисного участка',
  },
  'mechanic': null,
  'lifts': <Object>[],
};

void main() {
  test('fetchDraft: адрес ручки и разбор черновика', () async {
    final List<Uri> seen = <Uri>[];
    final AppointmentOrderDraft draft =
        await _repository(_draftJson, seen: seen).fetchDraft(12);

    expect(seen.single.path, endsWith('/api/v1/object/12/appointment-order/draft'));
    expect(draft.signerName, 'Кузнецов Д. А.');
    expect(draft.foreman?.fullName, 'Петров Иван Сергеевич');
    expect(draft.mechanic, isNull);
  });

  test('buildPdf: тело — черновик с правками, ссылка со схемой', () async {
    final List<Uri> seen = <Uri>[];
    final List<Object> bodies = <Object>[];
    final AppointmentOrderDraft edited = AppointmentOrderDraft.fromJson(
      _draftJson,
    ).copyWith(number: '17', city: 'Краснодар');

    final String url = await _repository(
      <String, Object>{
        'path': 'objects/12/appointment_order/9f3c.pdf',
        'url': 'els23.ru/api/v1/static/objects/12/appointment_order/9f3c.pdf?token=t',
        'expires_in': 60,
      },
      seen: seen,
      bodies: bodies,
    ).buildPdf(12, edited);

    expect(seen.single.path, endsWith('/api/v1/object/12/appointment-order/pdf'));
    final Map<String, dynamic> body = bodies.single as Map<String, dynamic>;
    expect(body['number'], '17');
    expect(body['city'], 'Краснодар');
    expect(body['signer_name'], 'Кузнецов Д. А.');
    expect(url, contains('://els23.ru/api/v1/static/objects/12/'));
    expect(url, endsWith('?token=t'));
  });

  test('403 — «Недостаточно прав», 404 — «Объект не найден»', () async {
    expect(
      () => _repository(null, status: 403).fetchDraft(1),
      throwsA(
        isA<AppointmentOrderException>()
            .having((AppointmentOrderException e) => e.message, 'message',
                'Недостаточно прав или истёк вход'),
      ),
    );
    expect(
      () => _repository(null, status: 404).fetchDraft(1),
      throwsA(
        isA<AppointmentOrderException>().having(
            (AppointmentOrderException e) => e.message, 'message', 'Объект не найден'),
      ),
    );
  });

  test('ответ pdf без url — ошибка словами', () async {
    expect(
      () => _repository(<String, Object>{'path': 'x'}).buildPdf(
        1,
        AppointmentOrderDraft.fromJson(_draftJson),
      ),
      throwsA(
        isA<AppointmentOrderException>().having(
            (AppointmentOrderException e) => e.message,
            'message',
            'Сервер не вернул ссылку на файл'),
      ),
    );
  });

  test('502 от nginx — тоже «Не удалось связаться с сервером»', () async {
    expect(
      () => _repository(null, status: 502).fetchDraft(1),
      throwsA(
        isA<AppointmentOrderException>().having(
            (AppointmentOrderException e) => e.message,
            'message',
            'Не удалось связаться с сервером'),
      ),
    );
  });

  test('сеть упала — «Не удалось связаться с сервером»', () async {
    final AppointmentOrderRepository repository = AppointmentOrderRepository(
      send: (Uri _) async => throw http.ClientException('down'),
      post: (Uri _, Object __) async => throw http.ClientException('down'),
    );
    expect(
      () => repository.fetchDraft(1),
      throwsA(
        isA<AppointmentOrderException>().having(
            (AppointmentOrderException e) => e.message,
            'message',
            'Не удалось связаться с сервером'),
      ),
    );
  });
}
