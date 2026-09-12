part of 'works_bloc.dart';

@immutable
abstract class WorksEvent {
  const WorksEvent();
}

/// Перечитать ленту с начала. [filters] — новый отбор; `null` — тот, что
/// стоит: так «Повторить» после ошибки не сбрасывает чипсы.
class WorksRequested extends WorksEvent {
  const WorksRequested({this.filters});

  final WorkFilters? filters;
}

/// Такт опроса: спросить, что изменилось с прошлого раза, и поправить ленту
/// на месте.
class WorksSynced extends WorksEvent {
  const WorksSynced();
}

/// Следующая страница по курсору.
class WorksMoreRequested extends WorksEvent {
  const WorksMoreRequested();
}

/// Назначить сотрудника на заявку.
class WorkAssigned extends WorksEvent {
  const WorkAssigned(this.item, this.who);

  final WorkItem item;
  final WorkEmployee who;
}

/// Прораб посмотрел: убрать из блока внимания.
class WorkReviewed extends WorksEvent {
  const WorkReviewed(this.item);

  final WorkItem item;
}
