"""Черновик приказа о назначении: `GET /object/{id}/appointment-order/draft`.

Проверяем сборку из карточки, а не хранение — приказ ничего не пишет в базу.
Важно то, что не видно глазами: директор организации становится
подписантом, должности людей подставляются как в образце, пустые связи
отдаются `null`, а не падением, и область видимости та же, что у карточки
объекта.
"""

import datetime
import os
import uuid

import pytest

from src.config import settings
from src.core.roles import Role
from src.models import (
    Division,
    FactoryModel,
    Object,
    Organization,
    TypeObject,
    UniversalUser,
    UserDivision,
)
from src.utils.time_stamp import to_timestamp

API = settings.API_V1_STR


def _draft_url(object_id):
    return f"{API}/object/{object_id}/appointment-order/draft"


def _user(db_session, role, name, division=None):
    user = UniversalUser(
        name=name,
        email=f"{role.name.lower()}-{uuid.uuid4().hex[:8]}@test",
        role_id=role.value,
        division_id=division.id if division else None,
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()
    return user


@pytest.fixture
def division(db_session):
    div = Division(title=f"Участок {uuid.uuid4().hex[:6]}")
    db_session.add(div)
    db_session.flush()
    return div


@pytest.fixture
def make_object(db_session):
    prefix = uuid.uuid4().hex[:8]

    def _make(**fields):
        number = uuid.uuid4().hex[:4]
        obj = Object(
            name=f"Лифт {prefix}-{number}",
            factory_number=f"F-{prefix}-{number}",
            registration_number=f"R-{prefix}-{number}",
            **fields,
        )
        db_session.add(obj)
        db_session.flush()
        return obj

    return _make


@pytest.fixture
def full_object(db_session, make_object, division):
    """Объект, у которого заполнено всё, что попадает в приказ."""
    director = _user(db_session, Role.ADMIN, "Садиков Тимур Аскерович")
    organization = Organization(
        title=f"ООО ПЭЛК {uuid.uuid4().hex[:6]}", director_id=director.id
    )
    # У справочника типов id без автоинкремента — задаём сами, подальше от сидера.
    type_object = TypeObject(
        id=90_000 + int(uuid.uuid4().hex[:3], 16), name="Лифт Пассажирский"
    )
    db_session.add_all([organization, type_object])
    db_session.flush()
    model = FactoryModel(
        type_object_id=type_object.id, factory="Wellmaks", model="Wellmaks"
    )
    db_session.add(model)
    db_session.flush()
    foreman = _user(db_session, Role.FOREMAN, "Ахметов Роман Арсенович", division)
    mechanic = _user(db_session, Role.MECHANIC, "Ковалёв Иван Петрович", division)
    return make_object(
        address="г. Нальчик, ул. Ленина, 1",
        division_id=division.id,
        organization_id=organization.id,
        factory_model_id=model.id,
        load_capacity=400,
        foreman_id=foreman.id,
        mechanic_id=mechanic.id,
    )


def _draft(client, object_id):
    response = client.get(_draft_url(object_id))
    assert response.status_code == 200, response.text
    return response.json()["data"]


def test_draft_is_built_from_object_card(client_with_db, as_role, full_object):
    as_role(Role.ADMIN.value)
    data = _draft(client_with_db, full_object.id)

    assert data["number"] == ""
    assert data["city"] == ""
    assert data["date"] == to_timestamp(datetime.date.today())
    assert data["address"] == "г. Нальчик, ул. Ленина, 1"
    assert data["organization"].startswith("ООО ПЭЛК")
    assert data["signer_position"] == "Генеральный директор"
    assert data["signer_name"] == "Садиков Тимур Аскерович"
    assert data["foreman"] == {
        "full_name": "Ахметов Роман Арсенович",
        "position": "прораба сервисного участка",
    }
    assert data["mechanic"] == {
        "full_name": "Ковалёв Иван Петрович",
        "position": "электромеханика по лифтам",
    }
    assert data["lifts"] == [
        {"type": "Лифт Пассажирский", "brand": "Wellmaks", "load_capacity_kg": 400}
    ]


def test_empty_card_gives_nulls_not_error(client_with_db, as_role, make_object):
    as_role(Role.ADMIN.value)
    data = _draft(client_with_db, make_object().id)

    assert data["address"] is None
    assert data["organization"] is None
    assert data["signer_position"] is None
    assert data["signer_name"] is None
    assert data["foreman"] is None
    assert data["mechanic"] is None
    assert data["lifts"] == []


def test_organization_without_director_has_no_signer(
    client_with_db, as_role, db_session, make_object
):
    as_role(Role.ADMIN.value)
    organization = Organization(title=f"ООО Без директора {uuid.uuid4().hex[:6]}")
    db_session.add(organization)
    db_session.flush()
    data = _draft(client_with_db, make_object(organization_id=organization.id).id)

    assert data["organization"] == organization.title
    assert data["signer_name"] is None
    assert data["signer_position"] is None


def test_capacity_alone_still_makes_a_lift(client_with_db, as_role, make_object):
    as_role(Role.ADMIN.value)
    data = _draft(client_with_db, make_object(load_capacity=630).id)

    assert data["lifts"] == [{"type": None, "brand": None, "load_capacity_kg": 630}]


def test_scope_matches_object_card(client_with_db, as_role, db_session, full_object):
    """Как у карточки: прораб видит все объекты, механик — только свои, нет — 404."""
    other = Division(title=f"Чужой участок {uuid.uuid4().hex[:6]}")
    db_session.add(other)
    db_session.flush()
    foreman = as_role(Role.FOREMAN.value, division_id=other.id)
    db_session.add(UserDivision(user_id=foreman.id, division_id=other.id))
    db_session.flush()
    assert client_with_db.get(_draft_url(full_object.id)).status_code == 200

    stranger = as_role(Role.MECHANIC.value, division_id=other.id)
    assert client_with_db.get(_draft_url(full_object.id)).status_code == 403

    full_object.mechanic_id = stranger.id
    db_session.flush()
    assert client_with_db.get(_draft_url(full_object.id)).status_code == 200
    assert client_with_db.get(_draft_url(10**9)).status_code == 404


# --- PDF: `POST /object/{id}/appointment-order/pdf` ---------------------------


def _pdf_url(object_id):
    return f"{API}/object/{object_id}/appointment-order/pdf"


def test_pdf_is_built_from_the_edited_draft(client_with_db, as_role, full_object):
    """Файл лежит в `static/objects/{id}/appointment_order/`, ссылка с токеном."""
    as_role(Role.ADMIN.value)
    draft = _draft(client_with_db, full_object.id)
    draft.update(number="10", city="Нальчик")

    response = client_with_db.post(_pdf_url(full_object.id), json=draft)

    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["path"].startswith(f"objects/{full_object.id}/appointment_order/")
    assert data["path"].endswith(".pdf")
    assert f"{API}/static/{data['path']}?token=" in data["url"]
    assert data["expires_in"] == settings.FILE_TOKEN_EXPIRE_SECONDS
    with open(os.path.join("static", data["path"]), "rb") as fh:
        assert fh.read(4) == b"%PDF"


def test_pdf_path_gets_a_fresh_link_from_files_link(
    client_with_db, as_role, full_object
):
    """Минута прошла — `/files/link` выдаёт ссылку заново по видимости объекта."""
    as_role(Role.ADMIN.value)
    draft = _draft(client_with_db, full_object.id)
    path = client_with_db.post(_pdf_url(full_object.id), json=draft).json()["data"][
        "path"
    ]

    response = client_with_db.post(f"{API}/files/link", json={"path": path})

    assert response.status_code == 200, response.text
    assert "token=" in response.json()["data"]["url"]


def test_pdf_is_built_even_from_an_empty_draft(client_with_db, as_role, make_object):
    as_role(Role.ADMIN.value)
    obj = make_object()
    draft = _draft(client_with_db, obj.id)

    response = client_with_db.post(_pdf_url(obj.id), json=draft)

    assert response.status_code == 200, response.text


def test_pdf_scope_matches_object_card(
    client_with_db, as_role, db_session, full_object
):
    other = Division(title=f"Чужой участок {uuid.uuid4().hex[:6]}")
    db_session.add(other)
    db_session.flush()
    as_role(Role.ADMIN.value)
    draft = _draft(client_with_db, full_object.id)

    as_role(Role.MECHANIC.value, division_id=other.id)
    assert client_with_db.post(_pdf_url(full_object.id), json=draft).status_code == 403
    assert client_with_db.post(_pdf_url(10**9), json=draft).status_code == 404
