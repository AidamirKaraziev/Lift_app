import 'package:flutter/widgets.dart';

import 'app_section.dart';

/// Куда ведёт адрес.
///
/// Адресов немного, и все они — верхний уровень: экран входа, страница
/// скачивания APK (`/app`, короткий адрес для механика) и раздел кабинета.
/// Детальные экраны внутри раздела адреса не имеют: они до S08 живут на
/// индексах подрядчика, и адрес при них остаётся адресом раздела.
class AppRoutePath {
  const AppRoutePath._(this.kind, this.section);

  const AppRoutePath.login() : this._(AppRouteKind.login, null);
  const AppRoutePath.download() : this._(AppRouteKind.download, null);
  const AppRoutePath.section(AppSection section)
      : this._(AppRouteKind.section, section);

  final AppRouteKind kind;
  final AppSection? section;

  /// Строка адреса.
  String get location {
    switch (kind) {
      case AppRouteKind.login:
        return '/login';
      case AppRouteKind.download:
        return '/app';
      case AppRouteKind.section:
        return '/${section!.slug}';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AppRoutePath && other.kind == kind && other.section == section;

  @override
  int get hashCode => Object.hash(kind, section);

  @override
  String toString() => 'AppRoutePath($location)';
}

enum AppRouteKind { login, download, section }

/// Разбор адреса и обратно.
///
/// Незнакомый адрес ведёт на «Главную», а не на 404: кабинет один, и
/// человеку с опечаткой в адресе показать больше нечего.
class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  const AppRouteInformationParser();

  static AppRoutePath parse(Uri uri) {
    final List<String> parts = uri.pathSegments;
    if (parts.isEmpty) return const AppRoutePath.section(AppSection.home);
    switch (parts.first) {
      case 'login':
        return const AppRoutePath.login();
      case 'app':
        return const AppRoutePath.download();
    }
    final AppSection? section = AppSection.bySlug(parts.first);
    return AppRoutePath.section(section ?? AppSection.home);
  }

  @override
  Future<AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async =>
      parse(routeInformation.uri);

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) =>
      RouteInformation(uri: Uri.parse(configuration.location));
}
