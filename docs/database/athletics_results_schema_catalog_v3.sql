-- Script generado para MySQL 8 - Base de datos de resultados de atletismo
-- Incluye catálogo de categorías moderno, pruebas y relaciones categoría-prueba por género.
-- Las categorías antiguas tipo Infantil/Cadete/Juvenil NO se crean como categorías; solo se añaden como alias de lectura para PDFs antiguos.

DROP DATABASE IF EXISTS athletics_results;
CREATE DATABASE athletics_results CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE athletics_results;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


CREATE TABLE sectors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  name_normalized VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_sectors_name_normalized (name_normalized)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE categories (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL,
  min_age INT NOT NULL,
  max_age INT NULL,
  is_master BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_categories_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE category_aliases (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT NOT NULL,
  alias VARCHAR(100) NOT NULL,
  alias_normalized VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_category_aliases_alias_normalized (alias_normalized),
  CONSTRAINT fk_category_aliases_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE event_types (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sector_id BIGINT NULL,
  name VARCHAR(150) NOT NULL,
  name_normalized VARCHAR(150) NOT NULL,
  distance_meters DECIMAL(10,3) NULL,
  implement_weight_grams INT NULL,
  hurdle_height_meters DECIMAL(6,3) NULL,
  is_relay BOOLEAN NOT NULL DEFAULT FALSE,
  is_combined BOOLEAN NOT NULL DEFAULT FALSE,
  has_obstacles BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_event_types_name_normalized (name_normalized),
  KEY idx_event_types_sector (sector_id),
  CONSTRAINT fk_event_types_sector FOREIGN KEY (sector_id) REFERENCES sectors(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE category_event_types (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT NOT NULL,
  event_type_id BIGINT NOT NULL,
  gender ENUM('M','F','BOTH') NOT NULL DEFAULT 'BOTH',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_category_event_types (category_id, event_type_id, gender),
  KEY idx_cet_event_type (event_type_id),
  CONSTRAINT fk_cet_category FOREIGN KEY (category_id) REFERENCES categories(id),
  CONSTRAINT fk_cet_event_type FOREIGN KEY (event_type_id) REFERENCES event_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE source_files (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  filename VARCHAR(255) NOT NULL,
  file_path VARCHAR(1000) NOT NULL,
  file_hash CHAR(64) NOT NULL,
  processed_at TIMESTAMP NULL,
  status ENUM('PENDING','PROCESSED','PARTIAL','ERROR','IGNORED') NOT NULL DEFAULT 'PENDING',
  error_message TEXT NULL,
  pages_count INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_source_files_hash (file_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE competitions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  name_normalized VARCHAR(255) NOT NULL,
  venue VARCHAR(255) NULL,
  venue_normalized VARCHAR(255) NULL,
  competition_date DATE NOT NULL,
  source_name VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_competitions_logical (name_normalized, competition_date, venue_normalized)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE clubs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  name_normalized VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_clubs_name_normalized (name_normalized)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE athletes (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(255) NOT NULL,
  full_name_normalized VARCHAR(255) NOT NULL,
  birth_date DATE NULL,
  gender ENUM('M','F') NULL,
  current_license VARCHAR(100) NULL,
  current_license_normalized VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_athletes_full_name_normalized (full_name_normalized),
  KEY idx_athletes_name_birth (full_name_normalized, birth_date),
  KEY idx_athletes_current_license (current_license_normalized)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE athlete_licenses (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  athlete_id BIGINT NOT NULL,
  license VARCHAR(100) NOT NULL,
  license_normalized VARCHAR(100) NOT NULL,
  source_file_id BIGINT NULL,
  competition_id BIGINT NULL,
  first_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_athlete_licenses_athlete_license (athlete_id, license_normalized),
  KEY idx_athlete_licenses_license (license_normalized),
  KEY idx_athlete_licenses_athlete (athlete_id),
  CONSTRAINT fk_athlete_licenses_athlete FOREIGN KEY (athlete_id) REFERENCES athletes(id),
  CONSTRAINT fk_athlete_licenses_source_file FOREIGN KEY (source_file_id) REFERENCES source_files(id),
  CONSTRAINT fk_athlete_licenses_competition FOREIGN KEY (competition_id) REFERENCES competitions(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE athlete_clubs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  athlete_id BIGINT NOT NULL,
  club_id BIGINT NOT NULL,
  competition_id BIGINT NULL,
  source_file_id BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_athlete_clubs_context (athlete_id, club_id, competition_id),
  CONSTRAINT fk_ac_athlete FOREIGN KEY (athlete_id) REFERENCES athletes(id),
  CONSTRAINT fk_ac_club FOREIGN KEY (club_id) REFERENCES clubs(id),
  CONSTRAINT fk_ac_competition FOREIGN KEY (competition_id) REFERENCES competitions(id),
  CONSTRAINT fk_ac_source_file FOREIGN KEY (source_file_id) REFERENCES source_files(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE competition_events (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  competition_id BIGINT NOT NULL,
  event_type_id BIGINT NULL,
  category_id BIGINT NULL,
  gender ENUM('M','F') NULL,
  event_name_original VARCHAR(255) NOT NULL,
  category_original VARCHAR(100) NULL,
  event_datetime DATETIME NULL,
  wind DECIMAL(5,2) NULL,
  round_type ENUM('SERIE','FINAL','GRUPO','CLASIFICACION','OTRO') NULL,
  round_name VARCHAR(100) NULL,
  source_file_id BIGINT NULL,
  page_number INT NULL,
  raw_header_text TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_competition_events_logical (competition_id, event_type_id, category_id, gender, round_name, event_datetime),
  KEY idx_ce_competition (competition_id),
  KEY idx_ce_event_type (event_type_id),
  KEY idx_ce_category (category_id),
  CONSTRAINT fk_ce_competition FOREIGN KEY (competition_id) REFERENCES competitions(id),
  CONSTRAINT fk_ce_event_type FOREIGN KEY (event_type_id) REFERENCES event_types(id),
  CONSTRAINT fk_ce_category FOREIGN KEY (category_id) REFERENCES categories(id),
  CONSTRAINT fk_ce_source_file FOREIGN KEY (source_file_id) REFERENCES source_files(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE results (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  competition_event_id BIGINT NOT NULL,
  athlete_id BIGINT NULL,
  club_id BIGINT NULL,
  bib_number VARCHAR(30) NULL,
  position INT NULL,
  lane INT NULL,
  order_number INT NULL,
  mark_raw VARCHAR(100) NULL,
  mark_value_numeric DECIMAL(12,4) NULL,
  mark_unit ENUM('seconds','meters','points','text','none') NULL,
  status ENUM('OK','DNS','NP','NM','DQ','DNF','ERROR','UNKNOWN') NOT NULL DEFAULT 'OK',
  status_original VARCHAR(50) NULL,
  wind DECIMAL(5,2) NULL,
  raw_text TEXT NULL,
  source_file_id BIGINT NULL,
  page_number INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_results_logical (competition_event_id, athlete_id, mark_raw, position),
  KEY idx_results_event (competition_event_id),
  KEY idx_results_athlete (athlete_id),
  KEY idx_results_club (club_id),
  CONSTRAINT fk_results_event FOREIGN KEY (competition_event_id) REFERENCES competition_events(id),
  CONSTRAINT fk_results_athlete FOREIGN KEY (athlete_id) REFERENCES athletes(id),
  CONSTRAINT fk_results_club FOREIGN KEY (club_id) REFERENCES clubs(id),
  CONSTRAINT fk_results_source_file FOREIGN KEY (source_file_id) REFERENCES source_files(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE result_attempts (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  result_id BIGINT NOT NULL,
  attempt_number INT NOT NULL,
  attempt_value_raw VARCHAR(100) NULL,
  attempt_value_numeric DECIMAL(12,4) NULL,
  attempt_status ENUM('VALID','FOUL','PASS','FAIL','UNKNOWN') NULL,
  height_or_distance DECIMAL(12,4) NULL,
  raw_text TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_result_attempts (result_id, attempt_number, height_or_distance),
  CONSTRAINT fk_attempts_result FOREIGN KEY (result_id) REFERENCES results(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE relay_result_members (
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

CREATE TABLE import_errors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  source_file_id BIGINT NULL,
  page_number INT NULL,
  block_text LONGTEXT NULL,
  error_type VARCHAR(100) NOT NULL,
  error_message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_import_errors_source_file (source_file_id),
  CONSTRAINT fk_import_errors_source_file FOREIGN KEY (source_file_id) REFERENCES source_files(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- Sectores

INSERT INTO sectors (name, name_normalized) VALUES ('COMBINADAS', 'combinadas') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('FONDO', 'fondo') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('LANZAMIENTOS', 'lanzamientos') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('MARCHA', 'marcha') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('MEDIOFONDO', 'mediofondo') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('RELEVOS', 'relevos') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('SALTOS', 'saltos') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('VALLAS', 'vallas') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;
INSERT INTO sectors (name, name_normalized) VALUES ('VELOCIDAD', 'velocidad') ON DUPLICATE KEY UPDATE name = VALUES(name), updated_at = CURRENT_TIMESTAMP;

-- Categorías oficiales modernas por edad

INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-8', 'SUB-8', 6, 7, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-10', 'SUB-10', 8, 9, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-12', 'SUB-12', 10, 11, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-14', 'SUB-14', 12, 13, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-16', 'SUB-16', 14, 15, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-18', 'SUB-18', 16, 17, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-20', 'SUB-20', 18, 19, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SUB-23', 'SUB-23', 20, 22, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('SENIOR_ABSOLUTA', 'SENIOR/ABSOLUTA', 23, 34, 0) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-35', 'MASTER-35', 35, 39, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-40', 'MASTER-40', 40, 44, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-45', 'MASTER-45', 45, 49, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-50', 'MASTER-50', 50, 54, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-55', 'MASTER-55', 55, 59, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-60', 'MASTER-60', 60, 64, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-65', 'MASTER-65', 65, 69, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-70', 'MASTER-70', 70, 74, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-75', 'MASTER-75', 75, 79, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-80', 'MASTER-80', 80, 84, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-85', 'MASTER-85', 85, 89, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-90', 'MASTER-90', 90, 94, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-95', 'MASTER-95', 95, 99, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;
INSERT INTO categories (code, name, min_age, max_age, is_master) VALUES ('MASTER-100', 'MASTER-100', 100, NULL, 1) ON DUPLICATE KEY UPDATE name=VALUES(name), min_age=VALUES(min_age), max_age=VALUES(max_age), is_master=VALUES(is_master), updated_at=CURRENT_TIMESTAMP;

-- Alias de lectura para poder interpretar PDFs, sin crear categorías obsoletas como categorías reales

INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Minibenjamin', 'minibenjamin' FROM categories c WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Minibenjamín', 'minibenjamin' FROM categories c WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-8', 'sub-8' FROM categories c WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB8', 'sub8' FROM categories c WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 8', 'sub8' FROM categories c WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub8', 'sub8' FROM categories c WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Benjamin', 'benjamin' FROM categories c WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Benjamín', 'benjamin' FROM categories c WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-10', 'sub-10' FROM categories c WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB10', 'sub10' FROM categories c WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 10', 'sub10' FROM categories c WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub10', 'sub10' FROM categories c WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Alevin', 'alevin' FROM categories c WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Alevín', 'alevin' FROM categories c WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-12', 'sub-12' FROM categories c WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB12', 'sub12' FROM categories c WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 12', 'sub12' FROM categories c WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub12', 'sub12' FROM categories c WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Inf', 'inf' FROM categories c WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Infantil', 'infantil' FROM categories c WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-14', 'sub-14' FROM categories c WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB14', 'sub14' FROM categories c WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 14', 'sub14' FROM categories c WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub14', 'sub14' FROM categories c WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Cad', 'cad' FROM categories c WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Cadete', 'cadete' FROM categories c WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-16', 'sub-16' FROM categories c WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB16', 'sub16' FROM categories c WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 16', 'sub16' FROM categories c WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub16', 'sub16' FROM categories c WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Juv', 'juv' FROM categories c WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Juvenil', 'juvenil' FROM categories c WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-18', 'sub-18' FROM categories c WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB18', 'sub18' FROM categories c WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 18', 'sub18' FROM categories c WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub18', 'sub18' FROM categories c WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Junior', 'junior' FROM categories c WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Júnior', 'junior' FROM categories c WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-20', 'sub-20' FROM categories c WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB20', 'sub20' FROM categories c WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 20', 'sub20' FROM categories c WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub20', 'sub20' FROM categories c WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Promesa', 'promesa' FROM categories c WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB-23', 'sub-23' FROM categories c WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SUB23', 'sub23' FROM categories c WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub 23', 'sub23' FROM categories c WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sub23', 'sub23' FROM categories c WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Absoluta', 'absoluta' FROM categories c WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Absoluto', 'absoluto' FROM categories c WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SENIOR/ABSOLUTA', 'senior/absoluta' FROM categories c WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'SENIOR_ABSOLUTA', 'senior_absoluta' FROM categories c WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Senior', 'senior' FROM categories c WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'Sénior', 'senior' FROM categories c WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-35', 'master-35' FROM categories c WHERE c.code='MASTER-35' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-40', 'master-40' FROM categories c WHERE c.code='MASTER-40' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-45', 'master-45' FROM categories c WHERE c.code='MASTER-45' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-50', 'master-50' FROM categories c WHERE c.code='MASTER-50' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-55', 'master-55' FROM categories c WHERE c.code='MASTER-55' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-60', 'master-60' FROM categories c WHERE c.code='MASTER-60' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-65', 'master-65' FROM categories c WHERE c.code='MASTER-65' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-70', 'master-70' FROM categories c WHERE c.code='MASTER-70' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-75', 'master-75' FROM categories c WHERE c.code='MASTER-75' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-80', 'master-80' FROM categories c WHERE c.code='MASTER-80' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-85', 'master-85' FROM categories c WHERE c.code='MASTER-85' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-90', 'master-90' FROM categories c WHERE c.code='MASTER-90' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-95', 'master-95' FROM categories c WHERE c.code='MASTER-95' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);
INSERT INTO category_aliases (category_id, alias, alias_normalized) SELECT c.id, 'MASTER-100', 'master-100' FROM categories c WHERE c.code='MASTER-100' ON DUPLICATE KEY UPDATE category_id=VALUES(category_id);

-- Pruebas

INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Decatlón', 'decatlon', NULL, NULL, NULL, 0, 1, 0 FROM sectors s WHERE s.name_normalized='combinadas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Heptatlón', 'heptatlon', NULL, NULL, NULL, 0, 1, 0 FROM sectors s WHERE s.name_normalized='combinadas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Hexatlón', 'hexatlon', NULL, NULL, NULL, 0, 1, 0 FROM sectors s WHERE s.name_normalized='combinadas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Octatlón', 'octatlon', NULL, NULL, NULL, 0, 1, 0 FROM sectors s WHERE s.name_normalized='combinadas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Pentatlón', 'pentatlon', NULL, NULL, NULL, 0, 1, 0 FROM sectors s WHERE s.name_normalized='combinadas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '10000m', '10000m', 10000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='fondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '1500 Obts', '1500obts', NULL, NULL, NULL, 0, 0, 1 FROM sectors s WHERE s.name_normalized='fondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '3000 Obts', '3000obts', NULL, NULL, NULL, 0, 0, 1 FROM sectors s WHERE s.name_normalized='fondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '3000m', '3000m', 3000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='fondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '5000m', '5000m', 5000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='fondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Disco (1,5kg)', 'disco(1.5kg)', NULL, 1500, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Disco (1,750kg)', 'disco(1.750kg)', NULL, 1750, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Disco (1kg)', 'disco(1kg)', NULL, 1000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Disco (2kg)', 'disco(2kg)', NULL, 2000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Disco (800g)', 'disco(800g)', NULL, 800, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Jabalina (400g)', 'jabalina(400g)', NULL, 400, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Jabalina (500g)', 'jabalina(500g)', NULL, 500, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Jabalina (600g)', 'jabalina(600g)', NULL, 600, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Jabalina (700g)', 'jabalina(700g)', NULL, 700, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Jabalina (800g)', 'jabalina(800g)', NULL, 800, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Martillo (3kg)', 'martillo(3kg)', NULL, 3000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Martillo (4kg)', 'martillo(4kg)', NULL, 4000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Martillo (5kg)', 'martillo(5kg)', NULL, 5000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Martillo (6kg)', 'martillo(6kg)', NULL, 6000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Martillo (7,260kg)', 'martillo(7.260kg)', NULL, 7260, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Peso (2kg)', 'peso(2kg)', NULL, 2000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Peso (3kg)', 'peso(3kg)', NULL, 3000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Peso (4kg)', 'peso(4kg)', NULL, 4000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Peso (5kg)', 'peso(5kg)', NULL, 5000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Peso (6kg)', 'peso(6kg)', NULL, 6000, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Peso (7,260kg)', 'peso(7.260kg)', NULL, 7260, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Vórtex', 'vortex', NULL, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='lanzamientos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '10000m', '10000m', 10000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='marcha' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '1000m', '1000m', 1000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='marcha' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '20000m', '20000m', 20000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='marcha' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '2000m', '2000m', 2000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='marcha' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '3000m', '3000m', 3000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='marcha' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '35km/50km', '35km/50km', NULL, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='marcha' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '5000m', '5000m', 5000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='marcha' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '1000m', '1000m', 1000.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='mediofondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '1500m', '1500m', 1500.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='mediofondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '500m', '500m', 500.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='mediofondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '600m', '600m', 600.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='mediofondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '800m', '800m', 800.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='mediofondo' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '4x100', '4x100', NULL, NULL, NULL, 1, 0, 0 FROM sectors s WHERE s.name_normalized='relevos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '4x300', '4x300', NULL, NULL, NULL, 1, 0, 0 FROM sectors s WHERE s.name_normalized='relevos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '4x400', '4x400', NULL, NULL, NULL, 1, 0, 0 FROM sectors s WHERE s.name_normalized='relevos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '4x50', '4x50', NULL, NULL, NULL, 1, 0, 0 FROM sectors s WHERE s.name_normalized='relevos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '4x60', '4x60', NULL, NULL, NULL, 1, 0, 0 FROM sectors s WHERE s.name_normalized='relevos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '4x80', '4x80', NULL, NULL, NULL, 1, 0, 0 FROM sectors s WHERE s.name_normalized='relevos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '5x80', '5x80', NULL, NULL, NULL, 1, 0, 0 FROM sectors s WHERE s.name_normalized='relevos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Altura', 'altura', NULL, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='saltos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Longitud', 'longitud', NULL, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='saltos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Pértiga', 'pertiga', NULL, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='saltos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, 'Triple', 'triple', NULL, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='saltos' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '100mv (0,762)', '100mv(0.762)', 100.0, NULL, 0.762, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '100mv (0,84)', '100mv(0.84)', 100.0, NULL, 0.84, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '100mv (0,914)', '100mv(0.914)', 100.0, NULL, 0.914, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '100mv (0,991)', '100mv(0.991)', 100.0, NULL, 0.991, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '100mv (1,067)', '100mv(1.067)', 100.0, NULL, 1.067, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '110mv (1,067)', '110mv(1.067)', 110.0, NULL, 1.067, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '220mv (0,762)', '220mv(0.762)', 220.0, NULL, 0.762, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '300mv (0,762)', '300mv(0.762)', 300.0, NULL, 0.762, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '300mv (0,84)', '300mv(0.84)', 300.0, NULL, 0.84, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '400mv (0,762)', '400mv(0.762)', 400.0, NULL, 0.762, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '400mv (0,838)', '400mv(0.838)', 400.0, NULL, 0.838, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '400mv (0,914)', '400mv(0.914)', 400.0, NULL, 0.914, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '50mv (0,50)', '50mv(0.50)', 50.0, NULL, 0.5, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '50mv (0,60)', '50mv(0.60)', 50.0, NULL, 0.6, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '60mv (0,762)', '60mv(0.762)', 60.0, NULL, 0.762, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '60mv (0,84)', '60mv(0.84)', 60.0, NULL, 0.84, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '60mv (0,914)', '60mv(0.914)', 60.0, NULL, 0.914, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '60mv (0,991)', '60mv(0.991)', 60.0, NULL, 0.991, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '60mv (1,067)', '60mv(1.067)', 60.0, NULL, 1.067, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '80mv (0,762)', '80mv(0.762)', 80.0, NULL, 0.762, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '80mv (0,84)', '80mv(0.84)', 80.0, NULL, 0.84, 0, 0, 0 FROM sectors s WHERE s.name_normalized='vallas' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '100m', '100m', 100.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='velocidad' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '200m', '200m', 200.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='velocidad' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '300m', '300m', 300.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='velocidad' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '400m', '400m', 400.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='velocidad' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '50m', '50m', 50.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='velocidad' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;
INSERT INTO event_types (sector_id, name, name_normalized, distance_meters, implement_weight_grams, hurdle_height_meters, is_relay, is_combined, has_obstacles) SELECT s.id, '60m', '60m', 60.0, NULL, NULL, 0, 0, 0 FROM sectors s WHERE s.name_normalized='velocidad' ON DUPLICATE KEY UPDATE name=VALUES(name), sector_id=VALUES(sector_id), distance_meters=VALUES(distance_meters), implement_weight_grams=VALUES(implement_weight_grams), hurdle_height_meters=VALUES(hurdle_height_meters), is_relay=VALUES(is_relay), is_combined=VALUES(is_combined), has_obstacles=VALUES(has_obstacles), updated_at=CURRENT_TIMESTAMP;

-- Relaciones categoría-prueba por género

INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='50m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='4x50' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-8' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='50m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='50mv(0.50)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.5) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='peso(2kg)' AND (e.implement_weight_grams <=> 2000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='4x50' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='vortex' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-10' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='50mv(0.60)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.6) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='peso(2kg)' AND (e.implement_weight_grams <=> 2000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='4x60' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='600m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='vortex' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'BOTH' FROM categories c JOIN event_types e ON e.name_normalized='2000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-12' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='peso(3kg)' AND (e.implement_weight_grams <=> 3000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x80' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='600m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='80mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(400g)' AND (e.implement_weight_grams <=> 400) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='2000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='5x80' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='220mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='peso(3kg)' AND (e.implement_weight_grams <=> 3000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x80' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='600m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='80mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(500g)' AND (e.implement_weight_grams <=> 500) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='2000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='5x80' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='220mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-14' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='600m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='peso(3kg)' AND (e.implement_weight_grams <=> 3000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pentatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1500obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='disco(800g)' AND (e.implement_weight_grams <=> 800) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='hexatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x300' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='300m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='300mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(500g)' AND (e.implement_weight_grams <=> 500) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='martillo(3kg)' AND (e.implement_weight_grams <=> 3000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='600m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='peso(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='hexatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1500obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.914)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.914) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='disco(1kg)' AND (e.implement_weight_grams <=> 1000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='octatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x300' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='300m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='300mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(600g)' AND (e.implement_weight_grams <=> 600) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='martillo(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-16' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='peso(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pentatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='disco(1kg)' AND (e.implement_weight_grams <=> 1000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(600g)' AND (e.implement_weight_grams <=> 600) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='martillo(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.914)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.914) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='peso(5kg)' AND (e.implement_weight_grams <=> 5000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.914)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.914) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='disco(1.5kg)' AND (e.implement_weight_grams <=> 1500) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='decatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.838)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.838) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(700g)' AND (e.implement_weight_grams <=> 700) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='martillo(5kg)' AND (e.implement_weight_grams <=> 5000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-18' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='peso(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pentatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='disco(1kg)' AND (e.implement_weight_grams <=> 1000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(600g)' AND (e.implement_weight_grams <=> 600) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='martillo(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.991)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.991) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='peso(6kg)' AND (e.implement_weight_grams <=> 6000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pentatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.991)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.991) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='disco(1.750kg)' AND (e.implement_weight_grams <=> 1750) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='10000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.914)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.914) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(800g)' AND (e.implement_weight_grams <=> 800) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='martillo(6kg)' AND (e.implement_weight_grams <=> 6000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='martillo(7.260kg)' AND (e.implement_weight_grams <=> 7260) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-20' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='peso(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pentatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='disco(1kg)' AND (e.implement_weight_grams <=> 1000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='10000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(600g)' AND (e.implement_weight_grams <=> 600) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='martillo(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60mv(1.067)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 1.067) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='peso(7.260kg)' AND (e.implement_weight_grams <=> 7260) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pentatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100mv(1.067)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 1.067) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='disco(2kg)' AND (e.implement_weight_grams <=> 2000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='10000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.914)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.914) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(800g)' AND (e.implement_weight_grams <=> 800) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='martillo(7.260kg)' AND (e.implement_weight_grams <=> 7260) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SUB-23' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='60mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='peso(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pentatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='100mv(0.84)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.84) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='disco(1kg)' AND (e.implement_weight_grams <=> 1000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='10000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.762)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.762) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(600g)' AND (e.implement_weight_grams <=> 600) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'F' FROM categories c JOIN event_types e ON e.name_normalized='martillo(4kg)' AND (e.implement_weight_grams <=> 4000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='800m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='60mv(1.067)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 1.067) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='longitud' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='peso(7.260kg)' AND (e.implement_weight_grams <=> 7260) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='heptatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='5000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x100' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='100m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='110mv(1.067)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 1.067) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='altura' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='disco(2kg)' AND (e.implement_weight_grams <=> 2000) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='decatlon' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='10000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='4x400' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='200m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='1500m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400mv(0.914)' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> 0.914) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='pertiga' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='jabalina(800g)' AND (e.implement_weight_grams <=> 800) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='20000m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='400m' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='3000obts' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='triple' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='martillo(7.260kg)' AND (e.implement_weight_grams <=> 7260) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT c.id, e.id, 'M' FROM categories c JOIN event_types e ON e.name_normalized='35km/50km' AND (e.implement_weight_grams <=> NULL) AND (e.hurdle_height_meters <=> NULL) WHERE c.code='SENIOR_ABSOLUTA' ON DUPLICATE KEY UPDATE gender=VALUES(gender);

-- Relaciones Master: se toman como referencia las pruebas SENIOR/ABSOLUTA del mismo género

INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-35' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-40' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-45' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-50' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-55' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-60' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-65' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-70' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-75' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-80' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-85' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-90' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-95' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);
INSERT INTO category_event_types (category_id, event_type_id, gender) SELECT cm.id, cet.event_type_id, cet.gender FROM categories cm JOIN categories cs ON cs.code='SENIOR_ABSOLUTA' JOIN category_event_types cet ON cet.category_id=cs.id WHERE cm.code='MASTER-100' AND cet.gender IN ('M','F') ON DUPLICATE KEY UPDATE gender=VALUES(gender);

CREATE TABLE venues (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(255) NOT NULL,
    name_normalized VARCHAR(255) NOT NULL,

    city VARCHAR(100) NULL,

    is_indoor BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_venues_name_normalized (name_normalized)
);

ALTER TABLE competitions
ADD COLUMN venue_id BIGINT NULL,
ADD CONSTRAINT fk_competitions_venue
    FOREIGN KEY (venue_id)
    REFERENCES venues(id);

ALTER TABLE competitions
MODIFY COLUMN venue VARCHAR(255) NULL;

INSERT INTO venues (
    name,
    name_normalized,
    city,
    is_indoor
) VALUES

-- PISTA CUBIERTA
(
    'Gallur',
    'GALLUR',
    'Madrid',
    TRUE
),

-- PISTAS AIRE LIBRE
(
    'Vallehermoso',
    'VALLEHERMOSO',
    'Madrid',
    FALSE
),
(
    'Moratalaz',
    'MORATALAZ',
    'Madrid',
    FALSE
),
(
    'Aluche',
    'ALUCHE',
    'Madrid',
    FALSE
),
(
    'Getafe',
    'GETAFE',
    'Getafe',
    FALSE
),
(
    'Móstoles',
    'MOSTOLES',
    'Móstoles',
    FALSE
),
(
    'Leganés',
    'LEGANES',
    'Leganés',
    FALSE
),
(
    'Fuenlabrada',
    'FUENLABRADA',
    'Fuenlabrada',
    FALSE
),
(
    'Parla',
    'PARLA',
    'Parla',
    FALSE
),
(
    'Alcorcón',
    'ALCORCON',
    'Alcorcón',
    FALSE
),
(
    'Alcalá de Henares',
    'ALCALA DE HENARES',
    'Alcalá de Henares',
    FALSE
),
(
    'Coslada',
    'COSLADA',
    'Coslada',
    FALSE
),
(
    'Arganda',
    'ARGANDA',
    'Arganda del Rey',
    FALSE
),
(
    'Rivas-Vaciamadrid',
    'RIVAS VACIAMADRID',
    'Rivas-Vaciamadrid',
    FALSE
),
(
    'Tres Cantos',
    'TRES CANTOS',
    'Tres Cantos',
    FALSE
),
(
    'Collado Villalba',
    'COLLADO VILLALBA',
    'Collado Villalba',
    FALSE
),
(
    'Aranjuez',
    'ARANJUEZ',
    'Aranjuez',
    FALSE
),
(
    'Majadahonda',
    'MAJADAHONDA',
    'Majadahonda',
    FALSE
),
(
    'Pozuelo',
    'POZUELO',
    'Pozuelo de Alarcón',
    FALSE
),
(
    'San Sebastián de los Reyes',
    'SAN SEBASTIAN DE LOS REYES',
    'San Sebastián de los Reyes',
    FALSE
),
(
    'Colmenar Viejo',
    'COLMENAR VIEJO',
    'Colmenar Viejo',
    FALSE
)

ON DUPLICATE KEY UPDATE
    city = VALUES(city),
    is_indoor = VALUES(is_indoor);

-- Fin del script
