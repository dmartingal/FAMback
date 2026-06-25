import re
import unicodedata


def normalize_name(value: str) -> str:
    value = unicodedata.normalize('NFKD', value)
    value = ''.join(c for c in value if not unicodedata.combining(c))
    value = re.sub(r'\s+', ' ', value.strip().upper())
    return value
