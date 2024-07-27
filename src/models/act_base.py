from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from src.core.db.base_class import Base
from sqlalchemy.orm import relationship

from src.models import FactoryModel, TypeAct


class ActBase(Base):
    __tablename__ = 'acts_bases'
    id = Column(Integer, primary_key=True)
    factory_model_id = Column(Integer, ForeignKey("factories_models.id", ondelete="SET NULL"))
    type_act_id = Column(Integer, ForeignKey("types_acts.id", ondelete="SET NULL"))
    step_list = Column(String)

    factory_model = relationship(FactoryModel)
    type_act = relationship(TypeAct)

    __table_args__ = (UniqueConstraint("factory_model_id", "type_act_id", name='_type_act_factory_model_uc'),
                      )
