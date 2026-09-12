import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../schedule/widgets/schedule_search_field.dart';
import '../models/work_counts.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../models/work_section.dart';
import 'work_summary_bar.dart';

/// Панель над лентой работ: чипсы статусов и видов со счётчиками, «Архив»
/// и поиск.
///
/// Раскладка и размеры — от панели графиков (`ScheduleFiltersBar`): белая
/// карточка, пилюли 24 с кеглем 10, рамка зелёная, выбранная — с заливкой.
/// Но чипсы, а не выпадающие списки: значений пять и пять, они известны в
/// коде, и прятать их за стрелкой значит скрывать счётчики — ради которых
/// панель и нужна.
///
/// Три ряда: статусы, под ними виды с архивом и поиском, под ними участок
/// и механик. В одном `Wrap` границу между «что с работой» и «что за
/// работа» глаз не находит. Участок и механик — выпадашками, а не чипсами:
/// значений там столько, сколько в справочнике, и в ряд они не лягут.
/// Внизу, за чертой, — полоса сводки ([WorkSummaryBar]).
///
/// Отбор применяется сразу по нажатию; кнопки «Применить» нет, как и на
/// графиках.
class WorkFilterChips extends StatelessWidget {
  const WorkFilterChips({
    Key? key,
    required this.filters,
    required this.counts,
    required this.onChanged,
    this.sections = const <WorkSection>[],
    this.employees = const <WorkEmployee>[],
  }) : super(key: key);

  final WorkFilters filters;
  final WorkCounts counts;
  final ValueChanged<WorkFilters> onChanged;

  /// Справочники для выпадашек — из ответа ленты. Механики — те же, кого
  /// можно назначить: отдельного списка исполнителей у ручки нет.
  final List<WorkSection> sections;
  final List<WorkEmployee> employees;

  static const double pillHeight = 24;
  static const double fontSize = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      // На всю ширину: в `Column` карточка иначе ужалась бы до чипсов и встала
      // по центру, а список под ней — во всю ширину.
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final WorkStatus status in WorkStatus.values)
                _Chip(
                  label: status.title,
                  count: counts.ofStatus(status),
                  dot: status.color,
                  active: filters.status == status,
                  onTap: () => onChanged(
                    filters.status == status
                        ? filters.copyWith(clearStatus: true)
                        : filters.copyWith(status: status),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final WorkKind kind in WorkKind.values)
                _Chip(
                  label: kind.title,
                  count: counts.ofKind(kind),
                  active: filters.kind == kind,
                  onTap: () => onChanged(
                    filters.kind == kind
                        ? filters.copyWith(clearKind: true)
                        : filters.copyWith(kind: kind),
                  ),
                ),
              // Архив — отдельный вид ленты, поэтому стоит отдельно от чипсов
              // отбора и рисуется иконкой: это не «ещё один статус».
              _Chip(
                label: 'Архив',
                icon: Icons.inventory_2_outlined,
                active: filters.archived,
                onTap: () =>
                    onChanged(filters.copyWith(archived: !filters.archived)),
              ),
              ScheduleSearchField(
                text: filters.search,
                onSearch: (String text) =>
                    onChanged(filters.copyWith(search: text)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _DropChip(
                label: 'Участок',
                value: filters.sectionId,
                options: <int, String>{
                  for (final WorkSection s in sections) s.id: s.label,
                },
                onSelected: (int? v) => onChanged(
                  v == null
                      ? filters.copyWith(clearSection: true)
                      : filters.copyWith(sectionId: v, mine: false),
                ),
              ),
              _DropChip(
                label: 'Механик',
                value: filters.performerId,
                options: <int, String>{
                  for (final WorkEmployee e in employees) e.id: e.name,
                },
                onSelected: (int? v) => onChanged(
                  v == null
                      ? filters.copyWith(clearPerformer: true)
                      : filters.copyWith(performerId: v),
                ),
              ),
              // «Мои участки» и один участок — взаимно исключают: выбранный
              // участок за пределами моих дал бы пустую ленту без объяснения.
              _Chip(
                label: 'Мои участки',
                icon: Icons.place_outlined,
                active: filters.mine,
                onTap: () => onChanged(
                  filters.mine
                      ? filters.copyWith(mine: false)
                      : filters.copyWith(mine: true, clearSection: true),
                ),
              ),
              // От одного условия, а не от двух: выпадашка «Участок: Центр»
              // одна — и снимать её через меню дольше, чем одной кнопкой.
              if (filters.activeCount > 0)
                _ResetAll(
                  count: filters.activeCount,
                  onPressed: () => onChanged(filters.cleared()),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: ColorApp.myColorGrayBorder),
          ),
          WorkSummaryBar(
            filters: filters,
            counts: counts,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Выпадашка в виде чипса: «Участок: все ▾», выбранное — «Участок: Центр ✕».
/// Рисуется как [_Chip], чтобы ряд читался одним рядом; стрелка вместо
/// счётчика говорит, что за ним список, а не переключатель.
/// Выпадашка «Участок» / «Механик»: значение — id, подпись — из
/// справочника. Выбранное, чего в справочнике уже нет (ушло из ленты после
/// опроса), показывается номером — чипс остаётся снимаемым.
class _DropChip extends StatelessWidget {
  const _DropChip({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  }) : super(key: key);

  final String label;
  final int? value;
  final Map<int, String> options;
  final ValueChanged<int?> onSelected;

  /// Пункт «Все»: id на бэке с единицы, ноль свободен.
  static const int _all = 0;

  @override
  Widget build(BuildContext context) {
    final bool active = value != null;
    final String? title = value == null ? null : options[value] ?? '№$value';
    return PopupMenuButton<int>(
      tooltip: label,
      padding: EdgeInsets.zero,
      onSelected: (int v) => onSelected(v == _all ? null : v),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        const PopupMenuItem<int>(
          value: _all,
          height: 36,
          child: Text('Все', style: TextStyle(fontSize: 12)),
        ),
        for (final MapEntry<int, String> o in options.entries)
          PopupMenuItem<int>(
            value: o.key,
            height: 36,
            child: Text(
              o.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: o.key == value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Container(
        height: WorkFilterChips.pillHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? ColorApp.myColorGreenLine : ColorApp.myColorWhite,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: ColorApp.myColorGreenAuth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$label: ${title ?? 'все'}',
              style: TextStyle(
                fontSize: WorkFilterChips.fontSize,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: ColorApp.myColorBlack,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              active ? Icons.close : Icons.arrow_drop_down,
              size: active ? 12 : 16,
              color: ColorApp.myColorGray,
            ),
          ],
        ),
      ),
    );
  }
}

/// Чипс-переключатель. Число справа — сколько строк за ним; ноль показываем
/// серым, а чипс оставляем нажимаемым: пустая выдача под ним честно скажет
/// «ничего», а исчезающие чипсы сбивают ряд.
class _Chip extends StatelessWidget {
  const _Chip({
    Key? key,
    required this.label,
    required this.active,
    required this.onTap,
    this.count,
    this.dot,
    this.icon,
  }) : super(key: key);

  final String label;
  final int? count;
  final Color? dot;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool zero = count == 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: WorkFilterChips.pillHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? ColorApp.myColorGreenLine : ColorApp.myColorWhite,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: zero && !active
                ? ColorApp.myColorGrayBorder
                : ColorApp.myColorGreenAuth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (dot != null) ...<Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...<Widget>[
              Icon(icon, size: 12, color: ColorApp.myColorGreenAuth),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: WorkFilterChips.fontSize,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: zero && !active
                    ? ColorApp.myColorGrayText
                    : ColorApp.myColorBlack,
              ),
            ),
            if (count != null) ...<Widget>[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: WorkFilterChips.fontSize,
                  fontWeight: FontWeight.w700,
                  color: zero
                      ? ColorApp.myColorGrayText
                      : ColorApp.myColorGreenAuth,
                ),
              ),
            ],
            if (active) ...<Widget>[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 12, color: ColorApp.myColorGray),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResetAll extends StatelessWidget {
  const _ResetAll({Key? key, required this.count, required this.onPressed})
    : super(key: key);

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: WorkFilterChips.pillHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Сбросить всё ($count)',
              style: const TextStyle(
                fontSize: WorkFilterChips.fontSize,
                fontWeight: FontWeight.w500,
                color: ColorApp.myColorGreenAuth,
                decoration: TextDecoration.underline,
                decorationColor: ColorApp.myColorGreenAuth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
