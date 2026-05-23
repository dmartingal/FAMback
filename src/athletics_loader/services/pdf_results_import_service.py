from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from athletics_loader.db.models import (
    Athlete,
    AthleteClub,
    AthleteLicense,
    Category,
    Club,
    Competition,
    CompetitionEvent,
    EventType,
    EventTypeAlias,
    ImportError,
    Result,
    ResultAttempt,
    SourceFile,
)
from athletics_loader.db.session import SessionLocal
from athletics_loader.pdf.pdf_reader import extract_text_pages
from athletics_loader.pdf.parsers.fam_results_parser import FamResultsParser
from athletics_loader.utils.hashes import sha256_file
from athletics_loader.utils.marks import infer_mark_unit, parse_mark_numeric
from athletics_loader.utils.text import normalize_name


class PdfResultsImportService:
    def __init__(self) -> None:
        self._missing_event_type_aliases: set[tuple[str, str]] = set()

    def import_dir(self, pdf_dir: Path) -> list[dict]:
        self._missing_event_type_aliases.clear()
        parser = FamResultsParser()
        out = []
        for pdf_path in sorted(pdf_dir.glob("*.pdf")):
            file_hash = sha256_file(pdf_path)
            pages = extract_text_pages(pdf_path)
            valid = parser.can_parse(pdf_path, pages)
            parsed = parser.parse(pdf_path, pages) if valid else {"pages": len(pages)}

            with SessionLocal() as db:
                existing = db.scalar(select(SourceFile).where(SourceFile.file_hash == file_hash))
                if existing and existing.status == "PROCESSED":
                    out.append({"filename": pdf_path.name, "hash": file_hash, "status": "SKIPPED"})
                    continue

                source = existing or SourceFile(
                    filename=pdf_path.name,
                    file_path=str(pdf_path),
                    file_hash=file_hash,
                    status="PENDING",
                )
                source.filename = pdf_path.name
                source.file_path = str(pdf_path)
                source.pages_count = len(pages)
                source.error_message = None
                db.add(source)
                db.flush()

                if not valid:
                    self._add_import_error(db, source, None, None, "UNSUPPORTED_PDF", "No se ha detectado formato FAM soportado")
                    source.status = "IGNORED"
                    source.processed_at = datetime.now()
                    db.commit()
                    out.append({"filename": pdf_path.name, "hash": file_hash, "status": source.status, "parsed": parsed})
                    continue

                summary = self._import_parsed(db, source, parsed)
                source.status = "PROCESSED" if summary["errors"] == 0 else "PARTIAL"
                source.processed_at = datetime.now()
                source.error_message = None if summary["errors"] == 0 else f"{summary['errors']} errores de importación"
                db.commit()
                out.append(
                    {
                        "filename": pdf_path.name,
                        "hash": file_hash,
                        "status": source.status,
                        "summary": summary,
                    }
                )
        return out

    def _import_parsed(self, db: Session, source: SourceFile, parsed: dict) -> dict:
        summary = {"events": 0, "results": 0, "attempts": 0, "errors": 0}
        competition = self._get_or_create_competition(db, parsed.get("competition", {}), source)

        for event in parsed.get("events", []):
            competition_event = self._get_or_create_competition_event(db, competition, source, event)
            summary["events"] += 1

            for line in event.get("unparsed_lines", []):
                self._add_import_error(
                    db,
                    source,
                    event.get("page_number"),
                    line,
                    "UNPARSED_LINE",
                    "No se ha podido interpretar la línea del bloque de resultados",
                )
                summary["errors"] += 1

            for result in event.get("results", []):
                if not result.get("birth_date") or not result.get("athlete_key"):
                    self._add_import_error(
                        db,
                        source,
                        event.get("page_number"),
                        result.get("raw_text"),
                        "MISSING_BIRTH_DATE",
                        "No se inserta el atleta porque el PDF no aporta fecha de nacimiento",
                    )
                    summary["errors"] += 1
                    continue

                club = self._get_or_create_club(db, result.get("club"))
                athlete = self._get_or_create_athlete(db, result, event.get("sex"))
                if result.get("license"):
                    self._get_or_create_athlete_license(db, athlete, result["license"], source, competition)
                if club:
                    self._get_or_create_athlete_club(db, athlete, club, source, competition)

                db_result = self._get_or_create_result(db, competition_event, athlete, club, source, event, result)
                summary["results"] += 1
                for attempt in result.get("attempts", []):
                    self._get_or_create_attempt(db, db_result, attempt)
                    summary["attempts"] += 1

        return summary

    def _get_or_create_competition(self, db: Session, data: dict, source: SourceFile) -> Competition:
        name = data.get("name") or source.filename
        venue = data.get("venue_original")
        competition_date = _parse_iso_date(data.get("competition_date")) or date.today()
        name_normalized = _db_normalized(name)
        venue_normalized = _db_normalized(venue) if venue else None

        competition = db.scalar(
            select(Competition).where(
                Competition.name_normalized == name_normalized,
                Competition.competition_date == competition_date,
                Competition.venue_normalized == venue_normalized,
            )
        )
        if not competition:
            competition = Competition(
                name=name,
                name_normalized=name_normalized,
                venue=venue,
                venue_normalized=venue_normalized,
                competition_date=competition_date,
                source_name=source.filename,
            )
            db.add(competition)
            db.flush()
        return competition

    def _get_or_create_club(self, db: Session, name: str | None) -> Club | None:
        if not name:
            return None
        normalized = _db_normalized(name)
        club = db.scalar(select(Club).where(Club.name_normalized == normalized))
        if not club:
            club = Club(name=name, name_normalized=normalized)
            db.add(club)
            db.flush()
        return club

    def _get_or_create_athlete(self, db: Session, result: dict, gender: str | None) -> Athlete:
        athlete_key = result["athlete_key"]
        athlete = db.scalar(select(Athlete).where(Athlete.athlete_key == athlete_key))
        license_code = result.get("license")
        license_normalized = _db_normalized(license_code) if license_code else None
        if not athlete:
            athlete = Athlete(
                full_name=result["athlete"],
                full_name_normalized=normalize_name(result["athlete"]),
                birth_date=_parse_iso_date(result["birth_date"]),
                gender=gender,
                current_license=license_code,
                current_license_normalized=license_normalized,
                athlete_key=athlete_key,
            )
            db.add(athlete)
            db.flush()
        else:
            athlete.gender = athlete.gender or gender
            if license_code:
                athlete.current_license = license_code
                athlete.current_license_normalized = license_normalized
        return athlete

    def _get_or_create_athlete_license(
        self,
        db: Session,
        athlete: Athlete,
        license_code: str,
        source: SourceFile,
        competition: Competition,
    ) -> AthleteLicense:
        normalized = _db_normalized(license_code)
        athlete_license = db.scalar(
            select(AthleteLicense).where(
                AthleteLicense.athlete_id == athlete.id,
                AthleteLicense.license_normalized == normalized,
            )
        )
        if not athlete_license:
            athlete_license = AthleteLicense(
                athlete_id=athlete.id,
                license=license_code,
                license_normalized=normalized,
                source_file_id=source.id,
                competition_id=competition.id,
            )
            db.add(athlete_license)
            db.flush()
        return athlete_license

    def _get_or_create_athlete_club(
        self,
        db: Session,
        athlete: Athlete,
        club: Club,
        source: SourceFile,
        competition: Competition,
    ) -> AthleteClub:
        athlete_club = db.scalar(
            select(AthleteClub).where(
                AthleteClub.athlete_id == athlete.id,
                AthleteClub.club_id == club.id,
                AthleteClub.competition_id == competition.id,
            )
        )
        if not athlete_club:
            athlete_club = AthleteClub(
                athlete_id=athlete.id,
                club_id=club.id,
                competition_id=competition.id,
                source_file_id=source.id,
            )
            db.add(athlete_club)
            db.flush()
        return athlete_club

    def _get_or_create_competition_event(
        self,
        db: Session,
        competition: Competition,
        source: SourceFile,
        event: dict,
    ) -> CompetitionEvent:
        event_datetime = _parse_datetime(event.get("event_datetime"))
        category_id = self._find_category_id(db, event.get("category_text"))
        event_type_id = self._find_event_type_id(db, event.get("event_name"))
        wind = _decimal_or_none(event.get("wind"))

        competition_event = db.scalar(
            select(CompetitionEvent).where(
                CompetitionEvent.competition_id == competition.id,
                CompetitionEvent.event_name_original == event.get("event_name"),
                CompetitionEvent.gender == event.get("sex"),
                CompetitionEvent.round_name == event.get("round_name"),
                CompetitionEvent.event_datetime == event_datetime,
                CompetitionEvent.source_file_id == source.id,
            )
        )
        if not competition_event:
            competition_event = CompetitionEvent(
                competition_id=competition.id,
                event_type_id=event_type_id,
                category_id=category_id,
                gender=event.get("sex"),
                event_name_original=event.get("event_name") or event.get("raw_name") or "",
                category_original=event.get("category_text"),
                event_datetime=event_datetime,
                wind=wind,
                round_type=event.get("round_type"),
                round_name=event.get("round_name"),
                source_file_id=source.id,
                page_number=event.get("page_number"),
                raw_header_text=event.get("raw_header_text"),
            )
            db.add(competition_event)
            db.flush()
        elif competition_event.event_type_id is None and event_type_id is not None:
            competition_event.event_type_id = event_type_id
        return competition_event

    def _get_or_create_result(
        self,
        db: Session,
        competition_event: CompetitionEvent,
        athlete: Athlete,
        club: Club | None,
        source: SourceFile,
        event: dict,
        result: dict,
    ) -> Result:
        mark_raw = result.get("mark") or result.get("status_original") or result.get("status")
        query = select(Result).where(
            Result.competition_event_id == competition_event.id,
            Result.athlete_id == athlete.id,
            Result.mark_raw == mark_raw,
        )
        if result.get("position") is None:
            query = query.where(Result.position.is_(None))
        else:
            query = query.where(Result.position == result.get("position"))
        db_result = db.scalar(query)
        if not db_result:
            db_result = Result(
                competition_event_id=competition_event.id,
                athlete_id=athlete.id,
                club_id=club.id if club else None,
                bib_number=result.get("dorsal"),
                position=result.get("position"),
                lane=result.get("lane"),
                order_number=result.get("order_number"),
                mark_raw=mark_raw,
                mark_value_numeric=parse_mark_numeric(result.get("mark")),
                mark_unit=infer_mark_unit(event.get("event_name"), result.get("mark")),
                status=result.get("status") or "UNKNOWN",
                status_original=result.get("status_original"),
                wind=_decimal_or_none(result.get("wind")),
                raw_text=result.get("raw_text"),
                source_file_id=source.id,
                page_number=event.get("page_number"),
            )
            db.add(db_result)
            db.flush()
        return db_result

    def _get_or_create_attempt(self, db: Session, result: Result, attempt: dict) -> ResultAttempt:
        height_or_distance = _decimal_or_none(attempt.get("height_or_distance"))
        query = select(ResultAttempt).where(
            ResultAttempt.result_id == result.id,
            ResultAttempt.attempt_number == attempt.get("attempt_number"),
        )
        if height_or_distance is None:
            query = query.where(ResultAttempt.height_or_distance.is_(None))
        else:
            query = query.where(ResultAttempt.height_or_distance == height_or_distance)
        db_attempt = db.scalar(query)
        if not db_attempt:
            db_attempt = ResultAttempt(
                result_id=result.id,
                attempt_number=attempt.get("attempt_number"),
                attempt_value_raw=attempt.get("attempt_value_raw"),
                attempt_value_numeric=parse_mark_numeric(attempt.get("attempt_value_raw")),
                attempt_status=attempt.get("attempt_status"),
                height_or_distance=height_or_distance,
                raw_text=attempt.get("attempt_value_raw"),
            )
            db.add(db_attempt)
            db.flush()
        return db_attempt

    def _find_category_id(self, db: Session, category: str | None) -> int | None:
        if not category:
            return None
        row = db.scalar(select(Category).where(Category.code == category))
        if not row:
            row = db.scalar(select(Category).where(Category.name == category))
        return row.id if row else None

    def _find_event_type_id(self, db: Session, event_name: str | None) -> int | None:
        if not event_name:
            return None
        event_name_normalized = _db_normalized(event_name)
        row = db.scalar(select(EventType).where(EventType.name_normalized == event_name_normalized))
        if row:
            return row.id

        alias = db.scalar(
            select(EventTypeAlias).where(EventTypeAlias.alias_normalized == event_name_normalized)
        )
        if alias:
            return alias.event_type_id

        self._warn_missing_event_type_alias(event_name, event_name_normalized or "")
        return None

    def _warn_missing_event_type_alias(self, event_name: str, event_name_normalized: str) -> None:
        key = (event_name, event_name_normalized)
        if key in self._missing_event_type_aliases:
            return
        self._missing_event_type_aliases.add(key)
        print(
            "[WARN] Alias de prueba no encontrado: "
            f"event_name={event_name!r}, alias_normalized={event_name_normalized!r}. "
            "Alta este alias en event_type_aliases para rellenar competition_events.event_type_id."
        )

    def _add_import_error(
        self,
        db: Session,
        source: SourceFile,
        page_number: int | None,
        block_text: str | None,
        error_type: str,
        error_message: str,
    ) -> None:
        db.add(
            ImportError(
                source_file_id=source.id,
                page_number=page_number,
                block_text=block_text,
                error_type=error_type,
                error_message=error_message,
            )
        )


def _db_normalized(value: str | None) -> str | None:
    return normalize_name(value or "").lower()


def _parse_iso_date(value: str | None) -> date | None:
    if not value:
        return None
    return date.fromisoformat(value)


def _parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    return datetime.fromisoformat(value)


def _decimal_or_none(value: str | int | float | Decimal | None) -> Decimal | None:
    if value in (None, ""):
        return None
    try:
        return Decimal(str(value).replace(",", "."))
    except (InvalidOperation, ValueError):
        return None
