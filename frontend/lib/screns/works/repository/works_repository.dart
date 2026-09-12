import '../models/work_counts.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';

/// Ответ ленты: строки под отбор, числа для чипсов и справочники для
/// выпадашек.
class WorksFeed {
  const WorksFeed({
    required this.items,
    required this.counts,
    this.attentionCount = 0,
    this.sections = const <String>[],
    this.performers = const <String>[],
    this.employees = const <WorkEmployee>[],
    this.mySections = const <String>{},
  });

  final List<WorkItem> items;
  final WorkCounts counts;

  /// Сколько первых строк [items] — блок «требуют внимания». Ноль при
  /// порядке [WorkSort.updated]: там блока нет.
  final int attentionCount;

  /// Участки и механики, что встречаются в ленте, — для выпадашек.
  final List<String> sections;
  final List<String> performers;

  /// Кого можно назначить — с должностью и участком.
  final List<WorkEmployee> employees;

  /// Участки прораба — под чипс «Мои участки».
  final Set<String> mySections;
}

/// Откуда лента берёт работы.
///
/// На S03 реализация одна — фикстура. Сетевая появится в S05 поверх ручки
/// `GET /work/feed` (S04); контракт нарочно узкий — отбор целиком туда,
/// строки и счётчики обратно, — чтобы экран не знал, откуда что приехало.
abstract class WorksRepository {
  Future<WorksFeed> fetch(WorkFilters filters);

  /// Назначить механика на заявку. Новая становится принятой.
  Future<void> assign(WorkItem item, String performer);

  /// Прораб посмотрел: строка уходит из блока внимания.
  Future<void> review(WorkItem item);
}
