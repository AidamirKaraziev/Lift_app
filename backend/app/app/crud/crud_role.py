from sqlalchemy.orm import Session

from app.crud.base import CRUDBase
from app.models import Role
from app.schemas.role import RoleCreate, RoleUpdate


class CrudRole(CRUDBase[Role, RoleCreate, RoleUpdate]):
    def get_role_by_id(self, db: Session, *, role_id: int):
        user = db.query(Role).filter(Role.id == role_id).first()
        if user is None:
            return None, -102, None
        return user, 0, None


crud_role = CrudRole(Role)
