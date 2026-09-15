import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../helper/api_client.dart';
import '../../../../helper/api_config.dart';
import '../model/appointment_order_draft.dart';

/// Ошибка, которую диалог показывает человеку словами.
///
/// Наружу уходит короткий текст без кодов и стектрейсов — он печатается
/// прямо в диалоге, как `BreakdownsException` в карточке на главной.
class AppointmentOrderException implements Exception {
  const AppointmentOrderException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Две ручки приказа о назначении: черновик и сборка PDF.
///
/// Запросы идут через [Api]: заголовок с токеном, обновление пары токенов
/// и повтор после `401` живут там. `dio` не заводим — весь проект ходит
/// через [Api].
class AppointmentOrderRepository {
  const AppointmentOrderRepository({
    this.timeout = const Duration(seconds: 20),
    Future<http.Response> Function(Uri uri)? send,
    Future<http.Response> Function(Uri uri, Object body)? post,
  })  : _send = send ?? _getViaApi,
        _post = post ?? _postViaApi;

  final Duration timeout;

  /// Как уходят запросы. Подменяются только в тестах: разбор ответа —
  /// половина смысла этого класса, и проверить его иначе нельзя.
  final Future<http.Response> Function(Uri uri) _send;
  final Future<http.Response> Function(Uri uri, Object body) _post;

  static Future<http.Response> _getViaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  static Future<http.Response> _postViaApi(Uri uri, Object body) => Api.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      );

  static Uri _uri(int objectId, String tail) =>
      Uri.parse('${ApiConfig.base}/object/$objectId/appointment-order/$tail');

  /// Черновик из карточки объекта: `GET /object/{id}/appointment-order/draft`.
  Future<AppointmentOrderDraft> fetchDraft(int objectId) async {
    final Map<String, dynamic> data =
        await _data(() => _send(_uri(objectId, 'draft')));
    return AppointmentOrderDraft.fromJson(data);
  }

  /// Собрать PDF по правленому черновику и вернуть адрес, готовый к
  /// `launchUrl`: `POST /object/{id}/appointment-order/pdf`.
  ///
  /// Ссылка живёт минуту — открывать сразу, а не складывать в состояние.
  Future<String> buildPdf(int objectId, AppointmentOrderDraft draft) async {
    final Map<String, dynamic> data =
        await _data(() => _post(_uri(objectId, 'pdf'), draft.toJson()));
    final Object? url = data['url'];
    if (url is! String || url.isEmpty) {
      throw const AppointmentOrderException('Сервер не вернул ссылку на файл');
    }
    // Адрес приходит без схемы, см. `ApiConfig.withScheme`.
    return ApiConfig.withScheme(url);
  }

  /// Выполнить запрос и достать `data` из конверта `SingleEntityResponse`;
  /// любой сбой — [AppointmentOrderException] со словами для человека.
  Future<Map<String, dynamic>> _data(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request().timeout(timeout);
    } catch (_) {
      throw const AppointmentOrderException('Не удалось связаться с сервером');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 401:
      case 403:
        throw const AppointmentOrderException(
          'Недостаточно прав или истёк вход',
        );
      case 404:
        throw const AppointmentOrderException('Объект не найден');
      default:
        throw AppointmentOrderException(
          'Сервер ответил ошибкой ${response.statusCode}',
        );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const AppointmentOrderException('Сервер ответил не JSON');
    }
    final Object? data = decoded is Map ? decoded['data'] : null;
    if (data is! Map) {
      throw const AppointmentOrderException('Сервер не вернул черновик');
    }
    return Map<String, dynamic>.from(data);
  }
}
