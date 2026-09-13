part of 'works_bloc.dart';

/// Состояние ленты «Работы». Одно, с полями, а не иерархия классов: лента
/// почти всегда на руках, меняются только флаги вокруг неё.
@immutable
class WorksState {
  const WorksState({
    this.filters = const WorkFilters(),
    this.feed,
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.message,
    this.messageSerial = 0,
    this.syncedAt,
  });

  final WorkFilters filters;

  /// Последний ответ, поправленный опросом и действиями. `null` — ещё
  /// ничего не приезжало.
  final WorksFeed? feed;

  /// Едет полный запрос или действие: поверх ленты заслонка, а строка после
  /// нажатия не должна «мигнуть» старым состоянием.
  final bool loading;

  /// Едет следующая страница: крутилка вместо «Показать ещё».
  final bool loadingMore;

  /// Полный запрос не удался. Лента, если была, остаётся на руках.
  final String? error;

  /// Что сказать снекбаром: «назначена», «не получилось». Снекбар не
  /// состояние, а событие, поэтому рядом [messageSerial]: одинаковый текст
  /// два раза подряд — это два снекбара.
  final String? message;
  final int messageSerial;

  /// С какого момента спрашивать перемены. Ставится перед полным запросом:
  /// то, что изменилось, пока он ехал, придёт следующим тактом.
  final DateTime? syncedAt;

  WorksState copyWith({
    WorkFilters? filters,
    WorksFeed? feed,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    String? message,
    DateTime? syncedAt,
  }) {
    return WorksState(
      filters: filters ?? this.filters,
      feed: feed ?? this.feed,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      message: message ?? this.message,
      messageSerial: message == null ? messageSerial : messageSerial + 1,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
