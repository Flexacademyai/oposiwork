-- =============================================
-- OPOSIWORK — Consentimientos de privacidad (RGPD)
-- =============================================
-- Registra el consentimiento explícito del usuario
-- antes de usar funciones de IA y voz.

CREATE TABLE IF NOT EXISTS consentimientos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('ia', 'voz', 'analytics')),
  aceptado BOOLEAN DEFAULT FALSE,
  aceptado_en TIMESTAMPTZ,
  ip_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, tipo)
);

CREATE INDEX IF NOT EXISTS idx_consentimientos_usuario
  ON consentimientos(usuario_id);

ALTER TABLE consentimientos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "consentimientos_propios" ON consentimientos
  FOR ALL USING (auth.uid() = usuario_id);
