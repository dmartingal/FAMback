from pathlib import Path
import pdfplumber


def extract_text_pages(pdf_path: Path) -> list[str]:
    with pdfplumber.open(pdf_path) as pdf:
        return [(p.extract_text() or '') for p in pdf.pages]
