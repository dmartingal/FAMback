from abc import ABC, abstractmethod
from pathlib import Path


class BasePdfParser(ABC):
    @abstractmethod
    def can_parse(self, pdf_path: Path, pages: list[str]) -> bool: ...

    @abstractmethod
    def parse(self, pdf_path: Path, pages: list[str]) -> dict: ...
