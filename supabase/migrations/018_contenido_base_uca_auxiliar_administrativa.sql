-- Contenido base Premium para Auxiliar Administrativa Universidad de Cadiz.
-- Fuente oficial: BOE-A-2026-9563, anexo II, programa.
-- https://www.boe.es/diario_boe/txt.php?id=BOE-A-2026-9563
-- Objetivo: evitar pantallas Premium vacias y cargar el programa oficial completo.

WITH oposicion AS (
  SELECT id
  FROM oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
),
limpieza AS (
  DELETE FROM temas
  WHERE oposicion_id = (SELECT id FROM oposicion)
  RETURNING id
),
programa AS (
  SELECT *
  FROM (VALUES
    (1, 'La Constitucion Espanola de 1978. Estructura y contenido. Titulo preliminar. Titulo I. De los derechos y deberes fundamentales.', 'Bloque I: Organizacion de la administracion', 1),
    (2, 'La Constitucion de 1978: Titulo II. De la Corona. Titulo III. De las Cortes Generales. Titulo IV. Del Gobierno y de la Administracion.', 'Bloque I: Organizacion de la administracion', 2),
    (3, 'La Constitucion de 1978: Titulo V. De las relaciones entre el Gobierno y las Cortes Generales. Titulo VI. Del Poder Judicial. Titulo VIII. De la Organizacion Territorial del Estado.', 'Bloque I: Organizacion de la administracion', 3),
    (4, 'El Estatuto de Autonomia para Andalucia. Derechos y deberes. Principios rectores. Competencias de la Comunidad Autonoma.', 'Bloque I: Organizacion de la administracion', 4),
    (5, 'Ley Organica 3/2007, de 22 de marzo, para la igualdad efectiva de mujeres y hombres. Objeto y ambito de la Ley. El principio de igualdad y la tutela contra la discriminacion. El principio de igualdad en el empleo publico: Criterios de actuacion de las Administraciones Publicas.', 'Bloque I: Organizacion de la administracion', 5),
    (6, 'Ley Organica 3/2018, de 5 de diciembre, de Proteccion de Datos Personales y garantia de los derechos digitales. Disposiciones generales. Principios de proteccion de los datos. Derecho de las personas.', 'Bloque I: Organizacion de la administracion', 6),
    (7, 'Sistema de Direccion Estrategica de la Universidad de Cadiz: mision, vision, valores, ambitos estrategicos y objetivos generales.', 'Bloque I: Organizacion de la administracion', 7),
    (8, 'Las fuentes del Derecho Administrativo: concepto y clases. La Ley. El Reglamento: concepto, naturaleza y clases. Otras fuentes del Derecho Administrativo.', 'Bloque II: Derecho Administrativo', 1),
    (9, 'La Ley 40/2015, de 1 de octubre, de Regimen Juridico del Sector Publico. Disposiciones generales. Los organos de las Administraciones Publicas.', 'Bloque II: Derecho Administrativo', 2),
    (10, 'La Ley 40/2015, de 1 de octubre. Funcionamiento electronico del sector publico.', 'Bloque II: Derecho Administrativo', 3),
    (11, 'La Ley 39/2015, de 1 de octubre, del Procedimiento Administrativo Comun de las Administraciones Publicas. De los interesados en el procedimiento. De la actividad de las Administraciones Publicas.', 'Bloque II: Derecho Administrativo', 4),
    (12, 'La Ley 39/2015, de 1 de octubre, del Procedimiento Administrativo Comun de las Administraciones Publicas. De los actos administrativos.', 'Bloque II: Derecho Administrativo', 5),
    (13, 'La Ley 39/2015, de 1 de octubre, del Procedimiento Administrativo Comun de las Administraciones Publicas. De las disposiciones sobre el procedimiento administrativo comun.', 'Bloque II: Derecho Administrativo', 6),
    (14, 'La Ley 39/2015, de 1 de octubre, del Procedimiento Administrativo Comun de las Administraciones Publicas. De la revision de los actos en via administrativa.', 'Bloque II: Derecho Administrativo', 7),
    (15, 'Real Decreto Legislativo 5/2015, de 30 de octubre, por el que se aprueba el texto refundido de la Ley del Estatuto Basico del Empleado Publico. Personal al servicio de las Administraciones Publicas.', 'Bloque III: Gestion de personal', 1),
    (16, 'Real Decreto Legislativo 5/2015, de 30 de octubre, por el que se aprueba el texto refundido de la Ley del Estatuto Basico del Empleado Publico. Derechos y deberes. Codigo de conducta de los empleados publicos.', 'Bloque III: Gestion de personal', 2),
    (17, 'Real Decreto Legislativo 5/2015, de 30 de octubre, por el que se aprueba el texto refundido de la Ley del Estatuto Basico del Empleado Publico. Adquisicion y perdida de la relacion de servicio.', 'Bloque III: Gestion de personal', 3),
    (18, 'Real Decreto Legislativo 5/2015, de 30 de octubre, por el que se aprueba el texto refundido de la Ley del Estatuto Basico del Empleado Publico. Ordenacion de la actividad profesional.', 'Bloque III: Gestion de personal', 4),
    (19, 'Real Decreto Legislativo 5/2015, de 30 de octubre, por el que se aprueba el texto refundido de la Ley del Estatuto Basico del Empleado Publico. Regimen disciplinario.', 'Bloque III: Gestion de personal', 5),
    (20, 'Ley Organica 2/2023, de 22 de marzo, del Sistema Universitario. Funciones del sistema universitario y autonomia de las universidades. Creacion y reconocimiento de las universidades.', 'Bloque IV: Gestion universitaria', 1),
    (21, 'Ley Organica 2/2023, de 22 de marzo, del Sistema Universitario. Regimen juridico y estructura de las universidades publicas. Gobernanza de las universidades publicas.', 'Bloque IV: Gestion universitaria', 2),
    (22, 'Ley Organica 2/2023, de 22 de marzo, del Sistema Universitario. El estudiantado en el Sistema Universitario. Personal docente e investigador de las universidades publicas. Personal tecnico, de gestion y de administracion y servicios de las universidades publicas.', 'Bloque IV: Gestion universitaria', 3),
    (23, 'Ley 1/2026, de 20 de febrero, Universitaria para Andalucia. Sistema universitario andaluz. Regimen juridico. Funciones, reserva de actividad y de denominacion. Prerrogativas y potestades de las universidades publicas.', 'Bloque IV: Gestion universitaria', 4),
    (24, 'Ley 1/2026, de 20 de febrero, Universitaria para Andalucia. Docencia, Investigacion y Transferencia del Conocimiento.', 'Bloque IV: Gestion universitaria', 5),
    (25, 'Ley 1/2026, de 20 de febrero, Universitaria para Andalucia. Regimen economico, financiero y patrimonial de las universidades publicas.', 'Bloque IV: Gestion universitaria', 6),
    (26, 'Normas de Ejecucion del Presupuesto de la Universidad de Cadiz: el presupuesto de la Universidad de Cadiz, los creditos y sus modificaciones, ejecucion del presupuesto.', 'Bloque IV: Gestion universitaria', 7),
    (27, 'Codigo etico de la Universidad de Cadiz (Codigo Penalver).', 'Bloque IV: Gestion universitaria', 8)
  ) AS p(numero, titulo, bloque, orden_en_bloque)
),
temas_insertados AS (
  INSERT INTO temas (oposicion_id, numero, titulo, bloque, orden)
  SELECT
    (SELECT id FROM oposicion),
    numero,
    titulo,
    bloque,
    numero
  FROM programa
  RETURNING id, numero, titulo, bloque
)
INSERT INTO contenido_temas (tema_id, tipo, contenido, version, generado_por, revisado)
SELECT
  id,
  'resumen',
  jsonb_build_object(
    'titulo', 'Tema ' || numero || '. ' || titulo,
    'resumen', 'Tema incluido en el programa oficial de la convocatoria UCA 2026. Estudia primero el esquema de la norma o materia, despues memoriza conceptos clave y termina con test. Este contenido es una ficha base: debe ampliarse con desarrollo completo antes del lanzamiento comercial masivo.',
    'articulos_clave', jsonb_build_array(
      jsonb_build_object('articulo', 'Fuente oficial', 'ley', 'BOE-A-2026-9563', 'contenido', 'Programa oficial, anexo II, de la convocatoria de Auxiliar Administrativa de la Universidad de Cadiz.')
    ),
    'conceptos', jsonb_build_array(
      'Ubicar el tema dentro del bloque oficial del programa.',
      'Memorizar la estructura general de la norma o materia.',
      'Relacionar conceptos con preguntas tipo test.',
      'Repasar definiciones y competencias.',
      'Practicar preguntas con explicacion antes del examen.'
    )
  ),
  1,
  'oposiwork-content-seed',
  false
FROM temas_insertados;

WITH oposicion AS (
  SELECT id
  FROM oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
),
t AS (
  SELECT id, numero
  FROM temas
  WHERE oposicion_id = (SELECT id FROM oposicion)
)
INSERT INTO flashcards (tema_id, pregunta, respuesta, articulo_referencia, dificultad)
SELECT t.id, f.pregunta, f.respuesta, f.referencia, f.dificultad
FROM t
JOIN (VALUES
  (1, 'Que partes de la Constitucion entran en el tema 1 de la UCA?', 'Estructura y contenido, Titulo preliminar y Titulo I sobre derechos y deberes fundamentales.', 'BOE-A-2026-9563, anexo II', 1),
  (1, 'Que regula el Titulo preliminar de la Constitucion?', 'Los principios basicos del Estado: Estado social y democratico de Derecho, soberania nacional, forma politica, unidad y autonomia, castellano, bandera, capital, partidos, sindicatos, Fuerzas Armadas y garantias juridicas.', 'Constitucion Espanola, arts. 1 a 9', 2),
  (1, 'Que contiene el Titulo I de la Constitucion?', 'La regulacion constitucional de los derechos y deberes fundamentales.', 'Constitucion Espanola, Titulo I', 1),
  (2, 'Que titulos constitucionales entran en el tema 2?', 'Titulo II Corona, Titulo III Cortes Generales y Titulo IV Gobierno y Administracion.', 'BOE-A-2026-9563, anexo II', 1),
  (2, 'Que organo representa al pueblo espanol segun la Constitucion?', 'Las Cortes Generales representan al pueblo espanol y estan formadas por el Congreso de los Diputados y el Senado.', 'Constitucion Espanola, art. 66', 2),
  (2, 'Quien dirige la politica interior y exterior?', 'El Gobierno dirige la politica interior y exterior, la Administracion civil y militar y la defensa del Estado.', 'Constitucion Espanola, art. 97', 2),
  (3, 'Que materias incluye el tema 3?', 'Relaciones Gobierno-Cortes, Poder Judicial y organizacion territorial del Estado.', 'BOE-A-2026-9563, anexo II', 1),
  (4, 'Que norma basica se estudia en el tema 4?', 'El Estatuto de Autonomia para Andalucia.', 'BOE-A-2026-9563, anexo II', 1),
  (5, 'Que materia central tiene la Ley Organica 3/2007?', 'La igualdad efectiva de mujeres y hombres y la tutela contra la discriminacion.', 'Ley Organica 3/2007', 1),
  (6, 'Que materia central tiene la Ley Organica 3/2018?', 'La proteccion de datos personales y la garantia de los derechos digitales.', 'Ley Organica 3/2018', 1),
  (8, 'Cuales son fuentes tipicas del Derecho Administrativo?', 'La Constitucion, la ley, el reglamento, los principios generales del Derecho y la costumbre cuando proceda.', 'Tema 8 UCA', 2),
  (9, 'Que ley regula el regimen juridico del sector publico?', 'La Ley 40/2015, de 1 de octubre.', 'Ley 40/2015', 1),
  (11, 'Que ley regula el procedimiento administrativo comun?', 'La Ley 39/2015, de 1 de octubre.', 'Ley 39/2015', 1),
  (15, 'Que norma aprueba el Estatuto Basico del Empleado Publico?', 'El Real Decreto Legislativo 5/2015, de 30 de octubre.', 'TREBEP', 1),
  (20, 'Que norma estatal regula el Sistema Universitario?', 'La Ley Organica 2/2023, de 22 de marzo, del Sistema Universitario.', 'LOSU', 1)
) AS f(numero, pregunta, respuesta, referencia, dificultad)
ON f.numero = t.numero;

WITH oposicion AS (
  SELECT id
  FROM oposiciones
  WHERE slug = 'auxiliar-administrativa-universidad-cadiz'
),
t AS (
  SELECT id, numero
  FROM temas
  WHERE oposicion_id = (SELECT id FROM oposicion)
)
INSERT INTO preguntas_test (
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
  (1, 'Segun el programa oficial, que parte de la Constitucion se incluye expresamente en el tema 1?', 'Titulo preliminar y Titulo I', 'Solo el Titulo VIII', 'Solo el Titulo II', 'Disposiciones adicionales exclusivamente', 'a', 'El anexo II del BOE incluye para el tema 1 la estructura, el Titulo preliminar y el Titulo I.', 'BOE-A-2026-9563, anexo II', 1),
  (1, 'La Constitucion proclama que Espana se constituye en:', 'Estado federal', 'Estado social y democratico de Derecho', 'Confederacion administrativa', 'Republica parlamentaria', 'b', 'El articulo 1.1 de la Constitucion establece el Estado social y democratico de Derecho.', 'Constitucion Espanola, art. 1.1', 1),
  (1, 'La soberania nacional reside en:', 'El Gobierno', 'El Rey', 'El pueblo espanol', 'Las Comunidades Autonomas', 'c', 'El articulo 1.2 de la Constitucion atribuye la soberania nacional al pueblo espanol.', 'Constitucion Espanola, art. 1.2', 1),
  (2, 'Las Cortes Generales estan formadas por:', 'Congreso y Senado', 'Gobierno y Senado', 'Rey y Congreso', 'Tribunal Constitucional y Senado', 'a', 'El articulo 66 de la Constitucion establece la composicion bicameral de las Cortes Generales.', 'Constitucion Espanola, art. 66', 1),
  (2, 'El Gobierno dirige:', 'Solo la Administracion local', 'La politica interior y exterior, la Administracion civil y militar y la defensa del Estado', 'Solo el Poder Judicial', 'El Tribunal Constitucional', 'b', 'El articulo 97 de la Constitucion recoge estas funciones del Gobierno.', 'Constitucion Espanola, art. 97', 2),
  (3, 'Que titulo constitucional regula el Poder Judicial?', 'Titulo IV', 'Titulo V', 'Titulo VI', 'Titulo VII', 'c', 'El programa incluye el Titulo VI dentro del tema 3; dicho titulo regula el Poder Judicial.', 'Constitucion Espanola, Titulo VI', 1),
  (5, 'La Ley Organica 3/2007 tiene por objeto principal:', 'Regular contratos publicos', 'Regular igualdad efectiva entre mujeres y hombres', 'Regular proteccion de datos', 'Regular universidades publicas', 'b', 'El propio titulo de la norma y el programa oficial la vinculan a la igualdad efectiva.', 'Ley Organica 3/2007', 1),
  (6, 'La Ley Organica 3/2018 desarrolla en Espana materias relacionadas con:', 'Proteccion de datos personales y derechos digitales', 'Contratacion administrativa', 'Haciendas locales', 'Procedimiento electoral', 'a', 'El programa oficial incluye disposiciones generales, principios de proteccion de datos y derechos de las personas.', 'Ley Organica 3/2018', 1),
  (9, 'La Ley 40/2015 se estudia en el bloque de:', 'Gestion universitaria', 'Derecho Administrativo', 'Gestion de personal', 'Informatica', 'b', 'El anexo II situa la Ley 40/2015 dentro del Bloque II: Derecho Administrativo.', 'BOE-A-2026-9563, anexo II', 1),
  (11, 'La Ley 39/2015 regula principalmente:', 'El procedimiento administrativo comun', 'La organizacion militar', 'El regimen electoral general', 'La universidad privada', 'a', 'La Ley 39/2015 es la norma basica del procedimiento administrativo comun.', 'Ley 39/2015', 1),
  (15, 'El TREBEP fue aprobado por:', 'Ley Organica 2/2023', 'Real Decreto Legislativo 5/2015', 'Ley 39/2015', 'Ley 1/2026', 'b', 'El programa oficial cita el Real Decreto Legislativo 5/2015 como texto refundido del Estatuto Basico del Empleado Publico.', 'BOE-A-2026-9563, anexo II', 1),
  (20, 'La Ley Organica 2/2023 regula:', 'El Sistema Universitario', 'El procedimiento sancionador tributario', 'La contratacion menor', 'La jurisdiccion contenciosa', 'a', 'El Bloque IV incluye la Ley Organica 2/2023 del Sistema Universitario.', 'BOE-A-2026-9563, anexo II', 1)
) AS q(numero, enunciado, a, b, c, d, correcta, explicacion, referencia, dificultad)
ON q.numero = t.numero;
