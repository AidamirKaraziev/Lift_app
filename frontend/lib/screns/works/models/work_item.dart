import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../submitted_works/models/submitted_work.dart' show WorkKind;

export '../../submitted_works/models/submitted_work.dart' show WorkKind;

/// Где работа сейчас — одно слово на пилюле.
///
/// На бэке этого поля пока нет: статус заявки, `state` текущей работы и
/// `outcome` сданной лежат в трёх ручках. Здесь они сведены в один ряд,
/// потому что прорабу нужен один ряд — ручка `GET /work/feed` (S04) обязана
/// отдать его одним полем, а не заставлять клиент собирать из трёх.
enum WorkStatus {
  /// Заявка создана, никто не взял.
  fresh,

  /// Назначена или взята механиком, но не начата.
  accepted,

  /// Ведётся прямо сейчас. Пауза — тот же статус с подписью: она не меняет
  /// того, кто отвечает за работу и что с ней делать прорабу.
  running,

  /// Сдана: ТО закрыто актом, заявка выполнена.
  submitted,

  /// Механик выехал и сделать не смог — заявка закрыта «Проблемой» или
  /// текущая работа стоит с проблемой.
  problem,
}

extension WorkStatusLabel on WorkStatus {
  String get title {
    switch (this) {
      case WorkStatus.fresh:
        return 'Новая';
      case WorkStatus.accepted:
        return 'Принята';
      case WorkStatus.running:
        return 'В работе';
      case WorkStatus.submitted:
        return 'Сдана';
      case WorkStatus.problem:
        return 'Проблема';
    }
  }

  /// Цвет пилюли. Жёлтый у проблемы — тот же, что у бейджа «Проблема» в
  /// ленте сданных: одно слово — один цвет по всему приложению.
  Color get color {
    switch (this) {
      case WorkStatus.fresh:
        return ColorApp.myColorBlue;
      case WorkStatus.accepted:
        return ColorApp.myColorGray;
      case WorkStatus.running:
        return ColorApp.myColorGreenAuth;
      case WorkStatus.submitted:
        return ColorApp.myColorGreen;
      case WorkStatus.problem:
        return ColorApp.myColorYellow;
    }
  }

  bool get isClosed =>
      this == WorkStatus.submitted || this == WorkStatus.problem;
}

extension WorkKindLabel on WorkKind {
  /// Подписи те же, что у `SubmittedWork.kindLabel`: одна работа не должна
  /// зваться в двух лентах по-разному.
  String get title {
    switch (this) {
      case WorkKind.maintenance:
        return 'ТО';
      case WorkKind.breakdown:
        return 'Авария';
      case WorkKind.clientRequest:
        return 'Обращение';
      case WorkKind.request:
        return 'Заявка';
      case WorkKind.defect:
        return 'Дефект';
    }
  }

  Color get color {
    switch (this) {
      case WorkKind.breakdown:
        return ColorApp.myColorRed;
      case WorkKind.clientRequest:
        return ColorApp.myColorBlue;
      case WorkKind.maintenance:
        return ColorApp.myColorGreenAuth;
      case WorkKind.request:
      case WorkKind.defect:
        return ColorApp.myColorGray;
    }
  }
}

/// Одна строка ленты «Работы»: заявка или акт ТО.
///
/// Даты стадий лежат по отдельности, а не одной «последней переменой»: по
/// ним считается таймер — сколько ждёт новая, сколько идёт работа, за
/// сколько выполнена. На бэке заявка хранит только `created_at` и
/// `updated_at`, акт — `started_at` и дату закрытия; момент принятия и
/// паузы — задача S04.
class WorkItem {
  const WorkItem({
    required this.id,
    required this.kind,
    required this.status,
    required this.objectName,
    required this.createdAt,
    this.actTitle,
    this.objectType,
    this.objectAddress,
    this.taskText,
    this.performer,
    this.acceptedAt,
    this.startedAt,
    this.pausedAt,
    this.closedAt,
    this.hasDefect = false,
    this.comment,
    this.isActual = true,
    this.section,
    this.reviewed = false,
  });

  final int id;
  final WorkKind kind;
  final WorkStatus status;

  /// Название фактического акта у ТО: «ТО-1», «ТО-3», «ТО-6», «ТО-12».
  /// Только у [WorkKind.maintenance]; на бейдже стоит оно, а не слово «ТО».
  final String? actTitle;

  final String objectName;

  /// Тип техники из справочника `type_objects`: «Лифт с МП», «Эскалатор»…
  /// Прораб по нему понимает, кого слать и с чем, ещё до открытия карточки.
  final String? objectType;

  final String? objectAddress;

  /// Значок к типу техники. По слову, а не по id: справочник редактируемый,
  /// и незнакомый тип получает общий значок, а не падение.
  IconData get objectTypeIcon {
    final String t = (objectType ?? '').toLowerCase();
    if (t.contains('эскалатор')) return Icons.escalator_outlined;
    if (t.contains('траволатор')) return Icons.conveyor_belt;
    if (t.contains('лифт')) return Icons.elevator_outlined;
    return Icons.precision_manufacturing_outlined;
  }

  /// Что просили сделать. Только у заявок: у ТО задание — чек-лист акта.
  final String? taskText;

  /// Кто ведёт или сдал. Пусто у новой заявки.
  final String? performer;

  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;

  /// Механик приостановил — и когда. Имеет смысл при [WorkStatus.running].
  final DateTime? pausedAt;

  final DateTime? closedAt;

  /// К работе привязан дефектный акт.
  final bool hasDefect;

  /// Комментарий механика: причина паузы, проблемы или просто заметка.
  final String? comment;

  /// Мягкое удаление с бэка (`is_actual`). Архив ленты — это ровно
  /// `isActual == false`, см. `backend/src/core/archiving.py`.
  final bool isActual;

  /// Участок обслуживания: по нему прораб отбирает свои объекты. На бэке
  /// поля у заявки нет — с чего его брать, решается в S04.
  final String? section;

  /// Прораб отметил «проверил»: строка уходит из блока «требуют внимания»
  /// до следующей перемены статуса. Сбрасывается бэком (S04), здесь — при
  /// смене статуса в фикстуре.
  final bool reviewed;

  WorkItem copyWith({
    WorkStatus? status,
    String? performer,
    DateTime? acceptedAt,
    String? section,
    bool? reviewed,
  }) {
    return WorkItem(
      id: id,
      kind: kind,
      status: status ?? this.status,
      actTitle: actTitle,
      objectName: objectName,
      objectType: objectType,
      objectAddress: objectAddress,
      taskText: taskText,
      performer: performer ?? this.performer,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt,
      pausedAt: pausedAt,
      closedAt: closedAt,
      hasDefect: hasDefect,
      comment: comment,
      isActual: isActual,
      section: section ?? this.section,
      reviewed: reviewed ?? this.reviewed,
    );
  }

  bool get paused => pausedAt != null && status == WorkStatus.running;

  /// Номер для пилюли: у заявки — её номер, у ТО — номер акта.
  String get number => '№ $id';

  /// Последняя перемена — по ней лента упорядочена.
  DateTime get updatedAt =>
      closedAt ?? pausedAt ?? startedAt ?? acceptedAt ?? createdAt;

  /// «11.09.2026, 09:30». Часы нужны: за день на объекте бывает несколько
  /// выходов, и без них их не различить.
  String get updatedLabel => formatDateTime(updatedAt);

  /// Стадии по порядку — для подсказки под таймером.
  List<MapEntry<String, DateTime>> get timeline => <MapEntry<String, DateTime>>[
    MapEntry<String, DateTime>('Создана', createdAt),
    if (acceptedAt != null) MapEntry<String, DateTime>('Принята', acceptedAt!),
    if (startedAt != null) MapEntry<String, DateTime>('Начата', startedAt!),
    if (pausedAt != null && !status.isClosed)
      MapEntry<String, DateTime>('Пауза', pausedAt!),
    if (closedAt != null)
      MapEntry<String, DateTime>(
        status == WorkStatus.problem ? 'Проблема' : 'Сдана',
        closedAt!,
      ),
  ];
}

String formatDateTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)}.${t.year}, ${two(t.hour)}:${two(t.minute)}';
}
