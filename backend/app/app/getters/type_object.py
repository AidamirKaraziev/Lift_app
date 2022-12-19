from app.models import TypeObject
from app.schemas.type_object import TypeObjectGet


def get_type_objects(db_obj: TypeObject) -> TypeObjectGet:
    return TypeObjectGet(
        id=db_obj.id,
        name=db_obj.name
    )
