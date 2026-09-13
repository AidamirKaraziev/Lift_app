import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/work_item.dart';
import '../models/work_timing.dart';

/// Таймер строки: «в работе 2 ч 15 мин», «ждёт 3 ч», «выполнена за 1 ч 20 мин».
///
/// Время считает сам виджет от [now], а тикает экран: один таймер на ленту,
/// не двадцать. Затянувшаяся стадия — красным и жирным: это единственный
/// красный текст в строке, и он значит «пора вмешаться».
///
/// Под числом — подсказка со стадиями: создана → принята → начата → сдана.
class WorkTimer extends StatelessWidget {
  const WorkTimer({
    Key? key,
    required this.item,
    required this.now,
    this.alignEnd = false,
    this.dense = false,
  }) : super(key: key);

  final WorkItem item;
  final DateTime now;
  final bool alignEnd;

  /// Только число, без подписи стадии: в корешке стадия уже написана строкой
  /// выше, и «в работе» дважды подряд — лишнее.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final WorkTiming timing = WorkTiming.of(item, now);
    final Color color = timing.overdue
        ? ColorApp.myColorRed
        : timing.live
        ? ColorApp.myColorBlack
        : ColorApp.myColorGray;

    return Tooltip(
      message: item.timeline
          .map(
            (MapEntry<String, DateTime> e) =>
                '${e.key} — ${formatDateTime(e.value)}',
          )
          .join('\n'),
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Сжимается, а не режется: «1 ч 05 мин» на 375 рядом с пилюлей
          // впритык, и обрезанное «1 ч 05 м…» врало бы про минуты.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  timing.live
                      ? Icons.timer_outlined
                      : Icons.check_circle_outline,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 3),
                Text(
                  timing.text,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!dense)
            Text(
              timing.label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 10,
                color: timing.overdue
                    ? ColorApp.myColorRed
                    : ColorApp.myColorGrayText,
              ),
            ),
        ],
      ),
    );
  }
}
