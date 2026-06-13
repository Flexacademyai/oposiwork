-- Pack inicial Premium para la oposicion UCA.
-- Amplia la semilla con esquemas, fichas, flashcards, tests y supuestos.

WITH oposicion AS (
  SELECT id
  FROM public.oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
  LIMIT 1
),
temas_uca AS (
  SELECT t.id, t.numero, t.titulo, t.bloque
  FROM public.temas t
  JOIN oposicion o ON o.id = t.oposicion_id
)
INSERT INTO public.contenido_temas (tema_id, tipo, contenido, version, generado_por, revisado)
SELECT
  id,
  'esquema',
  jsonb_build_object(
    'titulo', 'Esquema de estudio',
    'tema', numero,
    'bloque', bloque,
    'apartados', jsonb_build_array(
      jsonb_build_object('orden', 1, 'titulo', 'Materia oficial', 'contenido', titulo),
      jsonb_build_object('orden', 2, 'titulo', 'Primer repaso', 'contenido', 'Lee el texto oficial y marca definiciones, competencias, plazos, organos y procedimientos.'),
      jsonb_build_object('orden', 3, 'titulo', 'Memorizacion activa', 'contenido', 'Convierte cada epigrafe en preguntas cortas y responde sin mirar antes de pasar al test.'),
      jsonb_build_object('orden', 4, 'titulo', 'Repaso final', 'contenido', 'Cierra el tema con flashcards, preguntas test y un supuesto si la materia es procedimental.')
    )
  ),
  1,
  'Codex',
  true
FROM temas_uca
ON CONFLICT DO NOTHING;

WITH oposicion AS (
  SELECT id
  FROM public.oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
  LIMIT 1
),
temas_uca AS (
  SELECT t.id, t.numero, t.titulo
  FROM public.temas t
  JOIN oposicion o ON o.id = t.oposicion_id
)
INSERT INTO public.contenido_temas (tema_id, tipo, contenido, version, generado_por, revisado)
SELECT
  id,
  'ficha_articulos',
  jsonb_build_object(
    'titulo', 'Ficha de referencias',
    'tema', numero,
    'fuente_base', 'BOE-A-2026-9563, anexo II',
    'referencias', jsonb_build_array(
      jsonb_build_object('referencia', 'Programa oficial UCA', 'contenido', titulo),
      jsonb_build_object('referencia', 'Normativa aplicable', 'contenido', 'Contrasta este tema con el texto vigente de la norma citada en el programa antes del examen.'),
      jsonb_build_object('referencia', 'Criterio de estudio', 'contenido', 'Prioriza articulos, organos competentes, plazos, recursos, derechos y obligaciones.')
    )
  ),
  1,
  'Codex',
  true
FROM temas_uca
ON CONFLICT DO NOTHING;

WITH oposicion AS (
  SELECT id
  FROM public.oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
  LIMIT 1
),
temas_uca AS (
  SELECT t.id, t.numero, t.titulo
  FROM public.temas t
  JOIN oposicion o ON o.id = t.oposicion_id
)
INSERT INTO public.flashcards (tema_id, pregunta, respuesta, articulo_referencia, dificultad)
SELECT
  id,
  'Tema ' || numero || ': que materia entra segun el programa oficial?',
  titulo,
  'BOE-A-2026-9563, anexo II',
  1
FROM temas_uca
ON CONFLICT DO NOTHING;

WITH oposicion AS (
  SELECT id
  FROM public.oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
  LIMIT 1
),
temas_uca AS (
  SELECT t.id, t.numero, t.titulo, t.bloque
  FROM public.temas t
  JOIN oposicion o ON o.id = t.oposicion_id
)
INSERT INTO public.flashcards (tema_id, pregunta, respuesta, articulo_referencia, dificultad)
SELECT
  id,
  'Tema ' || numero || ': cual es el enfoque de examen mas probable?',
  CASE
    WHEN bloque ILIKE '%Derecho Administrativo%' THEN 'Identificar conceptos juridicos, organos, actos administrativos, procedimiento, recursos y plazos.'
    WHEN bloque ILIKE '%Gestion de personal%' THEN 'Dominar derechos, deberes, situaciones administrativas, incompatibilidades, igualdad y prevencion.'
    WHEN bloque ILIKE '%Gestion universitaria%' THEN 'Relacionar normativa universitaria, estatutos UCA, presupuesto, acceso y permanencia.'
    WHEN bloque ILIKE '%Informatica%' THEN 'Reconocer herramientas, operaciones basicas y usos habituales de Microsoft 365.'
    ELSE 'Distinguir organos, competencias, estructura normativa y conceptos clave del tema.'
  END,
  'Metodo Oposiwork',
  2
FROM temas_uca
ON CONFLICT DO NOTHING;

WITH oposicion AS (
  SELECT id
  FROM public.oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
  LIMIT 1
),
temas_uca AS (
  SELECT t.id, t.numero, t.titulo
  FROM public.temas t
  JOIN oposicion o ON o.id = t.oposicion_id
)
INSERT INTO public.preguntas_test (
  tema_id,
  oposicion_id,
  enunciado,
  opcion_a,
  opcion_b,
  opcion_c,
  opcion_d,
  respuesta_correcta,
  explicacion,
  articulo_referencia,
  dificultad
)
SELECT
  id,
  (SELECT id FROM oposicion),
  'Segun el programa oficial UCA, que contenido corresponde al tema ' || numero || '?',
  titulo,
  'Regimen electoral general completo',
  'Contratacion mercantil internacional',
  'Derecho penal especial completo',
  'a',
  'El anexo II de la convocatoria identifica expresamente esta materia para el tema indicado.',
  'BOE-A-2026-9563, anexo II',
  1
FROM temas_uca
ON CONFLICT DO NOTHING;

WITH oposicion AS (
  SELECT id
  FROM public.oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
  LIMIT 1
),
t AS (
  SELECT id, numero
  FROM public.temas
  WHERE oposicion_id = (SELECT id FROM oposicion)
)
INSERT INTO public.preguntas_test (
  tema_id,
  oposicion_id,
  enunciado,
  opcion_a,
  opcion_b,
  opcion_c,
  opcion_d,
  respuesta_correcta,
  explicacion,
  articulo_referencia,
  dificultad
)
SELECT
  t.id,
  (SELECT id FROM oposicion),
  q.enunciado,
  q.a,
  q.b,
  q.c,
  q.d,
  q.correcta,
  q.explicacion,
  q.referencia,
  q.dificultad
FROM t
JOIN (VALUES
  (4, 'El Estatuto de Autonomia para Andalucia forma parte de que bloque del programa UCA?', 'Organizacion de la administracion', 'Informatica', 'Gestion economica internacional', 'Psicotecnicos', 'a', 'El tema 4 aparece en el Bloque I del programa oficial.', 'BOE-A-2026-9563, anexo II', 1),
  (8, 'En Derecho Administrativo, las fuentes sirven para:', 'Determinar el origen y jerarquia de las normas aplicables', 'Calcular solo nominas', 'Disenar hojas de calculo', 'Regular exclusivamente el correo electronico', 'a', 'El tema 8 estudia el concepto y fuentes del Derecho Administrativo.', 'Tema 8 UCA', 2),
  (10, 'La nulidad y anulabilidad se estudian dentro de:', 'El acto administrativo', 'La ofimatica', 'La gestion presupuestaria', 'La autonomia universitaria exclusivamente', 'a', 'El tema 10 incluye eficacia, validez, ejecucion, nulidad y anulabilidad del acto administrativo.', 'Tema 10 UCA', 2),
  (12, 'Los recursos administrativos pertenecen al estudio de:', 'Revision de actos en via administrativa', 'Derechos digitales', 'Pruebas fisicas', 'Sistema operativo', 'a', 'El tema 12 incluye revision de oficio y recursos administrativos.', 'Tema 12 UCA', 2),
  (14, 'La obligacion de resolver se vincula principalmente con:', 'Procedimiento administrativo comun', 'Contratacion privada', 'Codigo etico exclusivamente', 'Hoja de calculo', 'a', 'El tema 14 incluye obligacion de resolver, silencio administrativo y terminacion.', 'Tema 14 UCA', 2),
  (16, 'Los derechos individuales del empleado publico se estudian en:', 'TREBEP', 'Ley Organica 3/2018 exclusivamente', 'Ley de marcas', 'Codigo Penal exclusivamente', 'a', 'El tema 16 trata derechos individuales y carrera profesional del empleado publico.', 'Tema 16 UCA', 2),
  (18, 'La Ley 31/1995 se refiere a:', 'Prevencion de riesgos laborales', 'Universidades', 'Proteccion de datos', 'Presupuesto universitario', 'a', 'El tema 18 incluye la Ley 31/1995 de Prevencion de Riesgos Laborales.', 'Tema 18 UCA', 1),
  (21, 'Los Estatutos de la Universidad de Cadiz se estudian en el bloque de:', 'Gestion universitaria', 'Informatica', 'Derecho penal', 'Contratacion mercantil', 'a', 'El tema 21 pertenece al Bloque IV de Gestion universitaria.', 'Tema 21 UCA', 1),
  (23, 'El procedimiento de elaboracion de disposiciones de caracter general de la UCA pertenece al tema:', '23', '1', '7', '27', 'a', 'El tema 23 incluye el Reglamento UCA/CG04/2015.', 'Tema 23 UCA', 2),
  (26, 'Las modificaciones de credito se estudian en:', 'Normas de Ejecucion del Presupuesto de la UCA', 'Ley Organica 3/2007', 'Titulo II de la Constitucion', 'Microsoft Outlook', 'a', 'El tema 26 incluye presupuesto, creditos, modificaciones y ejecucion presupuestaria.', 'Tema 26 UCA', 2)
) AS q(numero, enunciado, a, b, c, d, correcta, explicacion, referencia, dificultad)
ON q.numero = t.numero
ON CONFLICT DO NOTHING;

WITH oposicion AS (
  SELECT id
  FROM public.oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
  LIMIT 1
),
t AS (
  SELECT id, numero
  FROM public.temas
  WHERE oposicion_id = (SELECT id FROM oposicion)
)
INSERT INTO public.supuestos (
  oposicion_id,
  tema_id,
  titulo,
  enunciado,
  solucion,
  normativa_aplicable,
  dificultad
)
SELECT
  (SELECT id FROM oposicion),
  t.id,
  s.titulo,
  s.enunciado,
  s.solucion,
  s.normativa,
  s.dificultad
FROM t
JOIN (VALUES
  (11, 'Registro de solicitud fuera de plazo', 'Una persona presenta una solicitud relacionada con un procedimiento universitario despues de la fecha limite. Indica que debe comprobar la unidad administrativa y que respuesta procedimental procede.', 'Debe comprobarse la fecha de entrada, el medio de presentacion, el plazo aplicable y si existe causa de subsanacion o ampliacion prevista. Si el plazo esta vencido y no procede excepcion, debe tramitarse la inadmisibilidad o resolucion que corresponda con motivacion y pie de recursos.', ARRAY['Ley 39/2015', 'Tema 11 UCA'], 3),
  (12, 'Recurso contra acto administrativo', 'Un interesado no esta conforme con una resolucion administrativa dictada por un organo universitario. Identifica los elementos minimos que debe revisar la unidad antes de informar sobre el recurso.', 'Deben revisarse organo que dicto el acto, si pone fin a la via administrativa, plazo, legitimacion, contenido minimo del recurso, documentacion aportada y organo competente para resolver.', ARRAY['Ley 39/2015', 'Tema 12 UCA'], 3),
  (14, 'Silencio administrativo', 'Una solicitud no ha recibido respuesta expresa dentro del plazo maximo. Explica que comprobaciones debe realizar la unidad administrativa antes de informar al interesado.', 'Debe verificarse plazo maximo, fecha de inicio, posibles suspensiones, norma reguladora del procedimiento y sentido del silencio. Tambien debe recordarse que la Administracion mantiene la obligacion de resolver expresamente.', ARRAY['Ley 39/2015', 'Tema 14 UCA'], 3),
  (18, 'Incidencia preventiva en oficina', 'En una unidad administrativa se detecta cableado en zona de paso y fatiga visual por uso continuado de pantallas. Propón una respuesta preventiva basica.', 'Debe comunicarse la incidencia, ordenar la zona de paso, evitar riesgos de caida, revisar condiciones ergonomicas, programar pausas y aplicar las medidas preventivas previstas por la evaluacion de riesgos.', ARRAY['Ley 31/1995', 'Tema 18 UCA'], 2),
  (26, 'Modificacion presupuestaria', 'Una unidad necesita tramitar un gasto no previsto inicialmente en la aplicacion presupuestaria disponible. Indica el enfoque administrativo correcto.', 'Debe comprobarse existencia y adecuacion de credito, tipo de modificacion presupuestaria aplicable, organo competente, documentacion justificativa y fase de ejecucion presupuestaria antes de comprometer el gasto.', ARRAY['Normas de Ejecucion del Presupuesto UCA', 'Tema 26 UCA'], 3)
) AS s(numero, titulo, enunciado, solucion, normativa, dificultad)
ON s.numero = t.numero
ON CONFLICT DO NOTHING;
