import 'work_attention.dart';
import 'work_filters.dart';
import 'work_item.dart';
import 'work_timing.dart';

/// Лента в нужном порядке и размер блока «требуют внимания».
class WorkOrder {
  const WorkOrder({required this.items, required this.attentionCount});

  final List<WorkItem> items;

  /// Сколько первых строк — блок внимания. Ноль при [WorkSort.updated].
  final int attentionCount;

  /// Упорядочить строки так же, как это делает ручка.
  ///
  /// Блок внимания — самое давнее сверху: у кого стадия тянется дольше, тот
  /// и первый. Остальные — по последней перемене, новое сверху. Правило одно
  /// на фикстуру и на ленту после опроса перемен: ручка отдаёт строки уже в
  /// порядке, но после подмены строки на месте порядок надо восстановить
  /// самим, не перечитывая ленту.
  static WorkOrder arrange(
    Iterable<WorkItem> source,
    WorkSort sort,
    DateTime now,
  ) {
    int byUpdated(WorkItem a, WorkItem b) => b.updatedAt.compareTo(a.updatedAt);

    if (sort != WorkSort.attention) {
      return WorkOrder(
        items: source.toList()..sort(byUpdated),
        attentionCount: 0,
      );
    }
    final List<WorkItem> urgent =
        source.where((WorkItem i) => WorkAttention.of(i, now) != null).toList()
          ..sort(
            (WorkItem a, WorkItem b) => WorkTiming.of(
              b,
              now,
            ).duration.compareTo(WorkTiming.of(a, now).duration),
          );
    final List<WorkItem> rest =
        source.where((WorkItem i) => WorkAttention.of(i, now) == null).toList()
          ..sort(byUpdated);
    return WorkOrder(
      items: <WorkItem>[...urgent, ...rest],
      attentionCount: urgent.length,
    );
  }
}
