import 'model/appointment_order_draft.dart';

/// Расклады черновика приказа без сети — пока внешний вид не утверждён.
///
/// ФИО и организация вымышленные: в образце заказчика настоящие люди, и
/// на превью им не место.
enum AppointmentOrderFixture {
  /// Прораб и механик закреплены, два лифта — как в образце.
  full,

  /// Механик за объектом не закреплён — диалог говорит об этом словами.
  noMechanic,

  /// Один лифт — перечень из одной строки.
  oneLift,
}

extension AppointmentOrderFixtureTitle on AppointmentOrderFixture {
  /// Подпись для переключателя в точке входа `lib/dev`.
  String get title {
    switch (this) {
      case AppointmentOrderFixture.full:
        return 'Оба закреплены, два лифта';
      case AppointmentOrderFixture.noMechanic:
        return 'Нет механика';
      case AppointmentOrderFixture.oneLift:
        return 'Один лифт';
    }
  }
}

const AppointmentPerson _foreman = AppointmentPerson(
  fullName: 'Петров Иван Сергеевич',
  position: AppointmentPerson.foremanPosition,
);

const AppointmentPerson _mechanic = AppointmentPerson(
  fullName: 'Смирнов Алексей Владимирович',
  position: AppointmentPerson.mechanicPosition,
);

const List<AppointmentLift> _twoLifts = <AppointmentLift>[
  AppointmentLift(type: 'Лифт Пассажирский', brand: 'Wellmaks', loadCapacityKg: 400),
  AppointmentLift(type: 'Лифт Пассажирский', brand: 'Wellmaks', loadCapacityKg: 630),
];

/// Собрать черновик приказа для расклада [fixture].
AppointmentOrderDraft buildAppointmentOrderFixture(
  AppointmentOrderFixture fixture,
) {
  return AppointmentOrderDraft(
    number: '',
    date: DateTime(2026, 9, 13),
    city: 'Краснодар',
    address: 'Краснодарский край, г. Краснодар, ул. Кожевенная, 66',
    organization: 'ООО «Лифтсервис»',
    signerPosition: 'Генеральный директор',
    signerName: 'Кузнецов Д. А.',
    foreman: _foreman,
    mechanic: fixture == AppointmentOrderFixture.noMechanic ? null : _mechanic,
    lifts: fixture == AppointmentOrderFixture.oneLift
        ? _twoLifts.sublist(0, 1)
        : _twoLifts,
  );
}
