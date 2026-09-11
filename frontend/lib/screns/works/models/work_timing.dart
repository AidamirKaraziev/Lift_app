import 'work_item.dart';

/// Что показывает таймер строки и не пора ли его красить.
///
/// У каждой стадии свой отсчёт: новая — сколько ждёт, принятая — сколько
/// лежит у механика, идущая — сколько идёт, на паузе — сколько стоит, а у
/// закрытой — итог: за сколько выполнили. Одно число в строке, а не четыре:
/// прорабу нужен ответ «что с ней происходит и давно ли», остальное — в
/// подсказке по стадиям.
class WorkTiming {
  const WorkTiming({
    required this.label,
    required this.duration,
    required this.overdue,
    required this.live,
  });

  /// «ждёт», «в работе», «выполнена за» …
  final String label;
  final Duration duration;

  /// Стадия затянулась: новая ждёт дольше [freshLimit] и так далее. Таймер
  /// краснеет — это и есть повод прорабу вмешаться.
  final bool overdue;

  /// Отсчёт идёт: закрытую работу тикать незачем.
  final bool live;

  static const Duration freshLimit = Duration(hours: 2);
  static const Duration acceptedLimit = Duration(hours: 4);
  static const Duration runningLimit = Duration(hours: 8);
  static const Duration pausedLimit = Duration(hours: 1);

  static WorkTiming of(WorkItem item, DateTime now) {
    switch (item.status) {
      case WorkStatus.fresh:
        final Duration d = now.difference(item.createdAt);
        return WorkTiming(
          label: 'ждёт',
          duration: d,
          overdue: d > freshLimit,
          live: true,
        );
      case WorkStatus.accepted:
        final Duration d = now.difference(item.acceptedAt ?? item.createdAt);
        return WorkTiming(
          label: 'принята',
          duration: d,
          overdue: d > acceptedLimit,
          live: true,
        );
      case WorkStatus.running:
        if (item.paused) {
          final Duration d = now.difference(item.pausedAt!);
          return WorkTiming(
            label: 'на паузе',
            duration: d,
            overdue: d > pausedLimit,
            live: true,
          );
        }
        final Duration d = now.difference(item.startedAt ?? item.createdAt);
        return WorkTiming(
          label: 'в работе',
          duration: d,
          overdue: d > runningLimit,
          live: true,
        );
      case WorkStatus.submitted:
      case WorkStatus.problem:
        final DateTime end = item.closedAt ?? now;
        final DateTime start = item.startedAt ?? item.createdAt;
        return WorkTiming(
          label: item.status == WorkStatus.problem
              ? 'закрыта за'
              : 'выполнена за',
          duration: end.difference(start),
          overdue: false,
          live: false,
        );
    }
  }

  /// «40 мин» · «3 ч 20 мин» · «2 д 5 ч». Секунд нет: лента не секундомер,
  /// и мигающие секунды в двадцати строках только отвлекают.
  String get text => formatDuration(duration);

  static String formatDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final int days = d.inDays;
    final int hours = d.inHours % 24;
    final int minutes = d.inMinutes % 60;
    if (days > 0) return '$days д $hours ч';
    if (hours > 0) return '$hours ч ${minutes.toString().padLeft(2, '0')} мин';
    return '$minutes мин';
  }
}
