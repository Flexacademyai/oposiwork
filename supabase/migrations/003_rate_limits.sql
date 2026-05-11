-- =============================================
-- OPOSIWORK — Rate limiting por IP y endpoint
-- =============================================

CREATE TABLE IF NOT EXISTS rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_hash TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  conteo INTEGER DEFAULT 1,
  ventana_inicio TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_ip
  ON rate_limits(ip_hash, endpoint, ventana_inicio);

ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;
-- Solo service role puede operar sobre esta tabla (sin políticas para usuarios)

-- Función que verifica y registra un intento
-- Devuelve TRUE si se permite, FALSE si se supera el límite
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_ip_hash TEXT,
  p_endpoint TEXT,
  p_limite INTEGER,
  p_ventana_segundos INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  v_conteo INTEGER;
BEGIN
  SELECT COALESCE(SUM(conteo), 0)
  INTO v_conteo
  FROM rate_limits
  WHERE ip_hash = p_ip_hash
    AND endpoint = p_endpoint
    AND ventana_inicio > NOW() - (p_ventana_segundos || ' seconds')::INTERVAL;

  IF v_conteo >= p_limite THEN
    RETURN FALSE;
  END IF;

  INSERT INTO rate_limits(ip_hash, endpoint, ventana_inicio)
  VALUES (p_ip_hash, p_endpoint, NOW());

  -- Limpiar entradas antiguas (mantenimiento)
  DELETE FROM rate_limits
  WHERE ventana_inicio < NOW() - INTERVAL '2 hours';

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
