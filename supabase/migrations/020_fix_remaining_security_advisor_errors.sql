-- Correccion final para errores actuales del Supabase Security Advisor.
-- Errores objetivo:
-- - security_definer_view_public_oposiciones_activas
-- - rls_disabled_in_public_public_boletines

-- 1. Forzar que public.oposiciones_activas NO sea SECURITY DEFINER.
-- DROP + CREATE evita que quede una opcion antigua en reloptions.
DROP VIEW IF EXISTS public.oposiciones_activas;

CREATE VIEW public.oposiciones_activas
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

-- 2. Activar RLS en public.boletines y dejar lectura controlada.
ALTER TABLE IF EXISTS public.boletines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS boletines_lectura_publica ON public.boletines;
DROP POLICY IF EXISTS boletines_lectura_autenticada ON public.boletines;

CREATE POLICY boletines_lectura_autenticada
ON public.boletines
FOR SELECT
TO authenticated
USING (true);

-- 3. Consultas de comprobacion visual para SQL Editor.
SELECT
  'oposiciones_activas_reloptions' AS check_name,
  c.reloptions::text AS value
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'oposiciones_activas';

SELECT
  'boletines_rls' AS check_name,
  c.relrowsecurity::text AS value
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'boletines';
