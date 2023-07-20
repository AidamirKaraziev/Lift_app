from app.exceptions import UnprocessableEntity, InaccessibleEntity, UnfoundEntity


email_already_have = -100
location_not_found = -101

role_not_found = -102
role_incorrectly_selected = -1021  # неправильно выбрано, попытка создать клиента
role_without_access = -1022  # недостаточно прав
role_no_rights = -1023  # нет прав
role_changeable_list = -1024  # Не входит в список меняемых пользователей

working_specialty_not_found = -103

division_not_found = -104
division_not_none = -1041  # уже существует такой
division_cannot_be_assigned_to_this_user = -1042  # нельзя назначить этому пользователю
division_is_not_actual = -1043  # НЕ АКТУАЛЬНЫЙ УЧАСТОК

user_not_found = -105

company_not_found = -106
company_already_exists = -1061  # Такая компания уже есть

not_is_actual = -107
not_attribute_in_model = -108

checked_items_is_not_in_the_list = -109  # Одного из проверяемых элементов нет в проверяемом списке

type_contract_not_found = -110
cost_type_not_found = -111

contract_name_is_exists = -112  # Договор с таким названием существует
contract_not_found = -1121  # нет договора

contact_person_not_found = -113
# contract_person_phone_is_exists = 1131  # Контактное лицо с таким названием существует

organization_not_found = -114
organization_title_is_exist = -1141  # с таким названием уже есть

factory_model_not_found = -115
factory_model_is_exist = -1151
# factory_number_is_exist = -117

object_not_found = -116

registration_number_is_exist = -118

foreman_not_found = -119
mechanic_not_found = -120

act_base_not_found = -121
act_base_uc_factory_mode_id_and_type_act_id_is_exist = -1211

type_act_not_found = -122

act_fact_not_found = -123

status_not_found = -124

step_not_found = -125
step_name_is_exist = -1251

sub_step_not_found = -126
sub_step_name_is_exist = -1261

fault_category_not_found = -127
fault_category_name_is_exist = -1271

reason_fault_not_found = -128
reason_fault_name_is_exist = -1281


def get_raise(code: int):
    if code == -100:
        raise InaccessibleEntity(
            message="Пользователь с таким email уже есть!",
            num=100,
            description="Укажите другой email, для регистрации",
            path="$.body"
        )
    if code == -101:
        raise UnfoundEntity(
            message="Такого города не существует!",
            num=101,
            description="Выберете существующий город!",
            path="$.body"
        )
    if code == -102:
        raise UnfoundEntity(
            message="Такой Должности нет!",
            num=102,
            description="Выберете существующую должность!",
            path="$.body"
        )
    if code == -1021:
        raise InaccessibleEntity(
            message="Неправильно выбрана должность!",
            num=1021,
            description="Выберете правильную должность!!",
            path="$.body"
        )
    if code == -1022:
        raise InaccessibleEntity(
            message="Пользователь не обладает правами!",
            num=1022,
            description="Пользователь не обладает правами, к созданию других пользователей!",
            path="$.body"
        )
    if code == -1023:
        raise InaccessibleEntity(
            message="Вы не обладаете правами!",
            num=1023,
            description="Пользователь не обладает правами!",
            path="$.body"
        )
    if code == -1024:
        raise InaccessibleEntity(
            message="Этого пользователя нет в изменяемом списке!",
            num=1024,
            description="Этого пользователя нет в изменяемом списке!",
            path="$.body"
        )
    if code == -103:
        raise UnfoundEntity(
            message="Такой Специальности нет!",
            num=103,
            description="Выберете существующую Специальность!",
            path="$.body"
        )
    if code == -104:
        raise UnfoundEntity(
            message="Такого Участка нет!",
            num=104,
            description="Выберете существующую Участок или создайте новую!",
            path="$.body"
        )
    # if code == -1041:
    #     raise UnprocessableEntity(
    #         message="Н!",
    #         num=2,
    #         description="Выберите другое название сферы деятельности!",
    #         path="$.body"
    #     )
    if code == -1042:
        raise UnprocessableEntity(
            message="Нельзя назначить этому пользователю участок!",
            num=1042,
            description="Нельзя назначить этому пользователю участок!",
            path="$.body"
        )
    if code == -1043:
        raise UnprocessableEntity(
            message="Участок не актуален!",
            num=1043,
            description="Участок был удален или заморожен!",
            path="$.body"
        )
    if code == -105:
        raise UnfoundEntity(
            message="Нет такого пользователя!",
            num=105,
            description="Нет пользователя с таким id!",
            path="$.body"
        )
    if code == -106:
        raise UnfoundEntity(
            message="Такой компании нет!",
            num=106,
            description="Выберете существующую Компанию или создайте новую!",
            path="$.body"
        )
    if code == -1061:
        raise UnprocessableEntity(
            message="Такая компания уже есть в базе данных",
            num=1,
            description="Компания с таким названием уже есть в базе данных!",
            path="$.body"
        )
    if code == -107:
        raise UnprocessableEntity(
            message="Пользователь не актуален!",
            num=107,
            description="Статус пользователя не актуален, возможно его удалили!",
            path="$.body"
        )

    if code == -108:
        raise UnprocessableEntity(
            message="Модель в базе данных не имеет такого атрибута для файла!",
            num=108,
            description="Модель в базе данных не имеет такого атрибута для файла!",
            path="$.body"
        )
    if code == -109:
        raise UnprocessableEntity(
            message="Один из проверяемых элементов отсутствует в списке",
            num=109,
            description="Один из проверяемых элементов отсутствует в списке",
            path="$.body"
        )
    if code == -110:
        raise UnfoundEntity(
            message="Такого типа Договоров нет!!",
            num=110,
            description="Выберете существующий тип Договорив!",
            path="$.body"
        )
    if code == -111:
        raise UnfoundEntity(
            message="Такого типа Цен нет!!",
            num=111,
            description="Выберете существующий тип Цен!",
            path="$.body"
        )
    if code == -112:
        raise InaccessibleEntity(
            message="Договор с таким названием существует!",
            num=112,
            description="Договор с таким названием существует!",
            path="$.body"
        )
    if code == -1121:
        raise UnfoundEntity(
            message="Договора не существует!",
            num=1121,
            description="Договора не существует!",
            path="$.body"
        )
    if code == -113:
        raise UnfoundEntity(
            message="Контактного лица не существует!",
            num=113,
            description="Контактного лица не существует!",
            path="$.body"
        )
    if code == -114:
        raise UnfoundEntity(
            message="Организации не существует!",
            num=114,
            description="Выберете существующую организацию!",
            path="$.body"
        )
    if code == -1141:
        raise InaccessibleEntity(
            message="Организация с таким названием существует!",
            num=1141,
            description="Организация с таким названием существует!",
            path="$.body"
        )
    if code == -115:
        raise UnfoundEntity(
            message="Такой модели техники не существует!",
            num=115,
            description="Выберете существующую Модель техники!",
            path="$.body"
        )
    if code == -1151:
        raise InaccessibleEntity(
            message="Модель техники с таким названием уже существует!",
            num=1151,
            description="Модель техники с таким названием уже существует!",
            path="$.body"
        )
    if code == -116:
        raise UnfoundEntity(
            message="Такого объекта не существует!",
            num=116,
            description="Выберете существующий Объект!",
            path="$.body"
        )
    # if code == -117:
    #     raise UnfoundEntity(
    #         message="Техника с таким заводским номером уже есть!",
    #         num=117,
    #         description="Техника с таким заводским номером уже есть!",
    #         path="$.body"
    #     )
    if code == -118:
        raise InaccessibleEntity(
            message="Техника с таким регистрационным номером уже есть",
            num=118,
            description="Техника с таким регистрационным номером уже есть",
            path="$.body"
        )
    if code == -119:
        raise UnfoundEntity(
            message="Такого прораба не существует!",
            num=119,
            description="Выберете существующего прораба",
            path="$.body"
        )
    if code == -120:
        raise UnfoundEntity(
            message="Такого механика не существует!",
            num=120,
            description="Выберете существующего механика!",
            path="$.body"
        )
    if code == -121:
        raise UnfoundEntity(
            message="Такого Шаблона Актов не существует!",
            num=121,
            description="Выберете существующий Шаблон Актов!",
            path="$.body"
        )
    if code == -1211:
        raise InaccessibleEntity(
            message="В базе данных уже есть act_base с уникальными полями",
            num=1211,
            description="В базе данных уже есть act_base с уникальными полями",
            path="$.body"
        )
    if code == -122:
        raise UnfoundEntity(
            message="Такого Типа Актов не существует!",
            num=122,
            description="Выберете существующий Тип Актов!",
            path="$.body"
        )
    if code == -123:
        raise UnfoundEntity(
            message="Такого фактического акта не существует!",
            num=123,
            description="Выберете существующий Фактический акт!",
            path="$.body"
        )
    if code == -124:
        raise UnfoundEntity(
            message="Такого статуса не существует!",
            num=124,
            description="Выберете существующий статус!",
            path="$.body"
        )
    if code == -1251:
        raise InaccessibleEntity(
            message="Этап с таким названием уже есть!",
            num=1251,
            description="Этап с таким названием уже есть!",
            path="$.body"
        )
    if code == -125:
        raise UnfoundEntity(
            message="Такого этапа не существует!",
            num=125,
            description="Выберете существующий этап!",
            path="$.body"
        )
    if code == -126:
        raise UnfoundEntity(
            message="Такого подэтапа не существует!",
            num=126,
            description="Выберете существующий подэтап!",
            path="$.body"
        )
    if code == -1261:
        raise InaccessibleEntity(
            message="Подэтап с таким названием уже есть!",
            num=1261,
            description="Подэтап с таким названием уже есть!",
            path="$.body"
        )
    if code == -127:
        raise UnfoundEntity(
            message="Такой категории неисправности не существует!",
            num=127,
            description="Выберете существующую категорию неисправности!",
            path="$.body"
        )
    if code == -1271:
        raise UnprocessableEntity(
            message="Категория неисправности с таким названием уже есть!",
            num=1271,
            description="Категория неисправности с таким названием уже есть!",
            path="$.body"
        )
    if code == -128:
        raise UnfoundEntity(
            message="Такой причина неисправности не существует!",
            num=128,
            description="Выберете существующую причину неисправности!",
            path="$.body"
        )
    if code == -1281:
        raise UnprocessableEntity(
            message="Причина неисправности с таким названием уже есть!",
            num=1281,
            description="Причина неисправности с таким названием уже есть!",
            path="$.body"
        )
    if code != 0:
        raise UnfoundEntity(
            message=f"АЙДАМИР ВНЕСИ RAISE {code}",
            num=999,
            description=f"АЙДАМИР ВНЕСИ RAISE {code}",
            path="$.body"
            )
