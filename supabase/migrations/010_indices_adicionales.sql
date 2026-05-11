-- =============================================
-- OPOSIWORK — Índices adicionales de rendimiento
-- =============================================

CREATE INDEX IF NOT EXISTS idx_consentimientos_tipo
  ON consentimientos(usuario_id, tipo);

CREATE INDEX IF NOT EXISTS idx_tema_embeddings_contenido
  ON tema_embeddings(contenido_id);

CREATE INDEX IF NOT EXISTS idx_sesiones_voz_inicio
  ON sesiones_voz(inicio DESC);

CREATE INDEX IF NOT EXISTS idx_simulacros_estado
  ON simulacros(usuario_id, estado);

CREATE INDEX IF NOT EXISTS idx_simulacros_oposicion
  ON simulacros(oposicion_id);

-- Índice para búsqueda de flashcards a repasar hoy
CREATE INDEX IF NOT EXISTS idx_flashcards_sm2
  ON flashcards(proxima_revision, tema_id);

-- Índice para notificaciones sin enviar
CREATE INDEX IF NOT EXISTS idx_notificaciones_sin_enviar
  ON notificaciones_convocatoria(enviada, created_at)
  WHERE enviada = FALSE;
