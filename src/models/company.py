from sqlalchemy import Boolean, Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from src.session import Base
from src.models import Location


class Company(Base):
    __tablename__ = 'company'
    id = Column(Integer, primary_key=True)
    name = Column(String)

    director_name = Column(String)
    cont_phone = Column(String)
    email = Column(String)
    cont_address = Column(String)
    photo = Column(String)
    location_id = Column(Integer, ForeignKey("locations.id", ondelete="SET NULL"))
    site = Column(String)

    is_actual = Column(Boolean, default=True)

    location = relationship(Location)
