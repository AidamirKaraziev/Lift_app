import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../helper/class_colors.dart';
import '../model/appointment_order_draft.dart';
import '../repository/appointment_order_repository.dart';
import '../view/appointment_order_dialog.dart';

/// Кнопка «Приказ о назначении» в блоке документов карточки объекта.
///
/// Одна на обе карточки — админа и прораба. По нажатию тянет черновик с
/// сервера (`draft`), открывает диалог, а по «Скачать PDF» отдаёт правки в
/// `pdf` и открывает ссылку из ответа — снаружи приложения, как выгрузки
/// отчётов: на вебе это новая вкладка, на телефоне — просмотрщик PDF.
///
/// Ошибка любой из ручек — словами: черновика нет → снэкбар на странице,
/// PDF не собрался → строка в диалоге, правки остаются.
class AppointmentOrderButton extends StatefulWidget {
  const AppointmentOrderButton({
    Key? key,
    required this.objectId,
    this.repository = const AppointmentOrderRepository(),
  }) : super(key: key);

  /// `id` объекта из карточки; `null` — карточка ещё не знает объект,
  /// кнопка выключена.
  final int? objectId;

  final AppointmentOrderRepository repository;

  /// `viewObjectPage['id']` подрядчик держит нетипизированным — иногда это
  /// число, иногда строка.
  static int? objectIdFrom(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  @override
  State<AppointmentOrderButton> createState() => _AppointmentOrderButtonState();
}

class _AppointmentOrderButtonState extends State<AppointmentOrderButton> {
  bool _busy = false;

  Future<void> _open() async {
    final int? objectId = widget.objectId;
    if (_busy || objectId == null) return;
    setState(() => _busy = true);

    try {
      final AppointmentOrderDraft draft =
          await widget.repository.fetchDraft(objectId);
      if (!mounted) return;
      await showAppointmentOrderDialog(
        context,
        draft: draft,
        onDownload: (AppointmentOrderDraft edited) =>
            _download(objectId, edited),
      );
    } on AppointmentOrderException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(int objectId, AppointmentOrderDraft draft) async {
    final String url = await widget.repository.buildPdf(objectId, draft);
    // Ссылка живёт минуту, поэтому открываем сразу после получения, а не
    // складываем в состояние.
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = !_busy && widget.objectId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: enabled ? _open : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorApp.myColorGreenAuth,
            foregroundColor: ColorApp.myColorWhite,
            disabledBackgroundColor: ColorApp.myColorGreenAuth,
            disabledForegroundColor: ColorApp.myColorWhite,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          icon: _busy
              ? const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: ColorApp.myColorWhite,
                  ),
                )
              : const Icon(Icons.description_outlined, size: 18.0),
          label: const Text('Приказ о назначении'),
        ),
      ),
    );
  }
}
