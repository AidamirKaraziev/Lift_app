"""Черновик приказа о назначении ответственных за объект.

Приказ собирается из того, что уже лежит в карточке объекта и у сотрудников:
адрес, организация с директором, закреплённые прораб и электромеханик,
оборудование. Человек в диалоге правит только реквизиты — номер, дату, город,
подписанта; остальное читается как есть и в PDF уходит без правок (S03).

Форма повторяет модель диалога на фронте
(`frontend/lib/screns/object/appointment_order/model/appointment_order_draft.dart`).
Образец заказчика — ПЭЛК №10 от 01.11.2025:
`els-vault/knowledge/business/приказ о назначении ответственных - образец от заказчика для E04.md`.
"""

from typing import List, Optional

from pydantic import BaseModel, Field

#: Должность подписанта по умолчанию — в организации хранится только директор.
SIGNER_POSITION = "Генеральный директор"

#: Должности назначаемых в тексте приказа — как в образце заказчика, сразу в
#: родительном падеже: они подставляются после «Назначить …», а склонять
#: сервер не умеет. ФИО в черновике в именительном — его правит человек.
FOREMAN_POSITION = "прораба сервисного участка"
MECHANIC_POSITION = "электромеханика по лифтам"


class AppointmentPerson(BaseModel):
    full_name: str = Field(..., title="ФИО")
    position: str = Field(
        ...,
        title="Должность в тексте приказа",
        description=(
            "Как в тексте приказа, после «Назначить …»: «прораба сервисного "
            "участка», «электромеханика по лифтам»."
        ),
    )


class AppointmentLift(BaseModel):
    type: Optional[str] = Field(
        None,
        title="Тип оборудования",
        description="Из справочника: «Лифт Пассажирский».",
    )
    brand: Optional[str] = Field(
        None, title="Марка", description="Модель из карточки: «Wellmaks»."
    )
    load_capacity_kg: Optional[int] = Field(
        None,
        title="Грузоподъёмность, кг",
        description="Пусто, если в карточке не заполнена.",
    )


class AppointmentOrderDraft(BaseModel):
    number: str = Field(
        "",
        title="Номер приказа",
        description="Всегда пусто — вписывает человек в диалоге.",
    )
    date: int = Field(
        ...,
        title="Дата приказа",
        description="Метка времени начала сегодняшнего дня; правится в диалоге.",
    )
    city: str = Field(
        "",
        title="Город в шапке",
        description="Всегда пусто: у организации города нет, вписывает человек.",
    )
    address: Optional[str] = Field(None, title="Адрес объекта")
    organization: Optional[str] = Field(
        None,
        title="Организация",
        description="От чьего имени приказ; пусто без организации.",
    )
    signer_position: Optional[str] = Field(
        None,
        title="Должность подписанта",
        description="«Генеральный директор», если у организации есть директор.",
    )
    signer_name: Optional[str] = Field(
        None, title="ФИО подписанта", description="Директор организации объекта."
    )
    foreman: Optional[AppointmentPerson] = Field(
        None, title="Прораб", description="`null` — за объектом никто не закреплён."
    )
    mechanic: Optional[AppointmentPerson] = Field(
        None, title="Электромеханик", description="`null` — никто не закреплён."
    )
    lifts: List[AppointmentLift] = Field(
        ...,
        title="Оборудование",
        description=(
            "Перечень, который приказ закрепляет за обоими. Объект в базе — один "
            "лифт, так что здесь один элемент; пусто, если ни модели, ни "
            "грузоподъёмности в карточке нет."
        ),
    )


class AppointmentOrderPdfGet(BaseModel):
    """Где лежит собранный PDF и как его открыть.

    `url` — с токеном на минуту, как из `POST /files/link`: фронт открывает
    его в новой вкладке сразу, без второго запроса. `path` — на случай, когда
    минута прошла: по нему `/files/link` выдаст ссылку заново, доступ по
    объекту.
    """

    path: str = Field(
        ...,
        title="Путь к файлу в `static/`",
        example="objects/12/appointment_order/9f3c1b7e4a.pdf",
    )
    url: str = Field(..., title="Адрес с токеном, готовый к открытию")
    expires_in: int = Field(..., title="Сколько секунд ссылка живёт")
