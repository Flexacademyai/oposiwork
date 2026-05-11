-- =============================================
-- OPOSIWORK — Triggers para updated_at automático
-- =============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Convocatorias
CREATE OR REPLACE TRIGGER trg_convocatorias_updated_at
  BEFORE UPDATE ON convocatorias
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Perfiles de usuario
CREATE OR REPLACE TRIGGER trg_perfiles_updated_at
  BEFORE UPDATE ON perfiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Progreso por tema
CREATE OR REPLACE TRIGGER trg_progreso_temas_updated_at
  BEFORE UPDATE ON progreso_temas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Consentimientos de privacidad
CREATE OR REPLACE TRIGGER trg_consentimientos_updated_at
  BEFORE UPDATE ON consentimientos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
