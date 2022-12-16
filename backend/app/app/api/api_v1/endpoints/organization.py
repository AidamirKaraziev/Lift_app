import logging
from typing import Optional

from fastapi import APIRouter, Header, Depends, UploadFile, File, HTTPException, Query, Path, Request

from app.api import deps

from app.core.response import ListOfEntityResponse, SingleEntityResponse, Meta


from app.core.roles import ADMIN, CLIENT
from app.core.templates_raise import get_raise

from app.getters.organization import get_organization

from app.crud.crud_universal_user import crud_universal_users
from app.schemas.organization import OrganizationCreate, OrganizationUpdate

from app.crud.crud_organization import crud_organizations

from app.exceptions import UnfoundEntity
from app.schemas.organization import OrganizationGet

ROLES_ELIGIBLE = [ADMIN]
ROLES_ELIGIBLE_ADMIN_CLIENT = [ADMIN, CLIENT]

PATH_MODEL = "organization"
PATH_TYPE = "photo"
router = APIRouter()


# Вывод всех Компаний
# GET-MULTY
@router.get('/all-organization/',
            response_model=ListOfEntityResponse,
            name='Список организаций',
            description='Получение списка всех организаций',
            tags=['Админ панель / Организации']
            )
def get_data(
        request: Request,
        session=Depends(deps.get_db),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        page: int = Query(1, title="Номер страницы")
):
    logging.info(crud_organizations.get_multi(db=session, page=None))

    data, paginator = crud_organizations.get_multi(db=session, page=page)

    return ListOfEntityResponse(data=[get_organization(datum, request=request) for datum in data],
                                meta=Meta(paginator=paginator))


# GET ID
@router.get('/organization/{organization_id}/',
            response_model=SingleEntityResponse,
            name='Организация',
            description='Получение данных организации',
            tags=['Админ панель / Организации']
            )
def get_data(
        request: Request,
        organization_id: int = Path(..., title='ID организации'),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
):
    obj, code, indexes = crud_organizations.get_org(db=session, organization_id=organization_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_organization(organization=obj, request=request))


# CREATE NEW ORGANIZATION
@router.post('/organization/',
             response_model=SingleEntityResponse,
             name='Добавить Организацию',
             description='Добавить одну организацию в базу данных ',
             tags=['Админ панель / Организации']
             )
def create_organization(
        request: Request,
        new_data: OrganizationCreate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
    get_raise(code=code)

    organization, code, index = crud_organizations.create_organization(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_organization(organization=organization, request=request))


# UPDATE
@router.put('/organization/{organization_id}/',
            response_model=SingleEntityResponse,
            name='Изменить данные организации',
            description='Изменяет данные организации',
            tags=['Админ панель / Организации'])
def update_organization(
        request: Request,
        new_data: OrganizationUpdate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        organization_id: int = Path(..., title='Id организации'),
        session=Depends(deps.get_db)
):
    # проверка на роли
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
    get_raise(code=code)

    organization, code, indexes = crud_organizations.update_organization(db=session, organization=new_data,
                                                                        organization_id=organization_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_organization(organization=organization, request=request))


# UPDATE PHOTO
@router.put("/organization/{organization_id}/photo/",
            response_model=SingleEntityResponse[OrganizationGet],
            name='Изменить фотографию',
            description='Изменить фотографию для организации, если отправить пустой файл сбрасывает фото',
            tags=['Админ панель / Организации'],
            )
def create_upload_file(
        request: Request,
        file: Optional[UploadFile] = File(None),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        organization_id: int = Path(..., title='Id организации'),
        session=Depends(deps.get_db),
        ):
    # проверка на роли
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
    get_raise(code=code)

    obj, code, indexes = crud_organizations.get_org(db=session, organization_id=organization_id)
    get_raise(code=code)
    save_path = crud_organizations.adding_file(db=session, file=file, path_model=PATH_MODEL, path_type=PATH_TYPE,
                                               db_obj=obj)
    if not save_path:
        raise UnfoundEntity(message="Не отправлен загружаемый файл",
                            num=2,
                            description="Попробуйте загрузить файл еще раз",
                            path="$.body",
                            )
    return SingleEntityResponse(data=get_organization(obj, request=request))


# АПИ ПО АРХИВАЦИИ ОРГАНИЗАЦИИ
@router.get('/organization/{organization_id}/archive/',
            response_model=SingleEntityResponse,
            name='Заморозить организацию',
            description='Архивация организации',
            tags=['Админ панель / Организации'])
def archiving_organizations(
        request: Request,
        organization_id: int = Path(..., title='Id ОРГАНИЗАЦИИ'),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db)
):
    obj, code, indexes = crud_organizations.archiving_organization(db=session,
                                                                   current_user=current_user,
                                                                   organization_id=organization_id,
                                                                   role_list=ROLES_ELIGIBLE)
    get_raise(code=code)
    return SingleEntityResponse(data=get_organization(obj, request=request))


# АПИ ПО РАЗАРХИВАЦИИ ОРГАНИЗАЦИИ
@router.get('/organization/{organization_id}/unzip/',
            response_model=SingleEntityResponse,
            name='Разморозка Организации',
            description='Разархивация Организации, доступ к приложению размораживается',
            tags=['Админ панель / Организации'])
def unzipping_organizations(
        request: Request,
        organization_id: int = Path(..., title='Id ОРГАНИЗАЦИИ'),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db)
):
    obj, code, indexes = crud_organizations.unzipping_organization(db=session,
                                                                   current_user=current_user,
                                                                   organization_id=organization_id,
                                                                   role_list=ROLES_ELIGIBLE)
    get_raise(code=code)
    return SingleEntityResponse(data=get_organization(obj, request=request))


if __name__ == "__main__":
    logging.info('Running...')
