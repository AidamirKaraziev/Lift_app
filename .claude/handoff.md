---
этап: E03·S03b — улучшения окна «Работы» на фикстуре
статус: закрыт
дата: 2026-09-12
план: .claude/plan/E03-edinaya-navigatsiya.md
---

# Передача: улучшения «Работ» утверждены глазами, следующий — ручка S04

## Сделано и проверено

- `lib/screns/works/`: `WorkAttention` (три причины: не назначена, стадия
  затянулась, пауза дольше часа — пороги из `WorkTiming`), `WorkEmployee`
  (должность + участок), в `WorkItem` — `section`, `reviewed`, `copyWith`.
- `WorkFilters`: `section`, `performer`, `mine`, `attention`, `sort`;
  `matches(item, now:, mySections:)`. `WorkCounts.byAttention`.
- `WorksFeed`: `attentionCount`, `sections`, `performers`, `employees`,
  `mySections`. `WorksRepository.assign(item, who)` и `review(item)`.
- Виджеты: `WorkSummaryBar` (куски сводки — фильтры, переключатель порядка),
  третий ряд чипсов (выпадашки «Участок/Механик», «Мои участки»),
  `WorkGroupHeader`, `WorkRowActions` («Назначить» всегда, «позвонить /
  проверил» при наведении, на телефоне — «⋯»), диалог `_AssignDialog`
  с «Мои механики / Остальные», иконкой должности и участком.
- «Сбросить всё» — от одного условия.
- Утверждено глазами 12.09 на `works-preview` (порт 5614): сводка, назначение
  (1042 → принята), «проверил», участок «Юг», «Мои участки», телефон 375.
- `flutter test` 528 · `dart analyze lib/screns/works lib/dev` 0 ·
  `make lint` чист. Не закоммичено: handoff/план/ledger и весь код S03b.

## Не доделано

- Тестов на новое нет (сводка, порядок, «проверил», диалог) — старые 8 в
  `test/works/` зелёные. Написать до подключения к API в S05.
- «Позвонить» показывает снэкбар: телефона механика в ленте нет — S04.
- `flutter build web` в этой сессии не гонялся.

## Следующий этап

**Цель.** S04 — `GET /work/feed`: заявки и акты одной ручкой с полями под
ленту и её улучшения.

**Готово, когда.** Ручка отдаёт всё со списка ниже с курсором и
`updated_since`; старые `/order/all`, `/work/in-progress`, `/work/submitted`
живы и `deprecated`; `make test` и `make lint` чисты.

## Первые шаги

1. Поля строки: `status` одним словом (fresh/accepted/running/submitted/
   problem), `act_title`, `object_type`, `accepted_at`, `paused_at`,
   `has_defect`, `comment`, `is_actual`, `section` (из `division` объекта
   или исполнителя — решить), `reviewed`, `performer_phone`.
2. Параметры: `status`, `kind`, `search`, `only_archived`
   (`ArchiveView.ARCHIVED`, `backend/src/core/archiving.py`), `section`,
   `performer_id`, `mine`, `attention`, `sort=attention|updated`, курсор.
3. В ответе справочники: `sections`, `employees` (имя, `working_specialty`,
   `division`) — под выпадашки и диалог назначения; `my_sections` прораба.
4. Действия: `POST .../assign` и `POST .../review` — контракт под
   `WorksRepository.assign/review`; `reviewed` сбрасывать при смене статуса.
5. Правило причин внимания — `frontend/lib/screns/works/models/work_attention.dart`;
   на бэке считать так же или отдавать даты и оставить фронту.

## Не трогать

- `lib/navigation/*`, `WorksSection` — замена в S05.
- `submitted_works/*`, `in_progress_works/*` — из них только `WorkKind`.
- `pubspec.yaml`/`.lock`; `flutter pub get` не запускать.

## Уточнить перед стартом

- Участок работы — от объекта или от исполнителя? В базе `division` есть у
  пользователя; у объекта — проверить.
- Сортировку «сначала требуют внимания» считает бэк или фронт по датам?

## Ссылки

- `frontend/lib/screns/works/repository/works_repository.dart` — контракт,
  под который пишется ручка.
- `frontend/lib/screns/works/repository/fixture_works_repository.dart` —
  эталон поведения: порядок, счётчики, assign/review.
- `backend/src/models/universal_user.py` — `working_specialty`, `division`.
