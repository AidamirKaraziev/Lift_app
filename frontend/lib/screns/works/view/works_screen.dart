import 'dart:async';

import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../../navigation/shell_drawer.dart';
import '../../schedule/view/schedule_section.dart' show scheduleShowsLeading;
import '../models/work_counts.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../repository/works_repository.dart';
import '../widgets/work_filter_chips.dart';
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
          child: ListView.separated(
            itemCount: feed.items.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: ColorApp.myColorGrayBorder,
                ),
            itemBuilder: (BuildContext context, int index) {
              final WorkItem item = feed.items[index];
              return WorkRowTile(
                item: item,
                now: _now,
                onTap: widget.onOpen == null
                    ? null
                    : () => widget.onOpen!(item),
              );
            },
          ),
        ),
        if (_loading) ...<Widget>[
          const ModalBarrier(dismissible: false, color: Colors.black12),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
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
