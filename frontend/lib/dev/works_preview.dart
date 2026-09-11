import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return MaterialApp(
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
      ),
    );
  }
}
