-- =============================================
-- OPOSIWORK — Campos SM-2 en tabla flashcards
-- =============================================
-- Algoritmo de repetición espaciada SM-2:
--   intervalo: días hasta próxima revisión
--   repeticion: nº de repeticiones correctas consecutivas
--   facilidad: factor de facilidad (1.3–5.0, default 2.5)
--   proxima_revision: fecha de próxima revisión

ALTER TABLE flashcards
  ADD COLUMN IF NOT EXISTS intervalo INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS repeticion INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS facilidad FLOAT DEFAULT 2.5,
  ADD COLUMN IF NOT EXISTS proxima_revision DATE DEFAULT CURRENT_DATE;

CREATE INDEX IF NOT EXISTS idx_flashcards_proxima_revision
  ON flashcards(proxima_revision);
