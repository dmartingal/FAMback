from pathlib import Path
from athletics_loader.pdf.parsers.fam_results_parser import FamResultsParser
from athletics_loader.utils.marks import infer_mark_unit, parse_mark_numeric


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
    assert event["results"][0]["birth_date"] == "2009-04-29"
    assert "athlete_key" not in event["results"][0]
    assert event["results"][1]["position"] is None
    assert event["results"][1]["status"] == "DNS"


def test_fam_parser_ignores_race_rule_annotation_after_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/01/2026 400m Femenino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
3 415 Salome Carrasco Rebollo
EAMJ Playas de Jandia
16/02/2006
M11981
5 59.39 RT L17.3.3"""
    ]

    result = parser.parse(Path("race-annotation.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "400m"
    assert event["event_type"] == "race"
    assert event["results"][0]["position"] == 3
    assert event["results"][0]["dorsal"] == "415"
    assert event["results"][0]["lane"] == 5
    assert event["results"][0]["mark"] == "59.39"
    assert "L17.3.3" not in event["results"][0]["raw_text"]
    assert event["results"][0]["parse_warnings"] == [
        {
            "error_type": "RT_IGNORED",
            "raw_text": "5 59.39 RT L17.3.3",
            "message": "Se ha ignorado la columna RT de la fila de resultado",
        }
    ]


def test_fam_parser_ignores_race_rule_annotation_after_mark_with_spaced_event_name() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/01/2026 400 m Femenino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
3 415 Salome Carrasco Rebollo
EAMJ Playas de Jandia
16/02/2006
M11981
5 59.39 RT L17.3.3"""
    ]

    result = parser.parse(Path("race-annotation-spaced-name.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "400 m"
    assert event["results"][0]["lane"] == 5
    assert event["results"][0]["mark"] == "59.39"


def test_fam_parser_accepts_extra_text_on_birth_and_license_lines() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/01/2026 400m Femenino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
3 415 Salome Carrasco Rebollo
EAMJ Playas de Jandia
16/02/2006 Sub 20
M11981 ESP
5 59.39 RT L17.3.3"""
    ]

    result = parser.parse(Path("race-annotation-extra-text.pdf"), pages)

    event = result["events"][0]
    assert event["unparsed_lines"] == []
    assert event["results"][0]["birth_date"] == "2006-02-16"
    assert event["results"][0]["license"] == "M11981"
    assert event["results"][0]["lane"] == 5
    assert event["results"][0]["mark"] == "59.39"


def test_fam_parser_ignores_race_rule_annotation_without_lane() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/01/2026 400m Femenino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
3 415 Salome Carrasco Rebollo
EAMJ Playas de Jandia
16/02/2006
M11981
59.39 RT L17.3.3"""
    ]

    result = parser.parse(Path("race-annotation-no-lane.pdf"), pages)

    event = result["events"][0]
    assert event["results"][0]["lane"] is None
    assert event["results"][0]["mark"] == "59.39"


def test_fam_parser_ignores_400m_rt_rule_annotation_for_dorsal_only_result() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/01/2026 400m Masculino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
379 Sergio Eduardo Gonzalez Perez
Atletismo Alcorcon
13/11/2012
M3210
5 46.33 RT L17.3.3"""
    ]

    result = parser.parse(Path("race-annotation-dorsal-only.pdf"), pages)

    event = result["events"][0]
    assert event["unparsed_lines"] == []
    assert event["results"][0]["position"] is None
    assert event["results"][0]["dorsal"] == "379"
    assert event["results"][0]["lane"] == 5
    assert event["results"][0]["mark"] == "46.33"
    assert "L17.3.3" not in event["results"][0]["raw_text"]


def test_fam_parser_ignores_rt_tokens_in_any_race() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/01/2026 100m Masculino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
1 101 Juan Perez
Club X
01/01/2000
M123
11.34 RT 0.156"""
    ]

    result = parser.parse(Path("race-rt-token.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "100m"
    assert event["event_type"] == "race"
    assert event["results"][0]["mark"] == "11.34"
    assert event["results"][0]["attempts"] == []
    assert "0.156" not in event["results"][0]["raw_text"]
    assert event["results"][0]["parse_warnings"][0]["raw_text"] == "11.34 RT 0.156"


def test_fam_parser_ignores_rt_column_in_race_header() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 03/01/2026 100m Masculino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado RT
1 101 Juan Perez
Club X
01/01/2000
M123
11.34 0.156"""
    ]

    result = parser.parse(Path("race-rt-column.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "100m"
    assert event["event_type"] == "race"
    assert event["attempt_headers"] == []
    assert event["results"][0]["mark"] == "11.34"
    assert event["results"][0]["attempts"] == []
    assert "0.156" not in event["results"][0]["raw_text"]
    assert event["results"][0]["parse_warnings"][0]["raw_text"] == "11.34 0.156"


def test_fam_parser_ignores_yc_annotation_after_race_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid PC
Madrid-Gallur, 11 enero 2026
ACTA DEL CAMPEONATO
60m Vallas (0,762) Sub 16 Fem
Final
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Final 11/01/2026 12:00
2 249 Daniela Borrego Mora 06/03/2011 7 9.48 YC
Atletismo Leganes M28667"""
    ]

    result = parser.parse(Path("acta-yc-annotation.pdf"), pages)

    event = result["events"][0]
    parsed_result = event["results"][0]
    assert parsed_result["lane"] == 7
    assert parsed_result["mark"] == "9.48"
    assert parsed_result["attempts"] == []
    assert "YC" not in parsed_result["raw_text"]
    assert parsed_result["parse_warnings"] == []


def test_fam_parser_ignores_rt_rule_annotation_suffix_after_race_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid PC
Madrid-Gallur, 11 enero 2026
ACTA DEL CAMPEONATO
60m Sub 16 Fem
Final
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Final 11/01/2026 12:00
1 101 Ana Perez Gomez 01/01/2011 3 9.48 RT16.8
Club A M101
2 102 Bea Lopez Ruiz 02/02/2011 4 9.49 Rt17.3.3
Club B M102
3 103 Clara Sanz Gil 03/03/2011 5 9.50 rt17.3.3
Club C M103"""
    ]

    result = parser.parse(Path("acta-rt-rule-annotation.pdf"), pages)

    event = result["events"][0]
    assert [parsed_result["mark"] for parsed_result in event["results"]] == ["9.48", "9.49", "9.50"]
    assert all(parsed_result["attempts"] == [] for parsed_result in event["results"])
    assert all("RT" not in parsed_result["raw_text"].upper() for parsed_result in event["results"])
    assert all(parsed_result["parse_warnings"] == [] for parsed_result in event["results"])


def test_fam_parser_ignores_race_walk_fault_symbols_after_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Marcha Master
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
3.000m Marcha Master Masc 55-59
Pto Dor Marca
Final 10/01/2026 11:18
1 163 Juan Manuel De Lucas Pasalodos 29/06/196614:56.09 ~
Atletismo Leganes M24
2 39 Jose Antonio Santamaria Ugarte 25/06/196919:11.06 >
A.D. Sprint M10155
3 1120 Mario Fernandez Revilla 29/11/196819:44.37 >>
Spartak Getafe M880"""
    ]

    result = parser.parse(Path("race-walk-faults.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "3.000m Marcha"
    assert [parsed_result["mark"] for parsed_result in event["results"]] == ["14:56.09", "19:11.06", "19:44.37"]
    assert all(parsed_result["attempts"] == [] for parsed_result in event["results"])
    assert all(">" not in parsed_result["raw_text"] for parsed_result in event["results"])
    assert all("~" not in parsed_result["raw_text"] for parsed_result in event["results"])
    assert all(parsed_result["parse_warnings"] == [] for parsed_result in event["results"])


def test_fam_parser_keeps_ds_status_for_race_walk_disqualification_annotation() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Marcha Master
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
3.000m Marcha Master Fem 65-69
Pto Dor Marca
Final 10/01/2026 10:55
769 Azucena Lopez Almorox 25/02/1958 DS >>>RPT>54.7.5
Canguro A.A.C. M963
290 Yeray Hernan Tudela 06/02/1981 DS >~>RPT~54.7.5
Atletismo Alcorcon M14248
291 Ana Otra Atleta 06/02/1981 DS RT 54.7.5
Atletismo Alcorcon M14249
292 Alba Marchadora 06/02/1981 DS >>>RPT> 54.7.5
Atletismo Alcorcon M14249"""
    ]

    result = parser.parse(Path("race-walk-disqualified.pdf"), pages)

    event = result["events"][0]
    assert [parsed_result["dorsal"] for parsed_result in event["results"]] == ["769", "290", "291", "292"]
    assert all(parsed_result["mark"] is None for parsed_result in event["results"])
    assert all(parsed_result["status"] == "DQ" for parsed_result in event["results"])
    assert all(parsed_result["status_original"] == "DS" for parsed_result in event["results"])
    assert all("RPT" not in parsed_result["raw_text"] for parsed_result in event["results"])
    assert all("54.7.5" not in parsed_result["raw_text"] for parsed_result in event["results"])
    assert all(parsed_result["parse_warnings"] == [] for parsed_result in event["results"])


def test_fam_parser_parses_acta_semifinal_with_qualification_text_and_q_suffix() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid PC
Madrid-Gallur, 11 enero 2026
ACTA DEL CAMPEONATO
60m Abs Fem
Semifinal
Calificacion: Los 8 con mejores tiempos (q) progresan a la Final
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Semifinal 1 11/01/2026 12:00
1 415 Salome Carrasco Rebollo 16/02/2006 5 7.75 q
EAMJ Playas de Jandia M11981"""
    ]

    result = parser.parse(Path("acta-semifinal-q.pdf"), pages)

    assert result["events_detected"] == 1
    event = result["events"][0]
    assert event["event_name"] == "60m"
    assert event["category_text"] == "SENIOR/ABSOLUTA"
    assert event["sex"] == "F"
    assert event["round_name"] == "Semifinal 1"
    assert event["round_type"] == "CLASIFICACION"
    assert event["results"][0]["lane"] == 5
    assert event["results"][0]["mark"] == "7.75"
    assert event["results"][0]["attempts"] == []
    assert " q" not in event["results"][0]["raw_text"]
    assert event["results"][0]["parse_warnings"] == []


def test_fam_parser_starts_sub_16_18_semifinal_after_field_event() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid PC
Madrid-Gallur, 11 enero 2026
ACTA DEL CAMPEONATO
Peso (7,260kg) Sub 16 Masc
Final
Nombre F de Nac
Pto Dor 1 2 3 Marca
Club Lic
Final 11/01/2026 10:00
1 10 Lanzador Uno 01/01/2010 8.00 8.20 8.10 8.20
Club Peso M1
60m Vallas (0,762) Sub 16-18 Fem
Semifinal
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Semifinal 1 11/01/2026 10:20
1 11 Vallista Una 01/01/2010 4 9.20
Club Vallas M2"""
    ]

    result = parser.parse(Path("acta-sub16-18-hurdles.pdf"), pages)

    assert result["events_detected"] == 2
    weight_event, hurdles_event = result["events"]
    assert weight_event["event_name"] == "Peso (7,260kg)"
    assert weight_event["event_type"] == "field"
    assert weight_event["results"][0]["mark"] == "8.20"
    assert hurdles_event["event_name"] == "60m Vallas (0,762)"
    assert hurdles_event["category_text"] == "SUB-16-18"
    assert hurdles_event["event_type"] == "race"
    assert hurdles_event["round_name"] == "Semifinal 1"
    assert hurdles_event["results"][0]["mark"] == "9.20"


def test_fam_parser_ignores_repeated_meeting_title_inside_result_block() -> None:
    parser = FamResultsParser()
    pages = [
        """Reunion FAM 14
Madrid 3 enero 2026
RESULTADOS
17:15 03/01/2026 200m Abs Fem Serie 3
Pto. Dorsal Atleta Lic.
FN Resultado
Reunion FAM 14
1 415 Salome Carrasco Rebollo
EAMJ Playas de Jandia
M11981
16/02/2006 27.12"""
    ]

    result = parser.parse(Path("repeated-title.pdf"), pages)

    event = result["events"][0]
    assert event["unparsed_lines"] == []
    assert len(event["results"]) == 1
    assert event["results"][0]["mark"] == "27.12"


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


def test_fam_parser_ignores_team_points_after_field_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 10/01/2026 Triple Salto Masculino Final
Pto. Dorsal Atleta Lic.
FN 1 2 3 4 Resultado Puntos
1 113 Florentino Salas Rebolleda EX5412 13.70 X 13.51 X 13.70 12
Atletismo Alcorcon 24/10/1992"""
    ]

    result = parser.parse(Path("field-points.pdf"), pages)

    event = result["events"][0]
    assert event["attempt_headers"] == ["1", "2", "3", "4"]
    assert event["results"][0]["mark"] == "13.70"
    assert len(event["results"][0]["attempts"]) == 4
    assert event["results"][0]["attempts"][-1]["attempt_value_raw"] == "X"


def test_fam_parser_ignores_team_points_after_single_digit_field_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 10/01/2026 Peso Masculino Final
Pto. Dorsal Atleta Lic.
FN Resultado Puntos
1 113 Florentino Salas Rebolleda EX5412 9.42 8
Atletismo Alcorcon 24/10/1992"""
    ]

    result = parser.parse(Path("shot-put-single-digit-mark-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "field"
    assert event["event_name"] == "Peso"
    assert event["results"][0]["mark"] == "9.42"


def test_fam_parser_ignores_team_points_after_five_line_field_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 10/01/2026 Peso Masculino Final
Pto. Dorsal Atleta Lic.
FN Resultado Puntos
1 113 Florentino Salas Rebolleda
Atletismo Alcorcon
24/10/1992
EX5412
9.42 8"""
    ]

    result = parser.parse(Path("shot-put-five-line-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "field"
    assert event["event_name"] == "Peso"
    assert event["results"][0]["license"] == "EX5412"
    assert event["results"][0]["birth_date"] == "1992-10-24"
    assert event["results"][0]["mark"] == "9.42"


def test_fam_parser_ignores_team_points_after_five_line_field_attempts() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 10/01/2026 Peso Masculino Final
Pto. Dorsal Atleta Lic.
FN 1 2 3 4 Resultado Puntos
1 113 Florentino Salas Rebolleda
Atletismo Alcorcon
24/10/1992
EX5412
13.70 X 13.51 X 13.70 12"""
    ]

    result = parser.parse(Path("shot-put-five-line-attempts-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "field"
    assert event["results"][0]["mark"] == "13.70"
    assert len(event["results"][0]["attempts"]) == 4
    assert event["results"][0]["attempts"][1]["attempt_value_raw"] == "X"


def test_fam_parser_ignores_team_points_after_five_line_weight_attempts_with_short_header() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 10/01/2026 Peso Masculino Final
Pto. Dorsal Atleta Lic.
FN 1 2 3 Resultado Puntos
10 826 Balazs Laczko
Ajalkala
01/04/1977
M16545
9.35 8.84 8.94 9.35 3"""
    ]

    result = parser.parse(Path("shot-put-five-line-short-header-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "field"
    assert event["results"][0]["position"] == 10
    assert event["results"][0]["dorsal"] == "826"
    assert event["results"][0]["club"] == "Ajalkala"
    assert event["results"][0]["mark"] == "9.35"


def test_fam_parser_ignores_team_points_after_five_line_triple_attempts_with_short_header() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 10/01/2026 Triple Salto Masculino Final
Pto. Dorsal Atleta Lic.
FN 1 2 3 Resultado Puntos
9 256 Jesus Serrano Fuentes
E.A. Majadahonda
20/12/1997
M242
12.64 12.65 12.49 12.65 4"""
    ]

    result = parser.parse(Path("triple-five-line-short-header-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "field"
    assert event["event_name"] == "Triple Salto"
    assert event["results"][0]["position"] == 9
    assert event["results"][0]["dorsal"] == "256"
    assert event["results"][0]["club"] == "E.A. Majadahonda"
    assert event["results"][0]["mark"] == "12.65"


def test_fam_parser_keeps_field_mark_without_team_points() -> None:
    parser = FamResultsParser()
    pages = [
        """12:40 10/01/2026 Peso Masculino Final
Pto. Dorsal Atleta Lic.
FN Resultado
1 113 Florentino Salas Rebolleda EX5412 9.42
Atletismo Alcorcon 24/10/1992"""
    ]

    result = parser.parse(Path("shot-put-single-digit-mark.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "field"
    assert event["results"][0]["mark"] == "9.42"


def test_fam_parser_ignores_attempt_count_and_points_after_height_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 10/01/2026 Altura Masculino Final
Pto. Dorsal Atleta Lic.
FN Resultado Intentos Puntos
1 413 Daniel Rubio Pastor
Ourense Atletismo
M7052
27/07/2006 1.68 3 12"""
    ]

    result = parser.parse(Path("height-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "height"
    assert event["attempt_headers"] == []
    assert event["results"][0]["mark"] == "1.68"


def test_fam_parser_ignores_attempt_count_and_points_after_height_attempts() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 10/01/2026 Pertiga Masculino Final
Pto. Dorsal Atleta Lic.
FN 3.80 4.00 Resultado Intentos Puntos
1 413 Daniel Rubio Pastor
Ourense Atletismo
M7052
27/07/2006 O XO 4.00 2 12"""
    ]

    result = parser.parse(Path("height-attempts-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "height"
    assert event["attempt_headers"] == ["3.80", "4.00"]
    assert event["results"][0]["mark"] == "4.00"
    assert len(event["results"][0]["attempts"]) == 2
    assert event["results"][0]["attempts"][1]["attempt_value_raw"] == "XO"


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


def test_fam_parser_ignores_team_points_after_acta_race_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
200m MASC. PC
Final
Nombre F de Nac
Pto Dor Calle Marca Puntos
Club Lic
Final 10/01/2026 18:30
1 159 Diego Vargas Martinez 27/05/2008 6 22.14 12
Colmenar Viejo M6134"""
    ]

    result = parser.parse(Path("acta-race-points.pdf"), pages)

    event = result["events"][0]
    assert event["results"][0]["mark"] == "22.14"
    assert event["results"][0]["lane"] == 6


def test_fam_parser_parses_acta_round_with_inline_wind() -> None:
    parser = FamResultsParser()
    pages = [
        """Jornada de Menores 47 y 48 Arganda del Rey
Arganda del Rey, 9-10 mayo 2026
ACTA DEL CAMPEONATO
80m Sub 14 Fem
Final
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Serie 3 09/05/2026 11:39 Viento: -0.6
1 1297 Sara Sanchez Checa 27/08/2013 2 11.90
A. A. Moratalaz M3964697ATs
2 1037 Marina Martin Rodrigues 20/05/2014 3 12.15
Atletismo Los Angeles Villaverde M30258"""
    ]

    result = parser.parse(Path("acta-inline-wind.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "80m"
    assert event["category_text"] == "SUB-14"
    assert event["sex"] == "F"
    assert event["round_name"] == "Serie 3"
    assert event["wind"] == "-0.6"
    assert event["results"][1]["athlete"] == "Marina Martin Rodrigues"
    assert event["results"][1]["club"] == "Atletismo Los Angeles Villaverde"
    assert event["results"][1]["mark"] == "12.15"


def test_fam_parser_ignores_attempt_count_and_points_after_acta_height_mark() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
Altura MASC. PC
Final
Nombre F de Nac
Pto Dor Marca Intentos Puntos
Club Lic
Final 10/01/2026 18:30
1 159 Diego Vargas Martinez 27/05/2008 1.88 2 12
Colmenar Viejo M6134
1.76 O / 1.82 XO / 1.88 O"""
    ]

    result = parser.parse(Path("acta-height-points.pdf"), pages)

    event = result["events"][0]
    assert event["event_type"] == "height"
    assert event["attempt_headers"] == []
    assert event["results"][0]["mark"] == "1.88"
    assert len(event["results"][0]["attempts"]) == 3
    assert event["results"][0]["attempts"][1]["height_or_distance"] == "1.82"
    assert event["results"][0]["attempts"][1]["attempt_value_raw"] == "XO"


def test_fam_parser_parses_combined_individual_events_and_summary_points() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Pruebas Combinadas
Madrid-Gallur, 17-18 enero 2026
ACTA DEL CAMPEONATO
Heptatlón Abs Masc
60m Abs Masc
Nombre F de Nac Ptos
Pto Dor Cat Calle Marca
Club Lic Acum.
Serie 1 17/01/2026 15:30
1 101 Mario Prueba Uno 01/01/2000 SM 4 7.36 759
Club Uno M101 759
Longitud Abs Masc
Nombre F de Nac Ptos
Pto Dor Cat 1 2 3 Marca
Club Lic Acum.
Grupo 17/01/2026 15:50
1 101 Mario Prueba Uno 01/01/2000 SM 6.08 4.96 6.42 6.42 679
Club Uno M101 1.438
Heptatlón Abs Masc
Nombre F de Nac
Pto Dor Cat 60 Longitud Marca
Club Lic
1 101 Mario Prueba Uno 01/01/2000 SM 7.36 6.42 1.438
Club Uno M101
759 679"""
    ]

    result = parser.parse(Path("combined-heptathlon.pdf"), pages)

    race = next(event for event in result["events"] if event["event_name"] == "60m")
    field = next(event for event in result["events"] if event["event_name"] == "Longitud")
    combined = next(event for event in result["events"] if event["event_name"] == "Heptatlón")

    assert race["event_type"] == "race"
    assert race["combined_event"]["event_name"] == "Heptatlón"
    assert race["results"][0]["mark"] == "7.36"
    assert race["results"][0]["lane"] == 4
    assert race["results"][0]["combined_points"] == "759"
    assert field["event_type"] == "field"
    assert field["results"][0]["mark"] == "6.42"
    assert field["results"][0]["combined_points"] == "679"
    assert len(field["results"][0]["attempts"]) == 3
    assert combined["event_type"] == "combined"
    assert combined["results"][0]["mark"] == "1438"
    assert combined["results"][0]["combined_partial_points"] == {"60m": "759", "Longitud": "679"}


def test_fam_parser_parses_multiple_combined_events_same_pdf() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Pruebas Combinadas
Madrid-Gallur, 17-18 enero 2026
ACTA DEL CAMPEONATO
Heptatlón Sub 20 Masc
60m Sub 20 Masc
Nombre F de Nac Ptos
Pto Dor Cat Calle Marca
Club Lic Acum.
Serie 1 17/01/2026 15:33
1 201 Simon Ortega Perez 05/07/2008 JM 5 7.11 844
Club Corredores M201 844
Heptatlón Sub 20 Masc
Nombre F de Nac
Pto Dor Cat 60 Marca
Club Lic
1 201 Simon Ortega Perez 05/07/2008 JM 7.11 844
Club Corredores M201
844
Pentatlón Abs Fem
60m Vallas (0,84) Abs Fem
Nombre F de Nac Ptos
Pto Dor Cat Calle Marca
Club Lic Acum.
Serie 1 17/01/2026 15:36
1 301 Ana Prueba Dos 02/02/2000 SF 4 8.81 950
Club Dos M301 950
Altura Abs Fem
Nombre F de Nac Ptos
Pto Dor Cat Marca
Club Lic Acum.
Grupo 17/01/2026 15:50
1 301 Ana Prueba Dos 02/02/2000 SF 1.71 867
Club Dos M301 1.817
1.65 O/1.68 O/1.71 O/1.74 XXX
Pentatlón Abs Fem
Nombre F de Nac
Pto Dor Cat 60mv Altura Marca
Club Lic
1 301 Ana Prueba Dos 02/02/2000 SF 8.81 1.71 1.817
Club Dos M301
950 867"""
    ]

    result = parser.parse(Path("multiple-combined.pdf"), pages)

    combined_events = [event for event in result["events"] if event["event_type"] == "combined"]
    assert [(event["event_name"], event["category_text"], event["sex"]) for event in combined_events] == [
        ("Heptatlón", "SUB-20", "M"),
        ("Pentatlón", "SENIOR/ABSOLUTA", "F"),
    ]
    assert combined_events[0]["results"][0]["mark"] == "844"
    assert combined_events[1]["results"][0]["mark"] == "1817"
    assert combined_events[1]["results"][0]["combined_partial_points"] == {
        "60m Vallas (0,84)": "950",
        "Altura": "867",
    }


def test_fam_parser_keeps_normal_acta_event_without_combined_context() -> None:
    parser = FamResultsParser()
    pages = [
        """Jornada de Menores
Madrid-Gallur, 11 enero 2026
ACTA DEL CAMPEONATO
50m Sub 8 Masc
Final
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Serie 1 11/01/2026 11:10
1 137 Javier Marijuan Rodriguez 26/02/2019 4 9.23
CAP Alcobendas M35139"""
    ]

    result = parser.parse(Path("normal-acta.pdf"), pages)

    event = result["events"][0]
    assert event.get("combined_event") is None
    assert event["results"][0]["mark"] == "9.23"


def test_combined_total_marks_are_points() -> None:
    assert parse_mark_numeric("4776").to_eng_string() == "4776"
    assert infer_mark_unit("Heptatlón", "4776") == "points"
    assert infer_mark_unit("Pentatlón", "3950") == "points"


def test_fam_parser_treats_master_as_category() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 02/05/2026 200m Master Fem Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
1 458 Ainhoa Garcia Pintado
Union Atletica Coslada
M13716
29/04/1981 28.22"""
    ]

    result = parser.parse(Path("master.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "200m"
    assert event["category_text"] == "MASTER"
    assert event["sex"] == "F"


def test_fam_parser_ignores_vet_suffix_in_event_name() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 02/05/2026 300m vallas (0,762) VET 60-69 Máster Masculino Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
1 458 Jose Garcia Pintado
Union Atletica Coslada
M13716
29/04/1961 48.22"""
    ]

    result = parser.parse(Path("vet.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "300m vallas (0,762)"
    assert event["category_text"] == "MASTER"
    assert event["sex"] == "M"
    assert event["results"][0]["mark"] == "48.22"


def test_fam_parser_keeps_sub_category_out_of_event_name() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 02/05/2026 300m Sub 16 Fem Serie 1
Pto. Dorsal Atleta Lic.
FN Resultado
1 458 Ainhoa Garcia Pintado
Union Atletica Coslada
M13716
29/04/2011 42.22"""
    ]

    result = parser.parse(Path("sub16.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "300m"
    assert event["category_text"] == "SUB-16"
    assert event["sex"] == "F"


def test_fam_parser_parses_relay_results() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 10/01/2026 4x400m FEM. PC
Pto. Club Resultado
1 A.D. Marathon 3:51.23
2 Ajalkala 3:55.01"""
    ]

    result = parser.parse(Path("relay.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "4x400m"
    assert event["event_type"] == "relay"
    assert event["sex"] == "F"
    assert event["round_name"] is None
    assert event["results"][0]["position"] == 1
    assert event["results"][0]["club"] == "A.D. Marathon"
    assert event["results"][0]["mark"] == "3:51.23"
    assert event["results"][0]["birth_date"] is None
    assert "athlete_key" not in event["results"][0]


def test_fam_parser_parses_acta_relay_results_with_lane() -> None:
    parser = FamResultsParser()
    pages = [
        """Cto Madrid Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
4x400m MASC. PC
Final
Pto Dor Calle Marca
Serie 1 10/01/2026 20:30
1 4 A.D. Marathon 3:20.11
2 5 Ajalkala 3:22.07"""
    ]

    result = parser.parse(Path("relay-acta.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "4x400m"
    assert event["event_type"] == "relay"
    assert event["sex"] == "M"
    assert event["round_name"] == "Serie 1"
    assert event["results"][0]["position"] == 1
    assert event["results"][0]["lane"] == 4
    assert event["results"][0]["club"] == "A.D. Marathon"
    assert event["results"][0]["mark"] == "3:20.11"


def test_fam_parser_normalizes_all_relay_event_names() -> None:
    parser = FamResultsParser()
    relay_names = ["4x100m", "4x300m", "4x400m", "4x50m", "4x60m", "4x80m", "5x80m"]

    for relay_name in relay_names:
        result = parser.parse(
            Path("relay.pdf"),
            [
                f"""10:00 10/01/2026 {relay_name} FEM. PC
Pto. Club Resultado
1 A.D. Marathon 3:51.23"""
            ],
        )

        event = result["events"][0]
        assert event["event_name"] == relay_name
        assert event["event_type"] == "relay"
        assert event["results"][0]["mark"] == "3:51.23"


def test_fam_parser_parses_relay_lane_and_points_suffix() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 10/01/2026 4x400m MASC. PC
Pto. Club Calle Resultado Puntos
1 Colmenar Viejo 3 3:20.59 12"""
    ]

    result = parser.parse(Path("relay-points.pdf"), pages)

    event = result["events"][0]
    relay = event["results"][0]
    assert event["event_name"] == "4x400m"
    assert relay["position"] == 1
    assert relay["club"] == "Colmenar Viejo"
    assert relay["lane"] == 3
    assert relay["mark"] == "3:20.59"


def test_fam_parser_parses_relay_marks_with_dash_before_points() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 10/01/2026 4x400m FEM. PC
Pto. Club Calle Resultado Puntos
1 Ajalkala 3 3:51.1- 12
2 A.D. Sprint 5 3:52.3- 11
3 A.D. Marathon 6 3:52.7- 9
4 Atletismo Alcorcon 4 4:01.9- 8
5 A. A. Moratalaz 2 4:10.6- 5
6 Union Atletica Coslada 1 4:18.2- 3"""
    ]

    result = parser.parse(Path("relay-dash.pdf"), pages)

    event = result["events"][0]
    assert event["event_name"] == "4x400m"
    assert len(event["results"]) == 6
    assert event["unparsed_lines"] == []
    assert event["results"][0]["position"] == 1
    assert event["results"][0]["club"] == "Ajalkala"
    assert event["results"][0]["lane"] == 3
    assert event["results"][0]["mark"] == "3:51.1"
    assert event["results"][5]["club"] == "Union Atletica Coslada"
    assert event["results"][5]["lane"] == 1
    assert event["results"][5]["mark"] == "4:18.2"


def test_fam_parser_ignores_relay_member_lines() -> None:
    parser = FamResultsParser()
    pages = [
        """10:00 10/01/2026 4x400m MASC. PC Final A
Pto. Club Calle Resultado Puntos
438 Eduardo Jose Trujillo Garcia 12/01/2001 M6546
753 (f) Julio Manuel Manjon Becerra 06/11/2010 M3936171ATs
1 Colmenar Viejo 3 3:20.59 12"""
    ]

    result = parser.parse(Path("relay-members.pdf"), pages)

    event = result["events"][0]
    assert event["unparsed_lines"] == []
    assert len(event["results"]) == 1
    assert event["results"][0]["club"] == "Colmenar Viejo"
    assert event["results"][0]["mark"] == "3:20.59"
    assert event["relay_members"][0]["athlete_name"] == "Eduardo Jose Trujillo Garcia"
    assert event["relay_members"][0]["relay_group"] is None


def test_fam_parser_ignores_acta_relay_member_lines_before_team_result() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
4x400m MASC. PC
Final
Pto Dor Calle Marca
Serie 1 10/01/2026 20:30
159 Diego Vargas Martinez 27/05/2008 M6134
70 Juan Torres Alba 14/07/2009 M17369
1 Colmenar Viejo 3 3:20.59 12"""
    ]

    result = parser.parse(Path("relay-acta-members.pdf"), pages)

    event = result["events"][0]
    assert event["unparsed_lines"] == []
    assert len(event["results"]) == 1
    assert event["results"][0]["position"] == 1
    assert event["results"][0]["club"] == "Colmenar Viejo"
    assert event["results"][0]["lane"] == 3
    assert event["results"][0]["mark"] == "3:20.59"
    assert event["relay_members"][0]["athlete_name"] == "Diego Vargas Martinez"
    assert event["relay_members"][0]["birth_date"] == "2008-05-27"
    assert event["relay_members"][0]["license"] == "M6134"
    assert event["relay_members"][0]["relay_group"] is None


def test_fam_parser_links_relay_members_to_previous_team_result() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
4x400m MASC. PC
Final
Pto Dor Calle Marca
Final B 10/01/2026 20:30
1 Colmenar Viejo 3 3:20.59 12
159 Diego Vargas Martinez 27/05/2008 M6134
70 Juan Torres Alba 14/07/2009 M17369
2 A.D. Marathon 4 3:22.11 11
11 Eliam Fernandez Ortiz De Zarate 14/09/1992 M2222"""
    ]

    result = parser.parse(Path("relay-acta-members-after-team.pdf"), pages)

    event = result["events"][0]
    assert event["results"][0]["relay_group"] == 1
    assert event["results"][1]["relay_group"] == 2
    assert event["relay_members"][0]["athlete_name"] == "Diego Vargas Martinez"
    assert event["relay_members"][0]["relay_group"] == 1
    assert event["relay_members"][1]["athlete_name"] == "Juan Torres Alba"
    assert event["relay_members"][1]["relay_group"] == 1
    assert event["relay_members"][2]["athlete_name"] == "Eliam Fernandez Ortiz De Zarate"
    assert event["relay_members"][2]["relay_group"] == 2


def test_fam_parser_parses_relay_status_results_without_position() -> None:
    parser = FamResultsParser()
    pages = [
        """Jornada de Menores 46 Rivas-Vaciamadrid
Rivas-Vaciamadrid, 3 mayo 2026
ACTA DEL CAMPEONATO
4x100m Sub 16 Masc
Final
Pto Dor Equipo F de Nac Calle Marca
Relevistas Lic
Serie 1 03/05/2026 12:17
1 At. Arroyomolinos 5 47.50
741 Adrian Gao Ortiz Jimenez 08/06/2011 M12535
A.D. Sprint 3 NP
33 Diego Vargas Martinez 27/05/2011 M6134
A.D. Marathon 4 DS RT 24.7
70 Juan Torres Alba 14/07/2011 M17369
Ciudad de Rivas 6 AB
11 Eliam Fernandez Ortiz De Zarate 14/09/2011 M2222"""
    ]

    result = parser.parse(Path("relay-status-without-position.pdf"), pages)

    event = result["events"][0]
    assert event["unparsed_lines"] == []
    assert [(r["position"], r["club"], r["lane"], r["mark"], r["status"], r["status_original"]) for r in event["results"]] == [
        (1, "At. Arroyomolinos", 5, "47.50", "OK", None),
        (None, "A.D. Sprint", 3, None, "NP", "NP"),
        (None, "A.D. Marathon", 4, None, "DQ", "DS"),
        (None, "Ciudad de Rivas", 6, None, "DNF", "AB"),
    ]
    assert "RT" not in event["results"][2]["raw_text"]
    assert event["relay_members"][0]["relay_group"] == 1
    assert event["relay_members"][1]["relay_group"] == 2
    assert event["relay_members"][2]["relay_group"] == 3
    assert event["relay_members"][3]["relay_group"] == 4


def test_fam_parser_parses_relay_member_without_bib_number() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Relevos
Madrid-Aluche, 9-10 mayo 2026
ACTA DEL CAMPEONATO
4x100m Master Masc
Final
Pto Dor Equipo F de Nac Calle Marca
Relevistas Lic
Final 10/05/2026 12:17
Club Corredores 4 NP
409 Ivan Gomez Acedo 23/11/1980 M346
Masood Bapiri 22/09/1981 M3970412ATs"""
    ]

    result = parser.parse(Path("relay-member-without-bib.pdf"), pages)

    event = result["events"][0]
    assert event["unparsed_lines"] == []
    assert event["results"][0]["club"] == "Club Corredores"
    assert event["results"][0]["status"] == "NP"
    assert event["relay_members"][0]["bib_number"] == "409"
    assert event["relay_members"][1]["bib_number"] is None
    assert event["relay_members"][1]["athlete_name"] == "Masood Bapiri"
    assert event["relay_members"][1]["birth_date"] == "1981-09-22"
    assert event["relay_members"][1]["license"] == "M3970412ATs"


def test_fam_parser_parses_six_acta_relay_results_in_final_b() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
4x400m FEM. PC
Final
Pto Dor Calle Marca
Final B 10/01/2026 20:45
1 At. Arroyomolinos 6 3:52.53 6
2 Cronos Villaviciosa 5 4:07.20 5
3 Colmenar Viejo 4 4:07.57 4
4 Suanzes San Blas 3 4:08.11 3
5 A.D. Sprint B 2 4:10.62 2
6 Ajalkala B 1 4:12.30 1"""
    ]

    result = parser.parse(Path("relay-final-b.pdf"), pages)

    event = result["events"][0]
    assert event["round_name"] == "Final B"
    assert len(event["results"]) == 6
    assert event["results"][3]["position"] == 4
    assert event["results"][3]["club"] == "Suanzes San Blas"
    assert event["results"][3]["lane"] == 3
    assert event["results"][3]["mark"] == "4:08.11"


def test_fam_parser_continues_acta_relay_round_on_next_page() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
4x400m FEM. PC
Final
Pto Dor Calle Marca
Final A 10/01/2026 20:30
1 Ajalkala 3 3:51.1- 12
2 A.D. Sprint 5 3:52.3- 11
Final B 10/01/2026 20:45
1 At. Arroyomolinos 6 3:52.53 6
2 Cronos Villaviciosa 5 4:07.20 5
3 Colmenar Viejo 4 4:07.57 4""",
        """4 Suanzes San Blas 3 4:08.11 3
5 A.D. Sprint B 2 4:10.62 2
6 Ajalkala B 1 4:12.30 1
4x400m MASC. PC
Final
Pto Dor Calle Marca
Final A 10/01/2026 21:00
1 Colmenar Viejo 3 3:20.59 12""",
    ]

    result = parser.parse(Path("relay-final-b-page-continuation.pdf"), pages)

    final_b = [
        event
        for event in result["events"]
        if event["event_name"] == "4x400m" and event["sex"] == "F" and event["round_name"] == "Final B"
    ][0]
    assert len(final_b["results"]) == 6
    assert final_b["results"][3]["position"] == 4
    assert final_b["results"][3]["club"] == "Suanzes San Blas"
    assert final_b["results"][4]["position"] == 5
    assert final_b["results"][5]["position"] == 6


def test_fam_parser_merges_repeated_acta_title_continuation() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
4x400m FEM. PC
Final
Pto Dor Calle Marca
Final B 10/01/2026 20:45
1 At. Arroyomolinos 6 3:52.53 6
2 Cronos Villaviciosa 5 4:07.20 5
3 Colmenar Viejo 4 4:07.57 4""",
        """4x400m FEM. PC
Final
Pto Dor Calle Marca
4 Suanzes San Blas 3 4:08.11 3
5 A.D. Sprint B 2 4:10.62 2
6 Ajalkala B 1 4:12.30 1""",
    ]

    result = parser.parse(Path("relay-final-b-repeated-title.pdf"), pages)

    assert result["events_detected"] == 1
    event = result["events"][0]
    assert event["round_name"] == "Final B"
    assert len(event["results"]) == 6
    assert event["results"][5]["club"] == "Ajalkala B"


def test_fam_parser_ignores_acta_page_headers_and_team_standings() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
4x400m FEM. PC
Final
Pto Dor Calle Marca
Final B 10/01/2026 20:45
1 At. Arroyomolinos 6 3:52.53 6
2 Cronos Villaviciosa 5 4:07.20 5
3 Colmenar Viejo 4 4:07.57 4""",
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
Equipo F de Nac
Relevistas Lic
4 Suanzes San Blas 3 4:08.11 3
5 A.D. Sprint B 2 4:10.62 2
6 Ajalkala B 1 4:12.30 1
Pto Club Puntos por Puesto - Mujeres
1 ADMM - A.D. Marathon 136
2 SPRM - A.D. Sprint 124.5"""
    ]

    result = parser.parse(Path("relay-final-b-headers-standings.pdf"), pages)

    event = result["events"][0]
    assert event["round_name"] == "Final B"
    assert len(event["results"]) == 6
    assert event["unparsed_lines"] == []
    assert event["results"][3]["club"] == "Suanzes San Blas"


def test_fam_parser_ignores_club_points_table_in_acta_block() -> None:
    parser = FamResultsParser()
    pages = [
        """Campeonato de Madrid de Clubes Absoluto PC
Madrid-Gallur, 10 enero 2026
ACTA DEL CAMPEONATO
200m MASC. PC
Final
Nombre F de Nac
Pto Dor Calle Marca
Club Lic
Final 10/01/2026 18:30
1 159 Diego Vargas Martinez 27/05/2008 6 22.14
Colmenar Viejo M6134
Pto Club Puntos por Puesto - Hombres
1 ALCM - Atletismo Alcorcon 124.5
2 ADMM - A.D. Marathon 123.5"""
    ]

    result = parser.parse(Path("club-points-standings.pdf"), pages)

    event = result["events"][0]
    assert len(event["results"]) == 1
    assert event["unparsed_lines"] == []
    assert event["results"][0]["athlete"] == "Diego Vargas Martinez"
