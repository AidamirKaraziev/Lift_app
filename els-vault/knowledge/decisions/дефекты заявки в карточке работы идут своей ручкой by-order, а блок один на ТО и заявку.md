---
tags: [decision, дефектные акты, карточка работы, заявки, бэк, фронт]
date: 2026-09-15
---

# Дефекты заявки в карточке работы идут своей ручкой by-order, а блок один на ТО и заявку

Карточка работы из ленты «Работы» показывает блок «Дефекты» и у ТО, и у
заявки. Один виджет `WorkDefectsSection` (`foreman/defects/work_defects_section.dart`)
с флагом `byOrder`: у ТО он ходит в `GET /defective-act/by-act-fact/{id}/`,
у заявки — в новую `GET /defective-act/by-order/{order_id}/`
(`crud_defective_act.get_by_order_id`, доступ через `crud_orders.get_order_by_id`).
Из строки блока открывается та же `DefectCardScreen`, что и из ленты объекта.

## Почему

Дефектный акт заводится и на заявке (`order_id` в модели, тест
`test_act_from_the_order_carries_its_object`), но ручки «по заявке» не было —
у заявок дефектов в карточке не было видно вовсе. Отклонено: тянуть ленту
объекта за год и фильтровать на клиенте — карточка не знает года ленты, а
акты всего объекта ради двух строк — лишний трафик; те же доводы, что у
`by-act-fact`. Отклонено и второе: отдельный виджет для заявки — блок ничем
не отличается, кроме адреса запроса.

Клиентские потомки (`kind = client`) обе ручки не отдают — они видны из
своего первоисточника. Чужая заявка — 403, несуществующая — 404.

## Где

- бэк: `backend/src/api/api_v1/endpoints/defective_act.py`,
  `backend/src/crud/crud_defective_act.py`, тесты
  `backend/tests/test_api_defective_acts.py` (`acts_of_two_orders`)
- фронт: `DefectsRepository.byOrder`, ветка `OrderReady` в
  `screns/works/view/work_item_card_screen.dart`, тест
  `test/works/work_item_card_screen_test.dart`
- превью `lib/dev/works_preview.dart`: снимки из бандла через `Uri.base`
  (`assets/assets/…`), явная карта «работа → акты», флаг `hasDefect` в
  фикстуре ленты держится согласованным руками
