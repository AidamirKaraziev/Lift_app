import 'package:flutter/material.dart';

import '../../../helper/count_chip.dart';
import '../../submitted_works/unreviewed_counter.dart';

/// Число у пункта меню «Работы»: сколько сданных работ ждёт проверки.
///
/// Одна серая таблетка. Раньше рядом стояли ещё две — сколько работ идёт и
/// сколько встало с проблемой; их считал раздел «Сейчас в работе», которого
/// больше нет: и то и другое лента «Работ» показывает сама, пилюлями на
/// строках и чипсами отбора. В меню остаётся только долг прораба.
///
/// Ноль не показывается: всё проверено — строка меню без числа, и это
/// нормальный вечер, а не поломка. Число кладёт лента, здесь его лишь слушают.
class UnreviewedChip extends StatelessWidget {
  const UnreviewedChip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: unreviewedWorksCount,
      builder: (BuildContext context, int unreviewed, _) {
        if (unreviewed <= 0) return const SizedBox.shrink();
        return CountChip(count: unreviewed, tone: CountTone.neutral);
      },
    );
  }
}
