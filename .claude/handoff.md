---
этап: E04·S01 — диалог приказа о назначении на фикстуре
статус: закрыт
дата: 2026-09-13
ветка: fix/apk-api-origin
план: .claude/plan/E04-pismo-o-naznachenii.md
---

# Передача: диалог приказа утверждён глазами, дальше — ручка черновика

## Сделано и проверено

- Кнопка «Приказ о назначении» в блоке документов карточки объекта у админа
  (`screns/object/view/object_page.dart`) и прораба
  (`foreman/object_foreman/object_page_foreman.dart`) — общий
  `AppointmentOrderButton` (`screns/object/appointment_order/widgets/`).
- Диалог `showAppointmentOrderDialog` (`…/appointment_order/view/`): номер,
  дата (календарь ru), город, должность и ФИО подписанта правятся; организация,
  прораб, механик, адрес, список лифтов — только чтение; нет человека или лифтов
  — жёлтая плашка словами. На ширине < 420 px поля встают столбиком.
- «Скачать PDF» отдаёт черновик с правками в `onDownload`; колбэка нет —
  SnackBar «PDF появится в следующем этапе».
- Модель `AppointmentOrderDraft` + `fromObjectMap` — берёт из карточки адрес,
  ФИО прораба/механика, один лифт (тип из `factory_model_id.type_object_id.name`,
  марка из `model`, `load_capacity`); реквизиты пусты до S02. Решено оставить.
- Фикстура `fixture_appointment_order.dart` (три расклада), превью
  `lib/dev/appointment_order_preview.dart`, конфиг `appointment-order-preview`
  (5616) в `.claude/launch.json`. Вид утверждён 2026-09-13 на десктопе и 375 px.
- `flutter test` — 549 (4 новых в `test/object/`); `dart analyze lib test` —
  831 = 831 до правок; `flutter build web` собран; `make lint` чист.
- Не коммичено: все файлы этапа + `roadmap.md` (0/0 → 0/5) в рабочей копии.

## Не доделано

- Кнопка в реальных карточках не нажималась руками на `make up` — только
  превью на фикстуре. Проверка на стеке — S05.
- `make test` (бэк) не гонялся: бэк не трогали.

## Следующий этап

**Цель.** S02 — `GET /object/{id}/appointment-order/draft` отдаёт черновик
приказа: номер пусто, дата сегодня, город и адрес объекта, подписант из
организации, закреплённые прораб и механик, список лифтов.

**Готово, когда.** Область видимости как у карточки объекта; тест на ручку;
снимок OpenAPI обновлён (критерий из подплана).

## Первые шаги

1. `backend/src/models/object.py` — `Object` = один лифт с адресом; поля
   `foreman`, `mechanic`, `factory_model`, `load_capacity`, `organization`.
2. Форму ответа согласовать с фронтовой `AppointmentOrderDraft`
   (`frontend/lib/screns/object/appointment_order/model/appointment_order_draft.dart`):
   `number, date, city, address, organization, signer_position, signer_name,
   foreman{full_name, position}, mechanic{…}, lifts[{type, brand, load_capacity_kg}]`.
3. Ручку класть рядом с остальными объектными в `backend/src/api/api_v1/`;
   снимок OpenAPI — по тому, как делали для `/work/feed`.

## Не трогать

- `helper/letter_of_appointment.dart`, `foreman/…/letter_of_appointment_foreman.dart`
  и строка «Документ / Письмо о назначении» (загрузка файла) — снос после S05.
- Диалог и модель S01 — утверждены; менять только под контракт S02, не вид.
- `pubspec.yaml`/`.lock`; `flutter pub get` не запускать.

## Уточнить перед стартом

- «Список лифтов объекта»: в БД объект = один лифт, в образце два лифта на
  одном адресе. Ручка отдаёт один лифт объекта или все объекты с тем же
  адресом и той же парой прораб/механик?
- Подписант и город: откуда в `Organization` (есть ли поля директора и города)?
- Из E03, не чинил: 403 на `POST /work/maintenance/{id}/review/` прорабу под
  «Мои участки»; «FocusScopeNode used after disposed» при «Выйти» с открытым
  бургером; `IntTest.index*` — 415 мест, этапа в плане нет.

## Ссылки

- `els-vault/knowledge/business/приказ о назначении ответственных - образец от заказчика для E04.md` — что в приказе.
- `.claude/plan/E04-pismo-o-naznachenii.md` — критерии S02–S05.
- `frontend/lib/dev/appointment_order_preview.dart` — увидеть диалог без стека.
