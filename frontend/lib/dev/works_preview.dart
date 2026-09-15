import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/user_bloc/user_bloc.dart';
import '../foreman/defects/defect_entry.dart';
import '../foreman/defects/defects_repository.dart';
import '../screns/in_progress_works/models/order_details.dart';
import '../screns/in_progress_works/models/work_details.dart';
import '../screns/in_progress_works/repository/work_details_repository.dart';
import '../screns/works/repository/fixture_works_repository.dart';
import '../screns/works/view/works_screen.dart';

/// Отдельная точка входа: экран «Работы» на фикстуре, без сервера.
///
/// Нужна, пока набросок не утверждён: кадра в Figma нет, и смотреть вёрстку
/// через вход и оболочку с живой базой — долго и не про вёрстку.
///
/// Запуск:
///
///     flutter run -t lib/dev/works_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const WorksPreviewApp());
}

class WorksPreviewApp extends StatelessWidget {
  const WorksPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Профиль в шапке карточки читает `UserBloc`; даём пустой, без входа он
    // ничего не рисует. Выше `MaterialApp`, а не внутри `home`: карточка
    // открывается новым маршрутом, и провайдер из `home` ей не виден.
    return BlocProvider<UserBloc>(
      create: (_) => UserBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('ru', '')],
        theme: ThemeData(textTheme: GoogleFonts.ubuntuTextTheme()),
        // Меню — пустое: боковое меню тянет за собой вход в систему.
        home: WorksScreen(
          repository: FixtureWorksRepository(),
          drawer: const Drawer(),
          detailsRepository: const _FixtureDetailsRepository(),
          defectsRepository: const _FixtureDefectsRepository(),
        ),
      ),
    );
  }
}

/// Подробности работы без сервера: у каждого ТО один и тот же чек-лист с
/// отметками, у заявки — задание и категория. Времена считаются от id, чтобы
/// карточки не выглядели одинаково.
class _FixtureDetailsRepository extends WorkDetailsRepository {
  const _FixtureDetailsRepository();

  @override
  Future<WorkDetails> fetchDetails(int actId) async {
    final DateTime now = DateTime.now();
    // Сданные ТО в фикстуре — с id ниже 7700.
    final bool finished = actId < 7700;
    return WorkDetails(
      id: actId,
      checklist: const WorkChecklist(
        title: 'ТО',
        steps: <ChecklistStep>[
          ChecklistStep(
            id: 1,
            title: 'Проверка табличек и освещения',
            done: true,
          ),
          ChecklistStep(
            id: 2,
            title: 'Осмотр дверей шахты и кабины',
            done: true,
            comment: 'Ролик верхней створки с люфтом',
          ),
          ChecklistStep(id: 3, title: 'Проверка кнопок вызова', done: true),
          ChecklistStep(id: 4, title: 'Осмотр канатов', done: false),
          ChecklistStep(id: 5, title: 'Проверка ловителей', done: false),
        ],
      ),
      startedAt: now.subtract(Duration(minutes: 40 + actId % 50)),
      finishedAt: finished ? now.subtract(const Duration(minutes: 5)) : null,
      mainMechanicId: 5,
    );
  }

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async => WorkPhotos.empty;

  @override
  Future<OrderDetails> fetchOrder(int orderId) async {
    return OrderDetails(
      id: orderId,
      taskText: 'Лифт не закрывает двери на 3 этаже, жильцы жалуются',
      categoryName: 'Двери',
      reasonFault: 'Ролик створки',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      executor: const Performer(
        id: 5,
        name: 'Смирнов А.',
        phone: '+7 921 123-45-67',
      ),
    );
  }

  @override
  Future<OrderPhotos> fetchOrderPhotos(int orderId) async =>
      const OrderPhotos(<String>[]);

  @override
  Future<Performer> fetchPerformer(int userId) async => const Performer(
    id: 5,
    name: 'Смирнов А.',
    specialty: 'Механик',
    phone: '+7 921 123-45-67',
  );
}

/// Дефекты без сервера: у ТО с нечётным id — один акт, у остальных пусто.
class _FixtureDefectsRepository extends DefectsRepository {
  const _FixtureDefectsRepository();

  @override
  Future<List<DefectEntry>> byActFact(int actFactId) async {
    if (actFactId.isEven) return const <DefectEntry>[];
    return <DefectEntry>[
      DefectEntry(
        id: actFactId * 10,
        title: 'Износ ролика створки двери',
        source: DefectSource.checklistStep,
        state: DefectState.created,
        description: 'Ролик верхней створки с люфтом, требуется замена.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  @override
  Future<DefectEntry> byId(int id) async => (await byActFact(id ~/ 10)).first;
}
