from __future__ import annotations

from decimal import Decimal, InvalidOperation
import re
import unicodedata


SECONDS_MARK = re.compile(r"^(?:(?P<minutes>\d+):)?(?P<seconds>\d{1,2})(?:[.,](?P<fraction>\d+))?$")
DECIMAL_MARK = re.compile(r"^\d+(?:[.,]\d+)?$")


def parse_mark_numeric(mark: str | None) -> Decimal | None:
    if not mark:
        return None
    value = mark.strip()
    if not value or value.upper() in {"DNS", "NP", "NM", "SM", "DNF", "DQ"}:
        return None

    if ":" in value:
        match = SECONDS_MARK.match(value)
        if not match:
            return None
        minutes = Decimal(match.group("minutes") or "0")
        seconds = Decimal(match.group("seconds"))
        fraction = match.group("fraction") or "0"
        return minutes * Decimal(60) + seconds + Decimal(f"0.{fraction}")

    if DECIMAL_MARK.match(value):
        try:
            return Decimal(value.replace(",", "."))
        except InvalidOperation:
            return None
    return None


def infer_mark_unit(event_name: str | None, mark: str | None) -> str:
    if not mark:
        return "none"
    if mark.upper() in {"DNS", "NP", "NM", "SM", "DNF", "DQ"}:
        return "none"
    normalized_event = _normalize_event_name(event_name)
    if any(term in normalized_event for term in ("decatlon", "heptatlon", "hexatlon", "octatlon", "pentatlon")):
        return "points"
    if any(term in normalized_event for term in ("altura", "longitud", "triple", "peso", "jabalina", "disco", "martillo", "pertiga")):
        return "meters"
    if ":" in mark or re.match(r"^\d{1,2}[.,]\d+$", mark):
        return "seconds"
    return "text"


def _normalize_event_name(event_name: str | None) -> str:
    value = unicodedata.normalize("NFKD", event_name or "")
    value = "".join(c for c in value if not unicodedata.combining(c))
    return value.lower()
