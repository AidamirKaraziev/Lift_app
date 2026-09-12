import 'package:flutter/material.dart';

/// Сотрудник в списке «кого назначить».
///
/// Должность — из `working_specialty` пользователя, участок — из
/// `division`; так же их показывает профиль механика. Роль в системе здесь
/// не нужна: прораб назначает по специальности, а не по правам.
///
/// Поля — как у `WorkEmployee` в `backend/src/schemas/work_feed.py`;
/// назначение уходит на бэк по [id].
class WorkEmployee {
  const WorkEmployee({
    required this.id,
    required this.name,
    required this.specialty,
    this.sectionId,
    this.section,
    this.phone,
  });

  factory WorkEmployee.fromJson(Map<String, dynamic> json) => WorkEmployee(
    id: _int(json['id']) ?? 0,
    name: _string(json['name']) ?? 'Без имени',
    specialty: _string(json['specialty']) ?? '',
    sectionId: _int(json['section_id']),
    section: _string(json['section']),
    phone: _string(json['phone']),
  );

  final int id;
  final String name;
  final String specialty;
  final int? sectionId;
  final String? section;
  final String? phone;

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

int? _int(dynamic v) => v is num ? v.toInt() : null;

String? _string(dynamic v) {
  if (v == null) return null;
  final String s = v.toString();
  return s.isEmpty ? null : s;
}
