import 'work_attention.dart';
import 'work_filters.dart';
import 'work_item.dart';

/// Числа на чипсах: сколько строк за каждым статусом и видом.
///
/// Считаются по отбору **без** этого самого чипса: у чипса «В работе» число
/// должно говорить, сколько строк появится, если его нажать, — а не сколько
/// осталось после того, как выбрали «Сдана». Поиск и архив в счёт входят:
/// они сужают ленту для всех чипсов разом.
///
/// Сводка [byAttention] — по тому же правилу: без условия по причине, но с
/// остальным отбором, чтобы «3 не назначены» отвечало за видимую ленту.
class WorkCounts {
  const WorkCounts({
    required this.byStatus,
    required this.byKind,
    this.byAttention = const <AttentionReason, int>{},
  });

  final Map<WorkStatus, int> byStatus;
  final Map<WorkKind, int> byKind;
  final Map<AttentionReason, int> byAttention;

  static const WorkCounts empty = WorkCounts(
    byStatus: <WorkStatus, int>{},
    byKind: <WorkKind, int>{},
  );

  int ofStatus(WorkStatus status) => byStatus[status] ?? 0;
  int ofKind(WorkKind kind) => byKind[kind] ?? 0;
  int ofAttention(AttentionReason reason) => byAttention[reason] ?? 0;

  /// Всего требуют внимания — сумма по причинам.
  int get attentionTotal =>
      byAttention.values.fold<int>(0, (int a, int b) => a + b);

  static WorkCounts count(
    List<WorkItem> items,
    WorkFilters filters, {
    DateTime? now,
    Set<String> mySections = const <String>{},
  }) {
    final WorkFilters forStatus = filters.copyWith(clearStatus: true);
    final WorkFilters forKind = filters.copyWith(clearKind: true);
    final WorkFilters forAttention = filters.copyWith(clearAttention: true);

    final Map<WorkStatus, int> byStatus = <WorkStatus, int>{};
    final Map<WorkKind, int> byKind = <WorkKind, int>{};
    final Map<AttentionReason, int> byAttention = <AttentionReason, int>{};
    for (final WorkItem item in items) {
      if (forStatus.matches(item, now: now, mySections: mySections)) {
        byStatus[item.status] = (byStatus[item.status] ?? 0) + 1;
      }
      if (forKind.matches(item, now: now, mySections: mySections)) {
        byKind[item.kind] = (byKind[item.kind] ?? 0) + 1;
      }
      if (now != null &&
          forAttention.matches(item, now: now, mySections: mySections)) {
        final AttentionReason? reason = WorkAttention.of(item, now);
        if (reason != null) {
          byAttention[reason] = (byAttention[reason] ?? 0) + 1;
        }
      }
    }
    return WorkCounts(
      byStatus: byStatus,
      byKind: byKind,
      byAttention: byAttention,
    );
  }
}
