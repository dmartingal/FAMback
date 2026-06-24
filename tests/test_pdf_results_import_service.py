from datetime import date

from athletics_loader.db.models import Athlete, Category, Competition
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


class StatementCaptureDb(FakeDb):
    def __init__(self) -> None:
        super().__init__()
        self.statements = []

    def scalar(self, statement):
        self.statements.append(statement)
        return None


class RecordingCategoryService(PdfResultsImportService):
    def __init__(self) -> None:
        super().__init__()
        self.category_age_calls: list[tuple[int, bool]] = []
        self.category_id_calls: list[str | None] = []

    def _find_category_by_age(self, db, age: int, master_only: bool) -> Category | None:
        self.category_age_calls.append((age, master_only))
        return Category(
            id=10,
            code="MASTER-35" if master_only else "SUB-18",
            name="MASTER-35" if master_only else "SUB-18",
            min_age=35 if master_only else 16,
            max_age=39 if master_only else 17,
            is_master=master_only,
        )

    def _find_category_id(self, db, category: str | None) -> int | None:
        self.category_id_calls.append(category)
        return 99


def test_event_type_lookup_keys_accepts_thousands_separator_in_distance() -> None:
    assert _event_type_lookup_keys("1.000m") == ["1.000m", "1000m"]


def test_event_type_lookup_keys_compacts_implement_spacing_and_decimal_comma() -> None:
    assert _event_type_lookup_keys("peso (6 kg)") == ["peso (6 kg)", "peso(6kg)"]
    assert _event_type_lookup_keys("peso (7,260 kg)") == ["peso (7,260 kg)", "peso(7.260kg)"]


def test_event_type_lookup_keys_compacts_hurdles_spacing_and_decimal_comma() -> None:
    assert _event_type_lookup_keys("60m vallas (0,762)") == [
        "60m vallas (0,762)",
        "60m vallas(0.762)",
        "60mv(0.762)",
    ]


def test_event_type_lookup_keys_ignores_trailing_separator_from_pdf_header() -> None:
    assert _event_type_lookup_keys("60m vallas (0,91) -") == [
        "60m vallas (0,91) -",
        "60m vallas (0,91)",
        "60m vallas(0.91)",
        "60mv(0.91)",
    ]


def test_event_type_lookup_keys_compacts_distance_spacing_without_alias() -> None:
    assert _event_type_lookup_keys("1.000 m") == ["1.000 m", "1.000m", "1000m"]


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


def test_filter_results_by_club_keeps_only_matching_normalized_club() -> None:
    service = PdfResultsImportService(only_club_name="Atletismo Los Angeles Villaverde")
    results = [
        {"athlete": "A", "club": "Atletismo Los Angeles Villaverde"},
        {"athlete": "B", "club": "A.D. Marathon"},
        {"athlete": "C", "club": None},
    ]

    assert service._filter_results_by_club(results) == [results[0]]


def test_filter_results_by_club_without_filter_keeps_all_results() -> None:
    results = [
        {"athlete": "A", "club": "Atletismo Los Angeles Villaverde"},
        {"athlete": "B", "club": "A.D. Marathon"},
    ]

    assert PdfResultsImportService()._filter_results_by_club(results) == results


def test_filter_relay_members_by_groups_keeps_only_imported_relay_groups() -> None:
    service = PdfResultsImportService(only_club_name="Atletismo Los Angeles Villaverde")
    members = [
        {"relay_group": 1, "athlete_name": "A"},
        {"relay_group": 2, "athlete_name": "B"},
        {"relay_group": None, "athlete_name": "C"},
    ]

    assert service._filter_relay_members_by_groups(members, {2: 10}) == [members[1]]


def test_resolve_result_category_uses_competition_year_age_for_non_master() -> None:
    service = RecordingCategoryService()
    competition = Competition(
        name="Control",
        name_normalized="control",
        competition_date=date(2026, 5, 2),
    )
    athlete = Athlete(
        full_name="Maria Gomez",
        full_name_normalized="MARIA GOMEZ",
        birth_date=date(2010, 6, 1),
        gender="F",
    )

    category_id = service._resolve_result_category_id(
        FakeDb(),
        {"category_text": "SENIOR/ABSOLUTA"},
        competition,
        athlete,
        {},
    )

    assert category_id == 10
    assert service.category_age_calls == [(16, False)]


def test_resolve_result_category_uses_exact_age_for_master() -> None:
    service = RecordingCategoryService()
    competition = Competition(
        name="Control",
        name_normalized="control",
        competition_date=date(2026, 5, 2),
    )
    athlete = Athlete(
        full_name="Maria Gomez",
        full_name_normalized="MARIA GOMEZ",
        birth_date=date(1987, 6, 1),
        gender="F",
    )

    category_id = service._resolve_result_category_id(
        FakeDb(),
        {"category_text": "SENIOR/ABSOLUTA"},
        competition,
        athlete,
        {},
    )

    assert category_id == 10
    assert service.category_age_calls == [(38, True)]


def test_resolve_result_category_keeps_explicit_concrete_result_category() -> None:
    service = RecordingCategoryService()
    competition = Competition(
        name="Control",
        name_normalized="control",
        competition_date=date(2026, 5, 2),
    )

    category_id = service._resolve_result_category_id(
        FakeDb(),
        {"category_text": "SENIOR/ABSOLUTA"},
        competition,
        None,
        {"category_text": "SUB-18"},
    )

    assert category_id == 99
    assert service.category_id_calls == ["SUB-18"]
    assert service.category_age_calls == []


def test_get_or_create_competition_event_matches_by_category_id() -> None:
    db = StatementCaptureDb()
    competition = Competition(
        id=1,
        name="Control",
        name_normalized="control",
        competition_date=date(2026, 6, 13),
    )
    source = type("Source", (), {"id": 7})()

    PdfResultsImportService()._get_or_create_competition_event(
        db,
        competition,
        source,
        {
            "event_datetime": "2026-06-13T19:25:00",
            "event_name": "1.500m",
            "sex": "M",
            "round_name": "Serie 6",
        },
        category_id=45,
    )

    compiled_query = str(db.statements[-1].compile(compile_kwargs={"literal_binds": True}))
    assert "competition_events.category_id = 45" in compiled_query
