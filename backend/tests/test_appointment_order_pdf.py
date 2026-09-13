"""PDF приказа о назначении: что напечатано, а не только что файл получился.

Текст после сборки в PDF лежит в подмножестве шрифта и обратно не читается,
поэтому проверяем story — те же абзацы, что уходят в документ.
"""

import datetime

import pytest
from reportlab.platypus import Paragraph, Table

from src.schemas.appointment_order import (
    AppointmentLift,
    AppointmentOrderDraft,
    AppointmentPerson,
)
from src.services.appointment_order_pdf import (
    build_appointment_order_pdf,
    build_appointment_order_story,
    format_lift,
    format_order_date,
    initials_first,
    initials_last,
)
from src.utils.time_stamp import to_timestamp


def _texts(story) -> str:
    """Весь текст листа одной строкой, включая содержимое таблиц."""
    chunks = []

    def walk(node):
        if isinstance(node, Paragraph):
            chunks.append(node.text)
        elif isinstance(node, Table):
            for row in node._cellvalues:
                for cell in row:
                    walk(cell)

    for item in story:
        walk(item)
    return "\n".join(chunks)


@pytest.fixture
def filled():
    """Приказ ПЭЛК №10 — как в образце, с двумя лифтами."""
    lift = dict(type="Лифт Пассажирский", brand="Wellmaks")
    return AppointmentOrderDraft(
        number="10",
        date=to_timestamp(datetime.date(2025, 11, 1)),
        city="Краснодар",
        address="Краснодарский край, г. Краснодар, ул. Кожевенная, 66",
        organization="ООО «ПЭЛК»",
        signer_position="Генеральный директор",
        signer_name="Разумовский Александр Сергеевич",
        foreman=AppointmentPerson(
            full_name="Фугенфиров Виталий Алексеевич",
            position="прораба сервисного участка",
        ),
        mechanic=AppointmentPerson(
            full_name="Разумовский Лев Сергеевич",
            position="электромеханика по лифтам",
        ),
        lifts=[
            AppointmentLift(load_capacity_kg=400, **lift),
            AppointmentLift(load_capacity_kg=630, **lift),
        ],
    )


def test_header_carries_number_date_and_city(filled):
    text = _texts(build_appointment_order_story(filled))

    assert "ПРИКАЗ № 10" in text
    assert "«01» ноября 2025 г." in text
    assert "г. Краснодар" in text
    assert "«О назначении ответственных лиц" in text


def test_basis_names_both_regulations(filled):
    text = _texts(build_appointment_order_story(filled))

    assert "ТР ТС 011/2011" in text
    assert "от 20 октября 2023 г. № 1744" in text
    assert "ПРИКАЗЫВАЮ:" in text


def test_both_appointments_share_one_equipment_list(filled):
    text = _texts(build_appointment_order_story(filled))

    assert "1. Назначить прораба сервисного участка Фугенфиров Виталий" in text
    assert "2. Назначить электромеханика по лифтам Разумовский Лев" in text
    assert "ул. Кожевенная, 66, и закрепить за ним" in text
    # Перечень дважды в скобках и дважды списком — один источник.
    assert text.count("Лифт Пассажирский, Wellmaks, г/п 400 кг.") == 4
    assert text.count("- Лифт Пассажирский, Wellmaks, г/п 630 кг.") == 2
    assert "3. Контроль за исполнением настоящего приказа оставляю за собой." in text


def test_signature_and_two_acknowledgements(filled):
    text = _texts(build_appointment_order_story(filled))

    assert "Генеральный директор ООО «ПЭЛК»" in text
    assert "А.С. Разумовский" in text
    assert text.count("С приказом ознакомлен:") == 2
    assert "Фугенфиров В. А." in text
    assert "Разумовский Л. С." in text


def test_empty_draft_prints_dashes_not_errors():
    story = build_appointment_order_story(
        AppointmentOrderDraft(date=to_timestamp(datetime.date(2026, 1, 1)), lifts=[])
    )
    text = _texts(story)

    assert "ПРИКАЗ № —" in text
    assert "г. —" in text
    assert "Назначить — —" in text
    assert "(—) находящегося по адресу: —," in text
    assert text.count("- —") == 2
    assert text.count("С приказом ознакомлен:") == 2


def test_formatters_follow_the_sample():
    assert initials_first("Разумовский Александр Сергеевич") == "А.С. Разумовский"
    assert initials_last("Фугенфиров Виталий Алексеевич") == "Фугенфиров В. А."
    assert initials_first("Мадонна") == "Мадонна"
    assert initials_last(None) == "—"
    assert format_order_date(to_timestamp(datetime.date(2025, 11, 1))) == (
        "«01» ноября 2025 г."
    )
    assert format_lift(AppointmentLift(load_capacity_kg=630)) == "г/п 630 кг."
    assert format_lift(AppointmentLift()) == "—"


def test_a_real_pdf_is_written(filled, tmp_path):
    out = tmp_path / "order.pdf"
    build_appointment_order_pdf(str(out), filled)

    assert out.read_bytes().startswith(b"%PDF")
