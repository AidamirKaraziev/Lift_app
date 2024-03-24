import logging
from fastapi import APIRouter, Depends, Query, Path, Request

from app.api import deps

from app.core.response import ListOfEntityResponse, SingleEntityResponse, Meta
from app.core.roles import ADMIN, FOREMAN
from app.core.templates_raise import get_raise

from app.crud.crud_universal_user import crud_universal_users
from app.crud.crud_type_object import crud_type_object
from app.crud.crud_factory_model import crud_factory_models

from app.getters.factory_model import get_factory_model
from app.schemas.factory_model import FactoryModelCreate, FactoryModelUpdate


ROLES_ELIGIBLE = [ADMIN]
ROLES_ELIGIBLE_ADMIN_FOREMAN = [ADMIN, FOREMAN]

router = APIRouter()


# Вывод всех Компаний
# GET-MULTY
@router.get('/all-factory-model/',
            response_model=ListOfEntityResponse,
            name='Список моделей',
            description='Получение списка всех моделей',
            tags=['Админ панель / Модели']
            )
def get_data(
        request: Request,
        session=Depends(deps.get_db),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        page: int = Query(1, title="Номер страницы")
):
    logging.info(crud_factory_models.get_multi(db=session, page=None))

    data, paginator = crud_factory_models.get_multi(db=session, page=page)

    return ListOfEntityResponse(data=[get_factory_model(datum) for datum in data],
                                meta=Meta(paginator=paginator))


# GET ID
@router.get('/factory-model/{factory_model_id}/',
            response_model=SingleEntityResponse,
            name='Модели',
            description='Получение данных по модели техники',
            tags=['Админ панель / Модели']
            )
def get_data(
        request: Request,
        factory_model_id: int = Path(..., title='ID модели техники'),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
):
    obj, code, indexes = crud_factory_models.get_mod(db=session, factory_model_id=factory_model_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_factory_model(obj))


# GET factory_model by type_object_id
@router.get('/factory-model/sort-by-type-object/{type_object_id}/',
            response_model=ListOfEntityResponse,
            name='get_factory_model_by_type_object_id',
            description='Получение моделей техники по типу объектов',
            tags=['Админ панель / Модели']
            )
def get_factory_model_by_type_object_id(
        request: Request,
        type_object_id: int = Path(..., title='ID модели техники'),
        # current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
        page: int = Query(1, title="Номер страницы")
):
    obj, code, indexes = crud_type_object.get_type_object_by_id(db=session, type_object_id=type_object_id)
    get_raise(code=code)

    data, paginator = crud_factory_models.get_factory_model_by_type_obj_id(db=session, page=page, type_object_id=type_object_id)

    return ListOfEntityResponse(data=[get_factory_model(datum) for datum in data],
                                meta=Meta(paginator=paginator))


# CREATE NEW FACTORY_MODEL
@router.post('/factory-model/',
             response_model=SingleEntityResponse,
             name='Добавить новую модель техники',
             description='Добавить новую модель техники в базу данных ',
             tags=['Админ панель / Модели']
             )
def create_factory_models(
        request: Request,
        new_data: FactoryModelCreate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN)
    get_raise(code=code)

    factory_model, code, index = crud_factory_models.create_factory_model(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_factory_model(db_obj=factory_model))


# UPDATE
@router.put('/factory-model/{factory_model_id}/',
            response_model=SingleEntityResponse,
            name='Изменить данные модели техники',
            description='Изменяет данные модели техники',
            tags=['Админ панель / Модели'])
def update_factory_models(
        request: Request,
        new_data: FactoryModelUpdate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        factory_model_id: int = Path(..., title='Id модели'),
        session=Depends(deps.get_db)
):
    # проверка на роли
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN)
    get_raise(code=code)

    factory_model, code, indexes = crud_factory_models.update_factory_model(db=session, new_data=new_data,
                                                                            factory_model_id=factory_model_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_factory_model(factory_model))


if __name__ == "__main__":
    logging.info('Running...')
