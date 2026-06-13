-- Actualiza fuentes oficiales que estaban devolviendo 404 o endpoints obsoletos.
-- Fuentes verificadas manualmente en mayo de 2026.

UPDATE public.boletines
SET
  url = 'https://app.dipalme.org/pandora/index.vm?view=boletines',
  tipo = 'html',
  updated_at = NOW(),
  notas = COALESCE(notas || ' ', '') || 'URL oficial actualizada: BOP Almeria.'
WHERE source_key = 'bop-almeria';

UPDATE public.boletines
SET
  url = 'https://bop-admin.dipgra.es/',
  tipo = 'html',
  updated_at = NOW(),
  notas = COALESCE(notas || ' ', '') || 'URL oficial actualizada: BOP Granada.'
WHERE source_key = 'bop-granada';

UPDATE public.boletines
SET
  url = 'https://sede.diphuelva.es/servicios/bop',
  tipo = 'html',
  updated_at = NOW(),
  notas = COALESCE(notas || ' ', '') || 'URL oficial actualizada: BOP Huelva.'
WHERE source_key = 'bop-huelva';

UPDATE public.boletines
SET
  url = 'https://www.diputaciondepalencia.es/servicios/boletin-oficial-provincia/?page=0',
  tipo = 'html',
  updated_at = NOW(),
  notas = COALESCE(notas || ' ', '') || 'URL oficial actualizada: BOP Palencia.'
WHERE source_key = 'bop-palencia';

UPDATE public.boletines
SET
  url = 'https://aplicacions.dipta.cat/bopt/web/es',
  tipo = 'html',
  updated_at = NOW(),
  notas = COALESCE(notas || ' ', '') || 'URL oficial actualizada: BOP Tarragona.'
WHERE source_key = 'bop-tarragona';
