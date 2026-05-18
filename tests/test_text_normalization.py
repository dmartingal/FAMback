from athletics_loader.utils.text import normalize_name


def test_normalize_name() -> None:
    assert normalize_name(' Álvaro  Núñez ') == 'ALVARO NUNEZ'
