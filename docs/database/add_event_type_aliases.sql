-- MySQL 8 - Alias de nombres de pruebas leidos desde PDFs FAM.
-- Ejecutar despues de crear/cargar el catalogo base de event_types.

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

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT id, '60m Vallas (0,762)', '60m vallas (0,762)'
FROM event_types
WHERE name_normalized = '60mv(0.762)'
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT id, '60m Vallas (0,84)', '60m vallas (0,84)'
FROM event_types
WHERE name_normalized = '60mv(0.84)'
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT id, 'Peso (2kg)', 'peso (2kg)'
FROM event_types
WHERE name_normalized = 'peso(2kg)'
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT id, '1.500m', '1.500m'
FROM event_types
WHERE name_normalized = '1500m'
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT id, 'Triple Salto', 'triple salto'
FROM event_types
WHERE name_normalized = 'triple'
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT id, CAST(0x50C3A97274696761 AS CHAR CHARACTER SET utf8mb4), 'pertiga'
FROM event_types
WHERE name_normalized = 'pertiga'
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

INSERT INTO event_type_aliases (event_type_id, alias, alias_normalized)
SELECT id, CAST(0x50C39A7274696761 AS CHAR CHARACTER SET utf8mb4), 'purtiga'
FROM event_types
WHERE name_normalized = 'pertiga'
ON DUPLICATE KEY UPDATE event_type_id = VALUES(event_type_id), alias = VALUES(alias);

-- Backfill de eventos ya importados que quedaron sin event_type_id.
UPDATE competition_events ce
JOIN event_type_aliases eta ON eta.alias_normalized = LOWER(TRIM(ce.event_name_original))
SET ce.event_type_id = eta.event_type_id
WHERE ce.event_type_id IS NULL;

-- Comprobacion de aliases que siguen pendientes tras el backfill.
SELECT ce.event_name_original, LOWER(TRIM(ce.event_name_original)) AS alias_normalized, COUNT(*) AS total
FROM competition_events ce
WHERE ce.event_type_id IS NULL
GROUP BY ce.event_name_original, LOWER(TRIM(ce.event_name_original))
ORDER BY total DESC, ce.event_name_original;
