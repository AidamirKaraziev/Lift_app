from sqlalchemy import Boolean, Column, Integer, String, Date, ForeignKey, UniqueConstraint
from app.db.base_class import Base


class TypeAct(Base):
    __tablename__ = "types_acts"
    id = Column(Integer, primary_key=True, autoincrement=False)
    name = Column(String, unique=True)
