-- Corrige alertas actuales de Supabase Security Advisor.
-- Ejecutar manualmente en SQL Editor si supabase db push sigue bloqueado
-- por historial remoto de migraciones.

-- 1. public.boletines sin RLS.
DO $$
BEGIN
  IF to_regclass('public.boletines') IS NOT NULL THEN
    ALTER TABLE public.boletines ENABLE ROW LEVEL SECURITY;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'boletines'
        AND policyname = 'boletines_lectura_autenticada'
    ) THEN
      CREATE POLICY boletines_lectura_autenticada
      ON public.boletines
      FOR SELECT
      TO authenticated
      USING (true);
    END IF;
  END IF;
END $$;

-- 2. Vista public.oposiciones_activas con SECURITY DEFINER.
-- Las vistas deben respetar RLS del usuario invocador; security_invoker evita
-- que la vista ejecute con privilegios del propietario.
DO $$
BEGIN
  IF to_regclass('public.oposiciones_activas') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.oposiciones_activas SET (security_invoker = true)';
  END IF;
EXCEPTION
  WHEN undefined_object THEN
    NULL;
END $$;

-- Si la vista no existe, la creamos como security_invoker.
CREATE OR REPLACE VIEW public.oposiciones_activas
WITH (security_invoker = true) AS
SELECT
  o.*
FROM public.oposiciones o
WHERE o.activa = true
  AND EXISTS (
    SELECT 1
    FROM public.convocatorias c
    WHERE c.oposicion_id = o.id
      AND c.estado = 'abierta'
      AND c.fecha_inicio_instancias <= CURRENT_DATE
      AND c.fecha_fin_instancias >= CURRENT_DATE
  );

GRANT SELECT ON public.oposiciones_activas TO anon, authenticated;

-- 3. Function search_path mutable.
DO $$
BEGIN
  IF to_regprocedure('public.convocatoria_esta_activa(date,date,text)') IS NOT NULL THEN
    ALTER FUNCTION public.convocatoria_esta_activa(date,date,text)
      SET search_path = public, pg_temp;
  END IF;
END $$;

-- 4. SECURITY DEFINER ejecutables por anon/authenticated/public.
-- Se revoca PUBLIC primero porque Postgres concede EXECUTE a PUBLIC por defecto.
-- Reotorgamos solo a service_role/postgres. Si alguna de estas funciones se usa
-- desde el cliente, debe moverse a una vista/RPC no SECURITY DEFINER.
DO $$
BEGIN
  IF to_regprocedure('public.buscar_oposiciones_activas()') IS NOT NULL THEN
    REVOKE EXECUTE ON FUNCTION public.buscar_oposiciones_activas() FROM PUBLIC;
    REVOKE EXECUTE ON FUNCTION public.buscar_oposiciones_activas() FROM anon, authenticated;
    GRANT EXECUTE ON FUNCTION public.buscar_oposiciones_activas() TO postgres, service_role;
  END IF;

  IF to_regprocedure('public.cerrar_convocatorias_caducadas()') IS NOT NULL THEN
    REVOKE EXECUTE ON FUNCTION public.cerrar_convocatorias_caducadas() FROM PUBLIC;
    REVOKE EXECUTE ON FUNCTION public.cerrar_convocatorias_caducadas() FROM anon, authenticated;
    GRANT EXECUTE ON FUNCTION public.cerrar_convocatorias_caducadas() TO postgres, service_role;
  END IF;
END $$;
