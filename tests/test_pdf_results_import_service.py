from datetime import date

from athletics_loader.db.models import Athlete
from athletics_loader.services.pdf_results_import_service import PdfResultsImportService, _event_type_lookup_keys


class FakeDb:
    def __init__(self, athlete: Athlete | None = None) -> None:
        self.athlete = athlete
        self.added = []

    def scalar(self, _statement):
        return self.athlete

    def add(self, value) -> None:
        self.added.append(value)
        self.athlete = value

    def flush(self) -> None:
        pass


def test_event_type_lookup_keys_accepts_thousands_separator_in_distance() -> None:
    assert _event_type_lookup_keys("1.000m") == ["1.000m", "1000m"]


def test_event_type_lookup_keys_does_not_strip_implement_decimals() -> None:
    assert _event_type_lookup_keys("60m vallas (0.762)") == ["60m vallas (0.762)"]


def test_get_or_create_athlete_creates_without_birth_date() -> None:
    db = FakeDb()
    athlete, warnings = PdfResultsImportService()._get_or_create_athlete(
        db,
        {"athlete": "Maria Gomez Garcia", "birth_date": None, "license": "M33745"},
        "F",
    )

    assert warnings == []
    assert athlete.full_name_normalized == "MARIA GOMEZ GARCIA"
    assert athlete.birth_date is None
    assert athlete.current_license == "M33745"
    assert db.added == [athlete]


def test_get_or_create_athlete_updates_missing_birth_date() -> None:
    existing = Athlete(
        full_name="Maria Gomez Garcia",
        full_name_normalized="MARIA GOMEZ GARCIA",
        birth_date=None,
        gender="F",
        current_license="M33745",
        current_license_normalized="m33745",
    )
    db = FakeDb(existing)

    athlete, warnings = PdfResultsImportService()._get_or_create_athlete(
        db,
        {"athlete": "Maria Gomez Garcia", "birth_date": "2010-01-02", "license": "M33745"},
        "F",
    )

    assert athlete is existing
    assert warnings == []
    assert athlete.birth_date == date(2010, 1, 2)


def test_get_or_create_athlete_warns_on_birth_date_conflict_without_overwriting() -> None:
    existing = Athlete(
        full_name="Maria Gomez Garcia",
        full_name_normalized="MARIA GOMEZ GARCIA",
        birth_date=date(2010, 1, 2),
        gender="F",
        current_license="M33745",
        current_license_normalized="m33745",
    )
    db = FakeDb(existing)

    athlete, warnings = PdfResultsImportService()._get_or_create_athlete(
        db,
        {"athlete": "Maria Gomez Garcia", "birth_date": "2011-03-04", "license": "M99999"},
        "F",
    )

    assert athlete is existing
    assert athlete.birth_date == date(2010, 1, 2)
    assert athlete.current_license == "M99999"
    assert [warning[0] for warning in warnings] == ["ATHLETE_BIRTH_DATE_CONFLICT", "ATHLETE_LICENSE_CHANGED"]
