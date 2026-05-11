-- =============================================
-- OPOSIWORK — Rate limiting por usuario autenticado
-- =============================================
-- Complementa la tabla rate_limits (IP-based, migración 003).
-- Esta tabla registra intentos por usuario autenticado y endpoint,
-- usada tanto por Edge Functions como por el cliente Flutter via RPC.

CREATE TABLE IF NOT EXISTS user_rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL,
  conteo_minuto INTEGER DEFAULT 0,
  conteo_hora INTEGER DEFAULT 0,
  ventana_minuto TIMESTAMPTZ DEFAULT NOW(),
  ventana_hora TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, endpoint)
);

CREATE INDEX IF NOT EXISTS idx_user_rate_limits_usuario
  ON user_rate_limits(usuario_id, endpoint);

ALTER TABLE user_rate_limits ENABLE ROW LEVEL SECURITY;
-- Solo service role puede operar esta tabla directamente.
-- El acceso desde el cliente Flutter se hace via RPC SECURITY DEFINER.

-- ── Función para Edge Functions (recibe usuario_id explícito) ─────────────

CREATE OR REPLACE FUNCTION check_user_rate_limit(
  p_usuario_id    UUID,
  p_endpoint      TEXT,
  p_limite_minuto INTEGER,
  p_limite_hora   INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  v_ahora         TIMESTAMPTZ := NOW();
  v_conteo_min    INTEGER;
  v_conteo_hora   INTEGER;
  v_ventana_min   TIMESTAMPTZ;
  v_ventana_hora  TIMESTAMPTZ;
BEGIN
  -- Crear fila si no existe
  INSERT INTO user_rate_limits (usuario_id, endpoint, conteo_minuto, conteo_hora, ventana_minuto, ventana_hora)
  VALUES (p_usuario_id, p_endpoint, 0, 0, v_ahora, v_ahora)
  ON CONFLICT (usuario_id, endpoint) DO NOTHING;

  -- Leer estado actual (con bloqueo para atomicidad)
  SELECT conteo_minuto, conteo_hora, ventana_minuto, ventana_hora
  INTO v_conteo_min, v_conteo_hora, v_ventana_min, v_ventana_hora
  FROM user_rate_limits
  WHERE usuario_id = p_usuario_id AND endpoint = p_endpoint
  FOR UPDATE;

  -- Reiniciar ventana de minuto si expiró
  IF v_ventana_min < v_ahora - INTERVAL '1 minute' THEN
    v_conteo_min  := 0;
    v_ventana_min := v_ahora;
  END IF;

  -- Reiniciar ventana de hora si expiró
  IF v_ventana_hora < v_ahora - INTERVAL '1 hour' THEN
    v_conteo_hora  := 0;
    v_ventana_hora := v_ahora;
  END IF;

  -- Rechazar si se supera algún límite
  IF v_conteo_min >= p_limite_minuto OR v_conteo_hora >= p_limite_hora THEN
    -- Actualizar ventanas reiniciadas aunque no se permita la petición
    UPDATE user_rate_limits
    SET ventana_minuto = v_ventana_min,
        ventana_hora   = v_ventana_hora,
        conteo_minuto  = v_conteo_min,
        conteo_hora    = v_conteo_hora
    WHERE usuario_id = p_usuario_id AND endpoint = p_endpoint;
    RETURN FALSE;
  END IF;

  -- Persistir contadores incrementados
  UPDATE user_rate_limits
  SET conteo_minuto = v_conteo_min  + 1,
      conteo_hora   = v_conteo_hora + 1,
      ventana_minuto = v_ventana_min,
      ventana_hora   = v_ventana_hora
  WHERE usuario_id = p_usuario_id AND endpoint = p_endpoint;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Función para Flutter cliente (usa auth.uid() interno) ────────────────
-- Llamada desde lib/core/security/security_service.dart como:
--   supabase.rpc('verificar_rate_limit', params: {
--     'p_accion': accion, 'p_limite_minuto': x, 'p_limite_hora': y })

CREATE OR REPLACE FUNCTION verificar_rate_limit(
  p_accion       TEXT,
  p_limite_minuto INTEGER,
  p_limite_hora   INTEGER
) RETURNS BOOLEAN AS $$
BEGIN
  -- Si no hay usuario autenticado, permitir (auth en la capa de arriba)
  IF auth.uid() IS NULL THEN
    RETURN TRUE;
  END IF;

  RETURN check_user_rate_limit(auth.uid(), p_accion, p_limite_minuto, p_limite_hora);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
