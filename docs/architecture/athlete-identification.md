# Athlete Identification

Regla oficial:

`full_name_normalized`

La fecha de nacimiento y la licencia se gestionan como datos auxiliares. Si la fecha de nacimiento llega en un PDF y el atleta no la tiene, se completa. Si llega una fecha distinta para un atleta ya existente, no se sobrescribe automaticamente y se registra una advertencia.

La licencia se gestiona en `athlete_licenses` como dato auxiliar y versionable por PDF.
