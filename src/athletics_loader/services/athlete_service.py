from athletics_loader.utils.text import normalize_name


def build_athlete_key(full_name: str, birth_date_iso: str) -> str:
    return f"{normalize_name(full_name)}|{birth_date_iso}"
