import re


def normalize_pdf_text(text: str) -> str:
    return re.sub(r'\s+', ' ', text).strip()
