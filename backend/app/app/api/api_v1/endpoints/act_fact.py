import logging
from typing import Optional

from fastapi import APIRouter, Depends, Header, Request, UploadFile, File, Query
# from fastapi.params import Path, Form

from fastapi.params import Path
from app.api import deps

from app.crud.crud_universal_user import crud_universal_users
from app.core.response import ListOfEntityResponse, SingleEntityResponse, Meta


from app.core.templates_raise import get_raise


from app.core.roles import ADMIN, FOREMAN

from app.crud.crud_act_fact import crud_acts_fact
from app.getters.act_fact import get_acts_facts

from app.schemas.act_fact import ActFactGet

from app.schemas.act_fact import ActFactCreate

ROLES_ELIGIBLE = [ADMIN, FOREMAN]

router = APIRouter()


# GET-MULTY
@router.get('/all-acts-fact/',
            response_model=ListOfEntityResponse,
            name='Список Фактических Актов',
            description='Получение списка всех Фактических Актов',
            tags=['Админ панель / Фактические Акты']
            )
def get_data(
        request: Request,
        session=Depends(deps.get_db),
        page: int = Query(1, title="Номер страницы")
):
    logging.info(crud_acts_fact.get_multi(db=session, page=None))

    data, paginator = crud_acts_fact.get_multi(db=session, page=page)

    return ListOfEntityResponse(data=[get_acts_facts(obj=datum, request=request) for datum in data],
                                meta=Meta(paginator=paginator))


# GET BY ID
@router.get('/act-fact/{act_fact_id}/',
            response_model=SingleEntityResponse[ActFactGet],
            name='Получить данные фактического акта по id ',
            description='Получение данных фактического акта по id',
            tags=['Админ панель / Фактические Акты']
            )
def get_data(
        request: Request,
        session=Depends(deps.get_db),
        act_fact_id: int = Path(..., title='ID object'),
        # current_universal_user=Depends(deps.get_current_universal_user_by_bearer),
):
    obj, code, indexes = crud_acts_fact.getting_act_fact(db=session, act_fact_id=act_fact_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_facts(obj, request))


# CREATE NEW ACT FACT
@router.post('/act-fact/',
             response_model=SingleEntityResponse,
             name='Добавить акт факт',
             description='Добавить один акт факт в базу данных ',
             tags=['Админ панель / Фактические Акты']
             )
def create_act_fact(
        request: Request,
        new_data: ActFactCreate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        session=Depends(deps.get_db),
):
    # сделать проверку на роль Администратора и Прораба
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
    get_raise(code=code)

    obj, code, index = crud_acts_fact.create_act_fact(db=session, new_data=new_data)
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_facts(obj, request))


if __name__ == "__main__":
    logging.info('Running...')