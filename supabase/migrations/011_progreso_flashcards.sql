-- =============================================
-- OPOSIWORK — Progreso SM-2 por usuario y flashcard
-- =============================================
-- Tabla separada de la flashcard compartida para aislar
-- el estado de repaso espaciado de cada usuario.
-- La tabla flashcards almacena las columnas SM-2 globales (legacy/default);
-- esta tabla almacena el estado real por usuario.

CREATE TABLE IF NOT EXISTS progreso_flashcards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  flashcard_id UUID REFERENCES flashcards(id) ON DELETE CASCADE,
  intervalo INTEGER DEFAULT 1,
  repeticion INTEGER DEFAULT 0,
  facilidad FLOAT DEFAULT 2.5,
  proxima_revision DATE DEFAULT CURRENT_DATE,
  ultima_respuesta INTEGER,  -- 0=no sabía, 1=dudé, 2=sabía, 3=fácil
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, flashcard_id)
);

CREATE INDEX IF NOT EXISTS idx_progreso_flashcards_usuario
  ON progreso_flashcards(usuario_id);

CREATE INDEX IF NOT EXISTS idx_progreso_flashcards_revision
  ON progreso_flashcards(usuario_id, proxima_revision);

ALTER TABLE progreso_flashcards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "progreso_flashcards_propios" ON progreso_flashcards
  FOR ALL USING (auth.uid() = usuario_id);

CREATE OR REPLACE TRIGGER trg_progreso_flashcards_updated_at
  BEFORE UPDATE ON progreso_flashcards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
