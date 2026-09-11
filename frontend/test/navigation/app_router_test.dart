import 'package:els/helper/session.dart';
import 'package:els/navigation/app_route.dart';
import 'package:els/navigation/app_router.dart';
import 'package:els/navigation/app_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => idUserTest = Roles.admin);

  test('до входа адрес — /login, раздел из адреса открывается после входа',
      () async {
    final AppRouterDelegate router = AppRouterDelegate(autoRestore: false);
    await router.setNewRoutePath(const AppRoutePath.section(AppSection.objects));
    router.signedOut();
    expect(router.currentConfiguration, const AppRoutePath.login());

    // Адрес набрали до входа — запоминаем.
    await router.setNewRoutePath(const AppRoutePath.section(AppSection.companies));
    router.signedIn();
    expect(router.stage, AppStage.app);
    expect(router.section, AppSection.companies);
    expect(router.currentConfiguration,
        const AppRoutePath.section(AppSection.companies));
  });

  test('тап по бургеру меняет адрес и считается тапом', () {
    final AppRouterDelegate router = AppRouterDelegate(autoRestore: false)
      ..signedIn();
    final int before = router.tapSerial;
    int notified = 0;
    router.addListener(() => ++notified);

    router.goTo(AppSection.reports);
    expect(router.currentConfiguration, const AppRoutePath.section(AppSection.reports));
    expect(router.tapSerial, before + 1);
    expect(notified, 1);

    // Оболочка сообщает раздел карточки: адрес меняется, тапом не считается.
    router.showSection(AppSection.objects);
    expect(router.section, AppSection.objects);
    expect(router.tapSerial, before + 1);
    router.showSection(AppSection.objects);
    expect(notified, 2);
  });

  test('«/app» до входа открывается поверх кабинета после входа', () async {
    final AppRouterDelegate router = AppRouterDelegate(autoRestore: false);
    router.signedOut();
    await router.setNewRoutePath(const AppRoutePath.download());
    expect(router.downloadOpen, isFalse);
    router.signedIn();
    expect(router.downloadOpen, isTrue);
    expect(router.currentConfiguration, const AppRoutePath.download());

    expect(await router.popRoute(), isTrue);
    expect(router.downloadOpen, isFalse);
    expect(router.currentConfiguration, const AppRoutePath.section(AppSection.home));
  });

  test('выход возвращает на вход и сбрасывает раздел', () {
    final AppRouterDelegate router = AppRouterDelegate(autoRestore: false)
      ..signedIn()
      ..goTo(AppSection.employees)
      ..signedOut();
    expect(router.stage, AppStage.login);
    expect(router.currentConfiguration, const AppRoutePath.login());
    router.signedIn();
    expect(router.section, AppSection.home);
  });
}
