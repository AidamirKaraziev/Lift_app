from sqlalchemy import Column, Integer, String
from src.core.db.base_class import Base


class TypeObject(Base):
    __tablename__ = "type_objects"
    id = Column(Integer, primary_key=True, autoincrement=False)
    name = Column(String, unique=True)
