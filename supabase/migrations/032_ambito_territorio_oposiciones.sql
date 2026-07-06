-- Ámbito y territorio estructurados para filtrar oposiciones en la app
-- (estatal / autonomico / provincial / local / universidad) + territorio legible.
-- Las columnas ya existían (con 'estatal' heredado en todas las filas); esta
-- migración amplía el CHECK con 'universidad', añade índices y reclasifica
-- todas las filas a partir del texto libre de `administracion`.
-- monitor-boe rellena ambos campos para las oposiciones nuevas.

alter table oposiciones
  add column if not exists ambito text,
  add column if not exists territorio text;

alter table oposiciones drop constraint if exists oposiciones_ambito_check;
alter table oposiciones add constraint oposiciones_ambito_check
  check (ambito = any (array['estatal','autonomico','provincial','local','universidad']));

create index if not exists idx_oposiciones_ambito on oposiciones (ambito) where activa;
create index if not exists idx_oposiciones_territorio on oposiciones (territorio) where activa;

-- ── Reclasificación completa ────────────────────────────────────────────────

-- Locales: ayuntamientos y concellos → territorio = provincia entre paréntesis
-- si existe; si no, el municipio.
update oposiciones set
  ambito = 'local',
  territorio = coalesce(
    nullif(trim((regexp_match(administracion, '\(([^)]+)\)'))[1]), ''),
    trim(regexp_replace(administracion, '^(Ayuntamiento|Concello|Ajuntament) (de |d´|d'')?', '', 'i'))
  )
where administracion ~* '^(ayuntamiento|concello|ajuntament)';

-- Universidades
update oposiciones set
  ambito = 'universidad',
  territorio = trim(regexp_replace(administracion, '^Universidad (de |del )?', '', 'i'))
where administracion ~* '^universidad';

-- Provinciales: "Provincia de X", diputaciones y cabildos
update oposiciones set
  ambito = 'provincial',
  territorio = trim(regexp_replace(administracion, '^(Provincia de |Diputacion (Provincial )?de |Diputación (Provincial )?de |Cabildo (Insular )?de )', '', 'i'))
where administracion ~* '^(provincia de|diputacion|diputación|cabildo)';

-- Estatales
update oposiciones set ambito = 'estatal', territorio = 'España'
where administracion in ('Estatal', 'AGE', 'España')
   or administracion ~* 'administraci[oó]n del estado|instituto nacional|instituto social';

-- Autonómicas: comunidades y ciudades autónomas
update oposiciones set ambito = 'autonomico', territorio = administracion
where administracion in (
    'Andalucia','Andalucía','Aragon','Aragón','Asturias','Cantabria',
    'Castilla y Leon','Castilla y León','Castilla-La Mancha','Catalunya','Cataluña',
    'Comunitat Valenciana','Extremadura','Galicia','Illes Balears','Canarias',
    'La Rioja','Comunidad de Madrid','Madrid','Region de Murcia','Región de Murcia',
    'Murcia','Navarra','Pais Vasco','País Vasco','Ceuta','Melilla'
  );

-- Restos con 'estatal' heredado que no son estatales de verdad
update oposiciones set ambito = 'autonomico'
where ambito = 'estatal' and administracion not in ('Estatal','AGE','España')
  and administracion !~* 'administraci[oó]n del estado|instituto nacional|instituto social';

update oposiciones set territorio = administracion where territorio is null or territorio = '';
