import 'work_item.dart';
import 'work_timing.dart';

/// Почему строка требует внимания прораба — или не требует.
///
/// Три причины, и только они: заявка без исполнителя, стадия, что
/// затянулась дольше порога из [WorkTiming], и пауза дольше часа. Всё
/// остальное — «идёт как идёт», и трогать его прорабу незачем. Пороги здесь
/// не свои: полоса сводки, красный таймер в корешке и блок «требуют
/// внимания» должны сходиться в одном числе.
enum AttentionReason {
  /// Новая заявка, которую никто не взял.
  unassigned,

  /// Стадия дольше порога: ждёт, лежит у механика или идёт слишком долго.
  overdue,

  /// Стоит на паузе дольше [WorkTiming.pausedLimit].
  pausedLong,
}

extension AttentionReasonLabel on AttentionReason {
  /// Подпись в сводке: «3 не назначены». Число подставляет виджет.
  String get title {
    switch (this) {
      case AttentionReason.unassigned:
        return 'не назначены';
      case AttentionReason.overdue:
        return 'затянулись';
      case AttentionReason.pausedLong:
        return 'на паузе дольше часа';
    }
  }
}

class WorkAttention {
  WorkAttention._();

  /// Причина, по которой строка попадает в блок внимания, или `null`.
  ///
  /// Закрытые не считаются: сданное и проблемное — история, а не задача.
  /// Отмеченные «проверил» тоже: прораб уже посмотрел, и держать строку
  /// наверху до следующей перемены статуса — значит учить его не нажимать.
  static AttentionReason? of(WorkItem item, DateTime now) {
    if (item.status.isClosed || item.reviewed) return null;
    if (item.status == WorkStatus.fresh && item.performer == null) {
      return AttentionReason.unassigned;
    }
    final WorkTiming timing = WorkTiming.of(item, now);
    if (!timing.overdue) return null;
    return item.paused ? AttentionReason.pausedLong : AttentionReason.overdue;
  }
}
