-- =============================================
-- OPOSIWORK — Sesiones de voz con OpenAI Realtime
-- =============================================
-- Registra cada sesión de voz para control de cuota mensual.
-- Plan monthly: 1800s/mes. Plan annual: 3600s/mes.

CREATE TABLE IF NOT EXISTS sesiones_voz (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fin TIMESTAMPTZ,
  duracion_segundos INTEGER DEFAULT 0,
  modelo TEXT DEFAULT 'gpt-4o-realtime-preview',
  session_id_openai TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sesiones_voz_usuario_mes
  ON sesiones_voz(usuario_id, inicio);

ALTER TABLE sesiones_voz ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sesiones_voz_propias" ON sesiones_voz
  FOR ALL USING (auth.uid() = usuario_id);

-- Función para obtener los segundos de voz usados en el mes actual
CREATE OR REPLACE FUNCTION obtener_segundos_usados_mes(uid UUID)
RETURNS INTEGER AS $$
  SELECT COALESCE(SUM(duracion_segundos), 0)::INTEGER
  FROM sesiones_voz
  WHERE usuario_id = uid
    AND DATE_TRUNC('month', inicio) = DATE_TRUNC('month', NOW());
$$ LANGUAGE sql STABLE SECURITY DEFINER;
