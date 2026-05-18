from pathlib import Path
import re
from .base import BasePdfParser

HEADER = re.compile(r"\b\d{2}:\d{2}\s+\d{2}/\d{2}/\d{4}\b")


class FamResultsParser(BasePdfParser):
    def can_parse(self, pdf_path: Path, pages: list[str]) -> bool:
        return any(HEADER.search(p or "") for p in pages)

    def parse(self, pdf_path: Path, pages: list[str]) -> dict:
        headers = []
        for page in pages:
            for line in page.splitlines():
                if HEADER.search(line):
                    headers.append(line.strip())
        return {"pdf": pdf_path.name, "headers_detected": headers, "pages": len(pages)}
