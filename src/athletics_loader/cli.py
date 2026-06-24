from pathlib import Path
import json

import typer

from athletics_loader.config import settings
from athletics_loader.pdf.pdf_reader import extract_text_pages
from athletics_loader.pdf.parsers.fam_results_parser import FamResultsParser

app = typer.Typer(help='Athletics PDF loader CLI')


@app.command('import-pdfs')
def import_pdfs(
    pdf_dir: Path = typer.Option(Path(settings.pdf_input_dir), '--pdf-dir'),
    only_club: str | None = typer.Option(None, '--only-club', help='Import only results for this club name'),
) -> None:
    from athletics_loader.services.pdf_results_import_service import PdfResultsImportService

    result = PdfResultsImportService(only_club_name=only_club).import_dir(pdf_dir)
    typer.echo(f'PDFs encontrados: {len(list(pdf_dir.glob("*.pdf")))}')
    typer.echo(f'PDFs procesados/ignorados: {len(result)}')
    for item in result:
        typer.echo(f"- {item['filename']} [{item['status']}] {item['hash']}")


def _validate_pdf_file(pdf: Path) -> dict:
    pages = extract_text_pages(pdf)
    parser = FamResultsParser()
    valid = parser.can_parse(pdf, pages)
    return {
        'filename': pdf.name,
        'path': str(pdf),
        'valid_fam_results': valid,
        'details': parser.parse(pdf, pages) if valid else {},
    }


@app.command('validate-pdf')
def validate_pdf(pdf: Path = typer.Option(..., '--pdf')) -> None:
    result = _validate_pdf_file(pdf)
    typer.echo(json.dumps(result, ensure_ascii=False, indent=2))


@app.command('validate-pdfs')
def validate_pdfs(pdf_dir: Path = typer.Option(Path(settings.pdf_input_dir), '--pdf-dir')) -> None:
    pdfs = sorted(pdf_dir.glob('*.pdf'))
    results = [_validate_pdf_file(pdf) for pdf in pdfs]
    typer.echo(
        json.dumps(
            {
                'pdf_dir': str(pdf_dir),
                'pdfs_found': len(pdfs),
                'pdfs_valid_fam_results': sum(1 for result in results if result['valid_fam_results']),
                'results': results,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


@app.command('rollback-pdf')
def rollback_pdf(filename: str = typer.Option(None, '--filename'), source_file_id: int = typer.Option(None, '--source-file-id'), dry_run: bool = typer.Option(False, '--dry-run'), yes: bool = typer.Option(False, '--yes')) -> None:
    typer.echo({'filename': filename, 'source_file_id': source_file_id, 'dry_run': dry_run, 'yes': yes, 'status': 'pending_implementation'})


@app.command('report-pdf')
def report_pdf(filename: str = typer.Option(None, '--filename'), source_file_id: int = typer.Option(None, '--source-file-id')) -> None:
    typer.echo({'filename': filename, 'source_file_id': source_file_id, 'status': 'pending_implementation'})
