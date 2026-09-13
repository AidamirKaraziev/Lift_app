import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/class_colors.dart';
import '../screns/object/appointment_order/fixture_appointment_order.dart';
import '../screns/object/appointment_order/view/appointment_order_dialog.dart';

/// Набросок диалога «Приказ о назначении» — вид без сервера и без входа.
///
/// Кадра в макете нет, и по правилу «макет утверждается до логики» диалог
/// показывается отдельно на фикстуре: три расклада переключаются кнопками,
/// первый открывается сам.
///
/// Запуск:
///
///     flutter run -t lib/dev/appointment_order_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const AppointmentOrderPreviewApp());
}

class AppointmentOrderPreviewApp extends StatelessWidget {
  const AppointmentOrderPreviewApp({Key? key}) : super(key: key);

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
      home: const _FixturePicker(),
    );
  }
}

class _FixturePicker extends StatefulWidget {
  const _FixturePicker({Key? key}) : super(key: key);

  @override
  State<_FixturePicker> createState() => _FixturePickerState();
}

class _FixturePickerState extends State<_FixturePicker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _open(AppointmentOrderFixture.full),
    );
  }

  Future<void> _open(AppointmentOrderFixture fixture) {
    return showAppointmentOrderDialog(
      context,
      draft: buildAppointmentOrderFixture(fixture),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorWhite,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Набросок диалога «Приказ о назначении»',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16.0),
            for (final AppointmentOrderFixture fixture
                in AppointmentOrderFixture.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  onPressed: () => _open(fixture),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.myColorGreenAuth,
                    foregroundColor: ColorApp.myColorWhite,
                  ),
                  child: Text(fixture.title),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
