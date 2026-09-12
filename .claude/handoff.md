---
этап: E03·S07 — бейдж непросмотренных работ у пункта «Работы»
статус: закрыт
дата: 2026-09-12
план: .claude/plan/E03-edinaya-navigatsiya.md
---

# Передача: бейдж в бургере живёт вместе с лентой; следующий — S08 (снос замещённого)

## Сделано и проверено

- Бейдж у «Работы» стоял ещё с S02 (`WorkCountsChips`, серая таблетка из
  `unreviewedWorksCount`, при нуле скрыта). Чего не было — связи с лентой:
  теперь `WorksBloc._refreshCounts` после непустого дифа опроса и после
  «назначить»/«проверил» дёргает `WorksRepository.unreviewedCount()` и кладёт
  число в нотифайер (492c59b). API-реализация делегирует в
  `SubmittedWorksRepository`, фикстура считает `submitted && !reviewed`.
- Тест «перемена и «проверил» обновляют бейдж» в `test/works/works_bloc_test.dart`;
  `flutter test test/works test/in_progress_works test/navigation` — 153;
  `dart analyze lib/screns/works test/works` — 0; `make lint` чист.
- Руками на `make up`: `app-live` под `pr@mail.ru` — бургер показывает
  `11 · 6 · 2`, у механика пункта нет. `works-live` (5615): «проверил» на
  заявке №58 → `POST /work/request/58/review/` 200 → `GET /work/feed?…&limit=1`
  → `GET /work/submitted/unreviewed-count`; та же пара повторилась за такт
  опроса, когда диф увидел перемену.

## Не доделано

- Делегирование `ApiWorksRepository.unreviewedCount()` тестом не покрыто —
  у `SubmittedWorksRepository` нет инъекции http-клиента. Сознательно.
- **Новая лента «Работы» ещё не в оболочке**: на `make up` пункт «Работы»
  открывает старый раздел подрядчика (вкладки «Задачи / Выполненные /
  Сданные», `navigation/works_section.dart`). Бейдж с ней связан только через
  `works-live`. Ввод `WorksScreen` в оболочку — часть S08.
- Найдено попутно, не чинил: `POST /work/maintenance/272/review/` отдаёт
  прорабу 403, хотя лента показывает работу под чипсом «Мои участки» —
  область записи расходится с областью чтения (участок берётся от
  исполнителя, а не от объекта?). Право `WORK_REVIEW` у прораба есть.

## Следующий этап

**Цель.** S08 — ввести `WorksScreen` в оболочку вместо старого раздела,
пройти пути админа и прораба на собранном стеке и снести замещённое.

**Готово, когда.** На `make up` пути админа и прораба пройдены по всем
пунктам бургера; удалены `my_drawer.dart`, `drawer_foreman.dart`,
`IntTest.index*`, `screns/task/*`, `task_foreman/*`, `task_completed_*`,
экраны архива задач; `dart analyze` чист, `flutter build web` собран.

## Первые шаги

1. `frontend/lib/navigation/works_section.dart` и `section_index.dart` —
   где `AppSection.works` резолвится в старый раздел; подменить на
   `WorksScreen(repository: ApiWorksRepository(), drawer: ShellDrawer())`
   (образец сборки — `lib/dev/works_live.dart:106`).
2. `grep -rn "WorkCountsChips\|inProgressCounts" frontend/lib` — решить, что
   из трёх таблеток остаётся, когда «Сейчас в работе» уходит в ленту;
   `primeWorkCounts()` в `home_page.dart:93` / `home_foreman.dart:235`.
3. Снос по списку из «Готово, когда»; после каждого куска
   `dart analyze lib` и `flutter test`.
4. `make up` + `app-live` (5610): пройти все пункты бургера под `1` и
   `pr@mail.ru`. Пароль вводит человек.

## Не трогать

- `screns/works/bloc/*`, `WorksRepository` — S05/S07 закрыты.
- `GET /work/feed`, `/review/` и бэк вообще; 403 на №272 — отдельная задача.
- `pubspec.yaml`/`.lock`; `flutter pub get` не запускать.

## Уточнить перед стартом

- Три таблетки у «Работы» (непросмотренные · в работе · с проблемой) остаются
  как есть, или после сноса «Сейчас в работе» оставить одну — непросмотренные?
- 403 на «проверил» чужого участка — баг бэка в S08, отдельный этап или
  ожидаемое поведение?

## Ссылки

- `frontend/lib/dev/works_live.dart` — как собирать `WorksScreen` на живом API.
- `frontend/lib/navigation/shell_drawer.dart` — бургер, который получит `WorksScreen`.
