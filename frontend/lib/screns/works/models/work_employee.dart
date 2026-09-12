import 'package:flutter/material.dart';

/// Сотрудник в списке «кого назначить».
///
/// Должность — из `working_specialty` пользователя, участок — из
/// `division`; так же их показывает профиль механика. Роль в системе здесь
/// не нужна: прораб назначает по специальности, а не по правам.
class WorkEmployee {
  const WorkEmployee({
    required this.name,
    required this.specialty,
    this.section,
  });

  final String name;
  final String specialty;
  final String? section;

  /// Значок должности — по слову, как значок типа техники: справочник
  /// редактируемый, незнакомая должность получает общий значок.
  IconData get icon {
    final String s = specialty.toLowerCase();
    if (s.contains('диспетчер')) return Icons.headset_mic_outlined;
    if (s.contains('админ')) return Icons.admin_panel_settings_outlined;
    if (s.contains('наладчик') || s.contains('инженер')) {
      return Icons.settings_outlined;
    }
    if (s.contains('механик')) return Icons.build_outlined;
    return Icons.person_outline;
  }
}
