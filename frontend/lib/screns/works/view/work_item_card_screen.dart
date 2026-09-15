import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../foreman/defects/defects_repository.dart';
import '../../../foreman/defects/work_defects_section.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/my_user.dart';
import '../../in_progress_works/bloc/work_details_bloc.dart';
import '../../in_progress_works/repository/work_details_repository.dart';
import '../../in_progress_works/widgets/work_card_body.dart';
import '../../responsive_screens/responsive.dart';
import '../models/work_item.dart';
import '../widgets/work_kind_badge.dart';
import '../widgets/work_stub.dart';

/// Карточка работы из единой ленты «Работы» — любого статуса и вида.
///
/// Строка ленты отвечает на «что, где и в каком состоянии». Карточка — на
/// «что там на самом деле»: чек-лист с отметками и снимками, дефекты, времена
/// — у ТО; задание, категория, причина — у заявки. Шапка рисуется из строки,
/// по которой сюда пришли, и стоит до ответа сервера: открыв карточку, человек
/// видит ровно то, на что нажал.
///
/// Тело то же, что у карточек текущей и сданной работы
/// (`in_progress_works/widgets/work_card_body.dart`). Разница — в краях: лента
/// смешивает все статусы, и «работа ушла из списка» для этой карточки не
/// событие, поэтому подробности берутся в фазе `standalone`, без проверки
/// края. Действий два: позвонить механику и, для закрытой работы, отметить
/// «Проверил» — ту же отметку, что у кнопки в строке ленты.
class WorkItemCardScreen extends StatefulWidget {
  const WorkItemCardScreen({
    Key? key,
    required this.item,
    this.onReview,
    this.repository,
    this.defectsRepository,
  }) : super(key: key);

  final WorkItem item;

  /// Отметить «Проверил». Пусто — кнопки в карточке нет. Лента под карточкой
  /// перечитывает строку сама: карточка только зовёт и красит отметку у себя.
  final VoidCallback? onReview;

  /// Подменяются в тестах и превью; в бою карточка берёт живые ручки сама.
  final WorkDetailsRepository? repository;
  final DefectsRepository? defectsRepository;

  @override
  State<WorkItemCardScreen> createState() => _WorkItemCardScreenState();
}

class _WorkItemCardScreenState extends State<WorkItemCardScreen> {
  late WorkItem _item = widget.item;

  /// Отметку показываем сразу, не дожидаясь ленты: имени проверившего у
  /// клиента нет — его подставит сервер, и в ленте прораб увидит настоящее
  /// «кто и когда», когда вернётся.
  void _review() {
    widget.onReview?.call();
    setState(() => _item = _item.copyWith(reviewed: true));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkDetailsBloc>(
      create: (_) => WorkDetailsBloc(
        workId: _item.id,
        kind: _item.kind,
        phase: WorkPhase.standalone,
        repository: widget.repository,
      )..add(const WorkDetailsRequested()),
      child: _CardView(
        item: _item,
        onReview: widget.onReview == null ? null : _review,
        defectsRepository: widget.defectsRepository,
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({
    Key? key,
    required this.item,
    required this.onReview,
    required this.defectsRepository,
  }) : super(key: key);

  final WorkItem item;
  final VoidCallback? onReview;
  final DefectsRepository? defectsRepository;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      body: Column(
        children: <Widget>[
          _Header(size: size),
          Expanded(
            child: BlocBuilder<WorkDetailsBloc, WorkDetailsState>(
              builder: (BuildContext context, WorkDetailsState state) {
                return ListView(
                  padding: const EdgeInsets.all(ColorApp.kPadding),
                  children: _body(context, state),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, WorkDetailsState state) {
    // Порог тот же, что у строки ленты и у других карточек, — иначе экраны
    // разъедутся: слева шапка и действия, справа чек-лист во всю высоту; на
    // телефоне всё встаёт друг под друга.
    final bool narrow = Responsive.isMobile(context);

    final List<Widget> left = <Widget>[
      WorkSheet(child: _Head(item: item)),
      if (item.status.isClosed) ...<Widget>[
        const SizedBox(height: 12.0),
        WorkSheet(
          child: _Review(reviewed: item.reviewed, onReview: onReview),
        ),
      ],
      const SizedBox(height: 12.0),
      WorkSheet(
        child: WorkCallBlock(
          state: state,
          fallbackName: item.performer ?? 'Исполнитель не назначен',
          subtitle: item.kind == WorkKind.maintenance
              ? item.actTitle ?? 'ТО'
              : item.taskText,
        ),
      ),
    ];

    final List<Widget> right = <Widget>[
      if (state is WorkDetailsFailure)
        WorkSheet(child: WorkFailureBlock(message: state.message))
      else if (state is WorkDetailsReady) ...<Widget>[
        WorkSheet(
          child: WorkChecklistBlock(
            checklist: state.details.checklist,
            photos: state.photos,
          ),
        ),
        const SizedBox(height: 12.0),
        // Между чек-листом и временами: дефект — это то, что механик нашёл,
        // проходя чек-лист, и читается он следом за ним.
        WorkSheet(
          child: WorkDefectsSection(
            workId: item.id,
            objectName: item.objectName,
            repository: defectsRepository,
          ),
        ),
        const SizedBox(height: 12.0),
        WorkSheet(
          child: WorkTimesBlock(
            details: state.details,
            isProblem: item.status == WorkStatus.problem,
            showFinished: true,
            note: _timesNote(state),
          ),
        ),
      ] else if (state is OrderReady) ...<Widget>[
        // У заявки времена заменяет строка «Заведена», а больше система о
        // ней ничего не записывает — блок один, чек-листа нет.
        WorkSheet(child: WorkOrderBlock(state: state)),
        const SizedBox(height: 12.0),
        // Дефектный акт заводится и на заявке — механик нашёл его, разбирая
        // задание, и читается он следом за заданием.
        WorkSheet(
          child: WorkDefectsSection(
            workId: item.id,
            byOrder: true,
            objectName: item.objectName,
            repository: defectsRepository,
          ),
        ),
      ] else
        const WorkSheet(child: WorkSkeleton()),
    ];

    if (narrow) {
      return <Widget>[...left, const SizedBox(height: 12.0), ...right];
    }

    return <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: left,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: right,
            ),
          ),
        ],
      ),
    ];
  }

  /// Сноска к временам — по статусу строки, а не по ответу сервера: у
  /// назначенной работы времён нет ни одного, и блок остался бы пустым
  /// заголовком без объяснения, почему.
  String _timesNote(WorkDetailsReady state) {
    if (state.details.isFinished || item.status.isClosed) {
      return 'Работа закрыта механиком. Прораб её не правит — карточка '
          'показывает, что было сделано.';
    }
    if (state.details.startedAt == null) return 'Работа ещё не начата.';
    return 'Работа идёт. Прораб её не правит и не закрывает — это делает '
        'механик в своём телефоне.';
  }
}

/// Заголовок экрана — как у других карточек, со стрелкой назад вместо
/// бургера: карточка открыта поверх ленты, и уходить из неё некуда, кроме как
/// обратно.
class _Header extends StatelessWidget {
  const _Header({Key? key, required this.size}) : super(key: key);

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ColorApp.kPadding),
      color: ColorApp.myColorWhite,
      height: 70,
      width: double.infinity,
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: size.width > 350 ? 20.0 : 16.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            'Работа',
            style: TextStyle(
              fontSize: size.width > 350 ? 25.0 : 18.0,
              fontWeight: size.width > 350 ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(width: size.width > 500 ? 40.0 : 10.0),
          const MyUser(),
        ],
      ),
    );
  }
}

/// Шапка: ровно то, что было в строке ленты, на которую нажали.
///
/// Корешок с номером, статусом и таймером — тот же, что в ленте: прораб
/// узнаёт работу по нему. Задание и комментарий механика здесь не режутся —
/// за этим карточку и открывают.
class _Head extends StatelessWidget {
  const _Head({Key? key, required this.item}) : super(key: key);

  final WorkItem item;

  @override
  Widget build(BuildContext context) {
    final String? task = item.taskText;
    final String? comment = item.comment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: WorkStub(item: item, now: DateTime.now()),
              ),
            ),
            const SizedBox(width: 8.0),
            WorkKindBadge(kind: item.kind, actTitle: item.actTitle),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                item.objectName,
                style: const TextStyle(
                  fontSize: 16.0,
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
            style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
          ),
        if (item.objectType != null) ...<Widget>[
          const SizedBox(height: 4.0),
          Row(
            children: <Widget>[
              Icon(
                item.objectTypeIcon,
                size: 14.0,
                color: ColorApp.myColorGray,
              ),
              const SizedBox(width: 4.0),
              Text(
                item.objectType!,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: ColorApp.myColorGray,
                ),
              ),
            ],
          ),
        ],
        if (!item.isActual)
          const Text(
            'в архиве',
            style: TextStyle(
              fontSize: 11.0,
              fontStyle: FontStyle.italic,
              color: ColorApp.myColorGrayText,
            ),
          ),
        const SizedBox(height: 12.0),
        // Задание есть только у заявок; у ТО оно — чек-лист акта справа.
        Text(
          task ?? 'Плановое ТО по регламенту',
          style: TextStyle(
            fontSize: 13.0,
            color: task == null
                ? ColorApp.myColorGrayText
                : ColorApp.myColorBlack,
          ),
        ),
        const SizedBox(height: 12.0),
        WorkFact(
          name: 'Исполнитель',
          value: item.performer ?? 'не назначен',
          faint: item.performer == null,
        ),
        WorkFact(name: 'Изменена', value: item.updatedLabel),
        if (item.section != null)
          WorkFact(name: 'Участок', value: item.section!),
        if (comment != null) ...<Widget>[
          const SizedBox(height: 4.0),
          const Text(
            'Комментарий механика',
            style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
          ),
          const SizedBox(height: 2.0),
          Text(comment, style: const TextStyle(fontSize: 13.0)),
        ],
      ],
    );
  }
}

/// Отметка «Проверил» — второе действие карточки после звонка.
///
/// Только у закрытой работы: проверять можно то, что сдано. Стоит выше
/// чек-листа на телефоне и слева от него на широком экране: прораб сначала
/// читает, что сделано, и отмечает уже осознанно. Отмеченную работу
/// подписываем, а кнопку убираем: отмечать дважды нечего.
class _Review extends StatelessWidget {
  const _Review({Key? key, required this.reviewed, required this.onReview})
    : super(key: key);

  final bool reviewed;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    if (reviewed) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.check_circle_outline,
            size: 18.0,
            color: ColorApp.myColorGreenAuth,
          ),
          SizedBox(width: 8.0),
          Expanded(child: Text('Проверено', style: TextStyle(fontSize: 13.0))),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Работу ещё не смотрели.',
          style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
        ),
        const SizedBox(height: 10.0),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: onReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorApp.myColorGreenAuth,
              foregroundColor: ColorApp.myColorWhite,
              elevation: 0.0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Проверил'),
          ),
        ),
      ],
    );
  }
}
