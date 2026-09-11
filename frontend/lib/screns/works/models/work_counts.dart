import 'work_filters.dart';
import 'work_item.dart';

/// Числа на чипсах: сколько строк за каждым статусом и видом.
///
/// Считаются по отбору **без** этого самого чипса: у чипса «В работе» число
/// должно говорить, сколько строк появится, если его нажать, — а не сколько
/// осталось после того, как выбрали «Сдана». Поиск и архив в счёт входят:
/// они сужают ленту для всех чипсов разом.
class WorkCounts {
  const WorkCounts({required this.byStatus, required this.byKind});

  final Map<WorkStatus, int> byStatus;
  final Map<WorkKind, int> byKind;

  static const WorkCounts empty = WorkCounts(
    byStatus: <WorkStatus, int>{},
    byKind: <WorkKind, int>{},
  );

  int ofStatus(WorkStatus status) => byStatus[status] ?? 0;
  int ofKind(WorkKind kind) => byKind[kind] ?? 0;

  static WorkCounts count(List<WorkItem> items, WorkFilters filters) {
    final WorkFilters forStatus = filters.copyWith(clearStatus: true);
    final WorkFilters forKind = filters.copyWith(clearKind: true);

    final Map<WorkStatus, int> byStatus = <WorkStatus, int>{};
    final Map<WorkKind, int> byKind = <WorkKind, int>{};
    for (final WorkItem item in items) {
      if (forStatus.matches(item)) {
        byStatus[item.status] = (byStatus[item.status] ?? 0) + 1;
      }
      if (forKind.matches(item)) {
        byKind[item.kind] = (byKind[item.kind] ?? 0) + 1;
      }
    }
    return WorkCounts(byStatus: byStatus, byKind: byKind);
  }
}
