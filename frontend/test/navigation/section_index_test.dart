import 'package:els/helper/session.dart';
import 'package:els/navigation/app_section.dart';
import 'package:els/navigation/section_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final int roleId in <int>[Roles.admin, Roles.foreman]) {
    final SectionIndex index = SectionIndex.forRole(roleId);

    test('роль $roleId: корневой экран каждого раздела принадлежит ему', () {
      for (final AppSection s in AppSection.forRole(roleId)) {
        expect(index.sectionOf(index.rootOf(s)), s, reason: s.title);
      }
    });

    test('роль $roleId: вкладки «Работ» — экраны раздела «Работы»', () {
      expect(index.worksTabs.first.index, index.rootOf(AppSection.works));
      for (int i = 0; i < index.worksTabs.length; i++) {
        final WorksTab tab = index.worksTabs[i];
        expect(index.sectionOf(tab.index), AppSection.works, reason: tab.title);
        expect(index.worksTabOf(tab.index), i);
      }
    });
  }

  test('профиль ничейный: подсветка остаётся на прежнем разделе', () {
    expect(SectionIndex.admin.sectionOf(8), isNull);
    expect(SectionIndex.foreman.sectionOf(6), isNull);
    expect(SectionIndex.foreman.sectionOf(24), isNull);
  });

  test('у обеих ролей три вкладки «Работ», «Сданные» — последняя', () {
    for (final SectionIndex index in <SectionIndex>[
      SectionIndex.admin,
      SectionIndex.foreman,
    ]) {
      expect(index.worksTabs.map((WorksTab t) => t.title),
          <String>['Задачи', 'Выполненные', 'Сданные']);
    }
  });
}
