-- MySQL 8 - Soporte para resultados de relevos por club/equipo.
-- Ejecutar antes de reprocesar PDFs con relevos.

CREATE TABLE IF NOT EXISTS event_type_aliases (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_type_id BIGINT NOT NULL,
  alias VARCHAR(150) NOT NULL,
  alias_normalized VARCHAR(150) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_event_type_aliases_alias_normalized (alias_normalized),
  KEY idx_event_type_aliases_event_type (event_type_id),
  CONSTRAINT fk_event_type_aliases_event_type FOREIGN KEY (event_type_id) REFERENCES event_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE results
  MODIFY athlete_id BIGINT NULL;

CREATE TABLE IF NOT EXISTS relay_result_members (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  result_id BIGINT NULL,
  competition_event_id BIGINT NOT NULL,
  source_file_id BIGINT NULL,
  member_order INT NULL,
  bib_number VARCHAR(30) NULL,
  athlete_name VARCHAR(255) NOT NULL,
  birth_date DATE NULL,
  license VARCHAR(100) NULL,
  raw_text TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_rrm_result (result_id),
  KEY idx_rrm_event (competition_event_id),
  KEY idx_rrm_source_file (source_file_id),
  CONSTRAINT fk_rrm_result FOREIGN KEY (result_id) REFERENCES results(id) ON DELETE CASCADE,
  CONSTRAINT fk_rrm_event FOREIGN KEY (competition_event_id) REFERENCES competition_events(id),
  CONSTRAINT fk_rrm_source_file FOREIGN KEY (source_file_id) REFERENCES source_files(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT COLUMN_NAME, IS_NULLABLE, COLUMN_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'results'
  AND COLUMN_NAME = 'athlete_id';

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT
  et.id,
  CASE
    WHEN et.name_normalized LIKE '%m' THEN TRIM(TRAILING 'm' FROM et.name_normalized)
    ELSE CONCAT(et.name_normalized, 'm')
  END,
  CASE
    WHEN et.name_normalized LIKE '%m' THEN TRIM(TRAILING 'm' FROM et.name_normalized)
    ELSE CONCAT(et.name_normalized, 'm')
  END
FROM event_types et
WHERE et.name_normalized IN ('4x100', '4x300', '4x400', '4x50', '4x60', '4x80', '5x80',
                             '4x100m', '4x300m', '4x400m', '4x50m', '4x60m', '4x80m', '5x80m')
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

-- Normaliza eventos de relevo ya creados como "4x100m", "4x300m", etc. para que el reproceso
-- encuentre el mismo competition_event y complete resultados/marks.
UPDATE competition_events ce
JOIN event_types et ON (
  et.name_normalized = LOWER(TRIM(ce.event_name_original))
  OR et.name_normalized = LOWER(TRIM(TRAILING 'm' FROM ce.event_name_original))
  OR et.name_normalized = CONCAT(LOWER(TRIM(ce.event_name_original)), 'm')
)
SET
  ce.event_name_original = et.name_normalized,
  ce.event_type_id = et.id,
  ce.round_name = CASE
    WHEN UPPER(REPLACE(TRIM(COALESCE(ce.round_name, '')), '.', '')) = 'PC' THEN NULL
    ELSE ce.round_name
  END
WHERE LOWER(TRIM(ce.event_name_original)) IN ('4x100m', '4x300m', '4x400m', '4x50m', '4x60m', '4x80m', '5x80m');

-- Limpia importaciones erroneas previas donde integrantes del relevo se guardaron como clubes.
DELETE r
FROM results r
JOIN clubs cl ON cl.id = r.club_id
WHERE r.athlete_id IS NULL
  AND cl.name REGEXP '^[0-9]+ .*[0-9]{2}/[0-9]{2}/[0-9]{4}$';

-- Borra clubes contaminados por integrantes de relevo si ya no tienen resultados asociados.
DELETE cl
FROM clubs cl
LEFT JOIN results r ON r.club_id = cl.id
LEFT JOIN athlete_clubs ac ON ac.club_id = cl.id
WHERE r.id IS NULL
  AND ac.id IS NULL
  AND cl.name REGEXP '^[0-9]+ .*[0-9]{2}/[0-9]{2}/[0-9]{4}$';

-- Permite reprocesar el PDF afectado; el importador ya no deberia saltarlo.
UPDATE source_files
SET status = 'PENDING'
WHERE filename = '2026.01.10_CTO_MADRID_CLUBES_ABSOLUTO_PC_GALLUR.pdf';
