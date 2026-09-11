---
этап: E03·S01 — единый бургер по схеме разделов
статус: закрыт
дата: 2026-09-11
план: .claude/plan/E03-edinaya-navigatsiya.md
---

# Передача: макет единого бургера утверждён, следующий — S02 перевод оболочек на go_router

## Сделано и проверено

- Новая сущность `frontend/lib/navigation/`: `app_section.dart` (enum
  `AppSection` — единственное место порядка пунктов: Главная · Объекты ·
  График · Работы · Отчёты · Компании · Сотрудники; `forRole(roleId)`),
  `app_drawer.dart` (stateless `AppDrawer(current, roleId, onSelect,
  onLogout, userName, trailing)`), `logout_confirm.dart` (`confirmLogout`).
- Набросок `lib/dev/app_drawer_preview.dart`, конфиг `app-drawer-preview`
  (порт 5613): обе роли рядом, подсветка ходит за тапом, «Выйти» спрашивает.
  Утверждено глазами 11 сентября: строка «Имя · Роль» под заголовком,
  таблетки `CountChip` на «Работы», диалог выхода с зелёной кнопкой.
- Проверки: `make lint` чист, `make test` 1009, `flutter test test/navigation`
  4, `dart analyze lib test` 0 ошибок (961 инфо подрядчика). `pubspec.lock`
  не тронут.
- Не закоммичено: весь дифф (`git status`) — navigation/, dev-превью, тест,
  launch.json, план E03, roadmap (E01/E02 → Закрыто и archive/).

## Не доделано

- Старые `helper/my_drawer/my_drawer.dart` и `foreman/drawer_foreman.dart`
  живы и работают — их подключение заменяется в S02, снос в S08.

## Следующий этап

**Цель.** S02: оболочки админа (`screns/home_page/home_page.dart`) и прораба
(`foreman/home_foreman.dart`) рисуют `AppDrawer`, раздел выбирается маршрутом
go_router, а не `IntTest.indexScreens` / `indexScreensForeman`.

**Готово, когда.** Раздел выбирается маршрутом; при переходах пункты не
двигаются и не пропадают, активный подсвечен верно; на web адрес и «назад»
работают; старые экраны открываются по старым пунктам без регресса.

## Первые шаги

1. Решить с пользователем: `go_router` — пакета в `pubspec.yaml` нет,
   добавление требует `flutter pub get`, а CLAUDE.md просит его без нужды не
   гонять (CI и локальная машина требуют разных `intl`). Альтернатива —
   `Navigator 2.0` без пакета; выбор за пользователем.
2. Карта разделов → экраны: `foreman/home_foreman.dart:80-160` (`_screenAt`
   по индексам 0,1,2,3,4,5,25), `helper/my_drawer/my_drawer.dart` (индексы
   0,1,2,21,3..5 админа). «Работы» до S05 ведёт на текущие «Задачи»
   (`TaskPage`/`TaskScreenForeman`), «Выполненные» и «Сданные» — пока пункты
   внутри старых экранов не заменены, доступ через «Работы» → вкладки или
   временно оставить как есть; решить на старте.
3. **Обязательно:** таблетки `WorkCountsChips`
   (`screns/in_progress_works/widgets/work_counts_chips.dart`), что сейчас
   стоят на «Сданные работы» у прораба, переезжают на пункт «Работы» через
   `AppDrawer.trailing` — пользователь просил не сломать эти уведомления.
   `HomeForeman` кладёт первое значение при входе — сохранить.

## Не трогать

- `screns/report/*`, `/reports/*` — E02 принят.
- `schedule_page.dart` и старый экран графика — S2.6 другого плана.
- Экраны механика и диспетчера — вне E03.
- `lib/navigation/*` по виду утверждён — правки только по новой просьбе.

## Уточнить перед стартом

- go_router (пакет + `pub get`) или Navigator 2.0 без новых зависимостей?
- Куда до S05 ведут «Выполненные задачи» и «Сданные работы» у админа/прораба?

## Ссылки

- `.claude/plan/E03-edinaya-navigatsiya.md` — 8 этапов, S01 закрыт.
- `frontend/lib/navigation/app_drawer.dart` — контракт drawer'а для оболочек.
- `frontend/lib/foreman/home_foreman.dart` — индексы экранов прораба.
