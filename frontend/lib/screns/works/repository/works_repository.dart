import '../models/work_counts.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';

/// Ответ ленты: строки под отбор и числа для чипсов.
class WorksFeed {
  const WorksFeed({required this.items, required this.counts});

  final List<WorkItem> items;
  final WorkCounts counts;
}

/// Откуда лента берёт работы.
///
/// На S03 реализация одна — фикстура. Сетевая появится в S05 поверх ручки
/// `GET /work/feed` (S04); контракт нарочно узкий — отбор целиком туда,
/// строки и счётчики обратно, — чтобы экран не знал, откуда что приехало.
abstract class WorksRepository {
  Future<WorksFeed> fetch(WorkFilters filters);
}
