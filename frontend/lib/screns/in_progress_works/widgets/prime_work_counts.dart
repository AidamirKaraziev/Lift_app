import '../../submitted_works/repository/submitted_works_repository.dart';
import '../in_progress_counts.dart';
import '../models/in_progress_work.dart';
import '../repository/in_progress_works_repository.dart';

/// Первое значение таблеток у пункта «Работы» — при входе в оболочку.
///
/// Счётчики нужны кнопке меню, а не экрану: числа видны с любого раздела,
/// поэтому тянем их один раз при входе. Ошибку глотаем молча — из-за неё
/// нельзя не пустить человека в систему.
///
/// Раньше числа появлялись только после захода в «Сданные работы»: класть их
/// умел лишь блок раздела. Прораб открывал бургер и видел одну серую
/// таблетку, хотя работы шли. Зовут обе оболочки: у админа те же вкладки.
Future<void> primeWorkCounts() async {
  const SubmittedWorksRepository().unreviewedCount().catchError((_) => 0);
  try {
    final InProgressWorks works = await const InProgressWorksRepository().fetch();
    // Пишем только в пустое значение: если раздел успели открыть раньше,
    // чем вернулся этот запрос, свежие числа из блока затирать нечем.
    if (inProgressCounts.value != InProgressCounts.none) return;
    inProgressCounts.value =
        InProgressCounts(total: works.total, problems: works.problems);
  } catch (_) {
    // Пустое меню без чисел лучше, чем не пустить в систему.
  }
}
