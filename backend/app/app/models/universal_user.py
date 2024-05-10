from sqlalchemy import Boolean, Column, Integer, String, Date, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship

from app.db.base_class import Base
from app.models import Location
from app.models.role import Role
from app.models.working_specialty import WorkingSpecialty
from app.models.company import Company
from app.models.division import Division


class UniversalUser(Base):
    __tablename__ = "universal_users"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    email = Column(String)
    password = Column(String)  # hex-password
    contact_phone = Column(String)
    birthday = Column(Date)
    photo = Column(String)
    location_id = Column(Integer, ForeignKey("locations.id", ondelete="SET NULL"))
    role_id = Column(Integer, ForeignKey("roles.id", ondelete="SET NULL"))
    working_specialty_id = Column(Integer, ForeignKey("working_specialty.id", ondelete="SET NULL"))
    identity_card = Column(String)
    division_id = Column(Integer, ForeignKey("divisions.id", ondelete="SET NULL"))
    company_id = Column(Integer, ForeignKey("company.id", ondelete="SET NULL"))
    qualification_file = Column(String)
    date_of_employment = Column(Date)
    is_actual = Column(Boolean, default=True)

    working_specialty = relationship(WorkingSpecialty)
    location = relationship(Location)
    role = relationship(Role)
    company = relationship(Company)
    division = relationship(Division)

    __table_args__ = (UniqueConstraint('email', 'is_actual', name='_email_is_actual_uc'),
                      )
    # acts_fact_of_mechanic = relationship('ActFactOfMechanic', back_populates='mechanic', cascade="all, delete")
    # devices = relationship('Device', back_populates='universal_user', cascade="all, delete", passive_deletes=True)
