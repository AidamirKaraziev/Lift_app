import 'work_attention.dart';
import 'work_item.dart';

/// Порядок ленты.
enum WorkSort {
  /// Сначала блок «требуют внимания» (самое старое сверху), затем остальные
  /// по последней перемене.
  attention,

  /// Просто по последней перемене, новое сверху.
  updated,
}

/// Отбор ленты «Работы».
///
/// Одна пара «статус · вид», а не набор галочек: чипсы со счётчиками
/// отвечают на вопрос «сколько сейчас в работе», и множественный выбор его
/// только запутал бы — счётчики пришлось бы пересчитывать под каждую
/// комбинацию.
///
/// Порядок ([sort]) тоже здесь, хотя это не отбор: репозиторий получает
/// один объект «что показать и как», и ручке S04 он уйдёт целиком.
class WorkFilters {
  const WorkFilters({
    this.status,
    this.kind,
    this.search = '',
    this.archived = false,
    this.section,
    this.performer,
    this.mine = false,
    this.attention,
    this.sort = WorkSort.attention,
  });

  final WorkStatus? status;
  final WorkKind? kind;

  /// Поиск по названию и адресу объекта.
  final String search;

  /// Показывать **только** архив (мягко удалённое), а не живое.
  ///
  /// Это вид, а не галочка «и архив тоже»: удалённое рядом с живым в одной
  /// ленте выглядит как живое, и его берут в работу.
  final bool archived;

  /// Один участок из справочника — или `null`, все.
  final String? section;

  /// Один механик по имени — или `null`, все.
  final String? performer;

  /// Только участки, закреплённые за прорабом. Какие именно — знает
  /// репозиторий, не отбор: отбор хранит намерение, а не список.
  final bool mine;

  /// Только строки с этой причиной внимания — клик по куску сводки.
  final AttentionReason? attention;

  final WorkSort sort;

  bool get isEmpty => activeCount == 0;

  int get activeCount =>
      (status == null ? 0 : 1) +
      (kind == null ? 0 : 1) +
      (search.isEmpty ? 0 : 1) +
      (archived ? 1 : 0) +
      (section == null ? 0 : 1) +
      (performer == null ? 0 : 1) +
      (mine ? 1 : 0) +
      (attention == null ? 0 : 1);

  WorkFilters copyWith({
    WorkStatus? status,
    bool clearStatus = false,
    WorkKind? kind,
    bool clearKind = false,
    String? search,
    bool? archived,
    String? section,
    bool clearSection = false,
    String? performer,
    bool clearPerformer = false,
    bool? mine,
    AttentionReason? attention,
    bool clearAttention = false,
    WorkSort? sort,
  }) {
    return WorkFilters(
      status: clearStatus ? null : (status ?? this.status),
      kind: clearKind ? null : (kind ?? this.kind),
      search: search ?? this.search,
      archived: archived ?? this.archived,
      section: clearSection ? null : (section ?? this.section),
      performer: clearPerformer ? null : (performer ?? this.performer),
      mine: mine ?? this.mine,
      attention: clearAttention ? null : (attention ?? this.attention),
      sort: sort ?? this.sort,
    );
  }

  /// Сброс отбора; порядок остаётся — это не условие, а привычка.
  WorkFilters cleared() => WorkFilters(sort: sort);

  /// Подходит ли строка под отбор. Считает и фикстура, и тесты: правило
  /// одно, и расходиться ему негде.
  ///
  /// [now] нужен только отбору по причине внимания, [mySections] — только
  /// чипсу «Мои участки»; без них эти два условия считаются выполненными.
  bool matches(
    WorkItem item, {
    DateTime? now,
    Set<String> mySections = const <String>{},
  }) {
    if (item.isActual == archived) return false;
    if (status != null && item.status != status) return false;
    if (kind != null && item.kind != kind) return false;
    if (section != null && item.section != section) return false;
    if (performer != null && item.performer != performer) return false;
    if (mine && !mySections.contains(item.section)) return false;
    if (attention != null && now != null) {
      if (WorkAttention.of(item, now) != attention) return false;
    }
    if (search.isNotEmpty) {
      final String needle = search.toLowerCase();
      final bool hit =
          item.objectName.toLowerCase().contains(needle) ||
          (item.objectAddress?.toLowerCase().contains(needle) ?? false);
      if (!hit) return false;
    }
    return true;
  }
}
