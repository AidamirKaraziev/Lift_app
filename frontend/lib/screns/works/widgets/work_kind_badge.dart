import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/work_item.dart';

/// Бейдж вида работы — тот же, что в ленте сданных (`SubmittedWorkBadges`).
///
/// У ТО на нём название акта: «ТО-3», а не слово «ТО». Прорабу важно, какое
/// именно ТО идёт — годовое и месячное занимают разное время и проверяются
/// по-разному; слово «ТО» этого не говорит.
class WorkKindBadge extends StatelessWidget {
  const WorkKindBadge({Key? key, required this.kind, this.actTitle})
    : super(key: key);

  final WorkKind kind;
  final String? actTitle;

  @override
  Widget build(BuildContext context) {
    final bool isAct = kind == WorkKind.maintenance && actTitle != null;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kind.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAct ? actTitle! : kind.title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ColorApp.myColorWhite,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Значки у названия объекта: проблема, дефектный акт, комментарий механика.
///
/// Значки, а не текст: они стоят у каждой десятой строки, и слово там
/// раздувало бы ряд. Подсказка при наведении даёт текст целиком.
class WorkFlags extends StatelessWidget {
  const WorkFlags({Key? key, required this.item}) : super(key: key);

  final WorkItem item;

  @override
  Widget build(BuildContext context) {
    final List<Widget> flags = <Widget>[
      if (item.status == WorkStatus.problem)
        const _Flag(
          icon: Icons.warning_amber_rounded,
          color: ColorApp.myColorYellow,
          tooltip: 'Закрыта с проблемой',
        ),
      if (item.hasDefect)
        const _Flag(
          icon: Icons.report_gmailerrorred,
          color: ColorApp.myColorRed,
          tooltip: 'Есть дефектный акт',
        ),
      if (item.comment != null)
        _Flag(
          icon: Icons.chat_bubble_outline,
          color: ColorApp.myColorGray,
          tooltip: item.comment!,
        ),
    ];
    if (flags.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final Widget flag in flags) ...<Widget>[
          const SizedBox(width: 6),
          flag,
        ],
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({
    Key? key,
    required this.icon,
    required this.color,
    required this.tooltip,
  }) : super(key: key);

  final IconData icon;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 16, color: color),
    );
  }
}
