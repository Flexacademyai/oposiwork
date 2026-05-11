-- Evita duplicados accidentales durante cargas del pipeline de contenido.
-- Estas restricciones no sustituyen la revisión editorial del contenido.

CREATE UNIQUE INDEX IF NOT EXISTS idx_temas_oposicion_numero_unique
  ON temas(oposicion_id, numero);

CREATE UNIQUE INDEX IF NOT EXISTS idx_contenido_temas_version_unique
  ON contenido_temas(tema_id, tipo, version);

CREATE UNIQUE INDEX IF NOT EXISTS idx_flashcards_tema_pregunta_unique
  ON flashcards(tema_id, pregunta);

CREATE UNIQUE INDEX IF NOT EXISTS idx_preguntas_test_tema_enunciado_unique
  ON preguntas_test(tema_id, enunciado);

CREATE UNIQUE INDEX IF NOT EXISTS idx_psicotecnicos_oposicion_enunciado_unique
  ON psicotecnicos(oposicion_id, enunciado);

CREATE UNIQUE INDEX IF NOT EXISTS idx_temario_pdfs_oposicion_path_unique
  ON temario_pdfs(oposicion_id, storage_path);
