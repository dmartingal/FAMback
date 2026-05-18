from pathlib import Path
from athletics_loader.pdf.parsers.fam_results_parser import FamResultsParser


def test_fam_parser_detects_header() -> None:
    parser = FamResultsParser()
    pages = ['16:35 02/05/2026 100m Femenino Serie 1\nViento: -1.9']
    assert parser.can_parse(Path('x.pdf'), pages)
