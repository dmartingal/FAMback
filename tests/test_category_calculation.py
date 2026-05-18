from datetime import date
from athletics_loader.utils.dates import calculate_age


def test_calculate_age() -> None:
    assert calculate_age(date(2026, 5, 2), date(2010, 6, 1)) == 15
