from datetime import date
from typing import Optional

from src.models import Object, UniversalUser
from src.schemas.appointment_order import (
    FOREMAN_POSITION,
    MECHANIC_POSITION,
    SIGNER_POSITION,
    AppointmentLift,
    AppointmentOrderDraft,
    AppointmentPerson,
)
from src.utils.time_stamp import to_timestamp


def _person(
    user: Optional[UniversalUser], position: str
) -> Optional[AppointmentPerson]:
    if user is None or not user.name:
        return None
    return AppointmentPerson(full_name=user.name, position=position)


def get_appointment_order_draft(obj: Object) -> AppointmentOrderDraft:
    """Черновик приказа из карточки объекта.

    Ничего не хранится: реквизиты, которых в базе нет (номер, город), уходят
    пустыми, и человек вписывает их в диалоге. Отсутствие людей или директора
    — не ошибка, а `null`: диалог показывает это словами, и приказ всё равно
    можно посмотреть.
    """
    organization = obj.organization
    director = organization.director if organization is not None else None
    model = obj.factory_model
    has_lift = model is not None or obj.load_capacity is not None
    return AppointmentOrderDraft(
        number="",
        date=to_timestamp(date.today()),
        city="",
        address=obj.address,
        organization=organization.title if organization is not None else None,
        signer_position=SIGNER_POSITION if director is not None else None,
        signer_name=director.name if director is not None else None,
        foreman=_person(obj.foreman, FOREMAN_POSITION),
        mechanic=_person(obj.mechanic, MECHANIC_POSITION),
        lifts=[
            AppointmentLift(
                type=model.type_object.name
                if model is not None and model.type_object is not None
                else None,
                brand=model.model if model is not None else None,
                load_capacity_kg=obj.load_capacity,
            )
        ]
        if has_lift
        else [],
    )
