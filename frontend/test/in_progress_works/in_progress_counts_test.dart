/// Числа «идёт / с проблемой» из блока «Сейчас в работе».
///
/// Проверяется, что числа приходят из того же ответа, что и список, и
/// переживают неудачный запрос. Таблетка в меню их больше не показывает —
/// см. `test/works/unreviewed_chip_test.dart`.
library;

import 'package:els/screns/in_progress_works/bloc/in_progress_works_bloc.dart';
import 'package:els/screns/in_progress_works/in_progress_counts.dart';
import 'package:els/screns/in_progress_works/models/in_progress_work.dart';
import 'package:els/screns/in_progress_works/repository/in_progress_works_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _feed({int total = 4, int problems = 1}) {
  return <String, dynamic>{
    'data': <String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'kind': 'maintenance',
          'work_id': 12,
          'state': 'running',
          'since': 1786000000,
          'started_at': 1786000000,
          'performer': 'Механик Ковалёв',
          'object': const <String, dynamic>{'id': 3, 'name': 'Лифт 12'},
        },
      ],
      'total': total,
      'problems': problems,
    },
  };
}

class _Repository extends InProgressWorksRepository {
  _Repository({this.total = 4, this.problems = 1});

  final int total;
  final int problems;

  bool fails = false;

  @override
  Future<InProgressWorks> fetch() async {
    if (fails) throw const InProgressWorksException('Не удалось загрузить');
    return InProgressWorks.fromJson(_feed(total: total, problems: problems));
  }
}

void main() {
  setUp(() {
    inProgressCounts.value = InProgressCounts.none;
  });

  test('числа берутся из того же ответа, что и список', () async {
    final InProgressWorksBloc bloc =
        InProgressWorksBloc(repository: _Repository(total: 7, problems: 2));
    addTearDown(bloc.close);

    bloc.add(const InProgressWorksRequested());
    await bloc.stream.firstWhere((s) => s is InProgressWorksLoaded);

    expect(inProgressCounts.value,
        const InProgressCounts(total: 7, problems: 2));
  });

  test('неудачный запрос числа не обнуляет — они последние известные',
      () async {
    final _Repository repository = _Repository(total: 7, problems: 2);
    final InProgressWorksBloc bloc =
        InProgressWorksBloc(repository: repository);
    addTearDown(bloc.close);

    bloc.add(const InProgressWorksRequested());
    await bloc.stream.firstWhere((s) => s is InProgressWorksLoaded);

    repository.fails = true;
    bloc.add(const InProgressWorksRequested());
    await bloc.stream.firstWhere((s) => s is InProgressWorksFailure);

    expect(inProgressCounts.value,
        const InProgressCounts(total: 7, problems: 2));
  });
}
