from __future__ import annotations

from datetime import date, datetime
from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class SourceFile(Base):
    __tablename__ = "source_files"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    file_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    processed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Competition(Base):
    __tablename__ = "competitions"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)


class Club(Base):
    __tablename__ = "clubs"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)


class Athlete(Base):
    __tablename__ = "athletes"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_key: Mapped[str] = mapped_column(String(300), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)


class AthleteLicense(Base):
    __tablename__ = "athlete_licenses"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("athletes.id"), nullable=False)
    source_file_id: Mapped[int] = mapped_column(ForeignKey("source_files.id"), nullable=False)
    license_code: Mapped[str] = mapped_column(String(64), nullable=False)


class AthleteClub(Base):
    __tablename__ = "athlete_clubs"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("athletes.id"), nullable=False)
    club_id: Mapped[int] = mapped_column(ForeignKey("clubs.id"), nullable=False)
    source_file_id: Mapped[int] = mapped_column(ForeignKey("source_files.id"), nullable=False)


class CompetitionEvent(Base):
    __tablename__ = "competition_events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    competition_id: Mapped[int] = mapped_column(ForeignKey("competitions.id"), nullable=False)
    source_file_id: Mapped[int] = mapped_column(ForeignKey("source_files.id"), nullable=False)


class Result(Base):
    __tablename__ = "results"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_file_id: Mapped[int] = mapped_column(ForeignKey("source_files.id"), nullable=False)
    competition_event_id: Mapped[int] = mapped_column(ForeignKey("competition_events.id"), nullable=False)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("athletes.id"), nullable=False)


class ResultAttempt(Base):
    __tablename__ = "result_attempts"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    result_id: Mapped[int] = mapped_column(ForeignKey("results.id"), nullable=False)
    attempt_no: Mapped[int] = mapped_column(Integer, nullable=False)
    value: Mapped[str] = mapped_column(String(32), nullable=False)


class ImportError(Base):
    __tablename__ = "import_errors"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_file_id: Mapped[int] = mapped_column(ForeignKey("source_files.id"), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
