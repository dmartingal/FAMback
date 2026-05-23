from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import BigInteger, Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Category(Base):
    __tablename__ = "categories"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    code: Mapped[str] = mapped_column(String(50), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)


class EventType(Base):
    __tablename__ = "event_types"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    name_normalized: Mapped[str] = mapped_column(String(150), nullable=False)


class EventTypeAlias(Base):
    __tablename__ = "event_type_aliases"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    event_type_id: Mapped[int] = mapped_column(ForeignKey("event_types.id"), nullable=False)
    alias: Mapped[str] = mapped_column(String(150), nullable=False)
    alias_normalized: Mapped[str] = mapped_column(String(150), nullable=False)


class SourceFile(Base):
    __tablename__ = "source_files"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    file_path: Mapped[str] = mapped_column(String(1000), nullable=False)
    file_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    processed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    pages_count: Mapped[int | None] = mapped_column(Integer, nullable=True)


class Competition(Base):
    __tablename__ = "competitions"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    name_normalized: Mapped[str] = mapped_column(String(255), nullable=False)
    venue: Mapped[str | None] = mapped_column(String(255), nullable=True)
    venue_normalized: Mapped[str | None] = mapped_column(String(255), nullable=True)
    competition_date: Mapped[date] = mapped_column(Date, nullable=False)
    source_name: Mapped[str | None] = mapped_column(String(255), nullable=True)


class Club(Base):
    __tablename__ = "clubs"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    name_normalized: Mapped[str] = mapped_column(String(255), nullable=False)


class Athlete(Base):
    __tablename__ = "athletes"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name_normalized: Mapped[str] = mapped_column(String(255), nullable=False)
    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    gender: Mapped[str | None] = mapped_column(String(1), nullable=True)
    current_license: Mapped[str | None] = mapped_column(String(100), nullable=True)
    current_license_normalized: Mapped[str | None] = mapped_column(String(100), nullable=True)
    athlete_key: Mapped[str] = mapped_column(String(350), nullable=False)


class AthleteLicense(Base):
    __tablename__ = "athlete_licenses"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("athletes.id"), nullable=False)
    license: Mapped[str] = mapped_column(String(100), nullable=False)
    license_normalized: Mapped[str] = mapped_column(String(100), nullable=False)
    source_file_id: Mapped[int | None] = mapped_column(ForeignKey("source_files.id"), nullable=True)
    competition_id: Mapped[int | None] = mapped_column(ForeignKey("competitions.id"), nullable=True)


class AthleteClub(Base):
    __tablename__ = "athlete_clubs"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("athletes.id"), nullable=False)
    club_id: Mapped[int] = mapped_column(ForeignKey("clubs.id"), nullable=False)
    competition_id: Mapped[int | None] = mapped_column(ForeignKey("competitions.id"), nullable=True)
    source_file_id: Mapped[int | None] = mapped_column(ForeignKey("source_files.id"), nullable=True)


class CompetitionEvent(Base):
    __tablename__ = "competition_events"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    competition_id: Mapped[int] = mapped_column(ForeignKey("competitions.id"), nullable=False)
    event_type_id: Mapped[int | None] = mapped_column(ForeignKey("event_types.id"), nullable=True)
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"), nullable=True)
    gender: Mapped[str | None] = mapped_column(String(1), nullable=True)
    event_name_original: Mapped[str] = mapped_column(String(255), nullable=False)
    category_original: Mapped[str | None] = mapped_column(String(100), nullable=True)
    event_datetime: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    wind: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    round_type: Mapped[str | None] = mapped_column(String(20), nullable=True)
    round_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    source_file_id: Mapped[int | None] = mapped_column(ForeignKey("source_files.id"), nullable=True)
    page_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    raw_header_text: Mapped[str | None] = mapped_column(Text, nullable=True)


class Result(Base):
    __tablename__ = "results"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    competition_event_id: Mapped[int] = mapped_column(ForeignKey("competition_events.id"), nullable=False)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("athletes.id"), nullable=False)
    club_id: Mapped[int | None] = mapped_column(ForeignKey("clubs.id"), nullable=True)
    bib_number: Mapped[str | None] = mapped_column(String(30), nullable=True)
    position: Mapped[int | None] = mapped_column(Integer, nullable=True)
    lane: Mapped[int | None] = mapped_column(Integer, nullable=True)
    order_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    mark_raw: Mapped[str | None] = mapped_column(String(100), nullable=True)
    mark_value_numeric: Mapped[Decimal | None] = mapped_column(Numeric(12, 4), nullable=True)
    mark_unit: Mapped[str | None] = mapped_column(String(20), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    status_original: Mapped[str | None] = mapped_column(String(50), nullable=True)
    wind: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    raw_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_file_id: Mapped[int | None] = mapped_column(ForeignKey("source_files.id"), nullable=True)
    page_number: Mapped[int | None] = mapped_column(Integer, nullable=True)


class ResultAttempt(Base):
    __tablename__ = "result_attempts"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    result_id: Mapped[int] = mapped_column(ForeignKey("results.id"), nullable=False)
    attempt_number: Mapped[int] = mapped_column(Integer, nullable=False)
    attempt_value_raw: Mapped[str | None] = mapped_column(String(100), nullable=True)
    attempt_value_numeric: Mapped[Decimal | None] = mapped_column(Numeric(12, 4), nullable=True)
    attempt_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    height_or_distance: Mapped[Decimal | None] = mapped_column(Numeric(12, 4), nullable=True)
    raw_text: Mapped[str | None] = mapped_column(Text, nullable=True)


class ImportError(Base):
    __tablename__ = "import_errors"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    source_file_id: Mapped[int | None] = mapped_column(ForeignKey("source_files.id"), nullable=True)
    page_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    block_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    error_type: Mapped[str] = mapped_column(String(100), nullable=False)
    error_message: Mapped[str] = mapped_column(Text, nullable=False)
