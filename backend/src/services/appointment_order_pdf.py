"""Генерация PDF «Приказ о назначении ответственных» (ReportLab).

Текст приказа — дословно образец заказчика, ПЭЛК №10 от 01.11.2025
(`els-vault/knowledge/business/образцы/`): шапка с номером, датой и городом,
основание со ссылками на ТР ТС 011/2011 и ПП РФ № 1744, два назначения —
прораб и электромеханик — с одним и тем же перечнем оборудования, подпись
директора и две строки «С приказом ознакомлен».

Здесь нет ни базы, ни HTTP: на вход приходит правленый черновик из диалога
(`AppointmentOrderDraft`), и всё, чего в нём нет, печатается прочерком, а не
ошибкой — приказ без механика всё равно можно посмотреть и дописать ручкой.
Шрифт с кириллицей ищется так же, как у дефектной ведомости.
"""

from __future__ import annotations

import os
from datetime import datetime
from xml.sax.saxutils import escape

from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from src.schemas.appointment_order import (
    AppointmentLift,
    AppointmentOrderDraft,
    AppointmentPerson,
)

# Корень репозитория: src/services -> два уровня вверх
_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

_FONT_REGISTERED = False
_FONT_NAME = "AppointmentOrderNoto"

#: Чем заполняется пустое поле: прочерк читается как «нечего писать», а
#: пустое место — как «забыли заполнить».
_DASH = "—"

#: Заголовок и основание — дословно из образца. Менять только вместе с ним.
TITLE = (
    "«О назначении ответственных лиц за исправное состояние и проведение "
    "технического обслуживания оборудования»"
)
BASIS = (
    "В целях обеспечения исправного состояния и надлежащей организации работ "
    "по техническому обслуживанию Лифта, а также в соответствии с Техническим "
    "регламентом Таможенного союза ТР ТС 011/2011, Правилами организации "
    "безопасного использования и содержания лифтов, подъемных платформ для "
    "инвалидов, пассажирских конвейеров (движущихся пешеходных дорожек) и "
    "эскалаторов, за исключением эскалаторов в метрополитенах, утвержденных "
    "постановлением Правительства Российской Федерации от 20 октября 2023 г. "
    "№ 1744 и иными нормативно - правовыми актами"
)
FOREMAN_DUTY = (
    "специалистом, ответственным за организацию выполнения работ по "
    "техническому обслуживанию и ремонту оборудования"
)
MECHANIC_DUTY = (
    "ответственным за исправное состояние и проведение технического "
    "обслуживания оборудования"
)
CONTROL = "Контроль за исполнением настоящего приказа оставляю за собой."
ACKNOWLEDGED = "С приказом ознакомлен:"

_MONTHS_GENITIVE = [
    "января",
    "февраля",
    "марта",
    "апреля",
    "мая",
    "июня",
    "июля",
    "августа",
    "сентября",
    "октября",
    "ноября",
    "декабря",
]


def _resolve_font_path() -> str | None:
    candidates = [
        os.path.join(_REPO_ROOT, "static", "fonts", "NotoSans-Regular.ttf"),
        os.path.join(_REPO_ROOT, "static", "fonts", "DejaVuSans.ttf"),
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for p in candidates:
        if p and os.path.isfile(p):
            return os.path.abspath(p)
    return None


def _ensure_font() -> str:
    global _FONT_REGISTERED
    if _FONT_REGISTERED:
        return _FONT_NAME
    path = _resolve_font_path()
    if path:
        pdfmetrics.registerFont(TTFont(_FONT_NAME, path))
        _FONT_REGISTERED = True
        return _FONT_NAME
    return "Helvetica"


def _val(text: str | None) -> str:
    """Значение поля или прочерк."""
    return (text or "").strip() or _DASH


def format_order_date(ts: int) -> str:
    """«01» ноября 2025 г. — как в шапке образца.

    Метка читается по местному времени, зеркально `to_timestamp`, которым её
    собрал черновик: `date_from_timestamp` считает по UTC, и восточнее
    Гринвича полночь первого числа превращалась бы в тридцать первое.
    """
    d = datetime.fromtimestamp(ts).date()
    return f"«{d.day:02d}» {_MONTHS_GENITIVE[d.month - 1]} {d.year} г."


def _split_name(full_name: str) -> list[str]:
    return [part for part in (full_name or "").split() if part]


def initials_first(full_name: str | None) -> str:
    """«А.С. Разумовский» — подпись директора в образце."""
    parts = _split_name(full_name)
    if not parts:
        return _DASH
    if len(parts) == 1:
        return parts[0]
    initials = "".join(f"{p[0]}." for p in parts[1:])
    return f"{initials} {parts[0]}"


def initials_last(full_name: str | None) -> str:
    """«Фугенфиров В. А.» — строки «ознакомлен» в образце."""
    parts = _split_name(full_name)
    if not parts:
        return _DASH
    if len(parts) == 1:
        return parts[0]
    initials = " ".join(f"{p[0]}." for p in parts[1:])
    return f"{parts[0]} {initials}"


def format_lift(lift: AppointmentLift) -> str:
    """«Лифт Пассажирский, Wellmaks, г/п 400 кг.» — пустые части пропускаем."""
    parts = []
    if (lift.type or "").strip():
        parts.append(lift.type.strip())
    if (lift.brand or "").strip():
        parts.append(lift.brand.strip())
    if lift.load_capacity_kg is not None:
        parts.append(f"г/п {lift.load_capacity_kg} кг.")
    return ", ".join(parts) or _DASH


def _person_line(person: AppointmentPerson | None) -> str:
    """«прораба сервисного участка Иванов Иван Иванович» — как пришло.

    Должность черновик отдаёт уже в родительном падеже, а ФИО склонять
    сервер не умеет: человек правит его в диалоге, а не после сборки.
    """
    if person is None:
        return f"{_DASH} {_DASH}"
    return f"{_val(person.position)} {_val(person.full_name)}"


def _appointment_text(
    person: AppointmentPerson | None,
    duty: str,
    equipment: list[str],
    address: str | None,
) -> str:
    listed = " ".join(equipment) if equipment else _DASH
    return (
        f"Назначить {_person_line(person)} {duty} ({listed}) находящегося по "
        f"адресу: {_val(address)}, и закрепить за ним следующее оборудование:"
    )


#: Поля страницы: по ним считается ширина содержимого для таблиц шапки и
#: подписей.
_MARGIN_X = 20 * mm
_MARGIN_Y = 18 * mm


def _inner_width() -> float:
    w, _ = A4
    return w - 2 * _MARGIN_X


def build_appointment_order_story(
    draft: AppointmentOrderDraft, inner_w: float | None = None
) -> list:
    """Содержимое листа в порядке образца.

    Отделено от записи файла, чтобы проверять напечатанный текст: после
    сборки в PDF он лежит в подмножестве шрифта и обратно не читается.
    """
    font = _ensure_font()
    if inner_w is None:
        inner_w = _inner_width()

    styles = getSampleStyleSheet()
    base = dict(parent=styles["Normal"], fontName=font, fontSize=11, leading=15)
    title_style = ParagraphStyle(
        name="OrderTitle",
        **{**base, "fontSize": 14, "leading": 18},
        alignment=TA_CENTER,
        spaceAfter=8,
    )
    left_style = ParagraphStyle(name="OrderLeft", **base, alignment=TA_LEFT)
    right_style = ParagraphStyle(name="OrderRight", **base, alignment=TA_RIGHT)
    center_style = ParagraphStyle(
        name="OrderCenter", **base, alignment=TA_CENTER, spaceBefore=6, spaceAfter=6
    )
    body_style = ParagraphStyle(
        name="OrderBody", **base, alignment=TA_JUSTIFY, spaceAfter=6
    )
    item_style = ParagraphStyle(
        name="OrderItem", **base, alignment=TA_LEFT, leftIndent=8 * mm, spaceAfter=2
    )

    def p(text: str, style: ParagraphStyle) -> Paragraph:
        return Paragraph(escape(text), style)

    def two_columns(left: Paragraph, right: Paragraph) -> Table:
        table = Table([[left, right]], colWidths=[inner_w * 0.5, inner_w * 0.5])
        table.setStyle(
            TableStyle(
                [
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 0),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                ]
            )
        )
        return table

    equipment = [format_lift(lift) for lift in draft.lifts]
    # В скобках образца лифты перечислены через точку с пробелом, в списке —
    # с маркером; и там и там один перечень.
    in_brackets = [f"{item}." if not item.endswith(".") else item for item in equipment]

    story: list = []
    story.append(p(f"ПРИКАЗ № {_val(draft.number)}", title_style))
    story.append(
        two_columns(
            p(format_order_date(draft.date), left_style),
            p(f"г. {_val(draft.city)}", right_style),
        )
    )
    story.append(Spacer(1, 6 * mm))
    story.append(p(TITLE, center_style))
    story.append(p(BASIS, body_style))
    story.append(p("ПРИКАЗЫВАЮ:", center_style))

    for number, (person, duty) in enumerate(
        [(draft.foreman, FOREMAN_DUTY), (draft.mechanic, MECHANIC_DUTY)], start=1
    ):
        story.append(
            p(
                f"{number}. "
                + _appointment_text(person, duty, in_brackets, draft.address),
                body_style,
            )
        )
        for item in equipment or [_DASH]:
            story.append(p(f"- {item}", item_style))
        story.append(Spacer(1, 3 * mm))

    story.append(p(f"3. {CONTROL}", body_style))
    story.append(Spacer(1, 14 * mm))

    line = "_" * 22
    signer = " ".join(
        part for part in (draft.signer_position, draft.organization) if part
    )
    story.append(
        two_columns(
            p(_val(signer), left_style),
            p(f"{line} {initials_first(draft.signer_name)}", right_style),
        )
    )
    story.append(Spacer(1, 12 * mm))

    for person in (draft.foreman, draft.mechanic):
        name = initials_last(person.full_name) if person is not None else _DASH
        story.append(
            two_columns(p(ACKNOWLEDGED, left_style), p(f"{line} {name}", right_style))
        )
        story.append(Spacer(1, 6 * mm))

    return story


def build_appointment_order_pdf(output_path: str, draft: AppointmentOrderDraft) -> None:
    """Собирает PDF приказа по правленому черновику."""
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=_MARGIN_X,
        rightMargin=_MARGIN_X,
        topMargin=_MARGIN_Y,
        bottomMargin=_MARGIN_Y,
    )
    doc.build(build_appointment_order_story(draft, _inner_width()))
