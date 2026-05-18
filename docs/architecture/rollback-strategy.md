# Rollback Strategy

Rollback por `source_file_id` o `filename`:

1. Eliminar `result_attempts` y `results` del PDF.
2. Eliminar `competition_events` sin resultados restantes.
3. Eliminar `athlete_clubs` del PDF.
4. Eliminar `athlete_licenses` no usadas por otros PDFs.
5. Eliminar `import_errors` del PDF.
6. Marcar `source_files` como `ROLLED_BACK`.
