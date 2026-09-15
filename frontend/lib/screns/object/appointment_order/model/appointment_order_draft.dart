/// Черновик приказа о назначении ответственных за объект.
///
/// Приказ собирается из того, что уже лежит в карточке объекта и у
/// сотрудников: адрес, закреплённые прораб и электромеханик, оборудование.
/// Человек правит только реквизиты — номер, дату, город, подписанта; всё
/// остальное только читается и в PDF уходит как есть.
///
/// Образец заказчика — ПЭЛК №10 от 01.11.2025:
/// `els-vault/knowledge/business/приказ о назначении ответственных - образец
/// от заказчика для E04.md`.
class AppointmentOrderDraft {
  const AppointmentOrderDraft({
    required this.number,
    required this.date,
    required this.city,
    required this.address,
    required this.organization,
    required this.signerPosition,
    required this.signerName,
    required this.foreman,
    required this.mechanic,
    required this.lifts,
  });

  /// Номер приказа; пусто, пока человек не вписал.
  final String number;

  /// Дата приказа — по умолчанию сегодня.
  final DateTime date;

  /// Город в шапке приказа.
  final String city;

  /// Адрес объекта — как в карточке, только чтение.
  final String address;

  /// Организация, от имени которой приказ; только чтение.
  final String organization;

  /// Должность подписанта — «Генеральный директор».
  final String signerPosition;

  /// ФИО подписанта.
  final String signerName;

  /// Закреплённый прораб; `null` — за объектом никто не закреплён.
  final AppointmentPerson? foreman;

  /// Закреплённый электромеханик; `null` — никто не закреплён.
  final AppointmentPerson? mechanic;

  /// Оборудование, которое приказ закрепляет за обоими.
  final List<AppointmentLift> lifts;

  /// Черновик из ответа `GET /object/{id}/appointment-order/draft`.
  ///
  /// Контракт — `backend/src/schemas/appointment_order.py`: строки, которых
  /// в базе нет, приходят `null`; здесь они становятся пустыми — диалог
  /// печатает прочерк, а не слово `null`. `date` — секунды полуночи по UTC:
  /// бэк собирает и читает метку в UTC (`date_from_timestamp`), а не в поясе
  /// браузера — местная полночь восточнее Гринвича давала бы в PDF «вчера».
  factory AppointmentOrderDraft.fromJson(Map<String, dynamic> json) {
    final Object? rawLifts = json['lifts'];
    return AppointmentOrderDraft(
      number: _string(json['number']),
      date: dateFromTimestamp(json['date']),
      city: _string(json['city']),
      address: _string(json['address']),
      organization: _string(json['organization']),
      signerPosition: _string(json['signer_position']),
      signerName: _string(json['signer_name']),
      foreman: AppointmentPerson.fromJson(json['foreman']),
      mechanic: AppointmentPerson.fromJson(json['mechanic']),
      lifts: rawLifts is List
          ? <AppointmentLift>[
              for (final Object? item in rawLifts)
                if (item is Map)
                  AppointmentLift.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const <AppointmentLift>[],
    );
  }

  /// Тело `POST /object/{id}/appointment-order/pdf` — тот же формат, что у
  /// черновика; `null` не отдаём, бэк печатает пустое прочерком.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'number': number,
        'date': timestampFromDate(date),
        'city': city,
        'address': address,
        'organization': organization,
        'signer_position': signerPosition,
        'signer_name': signerName,
        'foreman': foreman?.toJson(),
        'mechanic': mechanic?.toJson(),
        'lifts': <Map<String, dynamic>>[
          for (final AppointmentLift lift in lifts) lift.toJson(),
        ],
      };

  /// Секунды с эпохи → календарный день. Метка читается по UTC, как её
  /// собрал бэк; день переносится в местный [DateTime] без сдвига, чтобы
  /// поле даты и календарь показывали то же число, что попадёт в PDF.
  static DateTime dateFromTimestamp(Object? raw) {
    final int? seconds = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (seconds == null) return DateTime.now();
    final DateTime utc =
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    return DateTime(utc.year, utc.month, utc.day);
  }

  /// Полночь выбранного дня по UTC в секундах — зеркально [dateFromTimestamp].
  static int timestampFromDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        1000;
  }

  AppointmentOrderDraft copyWith({
    String? number,
    DateTime? date,
    String? city,
    String? signerPosition,
    String? signerName,
  }) {
    return AppointmentOrderDraft(
      number: number ?? this.number,
      date: date ?? this.date,
      city: city ?? this.city,
      address: address,
      organization: organization,
      signerPosition: signerPosition ?? this.signerPosition,
      signerName: signerName ?? this.signerName,
      foreman: foreman,
      mechanic: mechanic,
      lifts: lifts,
    );
  }

  static String _string(Object? raw) => raw?.toString() ?? '';
}

/// Человек, которого приказ назначает ответственным.
class AppointmentPerson {
  const AppointmentPerson({required this.fullName, required this.position});

  /// Должности в тексте приказа — как в образце, сразу в родительном
  /// падеже: они идут после «Назначить …» (`FOREMAN_POSITION` на бэке).
  static const String foremanPosition = 'прораба сервисного участка';

  /// См. [foremanPosition] (`MECHANIC_POSITION` на бэке).
  static const String mechanicPosition = 'электромеханика по лифтам';

  final String fullName;
  final String position;

  /// `null` в ответе — за объектом никто не закреплён; без ФИО тоже некого
  /// назначать.
  static AppointmentPerson? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final String name = raw['full_name']?.toString() ?? '';
    if (name.isEmpty) return null;
    return AppointmentPerson(
      fullName: name,
      position: raw['position']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'position': position,
      };
}

/// Единица оборудования в перечне приказа.
class AppointmentLift {
  const AppointmentLift({
    required this.type,
    required this.brand,
    required this.loadCapacityKg,
  });

  /// Тип — «Лифт Пассажирский».
  final String type;

  /// Марка — «Wellmaks».
  final String brand;

  /// Грузоподъёмность, кг; `null` — в карточке не заполнена.
  final int? loadCapacityKg;

  factory AppointmentLift.fromJson(Map<String, dynamic> json) {
    final Object? capacity = json['load_capacity_kg'];
    return AppointmentLift(
      type: json['type']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      loadCapacityKg:
          capacity is int ? capacity : int.tryParse(capacity?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'brand': brand,
        'load_capacity_kg': loadCapacityKg,
      };

  /// Строка перечня как в образце: «Лифт Пассажирский, Wellmaks, г/п 400 кг.»
  String get line {
    final List<String> parts = <String>[
      if (type.isNotEmpty) type,
      if (brand.isNotEmpty) brand,
      if (loadCapacityKg != null) 'г/п $loadCapacityKg кг.',
    ];
    return parts.join(', ');
  }
}
