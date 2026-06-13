-- Convocatoria activa para probar el flujo free.
-- Fuentes verificadas:
-- - UCA Area de Personal: UCA/REC98GER/2026, publicada el 4/05/2026.
-- - BOE-A-2026-9563, BOE num. 107 de 2/05/2026.

WITH oposicion_uca AS (
  INSERT INTO oposiciones (
    slug,
    nombre,
    cuerpo,
    administracion,
    nivel,
    tiene_psicotecnicos,
    tiene_pruebas_fisicas,
    activa
  )
  VALUES (
    'auxiliar-administrativa-universidad-cadiz',
    'Auxiliar Administrativa Universidad de Cadiz',
    'Escala Auxiliar Administrativa',
    'Universidad de Cadiz',
    'C2',
    false,
    false,
    true
  )
  ON CONFLICT (slug) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    cuerpo = EXCLUDED.cuerpo,
    administracion = EXCLUDED.administracion,
    nivel = EXCLUDED.nivel,
    tiene_psicotecnicos = EXCLUDED.tiene_psicotecnicos,
    tiene_pruebas_fisicas = EXCLUDED.tiene_pruebas_fisicas,
    activa = EXCLUDED.activa
  RETURNING id
)
INSERT INTO convocatorias (
  oposicion_id,
  fecha_publicacion_boe,
  fecha_inicio_instancias,
  fecha_fin_instancias,
  fecha_examen,
  fecha_examen_confirmada,
  plazas,
  estado,
  url_boe,
  notas
)
SELECT
  id,
  DATE '2026-05-02',
  DATE '2026-05-04',
  DATE '2026-05-22',
  NULL,
  false,
  11,
  'abierta',
  'https://www.boe.es/diario_boe/txt.php?id=BOE-A-2026-9563',
  'Resolucion de 28 de abril de 2026 de la Universidad de Cadiz. Plazo UCA: del 4 al 22 de mayo de 2026, ambos inclusive. El BOE indica que el primer ejercicio no se celebrara antes del 1 de junio de 2026.'
FROM oposicion_uca
WHERE NOT EXISTS (
  SELECT 1
  FROM convocatorias c
  WHERE c.oposicion_id = oposicion_uca.id
    AND c.url_boe = 'https://www.boe.es/diario_boe/txt.php?id=BOE-A-2026-9563'
);
