import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/work_item.dart';
import 'work_timer.dart';

/// «Корешок» строки: номер и статус работы — первое, что видит прораб.
///
/// Стоит слева, как у талона: номер крупно и жирно, под ним статус словом,
/// под статусом — таймер стадии, вся плашка залита цветом статуса вполсилы,
/// слева — полная полоса того же цвета. Таймер здесь, а не в своей колонке:
/// «в работе 2 ч 15 мин» — одна мысль, и искать её половинки по строке
/// незачем. При прокрутке лента читается по корешкам: где синий — новая, где
/// жёлтый — проблема, и номер тут же, чтобы назвать её механику по телефону.
///
/// Заливка вполсилы, а не в полный цвет: двадцать цветных плашек подряд
/// кричат одинаково громко, и статус перестаёт читаться. Полный цвет — только
/// на полосе и в слове.
class WorkStub extends StatelessWidget {
  const WorkStub({
    Key? key,
    required this.item,
    required this.now,
    this.compact = false,
  }) : super(key: key);

  final WorkItem item;

  /// Момент, от которого считается таймер — третьей строкой корешка.
  final DateTime now;

  /// Узкий экран: номер и статус в одну строку, а не столбиком.
  final bool compact;

  static const double width = 132;

  @override
  Widget build(BuildContext context) {
    final WorkStatus status = item.status;
    final bool paused = item.paused;
    // Пауза — свой цвет и слово: она выглядит как «в работе», а по смыслу
    // ближе к остановке, и прораб должен ловить её глазом отдельно.
    final Color color = paused ? ColorApp.myColorOrange : status.color;
    final String title = paused ? 'Пауза' : status.title;

    final Widget number = Text(
      item.number,
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ColorApp.myColorBlack,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
    );

    // Сжимается, а не режется: «На паузе» со значком в корешок впритык.
    final Widget label = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (paused) ...<Widget>[
            Icon(Icons.pause, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: compact ? null : width,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: compact
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  number,
                  const SizedBox(width: 8),
                  label,
                  const SizedBox(width: 8),
                  WorkTimer(item: item, now: now, dense: true),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                number,
                const SizedBox(height: 2),
                label,
                const SizedBox(height: 4),
                WorkTimer(item: item, now: now, dense: true),
              ],
            ),
    );
  }
}
