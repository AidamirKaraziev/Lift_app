---
этап: E03·S08 — «Работы» в оболочке, снос замещённого
статус: закрыт
дата: 2026-09-13
знание: записано 2026-09-13 (/save-session) · эпик E03 закрыт
план: .claude/plan/E03-edinaya-navigatsiya.md
---

# Передача: E03 закрыт, лента «Работы» живёт в оболочке обеих ролей

## Сделано и проверено

- Пункт «Работы» у админа и прораба открывает `WorksScreen` (слот 2 в
  `home_page.dart` / `home_foreman.dart`); вкладки «Задачи / Выполненные /
  Сданные» и `works_section.dart` сняты. Коммит a8cfdc9.
- У «Работ» одна таблетка — `UnreviewedChip` (`screns/works/widgets/`) на
  `unreviewedWorksCount`; первое значение кладёт оболочка в `initState`.
- Удалены `screns/task/*`, `foreman/task_foreman/*`, `helper/my_drawer/`,
  `drawer_foreman.dart`, `submitted_works_screen.dart`, `prime_work_counts`,
  `work_counts_chips` — ≈7 900 строк. Слоты снятых экранов держат нумерацию
  заглушками, `SectionIndex` их не знает (тест «слоты ничейные»).
- Диспетчер: три запроса заявки/фото перенесены в его `application_screen.dart`,
  «Выполненные» получили `DrawerDispatcher` вместо `MyDrawer`.
- `flutter test` — 545; `dart analyze lib test` — новых предупреждений нет;
  `make lint` чист; `flutter build web` собран.
- Руками на `make up` + `app-live` (5610): админ `1` и прораб `pr@mail.ru` —
  все 7 пунктов бургера, карточка объекта и «назад», «Выйти» с диалогом.

## Не доделано

- **`IntTest.index*` не снят** — 415 мест в 91 файле (карточки объектов,
  компаний, сотрудников, архивы). Решение 2026-09-13: отдельный этап, в
  плане его ещё нет — `/plan`. Критерий S08 в подплане сужен.
- Строки ленты не нажимаются (`onOpen` пуст) — карточка работы отдельный
  этап; после неё сносить `submitted_works/view,widgets,bloc`,
  `in_progress_works/widgets/in_progress_*`, `work_card_live`.
- Найдено, не чинил: `POST /work/maintenance/272/review/` отдаёт прорабу 403
  при работе под чипсом «Мои участки» — область записи ≠ области чтения.
- Найдено, не чинил: при «Выйти» с открытым бургером в консоли
  «FocusScopeNode used after disposed» — `ShellDrawer.onLogout` не закрывает
  drawer перед `signOut`; шум debug-сборки, вход не ломает.
- Лента пересоздаётся при уходе в другой раздел (bloc внутри `WorksScreen`);
  «Графики» держат bloc в оболочке — тот же приём, если понадобится.

## Следующий этап

E03 закрыт. Дальше по roadmap — E04 «Письмо о назначении» (подплана нет,
образец у заказчика запрошен: `els-vault` → «приказ о назначении…»), либо
новый этап на хвосты E03: карточка работы по клику и снятие `IntTest.index*`.
Выбор — за человеком в `/plan`.

## Не трогать

- `screns/works/bloc/*`, `WorksRepository`, `GET /work/feed` — закрыты S05/S07.
- Слоты-заглушки в `_screens`/`_screensForeman` — не перенумеровывать:
  `els-vault/knowledge/decisions/снятые экраны подрядчика оставляют пустой слот…`.
- `pubspec.yaml`/`.lock`; `flutter pub get` не запускать.

## Уточнить перед стартом

- Что первым: E04 по образцу заказчика или хвосты E03 (карточка работы,
  `IntTest.index*`)?
- 403 на «проверил» чужого участка — баг бэка или ожидаемое право?

## Ссылки

- `.claude/plan/roadmap.md` — порядок эпиков после сдачи.
- `frontend/lib/dev/works_live.dart` — лента на живом API без оболочки.
- `frontend/lib/navigation/section_index.dart` — какие слоты сняты и почему.
