---
этап: E03·S02 — оболочки админа и прораба на маршрутах
статус: закрыт
дата: 2026-09-11
план: .claude/plan/E03-edinaya-navigatsiya.md
---

# Передача: обе оболочки ходят по маршрутам с одним бургером, следующий — S03 макет экрана «Работы»

## Сделано и проверено

- Раздел выбирается адресом: `lib/navigation/app_router.dart` (Navigator 2.0,
  без пакетов) + `app_route.dart` (парсер `/home … /employees`, `/login`,
  `/app`). `main.dart` — `MaterialApp.router`, path-адреса без `#`,
  `<base href="/">` в `web/index.html` (без него Flutter не стартует).
- Обе оболочки (`screns/home_page/home_page.dart`, `foreman/home_foreman.dart`)
  рисуют `ShellDrawer` (`lib/navigation/shell_drawer.dart` — `AppDrawer` из
  глобалей, без параметров); в 22 экранах `drawer: MyDrawer()/DrawerForeman()`
  заменён на `ShellDrawer()`.
- Индекс ↔ раздел: `lib/navigation/section_index.dart` — таблицы по ролям
  (фактические позиции списков, комментарии админа были сбиты на 1 с 8-го).
  Детальные экраны по-прежнему на `IntTest.index*` + `myStream`; оболочка
  сообщает раздел в `appRouter.showSection`, тап в бургере — `appRouter.goTo`
  (счётчик `tapSerial` отличает тап от смены адреса).
- «Работы» = `lib/navigation/works_section.dart`: вкладки Задачи · Выполненные ·
  Сданные у обеих ролей (админу лента сданных добавлена слотом 23), возврат
  из карточки — на ту же вкладку. Таблетки `WorkCountsChips` на «Работы» у
  обеих ролей; первое значение — `primeWorkCounts()`.
- Профиль админа: `_profileIndex[admin]` 9 → 8 — аватарка открывала карточку
  компании.
- Проверено на `make up` админом и прорабом: все пункты, адреса, «назад»
  браузера, карточки, вкладки, профиль, `/app`, выход, вход с `/companies`.
- `make lint` чист · `make test` 1009 · `flutter test` 520 (17 навигации) ·
  `dart analyze` 0 ошибок · `flutter build web` собран · коммит `eb43063`.

## Не доделано

- Заголовок в шапке старых экранов — их собственный («Обьекты», «Задачи»),
  не название раздела; уйдёт вместе с экранами в S05/S08.
- «Главная» прораба — админский `HomeScreen` как есть (все ручки статистики
  ответили 200); свои данные — S06.
- `helper/my_drawer/my_drawer.dart`, `foreman/drawer_foreman.dart` живы, но не
  подключены — снос в S08. Дисп. `application_screen_completed.dart` всё ещё
  на `MyDrawer` (вне E03).

## Следующий этап

**Цель.** S03: экран «Работы» на фикстуре — одна лента заявок и актов.

**Готово, когда.** Пилюля статуса (новая · принята · в работе · сдана ·
проблема), чипсы по статусу и виду со счётчиками, поиск по объекту, «Архив»
как фильтр; стиль как у экрана графика из E01; набросок утверждён глазами.

## Первые шаги

1. Кадр макета: спросить, есть ли в `~/els-figma/` кадр «Работы»; нет —
   набросок по образцу `lib/screns/schedule/view/schedules_screen.dart`
   (стиль E01) и `lib/screns/submitted_works/view/` (строка сданной работы).
2. Dev-превью по образцу `lib/dev/schedules_preview.dart` + конфиг в
   `.claude/launch.json` (следующий порт 5614).
3. Статусы и виды брать из `backend/src/api/api_v1/endpoints/submitted_works.py`
   (`outcome`, `kind`) и `in_progress_works.py` — ручка S04 их объединит.

## Не трогать

- `lib/navigation/*` — принят глазами; `WorksSection` заменится целиком в S05.
- `screns/report/*`, старый график, экраны механика и диспетчера.
- `pubspec.yaml`/`.lock` — `flutter_web_plugins` импортирован транзитивно
  намеренно, см. комментарий в `main.dart`.

## Уточнить перед стартом

- Есть ли кадр «Работы» в Figma или верстаем набросок?
- Один экран для обеих ролей или у прораба свои фильтры (свои участки)?

## Ссылки

- `.claude/plan/E03-edinaya-navigatsiya.md` — 8 этапов, S01–S02 закрыты.
- `frontend/lib/navigation/section_index.dart` — какие индексы у каких разделов.
- `frontend/lib/navigation/app_router.dart` — контракт маршрутизатора.
