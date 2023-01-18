from sqlalchemy import Boolean, Column, Integer, String, Date, ForeignKey, UniqueConstraint
from app.db.base_class import Base


class TypeObject(Base):
    __tablename__ = "type_objects"
    id = Column(Integer, primary_key=True, autoincrement=False)
    name = Column(String, unique=True)
