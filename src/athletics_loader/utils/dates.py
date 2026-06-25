from datetime import date


def calculate_age(on_date: date, birth_date: date) -> int:
    return on_date.year - birth_date.year - ((on_date.month, on_date.day) < (birth_date.month, birth_date.day))
