"""Единая лента работ: `GET /work/feed`, `assign`, `review`.

Проверяется то, чего не видно глазами: статус одним словом собирается по
одному правилу для заявки и акта; участок берётся от объекта, а без него —
от исполнителя; причина внимания и порядок считаются на бэке теми же
порогами, что на экране; курсор ходит без дыр и повторов; смена статуса
сбрасывает «проверил».
"""

import calendar
import datetime
import itertools
import json
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import (
    ActFact,
    DefectiveAct,
    Division,
    Object,
    Order,
    UniversalUser,
    UserDivision,
)

FEED = f"{settings.API_V1_STR}/work/feed"

STATUS_CREATED = 1
STATUS_ACCEPTED = 2
STATUS_IN_PROGRESS = 3
STATUS_DONE = 4
STATUS_PROBLEM = 5

HOUR = datetime.timedelta(hours=1)


def _now():
    return datetime.datetime.utcnow().replace(microsecond=0)


def _feed(response):
    assert response.status_code == 200, response.text
    return response.json()["data"]


def _items(response):
    return _feed(response)["items"]


def _by_id(items, work_id, kind=None):
    for item in items:
        if item["work_id"] == work_id and (
            kind is None or (item["kind"] == "maintenance") == (kind == "maintenance")
        ):
            return item
    raise AssertionError(f"работы {work_id} нет в ленте")


def _checklist(title="ТО-3"):
    return json.dumps(
        {"title": title, "steps": [{"id": 1, "title": "Пункт", "done": False}]},
        ensure_ascii=False,
    )


@pytest.fixture
def division(db_session):
    div = Division(title=f"Центр {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


@pytest.fixture
def other_division(db_session):
    div = Division(title=f"Юг {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


@pytest.fixture
def foreman(as_role, db_session, division):
    user = as_role(Role.FOREMAN.value, division_id=division.id)
    db_session.add(UserDivision(user_id=user.id, division_id=division.id))
    db_session.flush()
    return user


@pytest.fixture
def make_object(db_session, division):
    counter = itertools.count(1)
    prefix = uuid.uuid4().hex[:8]

    def _make(div=division):
        number = next(counter)
        obj = Object(
            name=f"Лифт {prefix}-{number}",
            address=f"ул. Единая, {number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            division_id=div.id if div else None,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def mechanic(db_session, other_division):
    user = UniversalUser(
        name="Механик Ковалёв",
        email=f"mech-{uuid.uuid4().hex[:8]}@test",
        role_id=Role.MECHANIC.value,
        contact_phone="+7 900 000-00-00",
        division_id=other_division.id,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def order(db_session, make_object, mechanic):
    """Заявка. По умолчанию — новая, без исполнителя, только что созданная."""

    def _make(
        status_id=STATUS_CREATED,
        executor=None,
        created_at=None,
        accepted_at=None,
        in_progress_at=None,
        obj=None,
        is_actual=True,
        updated_at=None,
        reviewed_at=None,
        creator=None,
    ):
        record = Order(
            creator_id=creator.id if creator else None,
            object_id=(obj if obj is not None else make_object()).id
            if obj is not False
            else None,
            executor_id=executor.id if executor else None,
            task_text="Не закрывается дверь",
            status_id=status_id,
            created_at=created_at or _now(),
            accepted_at=accepted_at,
            in_progress_at=in_progress_at,
            is_actual=is_actual,
            updated_at=updated_at or _now(),
            reviewed_at=reviewed_at,
        )
        db_session.add(record)
        db_session.flush()
        return record

    return _make


@pytest.fixture
def act(db_session, make_object, mechanic):
    """Акт ТО. По умолчанию — начат час назад, идёт."""

    def _make(
        started_at="default",
        status_id=STATUS_IN_PROGRESS,
        paused_at=None,
        finished_at=None,
        mechanic_id="default",
        obj=None,
        is_actual=True,
        updated_at=None,
    ):
        record = ActFact(
            object_id=(obj or make_object()).id,
            main_mechanic_id=mechanic.id if mechanic_id == "default" else mechanic_id,
            started_at=_now() - HOUR if started_at == "default" else started_at,
            paused_at=paused_at,
            finished_at=finished_at,
            status_id=status_id,
            step_list_fact=_checklist(),
            created_at=_now() - 2 * HOUR,
            is_actual=is_actual,
            updated_at=updated_at or _now(),
        )
        db_session.add(record)
        db_session.flush()
        return record

    return _make


# ---------------------------------------------------------------------------
# Статус одним словом
# ---------------------------------------------------------------------------


@pytest.mark.integration
@pytest.mark.parametrize(
    "status_id, expected",
    [
        (STATUS_CREATED, "fresh"),
        (None, "fresh"),
        (STATUS_ACCEPTED, "accepted"),
        (STATUS_IN_PROGRESS, "running"),
        (STATUS_DONE, "submitted"),
        (STATUS_PROBLEM, "problem"),
    ],
)
def test_order_status_is_one_word(client_with_db, foreman, order, status_id, expected):
    record = order(status_id=status_id)

    item = _by_id(_items(client_with_db.get(FEED)), record.id)

    assert item["status"] == expected
    assert item["kind"] == "breakdown"
    assert item["task_text"] == "Не закрывается дверь"
    assert item["act_title"] is None


@pytest.mark.integration
def test_maintenance_status_is_built_from_dates(client_with_db, foreman, act):
    now = _now()
    fresh = act(started_at=None, status_id=STATUS_CREATED, mechanic_id=None)
    accepted = act(started_at=None, status_id=STATUS_CREATED)
    running = act()
    paused = act(status_id=STATUS_ACCEPTED, paused_at=now - 10 * datetime.timedelta(minutes=1))
    problem = act(status_id=STATUS_PROBLEM)
    closed = act(finished_at=now, status_id=STATUS_DONE)

    items = _items(client_with_db.get(FEED))

    assert _by_id(items, fresh.id, "maintenance")["status"] == "fresh"
    assert _by_id(items, accepted.id, "maintenance")["status"] == "accepted"
    running_item = _by_id(items, running.id, "maintenance")
    assert running_item["status"] == "running"
    assert running_item["paused_at"] is None
    assert running_item["act_title"] == "ТО-3"
    paused_item = _by_id(items, paused.id, "maintenance")
    assert paused_item["status"] == "running"
    assert paused_item["paused_at"] is not None
    assert _by_id(items, problem.id, "maintenance")["status"] == "problem"
    closed_item = _by_id(items, closed.id, "maintenance")
    assert closed_item["status"] == "submitted"
    assert closed_item["closed_at"] is not None


@pytest.mark.integration
def test_section_comes_from_object_then_from_performer(
    client_with_db, foreman, order, make_object, mechanic, division, other_division
):
    from_object = order(obj=make_object(division), executor=mechanic)
    from_performer = order(obj=make_object(None), executor=mechanic)
    nowhere = order(obj=make_object(None))

    items = _items(client_with_db.get(FEED))

    assert _by_id(items, from_object.id)["section"] == division.title
    assert _by_id(items, from_performer.id)["section"] == other_division.title
    assert _by_id(items, nowhere.id)["section"] is None
    assert _by_id(items, from_object.id)["performer_phone"] == "+7 900 000-00-00"


@pytest.mark.integration
def test_defect_flag_and_archived_rows(client_with_db, foreman, order, db_session):
    with_defect = order()
    db_session.add(
        DefectiveAct(object_id=with_defect.object_id, order_id=with_defect.id, title="Трос")
    )
    archived = order(is_actual=False)
    db_session.flush()

    items = _items(client_with_db.get(FEED))
    assert _by_id(items, with_defect.id)["has_defect"] is True
    assert all(item["work_id"] != archived.id for item in items)

    archive = _items(client_with_db.get(FEED, params={"only_archived": True}))
    assert [item["work_id"] for item in archive] == [archived.id]
    assert archive[0]["is_actual"] is False


# ---------------------------------------------------------------------------
# Внимание и порядок
# ---------------------------------------------------------------------------


@pytest.mark.integration
def test_attention_reasons(client_with_db, foreman, order, act, mechanic):
    now = _now()
    unassigned = order()
    waited_long = order(executor=mechanic, created_at=now - 3 * HOUR)
    accepted_long = order(
        status_id=STATUS_ACCEPTED, executor=mechanic, accepted_at=now - 5 * HOUR
    )
    accepted_fresh = order(
        status_id=STATUS_ACCEPTED, executor=mechanic, accepted_at=now - HOUR
    )
    running_long = order(
        status_id=STATUS_IN_PROGRESS, executor=mechanic, in_progress_at=now - 9 * HOUR
    )
    paused_long = act(status_id=STATUS_ACCEPTED, paused_at=now - 2 * HOUR)
    paused_recently = act(status_id=STATUS_ACCEPTED, paused_at=now - HOUR / 2)
    closed = order(status_id=STATUS_DONE, executor=mechanic, created_at=now - 30 * HOUR)
    reviewed = order(created_at=now - 30 * HOUR, reviewed_at=now)

    items = _items(client_with_db.get(FEED))

    assert _by_id(items, unassigned.id)["attention"] == "unassigned"
    assert _by_id(items, waited_long.id)["attention"] == "overdue"
    assert _by_id(items, accepted_long.id)["attention"] == "overdue"
    assert _by_id(items, accepted_fresh.id)["attention"] is None
    assert _by_id(items, running_long.id)["attention"] == "overdue"
    assert _by_id(items, paused_long.id, "maintenance")["attention"] == "paused_long"
    assert _by_id(items, paused_recently.id, "maintenance")["attention"] is None
    assert _by_id(items, closed.id)["attention"] is None
    assert _by_id(items, reviewed.id)["attention"] is None
    assert _by_id(items, reviewed.id)["reviewed"] is True


@pytest.mark.integration
def test_attention_block_stands_first_longest_on_top(
    client_with_db, foreman, order, mechanic
):
    now = _now()
    calm = order(status_id=STATUS_ACCEPTED, executor=mechanic, accepted_at=now)
    waited_3h = order(created_at=now - 3 * HOUR)
    waited_30h = order(created_at=now - 30 * HOUR)

    feed = _feed(client_with_db.get(FEED))

    ids = [item["work_id"] for item in feed["items"]]
    assert ids == [waited_30h.id, waited_3h.id, calm.id]
    assert feed["attention_count"] == 2
    assert feed["counts"]["by_attention"] == {"unassigned": 2}

    by_updated = _feed(client_with_db.get(FEED, params={"sort": "updated"}))
    assert by_updated["attention_count"] == 0


@pytest.mark.integration
def test_sort_updated_is_by_last_change(client_with_db, foreman, order, mechanic):
    now = _now()
    old = order(updated_at=now - 5 * HOUR, created_at=now - 5 * HOUR, executor=mechanic)
    fresh = order(updated_at=now, created_at=now - 5 * HOUR, executor=mechanic)

    items = _items(client_with_db.get(FEED, params={"sort": "updated"}))

    assert [item["work_id"] for item in items] == [fresh.id, old.id]


@pytest.mark.integration
def test_cursor_walks_without_gaps_or_repeats(client_with_db, foreman, order):
    now = _now()
    records = [order(created_at=now - hours * HOUR) for hours in (1, 3, 5, 7, 9)]

    seen = []
    cursor = None
    for _ in range(10):
        params = {"limit": 2}
        if cursor:
            params["cursor"] = cursor
        feed = _feed(client_with_db.get(FEED, params=params))
        seen.extend(item["work_id"] for item in feed["items"])
        cursor = feed["next_cursor"]
        if cursor is None:
            break

    assert seen == [record.id for record in reversed(records)]
    assert client_with_db.get(FEED, params={"cursor": "мусор"}).status_code == 422


# ---------------------------------------------------------------------------
# Отбор, счётчики, синхронизация
# ---------------------------------------------------------------------------


@pytest.mark.integration
def test_counts_are_without_their_own_chip(client_with_db, foreman, order, act, mechanic):
    order(status_id=STATUS_ACCEPTED, executor=mechanic)
    order(status_id=STATUS_DONE, executor=mechanic)
    act()

    feed = _feed(client_with_db.get(FEED, params={"status": "accepted"}))

    assert [item["status"] for item in feed["items"]] == ["accepted"]
    assert feed["counts"]["by_status"] == {"accepted": 1, "submitted": 1, "running": 1}
    # Вид считается с учётом статуса: чипс вида говорит, сколько строк
    # появится при текущем отборе.
    assert feed["counts"]["by_kind"] == {"breakdown": 1}


@pytest.mark.integration
def test_filters_section_performer_mine_search(
    client_with_db,
    foreman,
    order,
    make_object,
    mechanic,
    division,
    other_division,
    db_session,
):
    mine = order(obj=make_object(division), executor=mechanic)
    foreign = order(obj=make_object(other_division))
    other = UniversalUser(
        name="Другой", email=f"o-{uuid.uuid4().hex[:6]}@test", role_id=Role.MECHANIC.value
    )
    db_session.add(other)
    db_session.flush()
    order(obj=make_object(other_division), executor=other)

    def ids(**params):
        return sorted(item["work_id"] for item in _items(client_with_db.get(FEED, params=params)))

    assert ids(mine=True) == [mine.id]
    assert ids(section_id=other_division.id) != [mine.id]
    assert mine.id not in ids(section_id=other_division.id)
    assert ids(performer_id=mechanic.id) == [mine.id]
    assert ids(search=f"Единая, {2}") == [foreign.id]

    feed = _feed(client_with_db.get(FEED))
    assert feed["my_sections"] == [division.id]
    assert {section["id"] for section in feed["sections"]} == {
        division.id,
        other_division.id,
    }
    assert any(
        employee["id"] == mechanic.id and employee["section"] == other_division.title
        for employee in feed["employees"]
    )


@pytest.mark.integration
def test_updated_since_brings_archived_rows(client_with_db, foreman, order):
    now = _now()
    stale = order(updated_at=now - 3 * HOUR)
    changed = order(updated_at=now)
    archived = order(updated_at=now, is_actual=False)

    # Даты в базе — наивный UTC; `timestamp()` считал бы их местным временем.
    since = calendar.timegm((now - HOUR).utctimetuple())
    items = _items(client_with_db.get(FEED, params={"updated_since": since}))

    ids = {item["work_id"]: item for item in items}
    assert stale.id not in ids
    assert changed.id in ids
    assert ids[archived.id]["is_actual"] is False


# ---------------------------------------------------------------------------
# Действия
# ---------------------------------------------------------------------------


@pytest.mark.integration
def test_assign_makes_fresh_order_accepted(client_with_db, foreman, order, mechanic):
    record = order(reviewed_at=_now())

    response = client_with_db.post(
        f"{settings.API_V1_STR}/work/breakdown/{record.id}/assign/",
        json={"performer_id": mechanic.id},
    )

    item = _feed(response)
    assert item["status"] == "accepted"
    assert item["performer_id"] == mechanic.id
    assert item["accepted_at"] is not None
    assert item["reviewed"] is False
    assert item["attention"] is None


@pytest.mark.integration
def test_assign_outside_write_scope_is_forbidden(
    client_with_db, foreman, order, make_object, mechanic, other_division
):
    record = order(obj=make_object(other_division))

    response = client_with_db.post(
        f"{settings.API_V1_STR}/work/breakdown/{record.id}/assign/",
        json={"performer_id": mechanic.id},
    )

    assert response.status_code == 403, response.text


@pytest.mark.integration
def test_review_on_open_work_and_reset_on_status_change(
    client_with_db, foreman, order, mechanic
):
    # Автор нужен: ответ `PUT /order/` (`OrderGet`) без него не собирается.
    record = order(created_at=_now() - 30 * HOUR, creator=foreman)

    reviewed = _feed(
        client_with_db.post(f"{settings.API_V1_STR}/work/breakdown/{record.id}/review/")
    )
    assert reviewed["reviewed"] is True
    assert reviewed["attention"] is None

    response = client_with_db.put(
        f"{settings.API_V1_STR}/order/{record.id}/",
        json={"status_id": STATUS_ACCEPTED, "executor_id": mechanic.id},
    )
    assert response.status_code == 200, response.text

    item = _by_id(_items(client_with_db.get(FEED)), record.id)
    assert item["reviewed"] is False
    assert item["status"] == "accepted"


@pytest.mark.integration
def test_old_feeds_are_deprecated_but_alive(client_with_db, foreman):
    schema = client_with_db.get(f"{settings.API_V1_STR}/openapi.json")
    if schema.status_code != 200:
        schema = client_with_db.get("/openapi.json")
    paths = schema.json()["paths"]
    for path in ("/order/all", "/work/in-progress", "/work/submitted"):
        assert paths[f"{settings.API_V1_STR}{path}"]["get"]["deprecated"] is True
    assert client_with_db.get(f"{settings.API_V1_STR}/work/submitted").status_code == 200
