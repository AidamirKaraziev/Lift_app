import 'package:flutter/material.dart';

import '../helper/class_colors.dart';
import 'section_index.dart';

/// Раздел «Работы» до S05: полоса вкладок над одним из старых экранов.
///
/// «Задачи», «Выполненные» и «Сданные работы» были отдельными пунктами
/// старых бургеров; в едином бургере это один раздел. Экран под вкладкой
/// показывается ровно один — не `TabBarView` и не `IndexedStack`: экраны
/// подрядчика делят `GlobalKey` `myOpenDrawer`, и два живых сразу — крэш.
///
/// Какая вкладка открыта, знает оболочка (по индексу экрана), поэтому
/// возврат из карточки задачи попадает на ту же вкладку.
class WorksSection extends StatelessWidget {
  const WorksSection({
    Key? key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    required this.child,
  }) : super(key: key);

  final List<WorksTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  /// Экран открытой вкладки.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: ColorApp.myColorWhite,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < tabs.length; i++)
                _Tab(
                  title: tabs[i].title,
                  active: i == selected,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
        const Divider(height: 1.0, color: ColorApp.myColorGrayBorder),
        Expanded(child: child),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.title, required this.active, required this.onTap});

  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2.0,
              color: active ? ColorApp.myColorGreenAuth : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? ColorApp.myColorGreenAuth : ColorApp.myColorGrayText,
          ),
        ),
      ),
    );
  }
}
