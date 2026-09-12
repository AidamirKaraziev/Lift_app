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
  }

  test('профиль ничейный: подсветка остаётся на прежнем разделе', () {
    expect(SectionIndex.admin.sectionOf(8), isNull);
    expect(SectionIndex.foreman.sectionOf(6), isNull);
    expect(SectionIndex.foreman.sectionOf(24), isNull);
  });

  test('слоты снятых экранов задач ничейные', () {
    for (final int i in <int>[7, 13, 21, 22, 23]) {
      expect(SectionIndex.admin.sectionOf(i), isNull, reason: 'admin $i');
    }
    for (final int i in <int>[11, 15, 16, 17, 25]) {
      expect(SectionIndex.foreman.sectionOf(i), isNull, reason: 'foreman $i');
    }
  });
}
