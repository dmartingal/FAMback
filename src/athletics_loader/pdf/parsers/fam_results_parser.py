from __future__ import annotations

from datetime import date, datetime, time
from pathlib import Path
import re

from athletics_loader.utils.categories import category_from_birth_date, normalize_category_alias
from athletics_loader.utils.text import normalize_name
from .base import BasePdfParser


TIME_ONLY = re.compile(r"^(?P<time>\d{2}:\d{2})$")
DATE_EVENT_HEADER = re.compile(r"^(?P<date>\d{2}/\d{2}/\d{4})\s+(?P<name>.+)$")
INLINE_EVENT_HEADER = re.compile(r"^(?P<time>\d{2}:\d{2})\s+(?P<date>\d{2}/\d{2}/\d{4})\s+(?P<name>.+)$")
WIND = re.compile(r"^Viento:\s*(?P<wind>[+-]?\d+(?:[.,]\d+)?)$", re.IGNORECASE)
ACTA_ROUND = re.compile(
    r"^(?P<round>(?:Serie\s+\d+)|(?:Final(?:\s+[A-Z])?))\s+"
    r"(?P<date>\d{2}/\d{2}/\d{4})\s+(?P<time>\d{2}:\d{2})$",
    re.IGNORECASE,
)
SEX = re.compile(r"\b(?P<sex>Femenino|Masculino|Fem|Masc)\b", re.IGNORECASE)
TEXT_CATEGORY = re.compile(
    r"\b(?P<category>Sub\s*\d{1,2}|Abs|Infantil|Inf|Cadete|Cad|Juvenil|Juv|Junior|Promesa|Absolut[ao]|Senior)\b",
    re.IGNORECASE,
)
SPANISH_DATE_LINE = re.compile(
    r"^(?P<venue>.*?)(?:,\s*|\s+)(?P<day>\d{1,2})\s+(?P<month>[A-Za-z]+)\s+(?P<year>\d{4})$"
)

STATUS_MAP = {
    "DNS": "DNS",
    "NP": "NP",
    "NM": "NM",
    "SM": "NM",
    "DNF": "DNF",
    "DQ": "DQ",
}

SPANISH_MONTHS = {
    "ene": 1,
    "enero": 1,
    "feb": 2,
    "febrero": 2,
    "mar": 3,
    "marzo": 3,
    "abr": 4,
    "abril": 4,
    "may": 5,
    "mayo": 5,
    "jun": 6,
    "junio": 6,
    "jul": 7,
    "julio": 7,
    "ago": 8,
    "agosto": 8,
    "sep": 9,
    "sept": 9,
    "septiembre": 9,
    "oct": 10,
    "octubre": 10,
    "nov": 11,
    "noviembre": 11,
    "dic": 12,
    "diciembre": 12,
}


class FamResultsParser(BasePdfParser):
    def can_parse(self, pdf_path: Path, pages: list[str]) -> bool:
        text = "\n".join(pages)
        return (
            "RESULTADOS" in text
            or "ACTA DEL CAMPEONATO" in text
            or any(INLINE_EVENT_HEADER.match(line.strip()) for page in pages for line in page.splitlines())
        )

    def parse(self, pdf_path: Path, pages: list[str]) -> dict:
        page_lines = self._clean_page_lines(pages)
        events = self._parse_fam_result_events(page_lines)
        events.extend(self._parse_acta_events(page_lines))
        return {
            "pdf": pdf_path.name,
            "parser": "fam_results",
            "competition": self._detect_competition(page_lines, events),
            "events_detected": len(events),
            "results_detected": sum(len(event["results"]) for event in events),
            "events": events,
            "pages": len(pages),
        }

    def _clean_page_lines(self, pages: list[str]) -> list[dict]:
        lines = []
        for page_number, page in enumerate(pages, start=1):
            for raw_line in (page or "").splitlines():
                line = re.sub(r"\s+", " ", raw_line).strip()
                if line:
                    lines.append({"text": line, "page_number": page_number})
        return lines

    def _parse_fam_result_events(self, page_lines: list[dict]) -> list[dict]:
        events = []
        for page_number in sorted({line["page_number"] for line in page_lines}):
            lines = [line for line in page_lines if line["page_number"] == page_number]
            index = 0
            while index < len(lines):
                header = self._match_fam_header(lines, index)
                if not header:
                    index += 1
                    continue

                next_index = self._find_next_fam_header(lines, index + header["consumed"])
                block = lines[index:next_index]
                event = self._parse_fam_event_block(block, header)
                if event:
                    events.append(event)
                index = next_index
        return events

    def _match_fam_header(self, lines: list[dict], index: int) -> dict | None:
        line = lines[index]["text"]
        inline = INLINE_EVENT_HEADER.match(line)
        if inline:
            return {
                "time": inline.group("time"),
                "date": inline.group("date"),
                "name": inline.group("name"),
                "consumed": 1,
            }

        time_match = TIME_ONLY.match(line)
        if time_match and index + 1 < len(lines):
            date_match = DATE_EVENT_HEADER.match(lines[index + 1]["text"])
            if date_match:
                return {
                    "time": time_match.group("time"),
                    "date": date_match.group("date"),
                    "name": date_match.group("name"),
                    "consumed": 2,
                }
        return None

    def _find_next_fam_header(self, lines: list[dict], start: int) -> int:
        for index in range(start, len(lines)):
            if self._match_fam_header(lines, index):
                return index
        return len(lines)

    def _parse_fam_event_block(self, block: list[dict], header: dict) -> dict | None:
        event_date = _parse_slash_date(header["date"])
        descriptor = self._parse_event_descriptor(header["name"])
        page_number = block[0]["page_number"]
        event = self._new_event(
            descriptor=descriptor,
            event_date=event_date,
            event_time=header["time"],
            page_number=page_number,
            raw_header_text=f"{header['time']} {header['date']} {header['name']}",
        )

        data_start = header["consumed"]
        table_header = ""
        detail_header = ""
        tail_mode = None
        for index, item in enumerate(block[data_start:], start=data_start):
            line = item["text"]
            wind_match = WIND.match(line)
            if wind_match:
                event["wind"] = _decimal(wind_match.group("wind"))
                data_start = index + 1
                continue
            if line.startswith("Pto."):
                table_header = line
                if index + 1 < len(block) and block[index + 1]["text"] in {"FN", "Cat."}:
                    detail_header = block[index + 1]["text"]
                    tail_mode = "fn" if detail_header == "FN" else "cat"
                    data_start = index + 2
                elif index + 1 < len(block) and block[index + 1]["text"].startswith(("FN", "Cat.")):
                    detail_header = block[index + 1]["text"]
                    tail_mode = "fn" if detail_header.startswith("FN") else "cat"
                    data_start = index + 2
                else:
                    data_start = index + 1
                break

        event["attempt_headers"] = self._parse_attempt_headers(table_header, detail_header)
        event["event_type"] = self._detect_event_type(event["event_name"], event["attempt_headers"])
        event["results"], event["unparsed_lines"] = self._parse_fam_rows(
            block[data_start:],
            event,
            tail_mode,
        )
        return event

    def _parse_fam_rows(self, lines: list[dict], event: dict, tail_mode: str | None) -> tuple[list[dict], list[str]]:
        results = []
        unparsed = []
        index = 0
        while index < len(lines):
            line = lines[index]["text"]
            if self._skip_line(line):
                index += 1
                continue
            if line.startswith("#"):
                event["notes"].append(line)
                index += 1
                continue
            if index + 1 >= len(lines):
                unparsed.append(line)
                index += 1
                continue

            first = self._parse_result_with_license(line, event["attempt_headers"], event["event_type"])
            if not first:
                split_result = self._parse_split_fam_result(lines[index:index + 4], event)
                if split_result:
                    results.append(split_result)
                    index += 4
                    continue
                unparsed.append(line)
                index += 1
                continue

            tail = self._parse_fam_tail(lines[index + 1]["text"], tail_mode)
            result = self._build_result(event, first, tail, raw_lines=[line, lines[index + 1]["text"]])
            results.append(result)
            index += 2
        return results, unparsed

    def _parse_split_fam_result(self, lines: list[dict], event: dict) -> dict | None:
        if len(lines) < 4:
            return None
        first_line = lines[0]["text"]
        first_tokens = first_line.split()
        prefix = _parse_position_dorsal(first_tokens)
        if not prefix:
            return None

        birth_values = lines[3]["text"].split()
        if not birth_values:
            return None
        birth_date = _parse_loose_date(birth_values[0])
        if not birth_date:
            return None

        mark_info = self._parse_mark_and_attempts(birth_values[1:], event["attempt_headers"], event["event_type"])
        first = {
            "position": prefix["position"],
            "dorsal": prefix["dorsal"],
            "athlete": " ".join(first_tokens[prefix["next_index"]:]),
            "license": lines[2]["text"],
            "birth_date": birth_date.isoformat(),
            "lane": None,
            "order_number": None,
            **mark_info,
        }
        tail = {"club": lines[1]["text"], "birth_date": birth_date.isoformat()}
        return self._build_result(event, first, tail, raw_lines=[line["text"] for line in lines])

    def _parse_acta_events(self, page_lines: list[dict]) -> list[dict]:
        events = []
        for page_number in sorted({line["page_number"] for line in page_lines}):
            lines = [line for line in page_lines if line["page_number"] == page_number]
            title_indexes = [index for index in range(len(lines)) if self._is_acta_event_title(lines, index)]
            for position, start in enumerate(title_indexes):
                end = title_indexes[position + 1] if position + 1 < len(title_indexes) else len(lines)
                events.extend(self._parse_acta_event_block(lines[start:end]))
        return events

    def _is_acta_event_title(self, lines: list[dict], index: int) -> bool:
        line = lines[index]["text"]
        if self._skip_line(line) or line in {"ACTA DEL CAMPEONATO", "Final", "Nombre F de Nac", "Club Lic"}:
            return False
        if "RESULTADOS" in line or "Página" in line or "PÁGINA" in normalize_name(line):
            return False
        if not SEX.search(line):
            return False
        next_line = lines[index + 1]["text"] if index + 1 < len(lines) else ""
        return next_line in {"Final", "Nombre F de Nac"}

    def _parse_acta_event_block(self, block: list[dict]) -> list[dict]:
        if not block:
            return []
        descriptor = self._parse_event_descriptor(block[0]["text"])
        table_header = ""
        for item in block:
            if item["text"].startswith("Pto Dor"):
                table_header = item["text"]
                break
        attempt_headers = self._parse_acta_attempt_headers(table_header)
        event_type = self._detect_event_type(descriptor["event_name"], attempt_headers)

        round_indexes = [index for index, item in enumerate(block) if ACTA_ROUND.match(item["text"])]
        events = []
        for position, round_index in enumerate(round_indexes):
            round_match = ACTA_ROUND.match(block[round_index]["text"])
            if not round_match:
                continue
            next_round_index = round_indexes[position + 1] if position + 1 < len(round_indexes) else len(block)
            event_date = _parse_slash_date(round_match.group("date"))
            round_name = self._compose_round_name(descriptor.get("round_name"), round_match.group("round"))
            event = self._new_event(
                descriptor={**descriptor, "round_name": round_name},
                event_date=event_date,
                event_time=round_match.group("time"),
                page_number=block[0]["page_number"],
                raw_header_text=f"{block[0]['text']} | {block[round_index]['text']}",
            )
            event["attempt_headers"] = attempt_headers
            event["event_type"] = event_type
            event["round_type"] = self._round_type(round_name)
            event["results"], event["unparsed_lines"] = self._parse_acta_rows(
                block[round_index + 1:next_round_index],
                event,
                table_header,
            )
            events.append(event)
        return events

    def _parse_acta_rows(self, lines: list[dict], event: dict, table_header: str) -> tuple[list[dict], list[str]]:
        results = []
        unparsed = []
        index = 0
        while index < len(lines):
            line = lines[index]["text"]
            if self._skip_line(line):
                index += 1
                continue
            if line.startswith("#"):
                event["notes"].append(line)
                index += 1
                continue

            first = self._parse_acta_result_line(line, event["attempt_headers"], event["event_type"], table_header)
            if not first:
                unparsed.append(line)
                index += 1
                continue
            if index + 1 >= len(lines):
                unparsed.append(line)
                index += 1
                continue

            tail = self._parse_club_license(lines[index + 1]["text"])
            raw_lines = [line, lines[index + 1]["text"]]
            consumed = 2
            if event["event_type"] == "height":
                compact_attempts = []
                attempt_index = index + 2
                while attempt_index < len(lines):
                    parsed_attempts = self._parse_compact_height_attempts(lines[attempt_index]["text"])
                    if not parsed_attempts:
                        break
                    compact_attempts.extend(parsed_attempts)
                    raw_lines.append(lines[attempt_index]["text"])
                    attempt_index += 1
                if compact_attempts:
                    for number, attempt in enumerate(compact_attempts, start=1):
                        attempt["attempt_number"] = number
                    first["attempts"] = compact_attempts
                    consumed = attempt_index - index

            result = self._build_result(event, first, tail, raw_lines=raw_lines)
            results.append(result)
            index += consumed
        return results, unparsed

    def _new_event(self, descriptor: dict, event_date: date, event_time: str, page_number: int, raw_header_text: str) -> dict:
        event_datetime = datetime.combine(event_date, _parse_time(event_time))
        return {
            "time": event_time,
            "date": event_date.isoformat(),
            "event_datetime": event_datetime.isoformat(sep=" "),
            **descriptor,
            "wind": None,
            "attempt_headers": [],
            "event_type": "race",
            "round_type": self._round_type(descriptor.get("round_name")),
            "page_number": page_number,
            "raw_header_text": raw_header_text,
            "notes": [],
            "results": [],
            "unparsed_lines": [],
        }

    def _parse_event_descriptor(self, descriptor: str) -> dict:
        sex_match = SEX.search(descriptor)
        sex = None
        round_name = None
        before_sex = descriptor
        if sex_match:
            sex_text = sex_match.group("sex").lower()
            sex = "F" if sex_text.startswith("f") else "M"
            before_sex = descriptor[: sex_match.start()].strip()
            round_name = descriptor[sex_match.end():].strip() or None

        category_match = TEXT_CATEGORY.search(before_sex)
        category_text = None
        event_name = before_sex
        if category_match:
            category_text = normalize_category_alias(category_match.group("category"))
            event_name = before_sex[: category_match.start()].strip()

        implement = None
        implement_match = re.search(r"\((?P<implement>[^)]+)\)", event_name)
        if implement_match:
            implement = implement_match.group("implement")

        return {
            "event_name": event_name.strip(),
            "implement": implement,
            "category_text": category_text,
            "sex": sex,
            "round_name": round_name,
            "raw_name": descriptor,
        }

    def _parse_attempt_headers(self, table_header: str, detail_header: str) -> list[str]:
        for source in (detail_header, table_header):
            content = source
            content = re.sub(r"^(FN|Cat\.)\s*", "", content).strip()
            content = re.sub(r"^Pto\.\s*Dorsal\s*Atleta\s*", "", content).strip()
            content = re.sub(r"^Pto\.\s*DorsalAtleta\s*", "", content).strip()
            content = re.sub(r"\b(Resultado|Marca)\b", "", content).strip()
            content = content.replace("Lic.", "").strip()
            if not content:
                continue
            return _split_attempt_header(content)
        return []

    def _parse_acta_attempt_headers(self, table_header: str) -> list[str]:
        content = re.sub(r"^Pto\s+Dor\s*", "", table_header).strip()
        content = re.sub(r"\b(Calle|Orden|Marca|Resultado)\b", "", content).strip()
        return content.split() if content else []

    def _detect_event_type(self, event_name: str, attempt_headers: list[str]) -> str:
        normalized = normalize_name(event_name)
        if "ALTURA" in normalized or "PERTIGA" in normalized:
            return "height"
        if attempt_headers:
            return "field"
        return "race"

    def _parse_result_with_license(self, line: str, attempt_headers: list[str], event_type: str) -> dict | None:
        tokens = line.split()
        prefix = _parse_position_dorsal(tokens)
        if not prefix:
            return None
        rest = tokens[prefix["next_index"]:]
        license_index = _find_license_index(rest)
        if license_index is None or license_index == 0:
            return None

        values = rest[license_index + 1:]
        mark_info = self._parse_mark_and_attempts(values, attempt_headers, event_type)
        return {
            "position": prefix["position"],
            "dorsal": prefix["dorsal"],
            "athlete": " ".join(rest[:license_index]),
            "license": rest[license_index],
            **mark_info,
            "lane": None,
            "order_number": None,
        }

    def _parse_acta_result_line(self, line: str, attempt_headers: list[str], event_type: str, table_header: str) -> dict | None:
        tokens = line.split()
        birth_index = _find_birth_date_index(tokens)
        if birth_index is None:
            return None

        prefix = _parse_position_dorsal(tokens[:birth_index])
        if not prefix:
            return None
        athlete_tokens = tokens[prefix["next_index"]:birth_index]
        birth_date = _parse_loose_date(tokens[birth_index])
        values = tokens[birth_index + 1:]
        if not values:
            return None

        lane = None
        order_number = None
        if "Calle" in table_header and len(values) >= 2:
            lane = _to_int(values[0])
            values = values[1:]
        elif "Orden" in table_header and len(values) >= 2:
            order_number = _to_int(values[0])
            values = values[1:]

        mark_info = self._parse_mark_and_attempts(values, attempt_headers, event_type)
        return {
            "position": prefix["position"],
            "dorsal": prefix["dorsal"],
            "athlete": " ".join(athlete_tokens),
            "birth_date": birth_date.isoformat() if birth_date else None,
            "lane": lane,
            "order_number": order_number,
            **mark_info,
        }

    def _parse_fam_tail(self, line: str, tail_mode: str | None) -> dict:
        if tail_mode == "fn":
            club, birth_date = _split_text_date_tail(line)
            return {"club": club, "birth_date": birth_date.isoformat() if birth_date else None}
        if tail_mode == "cat":
            club, category = _split_text_last_token(line)
            return {"club": club, "category_text": normalize_category_alias(category)}

        club, birth_date = _split_text_date_tail(line)
        if birth_date:
            return {"club": club, "birth_date": birth_date.isoformat()}
        club, category = _split_text_last_token(line)
        return {"club": club, "category_text": normalize_category_alias(category)}

    def _parse_club_license(self, line: str) -> dict:
        tokens = line.split()
        license_index = _find_license_index(tokens, from_right=True)
        if license_index is None:
            return {"club": line, "license": None}
        return {"club": " ".join(tokens[:license_index]), "license": tokens[license_index]}

    def _build_result(self, event: dict, first: dict, tail: dict, raw_lines: list[str]) -> dict:
        birth_date = first.get("birth_date") or tail.get("birth_date")
        category_calculated = None
        if birth_date:
            category_calculated = category_from_birth_date(_parse_iso_date(event["date"]), _parse_iso_date(birth_date))
        category_text = tail.get("category_text") or event.get("category_text")
        athlete = first.get("athlete", "").strip()
        return {
            "position": first.get("position"),
            "dorsal": first.get("dorsal"),
            "athlete": athlete,
            "club": tail.get("club"),
            "license": first.get("license") or tail.get("license"),
            "birth_date": birth_date,
            "athlete_key": f"{normalize_name(athlete)}|{birth_date}" if birth_date else None,
            "category_calculated": category_calculated,
            "category_text": category_text,
            "category": category_text or category_calculated,
            "lane": first.get("lane"),
            "order_number": first.get("order_number"),
            "mark": first.get("mark"),
            "status": first.get("status"),
            "status_original": first.get("status_original"),
            "wind": event.get("wind"),
            "attempts": first.get("attempts", []),
            "raw_text": "\n".join(raw_lines),
        }

    def _parse_mark_and_attempts(self, raw_values: list[str], attempt_headers: list[str], event_type: str) -> dict:
        if not raw_values:
            return {"mark": None, "status": "UNKNOWN", "status_original": None, "attempts": []}

        status_token = raw_values[0].upper()
        if status_token in STATUS_MAP:
            return {
                "mark": None,
                "status": STATUS_MAP[status_token],
                "status_original": " ".join(raw_values),
                "attempts": [],
            }

        mark = raw_values[-1]
        status = STATUS_MAP.get(mark.upper(), "OK")
        attempts = []
        if status == "OK":
            for number, value in enumerate(raw_values[:-1], start=1):
                header = attempt_headers[number - 1] if number <= len(attempt_headers) else None
                attempts.append(
                    {
                        "attempt_number": number,
                        "height_or_distance": header if event_type == "height" else None,
                        "attempt_value_raw": value,
                        "attempt_status": self._attempt_status(value, event_type),
                    }
                )
        return {
            "mark": None if status != "OK" else mark,
            "status": status,
            "status_original": mark if status != "OK" else None,
            "attempts": attempts,
        }

    def _parse_compact_height_attempts(self, line: str) -> list[dict]:
        parts = [part.strip() for part in line.split("/") if part.strip()]
        attempts = []
        for number, part in enumerate(parts, start=1):
            tokens = part.split()
            if len(tokens) != 2 or not _is_decimal(tokens[0]):
                return []
            attempts.append(
                {
                    "attempt_number": number,
                    "height_or_distance": _decimal(tokens[0]),
                    "attempt_value_raw": tokens[1],
                    "attempt_status": self._attempt_status(tokens[1], "height"),
                }
            )
        return attempts

    def _attempt_status(self, value: str, event_type: str) -> str:
        upper = value.upper()
        if upper == "-":
            return "PASS"
        if event_type == "height":
            if re.fullmatch(r"X+", upper):
                return "FAIL"
            if "O" in upper:
                return "VALID"
        if upper == "X":
            return "FOUL"
        if _is_decimal(upper):
            return "VALID"
        return "UNKNOWN"

    def _compose_round_name(self, descriptor_round: str | None, round_label: str) -> str:
        if descriptor_round and round_label.lower() == "final":
            return descriptor_round
        if descriptor_round:
            return f"{round_label} {descriptor_round}"
        return round_label

    def _round_type(self, round_name: str | None) -> str | None:
        if not round_name:
            return None
        normalized = normalize_name(round_name)
        if "SERIE" in normalized:
            return "SERIE"
        if "FINAL" in normalized:
            return "FINAL"
        if "GRUPO" in normalized or re.fullmatch(r"[A-Z]", round_name.strip()):
            return "GRUPO"
        return "OTRO"

    def _skip_line(self, line: str) -> bool:
        normalized = normalize_name(line)
        return (
            not line
            or line.startswith("Lic.")
            or line.startswith("Pto.")
            or line.startswith("Pto Dor")
            or line in {"FN", "Cat.", "Club Lic", "Nombre F de Nac", "Final"}
            or line.startswith("Pto. Puesto")
            or re.match(r"^(DNS|DQ|DNF|NP|NM|SM)\b", line)
            or "LICENCIA - " in normalized
            or "INFRACCION" in normalized
            or "NO PRESENTADO" in normalized
            or "DESCALIFICADO" in normalized
            or "PAGINA" in normalized
        )

    def _detect_competition(self, page_lines: list[dict], events: list[dict]) -> dict:
        texts = [line["text"] for line in page_lines]
        for index, line in enumerate(texts):
            if line not in {"RESULTADOS", "ACTA DEL CAMPEONATO"} or index < 2:
                continue
            venue, competition_date = _parse_venue_date(texts[index - 1])
            return {
                "name": texts[index - 2],
                "venue_original": venue,
                "competition_date": competition_date or _first_event_date(events),
            }

        return {
            "name": None,
            "venue_original": None,
            "competition_date": _first_event_date(events),
        }


def _parse_position_dorsal(tokens: list[str]) -> dict | None:
    if not tokens or not tokens[0].isdigit():
        return None
    if len(tokens) > 1 and tokens[1].isdigit():
        return {"position": int(tokens[0]), "dorsal": tokens[1], "next_index": 2}
    return {"position": None, "dorsal": tokens[0], "next_index": 1}


def _find_license_index(tokens: list[str], from_right: bool = False) -> int | None:
    indexes = range(len(tokens) - 1, -1, -1) if from_right else range(len(tokens))
    for index in indexes:
        if _looks_like_license(tokens[index]):
            return index
    return None


def _looks_like_license(value: str) -> bool:
    cleaned = value.strip()
    if "/" in cleaned or _is_decimal(cleaned) or cleaned.upper() in STATUS_MAP:
        return False
    return bool(re.search(r"[A-Za-z]", cleaned) and re.search(r"\d", cleaned))


def _find_birth_date_index(tokens: list[str]) -> int | None:
    for index, token in enumerate(tokens):
        if _parse_loose_date(token):
            return index
    return None


def _split_text_date_tail(line: str) -> tuple[str, date | None]:
    tokens = line.split()
    for index in range(len(tokens) - 1, -1, -1):
        parsed = _parse_loose_date(tokens[index])
        if parsed:
            return " ".join(tokens[:index]), parsed
    return line, None


def _split_text_last_token(line: str) -> tuple[str, str | None]:
    tokens = line.split()
    if not tokens:
        return "", None
    return " ".join(tokens[:-1]), tokens[-1]


def _parse_loose_date(value: str) -> date | None:
    digits = re.sub(r"\D", "", value)
    if len(digits) < 8:
        return None
    try:
        return date(int(digits[4:8]), int(digits[2:4]), int(digits[0:2]))
    except ValueError:
        return None


def _parse_slash_date(value: str) -> date:
    parsed = _parse_loose_date(value)
    if not parsed:
        raise ValueError(f"Invalid date: {value}")
    return parsed


def _parse_iso_date(value: str) -> date:
    return date.fromisoformat(value)


def _parse_time(value: str) -> time:
    hour, minute = value.split(":")
    return time(int(hour), int(minute))


def _parse_venue_date(value: str) -> tuple[str | None, str | None]:
    match = SPANISH_DATE_LINE.match(value)
    if not match:
        return value or None, None
    month = SPANISH_MONTHS.get(match.group("month").lower())
    if not month:
        return match.group("venue").strip(), None
    parsed_date = date(int(match.group("year")), month, int(match.group("day")))
    return match.group("venue").strip(), parsed_date.isoformat()


def _first_event_date(events: list[dict]) -> str | None:
    if not events:
        return None
    return events[0].get("date")


def _split_attempt_header(content: str) -> list[str]:
    if " " not in content and content.count(".") > 1:
        return re.findall(r"\d[.,]\d{2}", content)
    return content.split()


def _is_decimal(value: str) -> bool:
    return bool(re.fullmatch(r"\d+(?:[.,]\d+)?", value))


def _decimal(value: str) -> str:
    return value.replace(",", ".")


def _to_int(value: str | None) -> int | None:
    if value and value.isdigit():
        return int(value)
    return None
