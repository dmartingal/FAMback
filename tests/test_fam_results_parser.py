from pathlib import Path
from athletics_loader.pdf.parsers.fam_results_parser import FamResultsParser


def test_fam_parser_detects_header() -> None:
    parser = FamResultsParser()
    pages = ['16:35 02/05/2026 100m Femenino Serie 1\nViento: -1.9']
    assert parser.can_parse(Path('x.pdf'), pages)


def test_fam_parser_parses_race_results() -> None:
    parser = FamResultsParser()
    pages = [
        """Jornada saltos y lanzamientos 1 Mostoles
Mostoles 2 may 2026
RESULTADOS
16:35 02/05/2026 100m Femenino Serie 1
Viento: -1.9
Pto. Dorsal Atleta Lic.
FN Resultado
1 458 Ainhoa Garcia Pintado
Union Atletica Coslada
M13716
29/04/2009 12.22
107 Allegra Garcia-Minaur Arroyo
A.D. Marathon
M8082
18/09/2010 DNS"""
    ]

    result = parser.parse(Path("race.pdf"), pages)

    assert result["competition"]["name"] == "Jornada saltos y lanzamientos 1 Mostoles"
    assert result["competition"]["venue_original"] == "Mostoles"
    assert result["events_detected"] == 1
    event = result["events"][0]
    assert event["event_name"] == "100m"
    assert event["sex"] == "F"
    assert event["round_name"] == "Serie 1"
    assert event["wind"] == "-1.9"
    assert event["event_type"] == "race"
    assert event["results"][0]["position"] == 1
    assert event["results"][0]["dorsal"] == "458"
    assert event["results"][0]["mark"] == "12.22"
    assert event["results"][0]["status"] == "OK"
    assert event["results"][0]["athlete_key"] == "AINHOA GARCIA PINTADO|2009-04-29"
    assert event["results"][1]["position"] is None
    assert event["results"][1]["status"] == "DNS"


def test_fam_parser_parses_height_attempts() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 02/05/2026 Altura Femenino Grupo A
Pto. Dorsal Atleta Lic.
FN 1.28 1.33 1.38 1.43 1.48 Resultado
1 413 Daniela Rubio Pastor
Ourense Atletismo
M7052
27/07/2006 O O XXO XO XXX 1.68"""
    ]

    result = parser.parse(Path("height.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "height"
    assert event["attempt_headers"] == ["1.28", "1.33", "1.38", "1.43", "1.48"]
    attempts = event["results"][0]["attempts"]
    assert attempts[0]["height_or_distance"] == "1.28"
    assert attempts[0]["attempt_status"] == "VALID"
    assert attempts[-1]["attempt_value_raw"] == "XXX"
    assert attempts[-1]["attempt_status"] == "FAIL"


def test_fam_parser_parses_throw_attempts() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/05/2026 Jabalina (500g) Sub 18 Femenino Grupo A
Pto. Dorsal Atleta Lic.
FN 1 2 3 4 5 6 Resultado
1 29 Julia Gonzalez Corral
A.D. Sprint
M16806
03/05/2009 33.98 31.13 29.99 28.50 X X 33.98"""
    ]

    result = parser.parse(Path("throws.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "field"
    assert event["event_name"] == "Jabalina (500g)"
    assert event["implement"] == "500g"
    assert event["category_text"] == "SUB-18"
    attempts = event["results"][0]["attempts"]
    assert attempts[0]["attempt_value_raw"] == "33.98"
    assert attempts[0]["attempt_status"] == "VALID"
    assert attempts[-1]["attempt_value_raw"] == "X"
    assert attempts[-1]["attempt_status"] == "FOUL"


def test_fam_parser_parses_acta_championship_results() -> None:
    parser = FamResultsParser()
    pages = [
        """Jornada de Menores 18
Madrid-Gallur, 11 enero 2026
ACTA DEL CAMPEONATO
50m Sub 8 Masc
Final
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Serie 1 11/01/2026 11:10
1 137 Javier Marijuan Rodriguez 26/02/2019 4 9.23
CAP Alcobendas M35139
201 Adrian Parrilla Herranz 15/03/2019 4 NP
Lynze Parla M3938138ATs"""
    ]

    result = parser.parse(Path("acta.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "50m"
    assert event["category_text"] == "SUB-8"
    assert event["sex"] == "M"
    assert event["round_name"] == "Serie 1"
    assert event["results"][0]["lane"] == 4
    assert event["results"][0]["birth_date"] == "2019-02-26"
    assert event["results"][1]["status"] == "NP"
