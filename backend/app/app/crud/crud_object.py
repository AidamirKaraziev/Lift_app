import glob
import os
import shutil
import uuid
from typing import Optional, Any, Union, Dict

from fastapi import UploadFile
from fastapi.encoders import jsonable_encoder
from app.crud.base import CRUDBase
from sqlalchemy.orm import Session


from app.core.security import verify_password
from app.exceptions import UnprocessableEntity

from app.utils.time_stamp import date_from_timestamp

from app.core.security import get_password_hash

from app.exceptions import UnfoundEntity

from app.models import UniversalUser
from app.schemas.universal_user import UniversalUserCreate, UniversalUserUpdate, UniversalUserEntrance, \
    UniversalUserRequest

from app.models import Location, Division
from app.models.working_specialty import WorkingSpecialty
from app.schemas.foreman import ForemanCreate

from app.crud.base_user import CRUDBaseUser

from app.core.templates_raise import get_raise
from app.schemas.universal_user import UniversalUserDivision

from app.core.roles import ADMIN, FOREMAN, MECHANIC


from app.models import Object
from app.schemas.object import ObjectCreate, ObjectUpdate

from app.models import Organization, FactoryModel, Company, ContactPerson
from app.models.contract import Contract

ROLE_RIGHTS = [ADMIN, FOREMAN]
ROLE_MECHANIC = [MECHANIC]
ROLE_FOREMAN = [FOREMAN]


class CrudObject(CRUDBase[Object, ObjectCreate, ObjectUpdate]):

    def get_obj(self, *, db: Session, id: int):
        obj = db.query(Object).filter(Object.id == id).first()
        if obj is None:
            return None, -116, None
        return obj, 0, None

    def create_object(self, db: Session, *, new_data: ObjectCreate):
        # проверка на организацию
        if new_data.organization_id is not None:
            org = db.query(Organization).filter(Organization.id == new_data.organization_id).first()
            if org is None:
                return None, -114, None  # нет организации
        # проверка на участок
        if new_data.division_id is not None:
            div = db.query(Division).filter(Division.id == new_data.division_id).first()
            if div is None:
                return None, -104, None  # нет участка
        # проверка на модель техники
        if new_data.factory_model_id is not None:
            fac = db.query(FactoryModel).filter(FactoryModel.id == new_data.factory_model_id).first()
            if fac is None:
                return None, -115, None  # нет Модели техники
        # проверка на заводской номер
        if new_data.factory_number is not None:
            fac_num = db.query(Object).filter(Object.factory_number == new_data.factory_number).first()
            if fac_num is not None:
                return None, -1151, None  # номер техники уже существует
        # проверка на регистрационный номер
        if new_data.registration_number is not None:
            reg = db.query(Object).filter(Object.registration_number == new_data.registration_number).first()
            if reg is not None:
                return None, -118, None  # регистрационный номер уже есть
        # проверка на компанию
        if new_data.company_id is not None:
            com = db.query(Company).filter(Company.id == new_data.company_id).first()
            if com is None:
                return None, -106, None  # нет компании
        # проверка на контактное лицо
        if new_data.contact_person_id is not None:
            pers = db.query(ContactPerson).filter(ContactPerson.id == new_data.contact_person_id).first()
            if pers is None:
                return None, -113, None  # нет контактное лицо
        # проверка на контракт
        if new_data.contract_id is not None:
            con = db.query(Contract).filter(Contract.id == new_data.contract_id).first()
            if con is None:
                return None, -1121, None  # нет компании
        # перевод дат в нужный формат
        if new_data.date_inspection is not None:
            new_data.date_inspection = date_from_timestamp(new_data.date_inspection)
        if new_data.planned_inspection is not None:
            new_data.planned_inspection = date_from_timestamp(new_data.planned_inspection)
        if new_data.period_inspection is not None:
            new_data.period_inspection = date_from_timestamp(new_data.period_inspection)

        # проверка на ответственный прораб
        if new_data.foreman_id is not None:
            foreman = db.query(UniversalUser).filter(UniversalUser.id == new_data.foreman_id).first()
            if foreman is None:
                return None, -105, None  # нет пользователя
            # проверка на роли прораба
            if foreman.role_id not in ROLE_FOREMAN:
                return None, -119, None

        # проверка на ответственный механик
        if new_data.mechanic_id is not None:
            mech = db.query(UniversalUser).filter(UniversalUser.id == new_data.mechanic_id).first()
            if mech is None:
                return None, -105, None  # нет пользователя
        #     проверка на роль механика
            if mech.role_id not in ROLE_MECHANIC:
                return None, -120, None

        db_obj = super().create(db=db, obj_in=new_data)
        return db_obj, 0, None

    def update_object(self, db: Session, *, new_data: Optional[ObjectUpdate], object_id: int):
        # проверить есть ли объект с таким id
        this_object = (db.query(Object).filter(Object.id == object_id).first())
        if this_object is None:
            return None, -116, None

        # проверка на организацию
        if new_data.organization_id is not None:
            org = db.query(Organization).filter(Organization.id == new_data.organization_id).first()
            if org is None:
                return None, -114, None  # нет организации
            # проверка на участок
            if new_data.division_id is not None:
                div = db.query(Division).filter(Division.id == new_data.division_id).first()
                if div is None:
                    return None, -104, None  # нет участка
            # проверка на модель техники
            if new_data.factory_model_id is not None:
                fac = db.query(FactoryModel).filter(FactoryModel.id == new_data.factory_model_id).first()
                if fac is None:
                    return None, -115, None  # нет Модели техники
            # проверка на заводской номер
            if new_data.factory_number is not None:
                fac_num = db.query(Object).filter(Object.factory_number == new_data.factory_number).first()
                if fac_num is not None:
                    return None, -1151, None  # номер техники уже существует
            # проверка на регистрационный номер
            if new_data.registration_number is not None:
                reg = db.query(Object).filter(Object.registration_number == new_data.registration_number).first()
                if reg is not None:
                    return None, -118, None  # регистрационный номер уже есть
            # проверка на компанию
            if new_data.company_id is not None:
                com = db.query(Company).filter(Company.id == new_data.company_id).first()
                if com is None:
                    return None, -106, None  # нет компании
            # проверка на контактное лицо
            if new_data.contact_person_id is not None:
                pers = db.query(ContactPerson).filter(ContactPerson.id == new_data.contact_person_id).first()
                if pers is None:
                    return None, -113, None  # нет контактное лицо
            # проверка на контракт
            if new_data.contract_id is not None:
                con = db.query(Contract).filter(Contract.id == new_data.contract_id).first()
                if con is None:
                    return None, -1121, None  # нет компании
            # перевод дат в нужный формат
            if new_data.date_inspection is not None:
                new_data.date_inspection = date_from_timestamp(new_data.date_inspection)
            if new_data.planned_inspection is not None:
                new_data.planned_inspection = date_from_timestamp(new_data.planned_inspection)
            if new_data.period_inspection is not None:
                new_data.period_inspection = date_from_timestamp(new_data.period_inspection)

            # проверка на ответственный прораб
            if new_data.foreman_id is not None:
                foreman = db.query(UniversalUser).filter(UniversalUser.id == new_data.foreman_id).first()
                if foreman is None:
                    return None, -105, None  # нет пользователя
                # проверка на роли прораба
                if foreman.role_id not in ROLE_FOREMAN:
                    return None, -119, None

            # проверка на ответственный механик
            if new_data.mechanic_id is not None:
                mech = db.query(UniversalUser).filter(UniversalUser.id == new_data.mechanic_id).first()
                if mech is None:
                    return None, -105, None  # нет пользователя
                #     проверка на роль механика
                if mech.role_id not in ROLE_MECHANIC:
                    return None, -120, None
        # обновление данных
        db_obj = super().update(db=db, db_obj=this_object, obj_in=new_data)
        return db_obj, 0, None

    # def create_foreman(self,  db: Session, *, current_user: UniversalUser, new_data: ForemanCreate):
    #     # проверить есть ли такой current_user
    #     admin = db.query(UniversalUser).filter(UniversalUser.id == current_user.id).first()
    #     if admin is None:
    #         return None, -1, None
    #     # проверить должность current_user
    #     if current_user.role_id != 1:
    #         return None, -2, None
    #     # проверка есть ли такой email in db
    #     email = db.query(UniversalUser).filter(UniversalUser.email == new_data.email).first()
    #     if email is not None:
    #         return None, -3, None  # have email in db
    #
    #     # проверять хеш пароль
    #     # if new_data.password is None:
    #     #     return None, -3, None  # нет пароля
    #     psw = get_password_hash(password=new_data.password)
    #     new_data.password = psw
    #
    #     # Проверить дату дня рождения
    #     if new_data.birthday is not None:
    #         new_data.birthday = date_from_timestamp(new_data.birthday)
    #
    #     if new_data.location_id is not None:
    #         loc = db.query(Location).filter(Location.id == new_data.location_id).first()
    #         if loc is None:
    #             return None, -4, None  # нет города
    #
    #     if new_data.role_id != 2:
    #         return None, -5, None
    #
    #     if new_data.working_specialty_id is not None:
    #         spec = db.query(WorkingSpecialty).filter(WorkingSpecialty.id == new_data.working_specialty_id).first()
    #         if spec is None:
    #             return None, -6, None
    #     # Проверить участок
    #     if new_data.division_id is not None:
    #         div = db.query(Division).filter(Division.id == new_data.division_id).first()
    #         if div is None:
    #             return None, -7, None
    #     db_obj = super().create(db=db, obj_in=new_data)
    #     return db_obj, 0, None
    #
    # def get_universal_user(self, db: Session, *, universal_user: UniversalUserEntrance):
    #
    #     # getting_universal_user = db.query(UniversalUser).filter(UniversalUser.email == universal_user.email,
    #     #                                                         UniversalUser.is_actual == True).first()
    #     getting_universal_user = db.query(UniversalUser).filter(UniversalUser.email == universal_user.email).first()
    #     if getting_universal_user is None or not verify_password(plain_password=universal_user.password,
    #                                                              hashed_password=getting_universal_user.password):
    #         raise UnprocessableEntity(
    #             message="Неверный логин или пароль",
    #             num=1,
    #             description="Неверный логи или пароль",
    #             path="$.body"
    #         )
    #     if getting_universal_user.is_actual is False:
    #         raise UnprocessableEntity(
    #             message="Вам отказано в доступе",
    #             num=1,
    #             description="Администратор ограничил вам доступ",
    #             path="$.body"
    #         )
    #
    #     return getting_universal_user
    #
    # def get_by_email(self, db: Session, *, email: str):
    #     return db.query(UniversalUser).filter(UniversalUser.email == email).first()


crud_objects = CrudObject(Object)
