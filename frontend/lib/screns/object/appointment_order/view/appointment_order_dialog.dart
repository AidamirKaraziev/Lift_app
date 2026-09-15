import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../model/appointment_order_draft.dart';
import '../repository/appointment_order_repository.dart';

/// Диалог приказа о назначении ответственных за объект.
///
/// Реквизиты — номер, дата, город, подписант — правятся тут же; прораб,
/// механик и оборудование приходят из карточки объекта и только читаются:
/// приказ закрепляет то, что закреплено в системе, а не то, что вписали
/// руками. Нет человека или лифтов — диалог говорит об этом словами, а не
/// прячет строку.
///
/// [onDownload] получает черновик с правками и собирает PDF; пока он
/// работает, кнопка выключена и крутит индикатор. Бросил
/// [AppointmentOrderException] — текст печатается в диалоге, диалог остаётся
/// открытым: правки не пропадают, можно нажать ещё раз.
Future<void> showAppointmentOrderDialog(
  BuildContext context, {
  required AppointmentOrderDraft draft,
  required Future<void> Function(AppointmentOrderDraft draft) onDownload,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) =>
        AppointmentOrderDialog(draft: draft, onDownload: onDownload),
  );
}

class AppointmentOrderDialog extends StatefulWidget {
  const AppointmentOrderDialog({
    Key? key,
    required this.draft,
    required this.onDownload,
  }) : super(key: key);

  final AppointmentOrderDraft draft;
  final Future<void> Function(AppointmentOrderDraft draft) onDownload;

  @override
  State<AppointmentOrderDialog> createState() => _AppointmentOrderDialogState();
}

class _AppointmentOrderDialogState extends State<AppointmentOrderDialog> {
  late final TextEditingController _number;
  late final TextEditingController _city;
  late final TextEditingController _signerPosition;
  late final TextEditingController _signerName;
  late DateTime _date;

  /// Идёт сборка PDF — вторая отправка не уйдёт, пока не ответила первая.
  bool _busy = false;

  /// Что ответила ручка словами; `null` — ошибки нет.
  String? _error;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.draft.number);
    _city = TextEditingController(text: widget.draft.city);
    _signerPosition = TextEditingController(text: widget.draft.signerPosition);
    _signerName = TextEditingController(text: widget.draft.signerName);
    _date = widget.draft.date;
  }

  @override
  void dispose() {
    _number.dispose();
    _city.dispose();
    _signerPosition.dispose();
    _signerName.dispose();
    super.dispose();
  }

  AppointmentOrderDraft get _edited => widget.draft.copyWith(
        number: _number.text.trim(),
        date: _date,
        city: _city.text.trim(),
        signerPosition: _signerPosition.text.trim(),
        signerName: _signerName.text.trim(),
      );

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 1, 12, 31),
      locale: const Locale('ru'),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDownload(_edited);
    } on AppointmentOrderException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppointmentOrderDraft draft = widget.draft;
    return AlertDialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      titlePadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 0.0),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Приказ о назначении',
            style: TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.w600,
              color: ColorApp.myColorBlack,
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            'О назначении ответственных лиц за исправное состояние и '
            'проведение технического обслуживания оборудования',
            style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
          ),
        ],
      ),
      content: SizedBox(
        width: 560.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(child: SingleChildScrollView(child: _form(draft))),
            // Вне прокрутки: длинный перечень не спрячет ответ ручки.
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _ErrorLine(_error!),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
          child: const Text('Отмена'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _download,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorApp.myColorGreenAuth,
            foregroundColor: ColorApp.myColorWhite,
            disabledBackgroundColor: ColorApp.myColorGreenAuth,
            disabledForegroundColor: ColorApp.myColorWhite,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
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
              : const Icon(Icons.picture_as_pdf_outlined, size: 18.0),
          label: Text(_busy ? 'Собираем PDF…' : 'Скачать PDF'),
        ),
      ],
    );
  }

  /// Поля приказа — всё, что прокручивается.
  Widget _form(AppointmentOrderDraft draft) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _FieldRow(
          flexes: const <int>[3, 4, 5],
          children: <Widget>[
            _EditableField(
              label: 'Номер',
              hint: '—',
              controller: _number,
            ),
            _DateField(date: _date, onTap: _pickDate),
            _EditableField(label: 'Город', controller: _city),
          ],
        ),
        const _SectionTitle('Подписант'),
        _ReadOnlyField(label: 'Организация', value: draft.organization),
        const SizedBox(height: 12.0),
        _FieldRow(
          flexes: const <int>[5, 7],
          children: <Widget>[
            _EditableField(
              label: 'Должность',
              controller: _signerPosition,
            ),
            _EditableField(
              label: 'ФИО подписанта',
              controller: _signerName,
            ),
          ],
        ),
        const _SectionTitle('Ответственные'),
        _PersonRow(
          role: 'Прораб',
          person: draft.foreman,
          missing: 'Прораб не закреплён за объектом',
        ),
        const SizedBox(height: 12.0),
        _PersonRow(
          role: 'Электромеханик',
          person: draft.mechanic,
          missing: 'Электромеханик не закреплён за объектом',
        ),
        const _SectionTitle('Оборудование'),
        _ReadOnlyField(label: 'Адрес объекта', value: draft.address),
        const SizedBox(height: 12.0),
        if (draft.lifts.isEmpty)
          const _Notice('У объекта нет лифтов')
        else
          for (final AppointmentLift lift in draft.lifts) _LiftRow(lift),
        const SizedBox(height: 8.0),
      ],
    );
  }
}

const TextStyle _labelStyle = TextStyle(
  fontSize: 12.0,
  fontWeight: FontWeight.w300,
  color: ColorApp.myColorGray,
);

const TextStyle _valueStyle = TextStyle(
  fontSize: 15.0,
  fontWeight: FontWeight.w500,
  color: ColorApp.myColorBlack,
);

/// Поля в ряд на десктопе и столбиком на телефоне: в ряду уже 420 px
/// дата ломается на три строки.
class _FieldRow extends StatelessWidget {
  const _FieldRow({Key? key, required this.flexes, required this.children})
      : super(key: key);

  final List<int> flexes;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 420.0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 12.0),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 12.0),
              Expanded(flex: flexes[i], child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Заголовок блока внутри диалога.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          color: ColorApp.myColorBlack,
        ),
      ),
    );
  }
}

/// Поле, которое человек правит.
class _EditableField extends StatelessWidget {
  const _EditableField({
    Key? key,
    required this.label,
    required this.controller,
    this.hint,
  }) : super(key: key);

  final String label;
  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _labelStyle),
        const SizedBox(height: 4.0),
        TextField(
          controller: controller,
          style: _valueStyle,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
            enabledBorder: _border(ColorApp.myColorAvatar),
            focusedBorder: _border(ColorApp.myColorGreenAuth),
          ),
        ),
      ],
    );
  }
}

/// Дата приказа — тап открывает календарь.
class _DateField extends StatelessWidget {
  const _DateField({Key? key, required this.date, required this.onTap})
      : super(key: key);

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Дата', style: _labelStyle),
        const SizedBox(height: 4.0),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: ColorApp.myColorAvatar),
            ),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(formatOrderDate(date), style: _valueStyle)),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16.0,
                  color: ColorApp.myColorGray,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Поле только для чтения — данные из карточки объекта.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({Key? key, required this.label, required this.value})
      : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _labelStyle),
        const SizedBox(height: 4.0),
        Text(value.isEmpty ? '—' : value, style: _valueStyle),
      ],
    );
  }
}

/// Ответственный: роль, ФИО и должность из приказа; нет человека — плашка.
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    Key? key,
    required this.role,
    required this.person,
    required this.missing,
  }) : super(key: key);

  final String role;
  final AppointmentPerson? person;
  final String missing;

  @override
  Widget build(BuildContext context) {
    final AppointmentPerson? p = person;
    if (p == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(role, style: _labelStyle),
          const SizedBox(height: 4.0),
          _Notice(missing),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(role, style: _labelStyle),
        const SizedBox(height: 4.0),
        Text(p.fullName, style: _valueStyle),
        Text(
          p.position,
          style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
        ),
      ],
    );
  }
}

/// Строка перечня оборудования — как пункт списка в приказе.
class _LiftRow extends StatelessWidget {
  const _LiftRow(this.lift, {Key? key}) : super(key: key);

  final AppointmentLift lift;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.elevator_outlined,
            size: 18.0,
            color: ColorApp.myColorGray,
          ),
          const SizedBox(width: 8.0),
          Expanded(child: Text(lift.line, style: _valueStyle)),
        ],
      ),
    );
  }
}

/// Жёлтая плашка: чего в карточке не хватает для приказа.
class _Notice extends StatelessWidget {
  const _Notice(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorYellowLight,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: ColorApp.myColorYellow),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            size: 16.0,
            color: ColorApp.myColorOrange,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.0,
                color: ColorApp.myColorBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ответ ручки словами — над кнопками, вне прокрутки.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.error_outline, size: 16.0, color: ColorApp.myColorRed),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorRed),
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder _border(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(5.0),
    borderSide: BorderSide(color: color),
  );
}

/// «13.09.2026» — дата приказа как в шапке документа, без `intl`:
/// версии пакета у CI и локальной машины расходятся.
String formatOrderDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}
