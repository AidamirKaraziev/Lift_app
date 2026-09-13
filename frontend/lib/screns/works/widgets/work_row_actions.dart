import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/work_attention.dart';
import '../models/work_item.dart';

/// Что прораб может сделать со строкой, не открывая её.
///
/// У новой без исполнителя — одна тёмная кнопка «Назначить», и видна она
/// всегда: это главное действие прораба, и прятать его за наведением —
/// значит заставлять искать. У остальных живых — «позвонить» и «проверил»,
/// бледные, проявляются при наведении; «проверил» у строки из блока
/// внимания — зелёная, потому что именно её и ждут. У закрытых действий
/// нет: звонить по сданной незачем.
///
/// На узкой ширине — «Назначить» и меню «⋯»: два значка на телефоне
/// промахиваются.
class WorkRowActions extends StatefulWidget {
  const WorkRowActions({
    Key? key,
    required this.item,
    required this.now,
    required this.compact,
    this.onAssign,
    this.onCall,
    this.onReview,
  }) : super(key: key);

  final WorkItem item;
  final DateTime now;
  final bool compact;
  final VoidCallback? onAssign;
  final VoidCallback? onCall;
  final VoidCallback? onReview;

  /// Ширина колонки в широкой раскладке — под «Назначить» с запасом.
  static const double width = 160;

  @override
  State<WorkRowActions> createState() => _WorkRowActionsState();
}

class _WorkRowActionsState extends State<WorkRowActions> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final WorkItem item = widget.item;
    if (item.status.isClosed || !item.isActual) {
      return const SizedBox.shrink();
    }

    final bool unassigned = item.performer == null;
    if (unassigned) {
      return _Assign(onPressed: widget.onAssign);
    }

    final bool urgent = WorkAttention.of(item, widget.now) != null;

    if (widget.compact) {
      return PopupMenuButton<VoidCallback>(
        tooltip: 'Действия',
        padding: EdgeInsets.zero,
        onSelected: (VoidCallback f) => f(),
        icon: const Icon(
          Icons.more_horiz,
          size: 20,
          color: ColorApp.myColorGray,
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<VoidCallback>>[
          PopupMenuItem<VoidCallback>(
            value: widget.onCall ?? () {},
            child: const Text('Позвонить', style: TextStyle(fontSize: 13)),
          ),
          if (!item.reviewed)
            PopupMenuItem<VoidCallback>(
              value: widget.onReview ?? () {},
              child: const Text('Проверил', style: TextStyle(fontSize: 13)),
            ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedOpacity(
        // Бледные, а не спрятанные: при прокрутке колонка должна читаться
        // как колонка, а не появляться из ниоткуда.
        opacity: _hover ? 1 : 0.4,
        duration: const Duration(milliseconds: 120),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Ghost(
              icon: Icons.phone_outlined,
              tooltip: 'Позвонить: ${item.performer}',
              onPressed: widget.onCall,
            ),
            if (!item.reviewed) ...<Widget>[
              const SizedBox(width: 6),
              _Ghost(
                icon: Icons.check,
                label: 'Проверил',
                tooltip: 'Убрать из «требуют внимания»',
                color: urgent ? ColorApp.myColorGreenAuth : null,
                onPressed: widget.onReview,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Assign extends StatelessWidget {
  const _Assign({Key? key, this.onPressed}) : super(key: key);

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorApp.myColorBlack,
          foregroundColor: ColorApp.myColorWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
        label: const Text(
          'Назначить',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost({
    Key? key,
    required this.icon,
    required this.tooltip,
    this.label,
    this.color,
    this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String tooltip;
  final String? label;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? ColorApp.myColorGray;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: label == null ? 6 : 8),
          decoration: BoxDecoration(
            border: Border.all(color: color ?? ColorApp.myColorGrayBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: c),
              if (label != null) ...<Widget>[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: c,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
