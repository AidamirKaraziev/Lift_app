from app.models.type_act import TypeAct
from app.schemas.type_act import TypeActGet


def get_type_acts(db_obj: TypeAct) -> TypeActGet:
    return TypeActGet(
        id=db_obj.id,
        name=db_obj.name
    )
