---
этап: E03·S06 — вывести топ сотрудников на главной прораба
статус: закрыт
дата: 2026-09-12
план: .claude/plan/E03-edinaya-navigatsiya.md
---

# Передача: у прораба тот же топ сотрудников, что у админа; следующий — S07 (бейдж «Работы»)

## Сделано и проверено

- «Главная» была общей ещё с S02; отличие было одно — прорабу прятали
  переключатель «механики / прорабы», потому что ручка отвечала ему 403 на
  `kind=foreman`. Заказчик просил «общий топ», решение 2026-08-14
  пересмотрено: бэк отдаёт рейтинг прорабов прорабу (e853fd9), фронт
  показывает оба переключателя всем (bfe8628).
- `TopEmployees` принимает `repository` для тестов; новый виджет-тест
  `frontend/test/home/top_employees_switches_test.dart` (3 теста).
- `make lint` чист; `pytest tests/test_api_top_employees.py` — 25;
  `flutter test` — 548; `dart analyze` по `top_employees`, `test/home` — 0.
- Руками на `make up` + `app-live` под `pr@mail.ru`: оба переключателя,
  «Прорабы» → `GET /statistics/top-employees?kind=foreman` 200, список
  прорабов отрисован.
- Vault: заметка-решение о рейтинге и матрица прав обновлены (в bfe8628).
- Оба коммита на ветке `fix/apk-api-origin`, дерево чистое.

## Не доделано

- Описание ручки в OpenAPI поправлено, снапшот `openapi_surface.json`
  описаний не хранит — менять не пришлось.

## Следующий этап

**Цель.** S07 — бейдж числа новых/непросмотренных работ на пункте
«Работы» в бургере.

**Готово, когда.** В бургере у «Работы» число из
`GET /work/submitted/unreviewed-count`, обновляется вместе с лентой, при
нуле скрыт.

## Первые шаги

1. `frontend/lib/screns/submitted_works/unreviewed_counter.dart` —
   `ValueNotifier<int> unreviewedWorksCount`; его уже читают
   `in_progress_works/widgets/work_counts_chips.dart` и экран сданных,
   пишет `SubmittedWorksRepository.unreviewedCount()` / `markReviewed()`.
2. `frontend/lib/navigation/shell_drawer.dart` — пункт
   `AppSection.works` (`app_section.dart:17`) без бейджа; повесить
   `ValueListenableBuilder` на счётчик, при 0 не рисовать.
3. `frontend/lib/screns/works/bloc/works_bloc.dart` — после непустого дифа
   опроса bloc делает `fetch(limit: 1)` за счётчиками; там же обновить
   `unreviewedWorksCount` (ручка `/work/feed` считает те же сданные —
   `backend/.../work_feed.py:198`), чтобы бейдж жил «вместе с лентой».
4. Проверить под `pr@mail.ru` на `make up` через `app-live` (порт 5610):
   механик сдаёт работу → число в бургере растёт за такт опроса.

## Не трогать

- `GET /statistics/top-employees` и `top_employees.dart` — S06 закрыт.
- `GET /work/feed` — правки только если бейдж нельзя взять из `counts`.
- `lib/navigation/works_section.dart`, `section_index.dart` — снос в S08.
- `pubspec.yaml`/`.lock`; `flutter pub get` не запускать.

## Уточнить перед стартом

- Бейдж считает «непросмотренные сданные» (как `unreviewed-count`) или
  «новые» из `counts` ленты `/work/feed`? План говорит первое.
- Бейдж только у прораба/админа, или механику тоже что-то показывать?

## Ссылки

- `frontend/lib/screns/works/bloc/works_bloc.dart` — где лента узнаёт о
  переменах; сюда подвесить обновление счётчика.
- `frontend/lib/screns/submitted_works/repository/submitted_works_repository.dart:52`
  — `unreviewedCount()`, готовый запрос к ручке.
