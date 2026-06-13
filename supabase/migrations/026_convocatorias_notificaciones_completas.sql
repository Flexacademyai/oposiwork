-- Sistema completo de cambios, auditoria de fuentes y notificaciones.

ALTER TABLE public.perfiles
  ADD COLUMN IF NOT EXISTS email TEXT;

UPDATE public.perfiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id
  AND p.email IS NULL;

CREATE OR REPLACE FUNCTION public.manejar_nuevo_usuario()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre, apellidos, email, plan)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'nombre',
    NEW.raw_user_meta_data->>'apellidos',
    NEW.email,
    'free'
  )
  ON CONFLICT (id) DO UPDATE SET
    nombre = COALESCE(EXCLUDED.nombre, public.perfiles.nombre),
    apellidos = COALESCE(EXCLUDED.apellidos, public.perfiles.apellidos),
    email = COALESCE(EXCLUDED.email, public.perfiles.email),
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.manejar_nuevo_usuario() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manejar_nuevo_usuario() TO postgres;

CREATE OR REPLACE FUNCTION public.sincronizar_email_perfil()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  UPDATE public.perfiles
  SET email = NEW.email,
      updated_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_profile_email ON auth.users;
CREATE TRIGGER trg_sync_profile_email
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sincronizar_email_perfil();

DO $$
BEGIN
  ALTER TABLE public.notificaciones_convocatoria
    DROP CONSTRAINT IF EXISTS notificaciones_convocatoria_tipo_check;

  ALTER TABLE public.notificaciones_convocatoria
    ADD CONSTRAINT notificaciones_convocatoria_tipo_check
    CHECK (tipo IN (
      'retraso',
      'adelanto',
      'cambio_normativa',
      'nueva_convocatoria',
      'plazo_instancias',
      'cambio_convocatoria',
      'convocatoria_cerrada',
      'fuente_error'
    ));
END $$;

ALTER TABLE public.notificaciones_convocatoria
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS public.convocatoria_cambios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  convocatoria_id UUID REFERENCES public.convocatorias(id) ON DELETE CASCADE,
  oposicion_id UUID REFERENCES public.oposiciones(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL,
  campo TEXT,
  valor_anterior TEXT,
  valor_nuevo TEXT,
  fuente_url TEXT,
  detectado_en TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS public.notificacion_destinatarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notificacion_id UUID REFERENCES public.notificaciones_convocatoria(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES public.perfiles(id) ON DELETE CASCADE,
  canal TEXT NOT NULL CHECK (canal IN ('push', 'email', 'in_app')),
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'enviada', 'fallida', 'omitida')),
  error TEXT,
  enviada_en TIMESTAMPTZ,
  leida_en TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (notificacion_id, usuario_id, canal)
);

ALTER TABLE public.notificacion_destinatarios
  ADD COLUMN IF NOT EXISTS leida_en TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.usuario_dispositivos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES public.perfiles(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  plataforma TEXT,
  activo BOOLEAN DEFAULT TRUE,
  ultimo_uso TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (usuario_id, fcm_token)
);

CREATE TABLE IF NOT EXISTS public.fuente_auditoria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fuente_nombre TEXT NOT NULL,
  fuente_url TEXT NOT NULL,
  ambito TEXT,
  estado TEXT NOT NULL CHECK (estado IN ('ok', 'sin_resultados', 'error')),
  items_detectados INTEGER DEFAULT 0,
  error TEXT,
  ejecutado_en TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.convocatoria_cambios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacion_destinatarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuario_dispositivos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fuente_auditoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS convocatoria_cambios_lectura_autenticada ON public.convocatoria_cambios;
CREATE POLICY convocatoria_cambios_lectura_autenticada
ON public.convocatoria_cambios
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS notificacion_destinatarios_propias ON public.notificacion_destinatarios;
CREATE POLICY notificacion_destinatarios_propias
ON public.notificacion_destinatarios
FOR SELECT
TO authenticated
USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS notificacion_destinatarios_actualizar_propias ON public.notificacion_destinatarios;
CREATE POLICY notificacion_destinatarios_actualizar_propias
ON public.notificacion_destinatarios
FOR UPDATE
TO authenticated
USING (auth.uid() = usuario_id)
WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS usuario_dispositivos_propios ON public.usuario_dispositivos;
CREATE POLICY usuario_dispositivos_propios
ON public.usuario_dispositivos
FOR ALL
TO authenticated
USING (auth.uid() = usuario_id)
WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS fuente_auditoria_service_only ON public.fuente_auditoria;
CREATE POLICY fuente_auditoria_service_only
ON public.fuente_auditoria
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS notificaciones_lectura_autenticada ON public.notificaciones_convocatoria;
CREATE POLICY notificaciones_lectura_autenticada
ON public.notificaciones_convocatoria
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.notificacion_destinatarios nd
    WHERE nd.notificacion_id = notificaciones_convocatoria.id
      AND nd.usuario_id = auth.uid()
  )
);

CREATE INDEX IF NOT EXISTS idx_convocatoria_cambios_convocatoria
  ON public.convocatoria_cambios(convocatoria_id, detectado_en DESC);

CREATE INDEX IF NOT EXISTS idx_notificacion_destinatarios_pendientes
  ON public.notificacion_destinatarios(estado, canal, created_at)
  WHERE estado = 'pendiente';

CREATE INDEX IF NOT EXISTS idx_usuario_dispositivos_usuario_activo
  ON public.usuario_dispositivos(usuario_id, activo);

CREATE INDEX IF NOT EXISTS idx_fuente_auditoria_fecha
  ON public.fuente_auditoria(ejecutado_en DESC);

CREATE OR REPLACE FUNCTION public.marcar_notificaciones_enviadas_si_completas()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.notificaciones_convocatoria n
  SET enviada = true
  WHERE enviada = false
    AND EXISTS (
      SELECT 1
      FROM public.notificacion_destinatarios nd
      WHERE nd.notificacion_id = n.id
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.notificacion_destinatarios nd
      WHERE nd.notificacion_id = n.id
        AND nd.estado = 'pendiente'
    );
$$;

REVOKE EXECUTE ON FUNCTION public.marcar_notificaciones_enviadas_si_completas() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.marcar_notificaciones_enviadas_si_completas() TO service_role, postgres;
