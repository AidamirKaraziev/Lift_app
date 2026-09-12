import 'dart:async';

import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../../navigation/shell_drawer.dart';
import '../../schedule/view/schedule_section.dart' show scheduleShowsLeading;
import '../models/work_counts.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../repository/works_repository.dart';
import '../widgets/work_filter_chips.dart';
import '../widgets/work_group_header.dart';
import '../widgets/work_row_tile.dart';

/// Экран «Работы»: заявки и акты ТО одной лентой.
///
/// Набросок S03: вид собран по образцу графиков E01 — серый фон, белая
/// шапка, белая карточка фильтров, белая карточка списка с разделителями.
/// Своего кадра в Figma нет.
///
/// Состояние держит сам экран: отбор и последний ответ репозитория. Блока
/// нет намеренно — он появится в S05 вместе с опросом `updated_since`, и
/// тащить `flutter_bloc` в набросок, который утверждают глазами, незачем.
class WorksScreen extends StatefulWidget {
  const WorksScreen({
    Key? key,
    required this.repository,
    this.drawer = const ShellDrawer(),
    this.onOpen,
    this.tick = const Duration(seconds: 30),
  }) : super(key: key);

  final WorksRepository repository;

  /// Боковое меню. У прораба лента — корень раздела, и на узкой ширине это
  /// единственный путь из «Работ» куда-то ещё.
  final Widget drawer;

  /// Клик по строке. Пусто — строка не нажимается: карточка работы — S05.
  final ValueChanged<WorkItem>? onOpen;

  /// Как часто перерисовывать таймеры строк. Один таймер на ленту, а не в
  /// каждой строке. `null` — не тикать: так экран собирается в тесте, где
  /// периодический таймер не даёт `pumpAndSettle` закончиться.
  final Duration? tick;

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  WorkFilters _filters = const WorkFilters();
  WorksFeed? _feed;
  bool _loading = true;
  String? _error;

  /// Номер последнего запроса: ответ на устаревший отбор выбрасывается,
  /// иначе поиск, набранный быстрее, чем отвечает фикстура, показал бы
  /// выдачу на предыдущую букву.
  int _serial = 0;

  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    final Duration? tick = widget.tick;
    if (tick != null) {
      _ticker = Timer.periodic(
        tick,
        (_) => setState(() => _now = DateTime.now()),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final int serial = ++_serial;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final WorksFeed feed = await widget.repository.fetch(_filters);
      if (!mounted || serial != _serial) return;
      setState(() {
        _feed = feed;
        _now = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted || serial != _serial) return;
      setState(() {
        _error = 'Не удалось загрузить работы';
        _loading = false;
      });
    }
  }

  void _onFiltersChanged(WorkFilters filters) {
    setState(() => _filters = filters);
    _load();
  }

  /// Быстрое действие: репозиторий меняет строку, лента перечитывается.
  /// Пока едет — заслонка, как при смене отбора: строка не должна
  /// «мигнуть» старым состоянием после нажатия.
  Future<void> _act(Future<void> Function() action, String done) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не получилось, повторите')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(done), duration: const Duration(seconds: 2)),
      );
    await _load();
  }

  Future<void> _assign(WorkItem item) async {
    final WorksFeed? feed = _feed;
    final String? who = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _AssignDialog(
        item: item,
        employees: feed?.employees ?? const <WorkEmployee>[],
        mySections: feed?.mySections ?? const <String>{},
      ),
    );
    if (who == null) return;
    await _act(
      () => widget.repository.assign(item, who),
      '${item.number} назначена: $who',
    );
  }

  /// Телефона у механика в ленте пока нет — он придёт с ручкой S04. Пока
  /// действие честно говорит, кому звонить, и не притворяется звонком.
  void _call(WorkItem item) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Позвонить: ${item.performer} — номер появится в S04'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Лента с заголовками блоков при порядке «сначала требуют внимания».
  ///
  /// Заголовки — обычные элементы списка, а не `SliverList` с шапками: их
  /// два, и лента одна. Разделитель перед заголовком не рисуется — у него
  /// свой серый фон, и линия над ним читалась бы как двойная.
  Widget _list(WorksFeed feed) {
    final bool grouped =
        _filters.sort == WorkSort.attention && feed.items.isNotEmpty;
    final int urgent = feed.attentionCount;
    final int rest = feed.items.length - urgent;

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < feed.items.length; i++) {
      if (grouped && i == 0) {
        rows.add(
          urgent > 0
              ? WorkGroupHeader(
                  title: 'Требуют внимания',
                  count: urgent,
                  urgent: true,
                )
              : WorkGroupHeader(title: 'Остальные', count: rest),
        );
      } else if (grouped && i == urgent) {
        rows.add(WorkGroupHeader(title: 'Остальные', count: rest));
      } else if (i > 0) {
        rows.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: ColorApp.myColorGrayBorder,
          ),
        );
      }
      final WorkItem item = feed.items[i];
      rows.add(
        WorkRowTile(
          item: item,
          now: _now,
          onTap: widget.onOpen == null ? null : () => widget.onOpen!(item),
          onAssign: () => _assign(item),
          onCall: () => _call(item),
          onReview: () => _review(item),
        ),
      );
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int index) => rows[index],
    );
  }

  Future<void> _review(WorkItem item) =>
      _act(() => widget.repository.review(item), '${item.number} — проверено');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorGrayShadow,
      drawer: widget.drawer,
      appBar: AppBar(
        automaticallyImplyLeading: scheduleShowsLeading(context),
        title: const Text('Работы'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: ColorApp.myColorBlack,
      ),
      body: Column(
        children: <Widget>[
          // Панель рисуется во всех состояниях, включая загрузку: чипс
          // применяется сразу, и пропадай панель на время запроса — нажать
          // второй было бы не по чему.
          WorkFilterChips(
            filters: _filters,
            counts: _feed?.counts ?? WorkCounts.empty,
            sections: _feed?.sections ?? const <String>[],
            performers: _feed?.performers ?? const <String>[],
            onChanged: _onFiltersChanged,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final WorksFeed? feed = _feed;

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (feed == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feed.items.isEmpty && !_loading) {
      return _EmptyView(
        filters: _filters,
        onReset: () => _onFiltersChanged(_filters.cleared()),
      );
    }

    // Лента остаётся на месте, пока едет новый отбор: заслонка поверх, а не
    // спиннер вместо списка — иначе каждый чипс мигал бы пустым экраном.
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ColorApp.myColorWhite,
            borderRadius: BorderRadius.circular(5),
          ),
          child: _list(feed),
        ),
        if (_loading) ...<Widget>[
          const ModalBarrier(dismissible: false, color: Colors.black12),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

/// «Кого назначить»: сотрудники с должностью и участком. Сначала «мои
/// механики» — с участков прораба, потом остальные: своих он назначает по
/// десять раз на дню, чужих — когда свои заняты. Одно нажатие — выбор,
/// без «ОК».
class _AssignDialog extends StatelessWidget {
  const _AssignDialog({
    Key? key,
    required this.item,
    required this.employees,
    required this.mySections,
  }) : super(key: key);

  final WorkItem item;
  final List<WorkEmployee> employees;
  final Set<String> mySections;

  @override
  Widget build(BuildContext context) {
    final List<WorkEmployee> mine = employees
        .where((WorkEmployee e) => mySections.contains(e.section))
        .toList();
    final List<WorkEmployee> others = employees
        .where((WorkEmployee e) => !mySections.contains(e.section))
        .toList();

    return SimpleDialog(
      title: Text(
        '${item.number} · ${item.objectName}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      children: <Widget>[
        if (mine.isNotEmpty) ...<Widget>[
          _AssignGroup(title: 'Мои механики', count: mine.length),
          for (final WorkEmployee e in mine) _AssignOption(employee: e),
        ],
        if (others.isNotEmpty) ...<Widget>[
          _AssignGroup(
            title: mine.isEmpty ? 'Сотрудники' : 'Остальные',
            count: others.length,
          ),
          for (final WorkEmployee e in others) _AssignOption(employee: e),
        ],
      ],
    );
  }
}

class _AssignGroup extends StatelessWidget {
  const _AssignGroup({Key? key, required this.title, required this.count})
    : super(key: key);

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Text(
        '${title.toUpperCase()} · $count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: ColorApp.myColorGrayText,
        ),
      ),
    );
  }
}

/// Строка сотрудника: значок должности, имя, под ним должность; участок —
/// справа, серым: он нужен, чтобы не послать человека через весь город.
class _AssignOption extends StatelessWidget {
  const _AssignOption({Key? key, required this.employee}) : super(key: key);

  final WorkEmployee employee;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onPressed: () => Navigator.of(context).pop(employee.name),
      child: Row(
        children: <Widget>[
          Tooltip(
            message: employee.specialty,
            child: Icon(employee.icon, size: 18, color: ColorApp.myColorGray),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(employee.name, style: const TextStyle(fontSize: 14)),
                Text(
                  employee.specialty,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
              ],
            ),
          ),
          if (employee.section != null) ...<Widget>[
            const SizedBox(width: 16),
            const Icon(
              Icons.place_outlined,
              size: 14,
              color: ColorApp.myColorGray,
            ),
            const SizedBox(width: 4),
            Text(
              employee.section!,
              style: const TextStyle(fontSize: 12, color: ColorApp.myColorGray),
            ),
          ],
        ],
      ),
    );
  }
}

/// Пустая выдача: «работ нет» и «под отбор не подошло» — разные случаи, и
/// путать их нельзя: во втором виноват отбор, который человек сам сузил.
class _EmptyView extends StatelessWidget {
  const _EmptyView({Key? key, required this.filters, required this.onReset})
    : super(key: key);

  final WorkFilters filters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final bool filtered = !filters.isEmpty;
    final String text;
    if (filters.archived && filters.activeCount == 1) {
      text = 'В архиве пусто';
    } else if (filtered) {
      text = 'Под отбор не подошла ни одна работа';
    } else {
      text = 'Работ пока нет';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              filtered ? Icons.search_off : Icons.inbox_outlined,
              size: 48,
              color: ColorApp.myColorGrayBorder,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorApp.myColorGrayText,
              ),
            ),
            if (filtered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Стоит условий: ${filters.activeCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorApp.myColorGrayText,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Сбросить всё',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorApp.myColorGreenAuth,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
