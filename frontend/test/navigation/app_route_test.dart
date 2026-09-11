import 'package:els/navigation/app_route.dart';
import 'package:els/navigation/app_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AppRouteInformationParser parser = AppRouteInformationParser();

  test('раздел, вход и страница скачивания разбираются из адреса', () {
    expect(AppRouteInformationParser.parse(Uri.parse('/objects')),
        const AppRoutePath.section(AppSection.objects));
    expect(AppRouteInformationParser.parse(Uri.parse('/login')),
        const AppRoutePath.login());
    expect(AppRouteInformationParser.parse(Uri.parse('/app')),
        const AppRoutePath.download());
  });

  test('корень и незнакомый адрес ведут на «Главную»', () {
    expect(AppRouteInformationParser.parse(Uri.parse('/')),
        const AppRoutePath.section(AppSection.home));
    expect(AppRouteInformationParser.parse(Uri.parse('/nope/42')),
        const AppRoutePath.section(AppSection.home));
  });

  test('адрес восстанавливается из маршрута для каждого раздела', () async {
    for (final AppSection s in AppSection.values) {
      final AppRoutePath path = AppRoutePath.section(s);
      final RouteInformation? info = parser.restoreRouteInformation(path);
      expect(info!.uri.path, '/${s.slug}');
      expect(await parser.parseRouteInformation(info), path);
    }
  });
}
