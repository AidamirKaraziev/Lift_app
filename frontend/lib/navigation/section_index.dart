import '../helper/session.dart';
import 'app_section.dart';

/// Вкладка раздела «Работы»: заголовок и индекс старого экрана под ней.
class WorksTab {
  const WorksTab(this.title, this.index);

  final String title;
  final int index;
}

/// Соответствие «раздел ↔ индекс экрана» для оболочки одной роли.
///
/// Раздел выбирается маршрутом, но внутри раздела экраны подрядчика ходят
/// друг к другу по номерам в списке оболочки (`IntTest.indexScreens*`), и
/// таких мест 91 — снимаются в S08. До тех пор оболочка держит две таблицы:
/// по разделу — корневой индекс, по любому индексу — раздел, чтобы при
/// заходе в карточку объекта подсветка и адрес оставались на «Объектах».
///
/// Числа — фактические позиции в `_screens` / `_screensForeman`; в списке
/// админа комментарии подрядчика с восьмого элемента сбиты на единицу,
/// верить им нельзя.
class SectionIndex {
  const SectionIndex._(this._root, this._owner, this.worksTabs);

  /// Таблица для роли; для остальных ролей оболочек по разделам нет.
  factory SectionIndex.forRole(int roleId) =>
      roleId == Roles.foreman ? foreman : admin;

  final Map<AppSection, int> _root;
  final Map<int, AppSection> _owner;

  /// Вкладки «Работ» в порядке показа; первая — корневая для раздела.
  final List<WorksTab> worksTabs;

  /// Корневой индекс раздела.
  int rootOf(AppSection section) => _root[section]!;

  /// Раздел, которому принадлежит экран; `null` — ничейный (профиль):
  /// подсветка остаётся на разделе, откуда пришли.
  AppSection? sectionOf(int index) => _owner[index];

  /// Номер вкладки «Работ» под этим индексом; `null` — это не вкладка.
  int? worksTabOf(int index) {
    for (int i = 0; i < worksTabs.length; i++) {
      if (worksTabs[i].index == index) return i;
    }
    return null;
  }

  static const SectionIndex admin = SectionIndex._(
    <AppSection, int>{
      AppSection.home: 0,
      AppSection.schedule: 1,
      AppSection.works: 2,
      AppSection.objects: 3,
      AppSection.companies: 4,
      AppSection.reports: 5,
      AppSection.employees: 6,
    },
    <int, AppSection>{
      0: AppSection.home,
      1: AppSection.schedule,
      2: AppSection.works,
      3: AppSection.objects,
      4: AppSection.companies,
      5: AppSection.reports,
      6: AppSection.employees,
      7: AppSection.works, // TaskScreen (дубль)
      // 8 — MyProfile: ничейный
      9: AppSection.companies, // CompanyPage
      10: AppSection.objects, // ObjectPage
      11: AppSection.employees, // OpenViewEmployee
      13: AppSection.works, // TaskPage
      15: AppSection.employees, // EmployeesArchiveScreen
      16: AppSection.employees, // OpenViewEmployeeArchive
      17: AppSection.companies, // CompaniesScreenArchive
      18: AppSection.companies, // CompanyPageArchive
      19: AppSection.objects, // ObjectScreenArchive
      20: AppSection.objects, // ObjectPageArchive
      21: AppSection.works, // TaskScreenArchive — «Выполненные»
      22: AppSection.works, // TaskPageArchive
      23: AppSection.works, // SubmittedWorksScreen — «Сданные»
    },
    <WorksTab>[
      WorksTab('Задачи', 2),
      WorksTab('Выполненные', 21),
      WorksTab('Сданные', 23),
    ],
  );

  static const SectionIndex foreman = SectionIndex._(
    <AppSection, int>{
      AppSection.objects: 0,
      AppSection.schedule: 1,
      AppSection.works: 2,
      AppSection.companies: 3,
      AppSection.reports: 4,
      AppSection.employees: 5,
      // «Главная» у прораба своя не сделана (S06) — пока админский экран,
      // добавленный в конец списка, чтобы ничего не сдвигать.
      AppSection.home: 26,
    },
    <int, AppSection>{
      0: AppSection.objects,
      1: AppSection.schedule,
      2: AppSection.works,
      3: AppSection.companies,
      4: AppSection.reports,
      5: AppSection.employees,
      // 6 — MyProfile, 24 — OpenViewUserForeman: ничейные
      7: AppSection.companies, // CompanyPage
      8: AppSection.objects, // ObjectPageForeman
      9: AppSection.employees, // OpenViewEmployee
      11: AppSection.works, // TaskPage
      12: AppSection.objects, // ObjectScreenArchiveForeman
      13: AppSection.objects, // ObjectPageArchiveForeman
      15: AppSection.works, // TaskPageForeman
      16: AppSection.works, // TaskScreenCompletedForeman — «Выполненные»
      17: AppSection.works, // TaskPageCompletedForeman
      18: AppSection.companies, // CompanyPageForeman
      19: AppSection.companies, // CompaniesScreenArchiveForeman
      20: AppSection.companies, // CompanyPageArchiveForeman
      21: AppSection.employees, // OpenViewEmployeeForeman
      22: AppSection.employees, // EmployeesArchiveScreenForeman
      23: AppSection.employees, // OpenViewEmployeeArchiveForeman
      25: AppSection.works, // SubmittedWorksScreen — «Сданные»
      26: AppSection.home, // HomeScreen
    },
    <WorksTab>[
      WorksTab('Задачи', 2),
      WorksTab('Выполненные', 16),
      WorksTab('Сданные', 25),
    ],
  );
}
