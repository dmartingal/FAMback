from pathlib import Path
import typer

from athletics_loader.pdf.pdf_reader import extract_text_pages
from athletics_loader.pdf.parsers.fam_results_parser import FamResultsParser
from athletics_loader.services.pdf_results_import_service import PdfResultsImportService

app = typer.Typer(help='Athletics PDF loader CLI')


@app.command('import-pdfs')
def import_pdfs(pdf_dir: Path = typer.Option(Path('data/pdfs'), '--pdf-dir')) -> None:
    result = PdfResultsImportService().import_dir(pdf_dir)
    typer.echo(f'PDFs encontrados: {len(list(pdf_dir.glob("*.pdf")))}')
    typer.echo(f'PDFs procesados/ignorados: {len(result)}')
    for item in result:
        typer.echo(f"- {item['filename']} [{item['status']}] {item['hash']}")


@app.command('validate-pdf')
def validate_pdf(pdf: Path = typer.Option(..., '--pdf')) -> None:
    pages = extract_text_pages(pdf)
    parser = FamResultsParser()
    valid = parser.can_parse(pdf, pages)
    typer.echo({'filename': pdf.name, 'valid_fam_results': valid, 'details': parser.parse(pdf, pages) if valid else {}})


@app.command('rollback-pdf')
def rollback_pdf(filename: str = typer.Option(None, '--filename'), source_file_id: int = typer.Option(None, '--source-file-id'), dry_run: bool = typer.Option(False, '--dry-run'), yes: bool = typer.Option(False, '--yes')) -> None:
    typer.echo({'filename': filename, 'source_file_id': source_file_id, 'dry_run': dry_run, 'yes': yes, 'status': 'pending_implementation'})


@app.command('report-pdf')
def report_pdf(filename: str = typer.Option(None, '--filename'), source_file_id: int = typer.Option(None, '--source-file-id')) -> None:
    typer.echo({'filename': filename, 'source_file_id': source_file_id, 'status': 'pending_implementation'})
