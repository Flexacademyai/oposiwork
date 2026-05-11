-- =============================================
-- OPOSIWORK — Simulacros de examen
-- =============================================
-- Un simulacro es un examen completo cronometrado
-- sin feedback inmediato (igual que el examen real).

CREATE TABLE IF NOT EXISTS simulacros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  num_preguntas INTEGER NOT NULL DEFAULT 50,
  tiempo_limite_minutos INTEGER DEFAULT 90,
  estado TEXT DEFAULT 'en_curso'
    CHECK (estado IN ('en_curso', 'completado', 'abandonado')),
  inicio TIMESTAMPTZ DEFAULT NOW(),
  fin TIMESTAMPTZ,
  puntuacion_final FLOAT,          -- % de aciertos al completar
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_simulacros_usuario
  ON simulacros(usuario_id);

ALTER TABLE simulacros ENABLE ROW LEVEL SECURITY;

CREATE POLICY "simulacros_propios" ON simulacros
  FOR ALL USING (auth.uid() = usuario_id);

-- Resultados individuales de cada pregunta dentro del simulacro
CREATE TABLE IF NOT EXISTS resultados_simulacros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  simulacro_id UUID REFERENCES simulacros(id) ON DELETE CASCADE,
  pregunta_id UUID REFERENCES preguntas_test(id),
  respuesta_dada TEXT CHECK (respuesta_dada IN ('a', 'b', 'c', 'd')),
  correcto BOOLEAN,
  tiempo_segundos INTEGER
);

CREATE INDEX IF NOT EXISTS idx_resultados_simulacros
  ON resultados_simulacros(simulacro_id);

ALTER TABLE resultados_simulacros ENABLE ROW LEVEL SECURITY;

-- Acceso si el usuario es dueño del simulacro padre
CREATE POLICY "resultados_simulacro_propios" ON resultados_simulacros
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM simulacros
      WHERE id = simulacro_id AND usuario_id = auth.uid()
    )
  );
