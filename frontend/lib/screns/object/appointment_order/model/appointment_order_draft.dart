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

  /// Черновик из карточки объекта, как она лежит в памяти приложения.
  ///
  /// Подрядчик держит объект нетипизированной картой; здесь берётся ровно
  /// то, что карточка и так показывает. Реквизиты приказа в карте не живут
  /// — их отдаст ручка черновика в S02, а до неё они пусты.
  factory AppointmentOrderDraft.fromObjectMap(Map<String, dynamic> object) {
    final Map<String, dynamic>? model =
        _map(object['factory_model_id']);
    final int? capacity = _int(object['load_capacity']);
    final String type = _map(model?['type_object_id'])?['name']?.toString() ?? '';
    final String brand = model?['model']?.toString() ?? '';
    return AppointmentOrderDraft(
      number: '',
      date: DateTime.now(),
      city: '',
      address: object['address']?.toString() ?? '',
      organization: '',
      signerPosition: '',
      signerName: '',
      foreman: _person(object['foreman_id'], AppointmentPerson.foremanPosition),
      mechanic:
          _person(object['mechanic_id'], AppointmentPerson.mechanicPosition),
      lifts: model == null && capacity == null
          ? const <AppointmentLift>[]
          : <AppointmentLift>[
              AppointmentLift(type: type, brand: brand, loadCapacityKg: capacity),
            ],
    );
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

  static AppointmentPerson? _person(Object? raw, String position) {
    final String? name = _map(raw)?['name']?.toString();
    if (name == null || name.isEmpty) return null;
    return AppointmentPerson(fullName: name, position: position);
  }

  static Map<String, dynamic>? _map(Object? raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }
}

/// Человек, которого приказ назначает ответственным.
class AppointmentPerson {
  const AppointmentPerson({required this.fullName, required this.position});

  /// Должность прораба в тексте приказа — как в образце.
  static const String foremanPosition = 'прораб сервисного участка';

  /// Должность механика в тексте приказа — как в образце.
  static const String mechanicPosition = 'электромеханик по лифтам';

  final String fullName;
  final String position;
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
