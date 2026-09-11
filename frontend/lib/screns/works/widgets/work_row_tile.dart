import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/work_item.dart';
import 'work_kind_badge.dart';
import 'work_stub.dart';

/// Строка ленты «Работы»: объект и адрес · задание · исполнитель · вид ·
/// когда менялась · тип техники; слева — корешок с номером, статусом и
/// таймером.
///
/// Белая строка с разделителем, как у графиков, а не серая карточка, как в
/// ленте сданных: экран собран по образцу E01, и две разные строки в
/// соседних разделах сбивали бы с толку.
///
/// Что выделено и почему:
/// * название объекта — крупнее и жирнее всего: по нему строку ищут глазами;
/// * таймер в корешке — жирный, и красный, если стадия затянулась: это
///   единственный красный текст в строке;
/// * «не назначен» — жёлтым: новая заявка без исполнителя ждёт прораба;
/// * корешок слева — номер и статус, залитые цветом статуса: по ним ленту
///   читают при прокрутке, не вчитываясь в строки.
///
/// На узкой ширине колонки складываются. Порог — [kWideLayout].
class WorkRowTile extends StatelessWidget {
  const WorkRowTile({
    Key? key,
    required this.item,
    required this.now,
    this.onTap,
  }) : super(key: key);

  final WorkItem item;

  /// Момент, от которого считаются таймеры. Приходит с экрана: он один раз в
  /// полминуты перерисовывает ленту, и все строки тикают синхронно.
  final DateTime now;

  final VoidCallback? onTap;

  static const double kWideLayout = 960;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= kWideLayout;

        Widget content = Container(
          color: ColorApp.myColorWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: wide ? _wide() : _narrow(),
        );

        // Архивная строка приглушена и подписана: её видно, только когда
        // человек сам открыл архив, и всё же она не должна читаться как живая.
        if (!item.isActual) {
          content = Opacity(opacity: 0.6, child: content);
        }

        return InkWell(onTap: onTap, child: content);
      },
    );
  }

  Widget _wide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        WorkStub(item: item, now: now),
        const SizedBox(width: 16),
        Expanded(flex: 30, child: _object()),
        const SizedBox(width: 16),
        Expanded(flex: 32, child: _task()),
        const SizedBox(width: 16),
        Expanded(flex: 16, child: _performer()),
        const SizedBox(width: 16),
        SizedBox(
          width: 90,
          child: Align(
            alignment: Alignment.centerLeft,
            child: WorkKindBadge(kind: item.kind, actTitle: item.actTitle),
          ),
        ),
        const SizedBox(width: 12),
        // Дата и тип фиксированной ширины: в долях на 1100 дата ломалась на
        // две строки.
        SizedBox(width: 104, child: _when(alignEnd: true)),
        const SizedBox(width: 16),
        SizedBox(width: 108, child: _objectType(alignEnd: true)),
      ],
    );
  }

  Widget _narrow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: WorkStub(item: item, now: now, compact: true),
              ),
            ),
            const SizedBox(width: 8),
            WorkKindBadge(kind: item.kind, actTitle: item.actTitle),
          ],
        ),
        const SizedBox(height: 8),
        _object(),
        if (item.taskText != null) ...<Widget>[
          const SizedBox(height: 6),
          _task(),
        ],
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(child: _performer()),
            const SizedBox(width: 8),
            _when(),
          ],
        ),
        if (item.objectType != null) ...<Widget>[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: _objectType(alignEnd: true),
          ),
        ],
      ],
    );
  }

  Widget _object() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                item.objectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            WorkFlags(item: item),
          ],
        ),
        if (item.objectAddress != null)
          Text(
            item.objectAddress!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: ColorApp.myColorGray),
          ),
        if (!item.isActual)
          const Text(
            'в архиве',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: ColorApp.myColorGrayText,
            ),
          ),
      ],
    );
  }

  /// Задание есть только у заявок; у ТО оно — чек-лист акта, и здесь стоит
  /// подпись, а не пустое место: пустая колонка читается как потерянные данные.
  Widget _task() {
    final String? task = item.taskText;
    return Text(
      task ?? 'Плановое ТО по регламенту',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: task == null ? ColorApp.myColorGrayText : ColorApp.myColorBlack,
      ),
    );
  }

  Widget _performer() {
    final String? who = item.performer;
    final Color color = who == null
        ? ColorApp.myColorYellow
        : ColorApp.myColorBlack;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          who == null ? Icons.person_off_outlined : Icons.person_outline,
          size: 14,
          color: who == null ? ColorApp.myColorYellow : ColorApp.myColorGray,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            who ?? 'не назначен',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: who == null ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _when({bool alignEnd = false}) {
    return Text(
      item.updatedLabel,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: const TextStyle(fontSize: 11, color: ColorApp.myColorGrayText),
    );
  }

  /// Тип техники — последней колонкой, со значком: «Лифт с МП», «Эскалатор».
  /// Прораб по нему понимает, кого слать и с чем, не открывая карточку.
  Widget _objectType({bool alignEnd = false}) {
    final String? type = item.objectType;
    if (type == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(item.objectTypeIcon, size: 14, color: ColorApp.myColorGray),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorApp.myColorGray,
            ),
          ),
        ),
      ],
    );
  }
}
