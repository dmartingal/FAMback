-- Simplifica la identidad de atletas: un atleta se identifica por full_name_normalized.
-- Ejecutar sobre una base existente antes de reimportar PDFs.

ALTER TABLE athletes
  DROP INDEX uk_athletes_athlete_key,
  DROP COLUMN athlete_key,
  MODIFY birth_date DATE NULL,
  ADD UNIQUE INDEX uk_athletes_full_name_normalized (full_name_normalized);
