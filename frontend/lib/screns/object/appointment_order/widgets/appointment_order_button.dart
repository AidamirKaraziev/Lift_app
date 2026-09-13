import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../model/appointment_order_draft.dart';
import '../view/appointment_order_dialog.dart';

/// Кнопка «Приказ о назначении» в блоке документов карточки объекта.
///
/// Одна на обе карточки — админа и прораба: обе держат объект одной и той
/// же нетипизированной картой, из неё и собирается черновик. Реквизиты
/// приказа в карте не живут — до ручки черновика (S02) они пусты.
class AppointmentOrderButton extends StatelessWidget {
  const AppointmentOrderButton({Key? key, required this.object})
      : super(key: key);

  /// Объект как он лежит в `listSelectedObject['data']`.
  final Map<String, dynamic> object;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => showAppointmentOrderDialog(
            context,
            draft: AppointmentOrderDraft.fromObjectMap(object),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorApp.myColorGreenAuth,
            foregroundColor: ColorApp.myColorWhite,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          icon: const Icon(Icons.description_outlined, size: 18.0),
          label: const Text('Приказ о назначении'),
        ),
      ),
    );
  }
}
