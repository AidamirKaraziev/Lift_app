import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Заголовок блока ленты: «ТРЕБУЮТ ВНИМАНИЯ · 6», «ОСТАЛЬНЫЕ · 13».
///
/// Капителью, серым, с линией до края — как рубрика, а не как строка:
/// заголовок должен делить ленту, не споря со строками за внимание.
/// Блок внимания — красным: тем же, что и просроченный таймер.
class WorkGroupHeader extends StatelessWidget {
  const WorkGroupHeader({
    Key? key,
    required this.title,
    required this.count,
    this.urgent = false,
  }) : super(key: key);

  final String title;
  final int count;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final Color color = urgent ? ColorApp.myColorRed : ColorApp.myColorGray;
    return Container(
      color: ColorApp.myColorGrayShadow,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: <Widget>[
          Text(
            '${title.toUpperCase()} · $count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: color.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}
