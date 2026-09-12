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

  /// `counts` из ответа ручки: ключи — слова статусов, видов и причин.
  factory WorkCounts.fromJson(Map<String, dynamic> json) {
    Map<String, int> read(String key) {
      final dynamic raw = json[key];
      if (raw is! Map) return const <String, int>{};
      return <String, int>{
        for (final MapEntry<dynamic, dynamic> e in raw.entries)
          if (e.value is num) e.key.toString(): (e.value as num).toInt(),
      };
    }

    final Map<String, int> status = read('by_status');
    final Map<String, int> kind = read('by_kind');
    final Map<String, int> attention = read('by_attention');
    return WorkCounts(
      byStatus: <WorkStatus, int>{
        for (final WorkStatus s in WorkStatus.values)
          if (status[s.name] != null) s: status[s.name]!,
      },
      byKind: <WorkKind, int>{
        for (final WorkKind k in WorkKind.values)
          if (kind[kindPathSegment(k)] != null) k: kind[kindPathSegment(k)]!,
      },
      byAttention: <AttentionReason, int>{
        for (final AttentionReason r in AttentionReason.values)
          if (attention[r.apiName] != null) r: attention[r.apiName]!,
      },
    );
  }

  int ofStatus(WorkStatus status) => byStatus[status] ?? 0;
  int ofKind(WorkKind kind) => byKind[kind] ?? 0;
  int ofAttention(AttentionReason reason) => byAttention[reason] ?? 0;

  /// Всего требуют внимания — сумма по причинам.
  int get attentionTotal =>
      byAttention.values.fold<int>(0, (int a, int b) => a + b);

  /// Счёт на месте — для фикстуры; с ручки числа приходят готовыми.
  static WorkCounts count(
    List<WorkItem> items,
    WorkFilters filters, {
    DateTime? now,
    Set<int> mySections = const <int>{},
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
