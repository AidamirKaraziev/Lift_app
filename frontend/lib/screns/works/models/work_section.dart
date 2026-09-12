/// Участок обслуживания — для выпадашки «Участок».
///
/// Отбор идёт по [id], человеку показывается [title]: справочник
/// редактируемый, и хранить в отборе название значило бы терять его при
/// переименовании.
class WorkSection {
  const WorkSection({required this.id, this.title});

  factory WorkSection.fromJson(Map<String, dynamic> json) => WorkSection(
    id: json['id'] is num ? (json['id'] as num).toInt() : 0,
    title: json['title']?.toString(),
  );

  final int id;
  final String? title;

  /// Подпись в выпадашке. Без названия — по номеру, а не пусто.
  String get label => title == null || title!.isEmpty ? 'Участок $id' : title!;
}
