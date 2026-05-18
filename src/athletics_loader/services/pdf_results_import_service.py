from pathlib import Path
from sqlalchemy import select
from athletics_loader.db.models import SourceFile
from athletics_loader.db.session import SessionLocal
from athletics_loader.pdf.pdf_reader import extract_text_pages
from athletics_loader.pdf.parsers.fam_results_parser import FamResultsParser
from athletics_loader.utils.hashes import sha256_file


class PdfResultsImportService:
    def import_dir(self, pdf_dir: Path) -> list[dict]:
        parser = FamResultsParser()
        out = []
        for pdf_path in sorted(pdf_dir.glob('*.pdf')):
            file_hash = sha256_file(pdf_path)
            with SessionLocal() as db:
                existing = db.scalar(select(SourceFile).where(SourceFile.file_hash == file_hash))
                if existing and existing.status == 'PROCESSED':
                    out.append({"filename": pdf_path.name, "hash": file_hash, "status": "SKIPPED"})
                    continue
                pages = extract_text_pages(pdf_path)
                parsed = parser.parse(pdf_path, pages) if parser.can_parse(pdf_path, pages) else {"pages": len(pages)}
                source = SourceFile(filename=pdf_path.name, file_hash=file_hash, status='PROCESSED')
                db.add(source)
                db.commit()
                out.append({"filename": pdf_path.name, "hash": file_hash, "status": "PROCESSED", "parsed": parsed})
        return out
