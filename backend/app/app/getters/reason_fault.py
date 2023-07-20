from app.models.reason_fault import ReasonFault
from app.schemas.reason_fault import ReasonFaultGet


def getting_reason_fault(db_obj: ReasonFault) -> ReasonFaultGet:
    return ReasonFaultGet(
        id=db_obj.id,
        name=db_obj.name
    )
