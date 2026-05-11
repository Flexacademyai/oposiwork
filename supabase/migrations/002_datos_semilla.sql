-- =============================================
-- OPOSIWORK — Datos semilla MVP (3 oposiciones)
-- =============================================

INSERT INTO oposiciones (slug, nombre, cuerpo, administracion, nivel, tiene_psicotecnicos, tiene_pruebas_fisicas) VALUES
  (
    'auxiliar-administrativo-estado',
    'Auxiliar Administrativo del Estado',
    'Cuerpo General Auxiliar de la Administración del Estado',
    'AGE',
    'C2',
    FALSE,
    FALSE
  ),
  (
    'policia-nacional-escala-basica',
    'Policía Nacional — Escala Básica',
    'Cuerpo Nacional de Policía',
    'Nacional',
    'C1',
    TRUE,
    TRUE
  ),
  (
    'tes-bomberos-zaragoza',
    'TES Bomberos Zaragoza',
    'Técnico en Emergencias Sanitarias',
    'Zaragoza',
    'C2',
    TRUE,
    TRUE
  );

-- Logros predefinidos
INSERT INTO logros (slug, nombre, descripcion, icono, puntos) VALUES
  ('primer_tema', 'Primer Tema', 'Completa tu primer tema', '📚', 50),
  ('semana_perfecta', 'Semana Perfecta', '7 días estudiando seguidos', '🔥', 100),
  ('test_perfecto', 'Test Perfecto', '100% en un test', '⭐', 30),
  ('psico_master', 'Psico Máster', '50 psicotécnicos completados', '🧠', 80),
  ('temario_completo', 'Temario Completo', 'Todos los temas al 100%', '🏆', 200),
  ('madrugador', 'Madrugador', 'Estudia antes de las 8:00 AM', '🌅', 20),
  ('constante', 'Constante', '30 días de racha', '💪', 300);

-- Temas Auxiliar Administrativo (Bloque I — Organización del Estado)
INSERT INTO temas (oposicion_id, numero, titulo, bloque, orden)
SELECT
  id,
  t.numero,
  t.titulo,
  t.bloque,
  t.numero
FROM oposiciones, (VALUES
  (1, 'La Constitución Española de 1978. Estructura y contenido. Los principios constitucionales. Los derechos y deberes fundamentales', 'Bloque I: Organización del Estado'),
  (2, 'La Corona. Las Cortes Generales. El Gobierno y la Administración. El Poder Judicial', 'Bloque I: Organización del Estado'),
  (3, 'La organización territorial del Estado. Las Comunidades Autónomas. La Administración Local', 'Bloque I: Organización del Estado'),
  (4, 'La Unión Europea. Instituciones y órganos. El Derecho comunitario', 'Bloque I: Organización del Estado'),
  (5, 'La Ley 39/2015, de 1 de octubre, del Procedimiento Administrativo Común de las Administraciones Públicas (I)', 'Bloque I: Organización del Estado'),
  (6, 'La Ley 39/2015, de 1 de octubre, del Procedimiento Administrativo Común de las Administraciones Públicas (II)', 'Bloque I: Organización del Estado'),
  (7, 'La Ley 40/2015, de 1 de octubre, de Régimen Jurídico del Sector Público', 'Bloque I: Organización del Estado'),
  (8, 'El personal al servicio de la Administración General del Estado. Clases de personal. El Estatuto Básico del Empleado Público', 'Bloque I: Organización del Estado'),
  (9, 'Derechos y deberes de los empleados públicos. Régimen disciplinario', 'Bloque I: Organización del Estado'),
  (10, 'Los contratos administrativos. La Ley 9/2017 de Contratos del Sector Público', 'Bloque I: Organización del Estado'),
  (11, 'La protección de datos de carácter personal. El Reglamento General de Protección de Datos (RGPD)', 'Bloque I: Organización del Estado'),
  (12, 'La Ley Orgánica 3/2007 para la igualdad efectiva de mujeres y hombres', 'Bloque I: Organización del Estado'),
  (13, 'La Ley 19/2013 de transparencia, acceso a la información pública y buen gobierno', 'Bloque I: Organización del Estado'),
  (14, 'Las tecnologías de la información en la Administración. La Administración electrónica', 'Bloque II: Informática y Ofimática'),
  (15, 'Microsoft Windows. Conceptos básicos. El escritorio y sus elementos', 'Bloque II: Informática y Ofimática'),
  (16, 'Microsoft Word. Procesamiento de textos. Funciones principales', 'Bloque II: Informática y Ofimática'),
  (17, 'Microsoft Excel. Hojas de cálculo. Funciones y fórmulas básicas', 'Bloque II: Informática y Ofimática'),
  (18, 'Microsoft Access. Bases de datos. Tablas, consultas e informes', 'Bloque II: Informática y Ofimática'),
  (19, 'Internet y correo electrónico. Navegadores. Seguridad en internet', 'Bloque II: Informática y Ofimática'),
  (20, 'Redes locales. Conceptos básicos. Configuración básica de red', 'Bloque II: Informática y Ofimática')
) AS t(numero, titulo, bloque)
WHERE slug = 'auxiliar-administrativo-estado';
