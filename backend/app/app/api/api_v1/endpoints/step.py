import logging
from fastapi import APIRouter, Depends, Query, Path, Request

from app.api import deps
from app.core.response import ListOfEntityResponse, SingleEntityResponse, Meta
from app.core.roles import ADMIN, FOREMAN
from app.core.templates_raise import get_raise

from app.crud.crud_step import crud_step
from app.crud.crud_universal_user import crud_universal_users
from app.getters.step import get_step
from app.schemas.step import StepUpdate, StepCreate

router = APIRouter()
ROLES_ELIGIBLE_ADMIN_FOREMAN = [ADMIN, FOREMAN]


# Вывод всех Step
@router.get('/steps/',
            response_model=ListOfEntityResponse,
            name='Список Этапов',
            description='Получение списка всех названий Этапов',
            tags=['Админ панель / Название Этапов']
            )
def get_data(
        # current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
        page: int = Query(1, title="Номер страницы")
):
    logging.info(crud_step.get_multi(db=session, page=None))

    data, paginator = crud_step.get_multi(db=session, page=page)

    return ListOfEntityResponse(data=[get_step(datum) for datum in data], meta=Meta(paginator=paginator))


# CREATE NEW STEPS
@router.post('/steps/',
             response_model=SingleEntityResponse,
             name='Добавить название Этапа ',
             description='Добавить одно название этапа в базу данных ',
             tags=['Админ панель / Название Этапов']
             )
def create_steps(
        request: Request,
        new_data: StepCreate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
):
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN)
    get_raise(code=code)

    obj, code, index = crud_step.create_steps(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_step(db_obj=obj))


# UPDATE
@router.put('/steps/{step_id}/',
            response_model=SingleEntityResponse,
            name='Изменить название этапа',
            description='Изменяет название этапа',
            tags=['Админ панель / Название Этапов'])
def update_steps(
        request: Request,
        new_data: StepUpdate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        step_id: int = Path(..., title='Id этапа'),
        session=Depends(deps.get_db)
):
    # проверка на роли
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN)
    get_raise(code=code)

    obj, code, indexes = crud_step.update_steps(db=session, new_data=new_data, step_id=step_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_step(obj))


# Апи удаляет название этапа
@router.get('/steps/{step_id}/',
            response_model=SingleEntityResponse,
            name='Удалить название этапа',
            description='Полностью удаляет название этапа',
            tags=['Админ панель / Название Этапов'])
def delete_step(
        step_id: int = Path(..., title='Id этапа'),
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db)
):
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE_ADMIN_FOREMAN)
    get_raise(code=code)

    obj, code, indexes = crud_step.get_step(db=session, step_id=step_id)
    get_raise(code=code)

    return SingleEntityResponse(data=crud_step.remove(db=session, id=step_id))


if __name__ == "__main__":
    logging.info('Running...')
