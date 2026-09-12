// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../submitted_works/unreviewed_counter.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../models/work_order.dart';
import '../repository/works_repository.dart';

part 'works_event.dart';
part 'works_state.dart';

/// Лента «Работы»: отбор, страницы и живое обновление.
///
/// Полный запрос — только по смене отбора и по «Повторить». Дальше лента
/// живёт опросом перемен ([WorksSynced]): репозиторий отдаёт строки, что
/// изменились с [WorksState.syncedAt], и они подменяются на месте по ключу
/// `(вид, id)`. Строка, что ушла из-под чипса, убирается сразу, архивная —
/// тоже. Так у прораба карточка меняет пилюлю, не пропадая и не прыгая
/// вместе со всей лентой.
///
/// Действия («назначить», «проверил») тоже не перечитывают ленту: ручка
/// отдаёт строку, какой она стала, и её достаточно. Счётчики на чипсах после
/// любой перемены берутся отдельным лёгким запросом (`limit: 1`): считать их
/// на клиенте нельзя — на руках одна страница, а числа — по всему отбору.
/// Тем же запросом обновляется и бейдж непросмотренных у пункта «Работы» в
/// бургере ([unreviewedWorksCount]): механик сдал — число выросло за такт,
/// прораб нажал «проверил» — упало, не дожидаясь захода в раздел.
///
/// Такт опроса — у виджета, не здесь: остановить его надо вместе с экраном
/// и свёрнутым приложением, а про это знает виджет.
class WorksBloc extends Bloc<WorksEvent, WorksState> {
  WorksBloc({required WorksRepository repository, DateTime Function()? clock})
    : _repository = repository,
      _clock = clock ?? DateTime.now,
      super(const WorksState()) {
    on<WorksRequested>(_onRequested);
    on<WorksSynced>(_onSynced);
    on<WorksMoreRequested>(_onMoreRequested);
    on<WorkAssigned>(_onAssigned);
    on<WorkReviewed>(_onReviewed);
  }

  final WorksRepository _repository;
  final DateTime Function() _clock;

  /// Номер последнего полного запроса: ответ на устаревший отбор
  /// выбрасывается, иначе поиск, набранный быстрее, чем отвечает сервер,
  /// показал бы выдачу на предыдущую букву.
  int _serial = 0;

  /// Опрос уже в пути — второй ни к чему.
  bool _syncing = false;

  Future<void> _onRequested(
    WorksRequested event,
    Emitter<WorksState> emit,
  ) async {
    final int serial = ++_serial;
    final WorkFilters filters = event.filters ?? state.filters;
    // Момент — до запроса, а не после: перемена, случившаяся пока он ехал,
    // придёт следующим тактом, а не потеряется.
    final DateTime since = _clock();
    emit(
      state.copyWith(
        filters: filters,
        loading: true,
        clearError: true,
        syncedAt: since,
      ),
    );
    try {
      final WorksFeed feed = await _repository.fetch(filters);
      if (serial != _serial) return;
      emit(state.copyWith(feed: feed, loading: false));
    } on WorksException catch (e) {
      if (serial != _serial) return;
      emit(state.copyWith(loading: false, error: e.message));
    } catch (_) {
      if (serial != _serial) return;
      emit(state.copyWith(loading: false, error: 'Не удалось загрузить работы'));
    }
  }

  Future<void> _onSynced(WorksSynced event, Emitter<WorksState> emit) async {
    final WorksFeed? feed = state.feed;
    final DateTime? since = state.syncedAt;
    if (feed == null || since == null || state.loading || _syncing) return;

    final int serial = _serial;
    final WorkFilters filters = state.filters;
    final DateTime now = _clock();
    _syncing = true;
    try {
      final List<WorkItem> changed = await _repository.changes(filters, since);
      // Отбор сменился, пока ехал опрос: ответ уже не про эту ленту.
      if (serial != _serial) return;
      emit(state.copyWith(syncedAt: now));
      if (changed.isEmpty) return;

      emit(state.copyWith(feed: _merged(state.feed!, changed, filters, now)));
      await _refreshCounts(emit, serial);
    } catch (_) {
      // Сбой опроса — молча: лента на руках, следующий такт попробует снова.
    } finally {
      _syncing = false;
    }
  }

  Future<void> _onMoreRequested(
    WorksMoreRequested event,
    Emitter<WorksState> emit,
  ) async {
    final WorksFeed? feed = state.feed;
    final String? cursor = feed?.nextCursor;
    if (feed == null || cursor == null || state.loading || state.loadingMore) {
      return;
    }
    final int serial = _serial;
    emit(state.copyWith(loadingMore: true));
    try {
      final WorksFeed page = await _repository.fetch(
        state.filters,
        cursor: cursor,
      );
      if (serial != _serial) return;
      final WorksFeed current = state.feed!;
      final Set<String> known = <String>{
        for (final WorkItem i in current.items) i.key,
      };
      emit(
        state.copyWith(
          loadingMore: false,
          feed: current.copyWith(
            items: <WorkItem>[
              ...current.items,
              // Строка могла подняться на первую страницу, пока листали, —
              // второй раз её не показываем.
              for (final WorkItem i in page.items)
                if (!known.contains(i.key)) i,
            ],
            nextCursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
          ),
        ),
      );
    } catch (_) {
      if (serial != _serial) return;
      emit(
        state.copyWith(
          loadingMore: false,
          message: 'Не удалось загрузить ещё',
        ),
      );
    }
  }

  Future<void> _onAssigned(WorkAssigned event, Emitter<WorksState> emit) =>
      _act(
        emit,
        () => _repository.assign(event.item, event.who),
        '${event.item.number} назначена: ${event.who.name}',
      );

  Future<void> _onReviewed(WorkReviewed event, Emitter<WorksState> emit) =>
      _act(
        emit,
        () => _repository.review(event.item),
        '${event.item.number} — проверено',
      );

  /// Быстрое действие: заслонка, запрос, ответная строка — на место.
  Future<void> _act(
    Emitter<WorksState> emit,
    Future<WorkItem> Function() action,
    String done,
  ) async {
    if (state.feed == null) return;
    final int serial = _serial;
    emit(state.copyWith(loading: true));
    WorkItem fresh;
    try {
      fresh = await action();
    } on WorksException catch (e) {
      if (serial != _serial) return;
      emit(state.copyWith(loading: false, message: e.message));
      return;
    } catch (_) {
      if (serial != _serial) return;
      emit(state.copyWith(loading: false, message: 'Не получилось, повторите'));
      return;
    }
    if (serial != _serial) return;
    final DateTime now = _clock();
    emit(
      state.copyWith(
        loading: false,
        message: done,
        feed: _merged(state.feed!, <WorkItem>[fresh], state.filters, now),
      ),
    );
    await _refreshCounts(emit, serial);
  }

  /// Числа на чипсах, справочники и бейдж в бургере — лёгким запросом, без
  /// строк. Не вышло — остаются прежние: лента важнее чисел над ней.
  Future<void> _refreshCounts(Emitter<WorksState> emit, int serial) async {
    try {
      final WorksFeed light = await _repository.fetch(state.filters, limit: 1);
      if (serial != _serial || state.feed == null) return;
      emit(
        state.copyWith(
          feed: state.feed!.copyWith(
            counts: light.counts,
            sections: light.sections,
            employees: light.employees,
            mySections: light.mySections,
          ),
        ),
      );
      // Число кладёт блок, а не репозиторий: он и решает, чей ответ
      // настоящий, — устаревший не должен менять бургер, как не меняет ленту.
      final int unreviewed = await _repository.unreviewedCount();
      if (serial != _serial) return;
      unreviewedWorksCount.value = unreviewed;
    } catch (_) {
      // Счётчики подождут следующей перемены.
    }
  }

  /// Перемены — в ленту: по ключу заменить, чужое под отбор убрать, новое
  /// вставить; потом восстановить порядок. Блок внимания пересчитывается по
  /// строкам на руках, а не по всему отбору: пока страница одна, это то же
  /// число, а с курсором — честнее, чем показывать заголовок с числом, за
  /// которым строк нет.
  static WorksFeed _merged(
    WorksFeed feed,
    List<WorkItem> changed,
    WorkFilters filters,
    DateTime now,
  ) {
    final Map<String, WorkItem> byKey = <String, WorkItem>{
      for (final WorkItem i in feed.items) i.key: i,
    };
    for (final WorkItem row in changed) {
      final bool keep =
          row.isActual &&
          filters.matches(row, now: now, mySections: feed.mySections);
      if (keep) {
        byKey[row.key] = row;
      } else {
        byKey.remove(row.key);
      }
    }
    final WorkOrder order = WorkOrder.arrange(byKey.values, filters.sort, now);
    return feed.copyWith(
      items: order.items,
      attentionCount: order.attentionCount,
    );
  }
}
