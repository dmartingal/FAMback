from __future__ import annotations

from datetime import date

from athletics_loader.utils.dates import calculate_age


CATEGORY_ALIASES = {
    "ABS": "SENIOR/ABSOLUTA",
    "INF": "SUB-14",
    "INFANTIL": "SUB-14",
    "CAD": "SUB-16",
    "CADETE": "SUB-16",
    "JUV": "SUB-18",
    "JUVENIL": "SUB-18",
    "JUNIOR": "SUB-20",
    "PROMESA": "SUB-23",
    "ABSOLUTO": "SENIOR/ABSOLUTA",
    "ABSOLUTA": "SENIOR/ABSOLUTA",
    "SENIOR": "SENIOR/ABSOLUTA",
    "SEN": "SENIOR/ABSOLUTA",
    "SESN": "SENIOR/ABSOLUTA",
}


def normalize_category_alias(value: str | None) -> str | None:
    if not value:
        return None
    normalized = value.strip().upper().replace(" ", "-")
    if normalized.startswith("SUB-"):
        return normalized
    if normalized.startswith("SUB") and normalized[3:].isdigit():
        return f"SUB-{normalized[3:]}"
    if normalized.startswith("S") and normalized[1:].isdigit():
        return f"SUB-{normalized[1:]}"
    if normalized[0:1] in {"M", "F"} and normalized[1:].isdigit():
        return f"MASTER-{normalized[1:]}"
    return CATEGORY_ALIASES.get(normalized, normalized)


def category_from_birth_date(competition_date: date, birth_date: date) -> str:
    age = calculate_age(competition_date, birth_date)
    if age <= 7:
        return "SUB-8"
    if age <= 9:
        return "SUB-10"
    if age <= 11:
        return "SUB-12"
    if age <= 13:
        return "SUB-14"
    if age <= 15:
        return "SUB-16"
    if age <= 17:
        return "SUB-18"
    if age <= 19:
        return "SUB-20"
    if age <= 22:
        return "SUB-23"
    if age <= 34:
        return "SENIOR/ABSOLUTA"
    master_floor = ((age - 35) // 5) * 5 + 35
    if master_floor > 100:
        master_floor = 100
    return f"MASTER-{master_floor}"
