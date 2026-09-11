import 'work_item.dart';

/// Отбор ленты «Работы».
///
/// Одна пара «статус · вид», а не набор галочек: чипсы со счётчиками
/// отвечают на вопрос «сколько сейчас в работе», и множественный выбор его
/// только запутал бы — счётчики пришлось бы пересчитывать под каждую
/// комбинацию.
class WorkFilters {
  const WorkFilters({
    this.status,
    this.kind,
    this.search = '',
    this.archived = false,
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

  bool get isEmpty =>
      status == null && kind == null && search.isEmpty && !archived;

  int get activeCount =>
      (status == null ? 0 : 1) +
      (kind == null ? 0 : 1) +
      (search.isEmpty ? 0 : 1) +
      (archived ? 1 : 0);

  WorkFilters copyWith({
    WorkStatus? status,
    bool clearStatus = false,
    WorkKind? kind,
    bool clearKind = false,
    String? search,
    bool? archived,
  }) {
    return WorkFilters(
      status: clearStatus ? null : (status ?? this.status),
      kind: clearKind ? null : (kind ?? this.kind),
      search: search ?? this.search,
      archived: archived ?? this.archived,
    );
  }

  WorkFilters cleared() => const WorkFilters();

  /// Подходит ли строка под отбор. Считает и фикстура, и тесты: правило
  /// одно, и расходиться ему негде.
  bool matches(WorkItem item) {
    if (item.isActual == archived) return false;
    if (status != null && item.status != status) return false;
    if (kind != null && item.kind != kind) return false;
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
