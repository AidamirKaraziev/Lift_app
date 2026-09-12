import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/work_attention.dart';
import '../models/work_counts.dart';
import '../models/work_filters.dart';

/// Полоса сводки под фильтрами: сколько строк требуют внимания и из чего
/// это сложено, справа — переключатель порядка.
///
/// Одна строка, а не плитки с большими числами: прорабу нужен ответ «есть
/// ли что-то, что я должен сделать прямо сейчас», и три коротких куска
/// текста его дают быстрее, чем три квадрата. Каждый кусок нажимается и
/// работает как фильтр: «3 не назначены» оставляет в ленте только их;
/// повторное нажатие снимает.
///
/// Цвет числа — цвет причины в строке: жёлтое «не назначен», красный
/// таймер, оранжевая пауза. Слово рядом — серое: цвет несёт число.
class WorkSummaryBar extends StatelessWidget {
  const WorkSummaryBar({
    Key? key,
    required this.filters,
    required this.counts,
    required this.onChanged,
  }) : super(key: key);

  final WorkFilters filters;
  final WorkCounts counts;
  final ValueChanged<WorkFilters> onChanged;

  static const double fontSize = 11;

  @override
  Widget build(BuildContext context) {
    final int total = counts.attentionTotal;

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          total == 0
              ? 'Внимания не требует ничего'
              : 'Требуют внимания: $total',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: total == 0
                ? ColorApp.myColorGrayText
                : ColorApp.myColorBlack,
          ),
        ),
        for (final AttentionReason reason in AttentionReason.values)
          if (counts.ofAttention(reason) > 0 || filters.attention == reason)
            _Segment(
              reason: reason,
              count: counts.ofAttention(reason),
              active: filters.attention == reason,
              onTap: () => onChanged(
                filters.attention == reason
                    ? filters.copyWith(clearAttention: true)
                    : filters.copyWith(attention: reason),
              ),
            ),
        _SortToggle(
          sort: filters.sort,
          onChanged: (WorkSort sort) => onChanged(filters.copyWith(sort: sort)),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    Key? key,
    required this.reason,
    required this.count,
    required this.active,
    required this.onTap,
  }) : super(key: key);

  final AttentionReason reason;
  final int count;
  final bool active;
  final VoidCallback onTap;

  Color get _color {
    switch (reason) {
      case AttentionReason.unassigned:
        return ColorApp.myColorYellow;
      case AttentionReason.overdue:
        return ColorApp.myColorRed;
      case AttentionReason.pausedLong:
        return ColorApp.myColorOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: active ? ColorApp.myColorGreenLine : null,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$count ',
              style: TextStyle(
                fontSize: WorkSummaryBar.fontSize,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
            Text(
              reason.title,
              style: TextStyle(
                fontSize: WorkSummaryBar.fontSize,
                color: active ? ColorApp.myColorBlack : ColorApp.myColorGray,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
                decorationColor: ColorApp.myColorGrayBorder,
              ),
            ),
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

/// «Сначала: требуют внимания | по времени» — два сегмента, выбранный
/// залит тёмным. Не чипс: это не условие отбора, а порядок, и выглядеть
/// как чипсы над ним он не должен.
class _SortToggle extends StatelessWidget {
  const _SortToggle({Key? key, required this.sort, required this.onChanged})
    : super(key: key);

  final WorkSort sort;
  final ValueChanged<WorkSort> onChanged;

  @override
  Widget build(BuildContext context) {
    // `Wrap`, а не `Row`: на телефоне подпись и переключатель встают в две
    // строки, а не вылезают за край. `FittedBox` — на случай широкого
    // шрифта: два сегмента должны остаться рядом, пусть чуть мельче.
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        const Text(
          'Сначала: ',
          style: TextStyle(
            fontSize: WorkSummaryBar.fontSize,
            color: ColorApp.myColorGray,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: ColorApp.myColorGrayBorder),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _segment('требуют внимания', WorkSort.attention),
                _segment('по времени', WorkSort.updated),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _segment(String label, WorkSort value) {
    final bool on = sort == value;
    return InkWell(
      onTap: on ? null : () => onChanged(value),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: on ? ColorApp.myColorBlack : ColorApp.myColorWhite,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: WorkSummaryBar.fontSize,
            fontWeight: on ? FontWeight.w500 : FontWeight.w400,
            color: on ? ColorApp.myColorWhite : ColorApp.myColorGray,
          ),
        ),
      ),
    );
  }
}
