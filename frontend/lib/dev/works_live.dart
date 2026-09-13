import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../helper/api_client.dart';
import '../helper/class_colors.dart';
import '../screns/works/repository/api_works_repository.dart';
import '../screns/works/view/works_screen.dart';

/// Отдельная точка входа: экран «Работы» на **живом** бэкенде.
///
/// Соседняя `works_preview.dart` показывает тот же экран на фикстуре — но на
/// ней не проверить главное: что лента подхватывает перемены с сервера.
/// Сценарий: открыть под прорабом, во второй вкладке или в APK под механиком
/// взять заявку в работу — здесь пилюля строки должна смениться за такт
/// опроса, не пропав.
///
/// Запуск (бэкенд поднят через `make up`, nginx отдаёт API на 8080):
///
///     flutter run -t lib/dev/works_live.dart -d chrome \
///       --dart-define=API_ORIGIN=http://localhost:8080
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const WorksLiveApp());
}

class WorksLiveApp extends StatelessWidget {
  const WorksLiveApp({Key? key}) : super(key: key);

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
      home: const _LiveForm(),
    );
  }
}

/// Вход — единственное, чего экрану не хватает без оболочки.
class _LiveForm extends StatefulWidget {
  const _LiveForm({Key? key}) : super(key: key);

  @override
  State<_LiveForm> createState() => _LiveFormState();
}

class _LiveFormState extends State<_LiveForm> {
  final TextEditingController _login = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    // Пара токенов могла остаться с прошлого запуска.
    Api.restoreSession().then((bool ok) {
      if (mounted) setState(() => _signedIn = ok);
    });
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final http.Response response = await Api.login(
        email: _login.text.trim(),
        password: _password.text,
      );
      if (response.statusCode != 200) {
        setState(() => _error = 'Войти не удалось: проверьте почту и пароль');
        return;
      }
      setState(() => _signedIn = true);
    } catch (error) {
      setState(() => _error = 'Войти не удалось: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Меню — пустое: боковое меню тянет за собой оболочку раздела.
        builder: (BuildContext context) => WorksScreen(
          repository: ApiWorksRepository(),
          drawer: const Drawer(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text('Работы — живой бэкенд'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!_signedIn) ...<Widget>[
                  _field(_login, 'Почта'),
                  _field(_password, 'Пароль', obscure: true),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _busy ? null : _signIn,
                    style: _buttonStyle(),
                    child: Text(_busy ? 'Входим…' : 'Войти'),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: _openScreen,
                    style: _buttonStyle(),
                    child: const Text('Открыть «Работы»'),
                  ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12.0),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: ColorApp.myColorRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  static ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
    backgroundColor: ColorApp.myColorGreenAuth,
    foregroundColor: ColorApp.myColorWhite,
    elevation: 0.0,
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  );
}
