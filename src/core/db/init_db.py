from sqlalchemy.orm import Session

from src.core.security import get_password_hash
from src.crud.users import crud_universal_user
from src.schemas.universal_user import UniversalUserCreate
from src.session import get_session
from src.models import Role, Status, TypeObject, TypeContract, Location, FaultCategory, ReasonFault, TypeAct, CostType


def create_super_admin() -> None:
    for db in get_session():
        user, code, indexes = crud_universal_user.crud_universal_users.get_user_by_id(db=db, user_id=1)
        if not user:
            hashed_password = get_password_hash('1')
            user_in = UniversalUserCreate(
                id=1,
                name="Супер Админ",
                email="1",
                password=hashed_password,
                role_id=1,
            )
            crud_universal_user.crud_universal_users.create(db=db, obj_in=user_in)
        db.commit()
        db.close()


def check_roles(db: Session):
    check_list = [
        Role(id=1, name='Админ'),
        Role(id=2, name='Прораб'),
        Role(id=3, name='Механик'),
        Role(id=4, name='Инженер наладчик'),
        Role(id=5, name='Диспетчер'),
        Role(id=6, name='Клиент')
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(Role).filter(Role.id == obj.id, Role.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_roles():
    for db in get_session():
        creation_list = check_roles(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_statuses(db: Session):
    check_list = [
        Status(id=1, name='Создано'),
        Status(id=2, name='Принято'),
        Status(id=3, name='В процессе'),
        Status(id=4, name='Выполнено'),
        Status(id=5, name='Проблема')
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(Status).filter(Status.id == obj.id, Status.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_statuses():
    for db in get_session():
        creation_list = check_statuses(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_type_objects(db: Session):
    check_list = [
        TypeObject(id=1, name='Лифт без МП'),
        TypeObject(id=2, name='Лифт с МП'),
        TypeObject(id=3, name='Траволатор'),
        TypeObject(id=4, name='Эскалатор'),
        TypeObject(id=5, name='Грузовой лифт'),
        TypeObject(id=6, name='Инвалидный подъемник'),
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(TypeObject).filter(TypeObject.id == obj.id, TypeObject.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_type_objects():
    for db in get_session():
        creation_list = check_type_objects(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_type_contracts(db: Session):
    check_list = [
        TypeContract(id=1, name='Государственный'),
        TypeContract(id=2, name='Коммерческий')
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(TypeContract).filter(TypeContract.id == obj.id, TypeContract.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_type_contracts():
    for db in get_session():
        creation_list = check_type_contracts(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_locations(db: Session):
    check_list = [
        Location(id=1, name='Краснодар'),
        Location(id=2, name='Москва'),
        Location(id=3, name='Ростов на Дону'),
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(Location).filter(Location.id == obj.id, Location.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_locations():
    for db in get_session():
        creation_list = check_locations(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_fault_category(db: Session):
    check_list = [
        FaultCategory(id=1, name='AA (Застревание пассажира. Опасность)'),
        FaultCategory(id=2, name='А (Остановка лифта, подъемника, эскалатора, траволатора)'),
        FaultCategory(id=3, name='В (Ухудшение рабочих характеристик, требуется наладка)'),
        FaultCategory(id=4, name='Н (Незначительные проблемы)'),
        FaultCategory(id=5, name='Д (Заказчик или другие)'),
        FaultCategory(id=6, name='ТО (Плановые работы)'),
        FaultCategory(id=7, name='ПТО (Периодическое техническое освидетельствование)'),
        FaultCategory(id=8, name='КР (Капитальный ремонт, Ремонт)'),
        FaultCategory(id=9, name='С (Проблемы по связи)'),
        FaultCategory(id=10, name='Л (Ложный вызов)'),
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(FaultCategory).filter(FaultCategory.id == obj.id, FaultCategory.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_fault_category():
    for db in get_session():
        creation_list = check_fault_category(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_reason_fault(db: Session):
    check_list = [
        ReasonFault(id=1, name='Авария главного привода по УКСЛ.'),
        ReasonFault(id=2, name='АБЛ'),
        ReasonFault(id=3, name='Не сработал датчик УБ'),
        ReasonFault(id=4, name='NAV - не готов, очень серьезная ошибка'),
        ReasonFault(id=5, name='43 - не исправна цепь блокировки.'),
        ReasonFault(id=6, name='160 - проникновение в шахту.'),
        ReasonFault(id=7, name='28 - залипание верхних и нижних концевых выключателей.'),
        ReasonFault(id=8, name='17 - отсутствует сигнал от инвертора.'),
        ReasonFault(id=9, name='47 - многократный реверс.'),
        ReasonFault(id=10, name='41 - разрыв цепи безопасности.'),
        ReasonFault(id=11, name='72 - разомкнута KV-15 или выключателей ДК.'),
        ReasonFault(id=12, name='ТО'),
        ReasonFault(id=13, name='21 - время перемещения превышает заданное время.'),
        ReasonFault(id=14, name='10 - разрыв цепи аварийной опасности.'),
        ReasonFault(id=15, name='Нет Связи.'),
        ReasonFault(id=16, name='44 - Охрана шахты.'),
        ReasonFault(id=17, name='Сгорел блок обь.'),
        ReasonFault(id=18, name='Пожарная опасность.'),
        ReasonFault(id=19, name='5 - ошибка тормоза.'),
        ReasonFault(id=20, name='Перезапуск в присутствии механика.'),
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(ReasonFault).filter(ReasonFault.id == obj.id, ReasonFault.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_reason_fault():
    for db in get_session():
        creation_list = check_reason_fault(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_cost_type(db: Session):
    check_list = [
        CostType(id=1, name='С НДС'),
        CostType(id=2, name='Без НДС')]
    creation_list = []
    for obj in check_list:
        query = db.query(CostType).filter(CostType.id == obj.id, CostType.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_cost_type():
    for db in get_session():
        creation_list = check_cost_type(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def check_type_acts(db: Session):
    check_list = [
        TypeAct(id=1, name='ТО 1'),
        TypeAct(id=3, name='ТО 3'),
        TypeAct(id=6, name='ТО 6'),
        TypeAct(id=12, name='ТО 12'),
    ]
    creation_list = []
    for obj in check_list:
        query = db.query(TypeAct).filter(TypeAct.id == obj.id, TypeAct.name == obj.name).first()
        if query is None:
            creation_list.append(obj)
    return creation_list


def create_type_acts():
    for db in get_session():
        creation_list = check_type_acts(db)
        [db.add(obj) for obj in creation_list]
        db.commit()
        db.close()


def create_initial_data():
    try:
        create_roles()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ РОЛЕЙ: {ex}")
    try:
        create_statuses()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ СТАТУСОВ: {ex}")
    try:
        create_type_objects()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ ТИПЫ ТЕХНИКИ: {ex}")
    try:
        create_type_contracts()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ ТИПЫ КОНТРАКТЫ: {ex}")
    try:
        create_locations()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ ГОРОДОВ: {ex}")
    try:
        create_fault_category()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ КАТЕГОРИЙ НЕИСПРАВНОСТИ: {ex}")
    try:
        create_reason_fault()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ ПРИЧИН НЕИСПРАВНОСТИ: {ex}")
    try:
        create_type_acts()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ БАЗУ ДАННЫХ ДЛЯ ТИПОВ АКТОВ: {ex}")
    try:
        create_cost_type()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ В БАЗЕ ДАННЫХ ТИПЫ ЦЕН: {ex}")
    try:
        create_super_admin()
    except Exception as ex:
        print(f"НЕ СОЗДАЛ В БАЗЕ ДАННЫХ ТИПЫ ЦЕН: {ex}")
