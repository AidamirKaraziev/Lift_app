from sqlite3 import Date
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.location import LocationGet
from app.schemas.role import RoleGet
from app.schemas.working_specialty import WorkingSpecialtyGet

from app.schemas.company import CompanyGet
from app.schemas.divisions import DivisionGet

from app.schemas.contact_person import ContactPersonGet
from app.schemas.contract import ContractGet
from app.schemas.factory_model import FactoryModelGet
from app.schemas.organization import OrganizationGet
from app.schemas.universal_user import UniversalUserGet


class ObjectBase(BaseModel):
    id: int
    name: Optional[str]
    organization_id: Optional[int]
    division_id: Optional[int]
    address: Optional[str]

    factory_model_id: Optional[int]
    factory_number: Optional[str]
    registration_number: Optional[str]

    number_of_stops: Optional[int]
    lifting_heights: Optional[int]
    load_capacity: Optional[int]
    width: Optional[int]

    cost_nds: Optional[int]
    cost_no_nds: Optional[int]

    company_id: Optional[int]
    contact_person_id: Optional[int]
    contract_id: Optional[int]

    date_inspection: Optional[Date]
    planned_inspection: Optional[Date]
    period_inspection: Optional[Date]

    foreman_id: Optional[int]
    mechanic_id: Optional[int]
    letter_of_appointment: Optional[str]

    acceptance_certificate: Optional[str]
    act_pto: Optional[str]
    geo: Optional[str]
    is_actual: Optional[bool]

    # name: str
    # email: str
    # password: str
    # contact_phone: Optional[str]
    # birthday: Optional[Date]
    # photo: Optional[str]
    # location_id: Optional[LocationGet]
    # role_id: Optional[RoleGet]
    # working_specialty_id: Optional[WorkingSpecialtyGet]
    # identity_card: Optional[str]
    # company_id: Optional[CompanyGet]
    # division_id: Optional[DivisionGet]
    # qualification_file: Optional[str]
    # date_of_employment: Optional[Date]


# Создание юзера
class ObjectCreate(BaseModel):
    # id: int
    name: Optional[str]
    organization_id: Optional[int]
    division_id: Optional[int]
    address: Optional[str]

    factory_model_id: Optional[int]
    factory_number: Optional[str]
    registration_number: Optional[str]

    number_of_stops: Optional[int]
    lifting_heights: Optional[int]
    load_capacity: Optional[int]
    width: Optional[int]

    cost_nds: Optional[int]
    cost_no_nds: Optional[int]

    company_id: Optional[int]
    contact_person_id: Optional[int]
    contract_id: Optional[int]

    date_inspection: Optional[int]
    planned_inspection: Optional[int]
    period_inspection: Optional[int]

    foreman_id: Optional[int]
    mechanic_id: Optional[int]
    # letter_of_appointment: Optional[str]
    #
    # acceptance_certificate: Optional[str]
    # act_pto: Optional[str]
    geo: Optional[str]
    # is_actual: Optional[bool]


# Изменение юзера
class ObjectUpdate(BaseModel):
    # id: int
    name: Optional[str]
    organization_id: Optional[int]
    division_id: Optional[int]
    address: Optional[str]

    factory_model_id: Optional[int]
    factory_number: Optional[str]
    registration_number: Optional[str]

    number_of_stops: Optional[int]
    lifting_heights: Optional[int]
    load_capacity: Optional[int]
    width: Optional[int]

    cost_nds: Optional[int]
    cost_no_nds: Optional[int]

    company_id: Optional[int]
    contact_person_id: Optional[int]
    contract_id: Optional[int]

    date_inspection: Optional[int]
    planned_inspection: Optional[int]
    period_inspection: Optional[int]

    foreman_id: Optional[int]
    mechanic_id: Optional[int]
    # letter_of_appointment: Optional[str]

    # acceptance_certificate: Optional[str]
    # act_pto: Optional[str]
    geo: Optional[str]
    # is_actual: Optional[bool]


# вывод юзера
class ObjectGet(BaseModel):
    id: int
    name: Optional[str]
    organization_id: Optional[OrganizationGet]
    division_id: Optional[DivisionGet]
    address: Optional[str]

    factory_model_id: Optional[FactoryModelGet]
    factory_number: Optional[str]
    registration_number: Optional[str]

    number_of_stops: Optional[int]
    lifting_heights: Optional[int]
    load_capacity: Optional[int]
    width: Optional[int]

    cost_nds: Optional[int]
    cost_no_nds: Optional[int]

    company_id: Optional[CompanyGet]
    contact_person_id: Optional[ContactPersonGet]
    contract_id: Optional[ContractGet]

    date_inspection: Optional[Date]
    planned_inspection: Optional[Date]
    period_inspection: Optional[Date]

    foreman_id: Optional[UniversalUserGet]
    mechanic_id: Optional[UniversalUserGet]
    letter_of_appointment: Optional[str]  # file

    acceptance_certificate: Optional[str]  # file
    act_pto: Optional[str]  # file
    geo: Optional[str]
    is_actual: Optional[bool]
