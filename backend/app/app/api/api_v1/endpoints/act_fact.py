import logging

from fastapi import APIRouter, Depends, Request, UploadFile, File, Query

from fastapi.params import Path
from app.api import deps

from app.crud.crud_universal_user import crud_universal_users
from app.core.response import ListOfEntityResponse, SingleEntityResponse, Meta


from app.core.templates_raise import get_raise


from app.core.roles import ADMIN, FOREMAN, MECHANIC

from app.crud.crud_act_fact import crud_acts_fact
from app.getters.act_fact import get_acts_facts

from app.schemas.act_fact import ActFactGet

from app.schemas.act_fact import ActFactCreate, ActFactUpdate

ROLES_ELIGIBLE = [ADMIN, FOREMAN]
PATH_MODEL = "act_fact"
PATH_TYPE = "file"

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
    obj, code, indexes = crud_acts_fact.get_act_fact_by_id(db=session, id=act_fact_id)
    get_raise(code=code)
    return SingleEntityResponse(data=get_acts_facts(obj, request))


@router.post('/act-fact/',
             response_model=SingleEntityResponse,
             summary='Создает фактический акт',
             description='''
Добавить один акт факт в БД.
Который в последствии будет выполнять механик, заполняя данными о ходе выполнения работ.
''',
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


@router.put('/act-fact/{act_fact_id}/',
            response_model=SingleEntityResponse,
            summary='Изменить данные фактического акта',
            description="""
Обновляет данные фактического акта по его идентификатору.

### Требования:
- Пользователь должен быть аутентифицирован.
- Доступ имеют только пользователи с ролями **Администратор**, **Прораб** или **Механик**.

### Параметры:
- **act_fact_id**: Идентификатор фактического акта.
- **update_data**: Объект с данными для обновления фактического акта.

### Схемы:
**ActFactUpdate**:
- `step_list_fact` (Optional[str]): Список выполненных шагов.
- `started_at` (Optional[int]): Время начала в формате timestamp.
- `finished_at` (Optional[int]): Время окончания в формате timestamp.
- `foreman_id` (Optional[int]): Идентификатор ответственного прораба.
- `main_mechanic_id` (Optional[int]): Идентификатор ответственного механика.
- `status_id` (Optional[int]): Идентификатор статуса.

**ActFactGet**:
- `id` (int): Идентификатор фактического акта.
- `object_id` (Optional[int]): Идентификатор объекта.
- `act_base_id` (Optional[int]): Идентификатор базового акта.
- `step_list_fact` (Optional[str]): Список выполненных шагов.
- `created_at` (Optional[datetime]): Время создания акта.
- `started_at` (Optional[datetime]): Время начала.
- `finished_at` (Optional[datetime]): Время окончания.
- `foreman_id` (Optional[int]): Идентификатор ответственного прораба.
- `main_mechanic_id` (Optional[int]): Идентификатор ответственного механика.
- `file` (Optional[str]): Ссылка на файл.
- `status_id` (Optional[StatusGet]): Идентификатор статуса.

### Возвращает:
- **SingleEntityResponse**: Объект с обновленными данными фактического акта.        
            """,
            tags=['Админ панель / Фактические Акты'])
def update_act_fact(
        request: Request,
        update_data: ActFactUpdate,
        current_user=Depends(deps.get_current_universal_user_by_bearer),
        act_fact_id: int = Path(..., title='Id фактического акта'),
        session=Depends(deps.get_db)
):
    # проверка на роли
    code = crud_universal_users.check_role_list(current_user=current_user, role_list=[ADMIN, FOREMAN, MECHANIC])
    get_raise(code=code)

    obj, code, indexes = crud_acts_fact.update_act_fact(db=session, update_data=update_data, act_fact_id=act_fact_id)
    get_raise(code=code)

    return SingleEntityResponse(data=get_acts_facts(obj, request=request))
#
#
# # UPDATE FILE
# @router.put("/act-fact/{act_fact_id}/file/",
#             response_model=SingleEntityResponse[ActFactGet],
#             name='Изменить файл',
#             description='Изменить файл для фактического акта, если отправить пустой файл сбрасывается',
#             tags=['Админ панель / Фактические Акты'],
#             )
# def create_upload_file(
#         request: Request,
#         file: Optional[UploadFile] = File(None),
#         current_user=Depends(deps.get_current_universal_user_by_bearer),
#         act_fact_id: int = Path(..., title='Id фактический акт'),
#         session=Depends(deps.get_db),
#         ):
#     # проверка на роли
#     code = crud_universal_users.check_role_list(current_user=current_user, role_list=ROLES_ELIGIBLE)
#     get_raise(code=code)
#
#     obj, code, indexes = crud_acts_fact.getting_act_fact(db=session, act_fact_id=act_fact_id)
#     get_raise(code=code)
#     crud_acts_fact.adding_file(db=session, file=file, path_model=PATH_MODEL, path_type=PATH_TYPE, db_obj=obj)
#
#     return SingleEntityResponse(data=get_acts_facts(crud_acts_fact.get(db=session, id=act_fact_id), request=request))


if __name__ == "__main__":
    logging.info('Running...')
