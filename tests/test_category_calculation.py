from datetime import date
from athletics_loader.utils.categories import category_from_birth_date, normalize_category_alias
from athletics_loader.utils.dates import calculate_age


def test_calculate_age() -> None:
    assert calculate_age(date(2026, 5, 2), date(2010, 6, 1)) == 15


def test_category_from_birth_date() -> None:
    assert category_from_birth_date(date(2026, 5, 2), date(2010, 6, 1)) == "SUB-16"
    assert category_from_birth_date(date(2026, 5, 2), date(1987, 1, 1)) == "MASTER-35"


def test_normalize_category_alias() -> None:
    assert normalize_category_alias("Inf") == "SUB-14"
    assert normalize_category_alias("Sub 18") == "SUB-18"
