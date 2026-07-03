-- ════════════════════════════════════════════════════════════════════════
-- 030_proteger_columnas_facturacion_perfil.sql
--
-- FIX CRÍTICO: bloquea el bypass del pago.
--
-- La política "perfil_propio" (001) es FOR ALL USING (auth.uid() = id) y no
-- tiene WITH CHECK ni restricción de columnas. Eso permitía que cualquier
-- usuario autenticado, con la anon key pública + su JWT, hiciera:
--
--   supabase.from('perfiles').update({ plan: 'annual', plan_fin: '2099-01-01' })
--
-- auto-concediéndose Premium y accediendo a TODO el contenido de pago (cuyas
-- políticas RLS leen perfiles.plan / plan_fin). También podía sobrescribir
-- stripe_customer_id / revenuecat_id.
--
-- Defensa en dos capas:
--   1. Privilegios de columna: authenticated/anon solo pueden escribir las
--      columnas legítimas del perfil. Las columnas de facturación quedan
--      reservadas a service_role (Edge Functions de Stripe/RevenueCat).
--   2. Trigger BEFORE INSERT/UPDATE: aunque alguien re-otorgue privilegios o
--      use otra vía, los valores de facturación se preservan/forzan salvo que
--      la operación venga de un rol privilegiado (service_role/postgres).
--
-- El cliente Flutter solo escribe: nombre, apellidos, avatar_url,
-- notificaciones_push, notificaciones_email, updated_at — así que esta
-- restricción NO rompe ningún flujo de la app.
-- ════════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────────────
-- Capa 1 · Privilegios de columna
-- ────────────────────────────────────────────────────────────────────────

REVOKE UPDATE, INSERT ON public.perfiles FROM anon, authenticated;

-- Columnas que el usuario SÍ puede modificar sobre su propia fila.
GRANT UPDATE (
  nombre,
  apellidos,
  avatar_url,
  notificaciones_push,
  notificaciones_email,
  updated_at
) ON public.perfiles TO authenticated;

-- INSERT acotado: el perfil lo crea un trigger SECURITY DEFINER en el alta,
-- pero si por cualquier vía el cliente insertara, no podrá fijar 'plan' ni
-- columnas de facturación (tomarán su DEFAULT — 'free').
GRANT INSERT (
  id,
  nombre,
  apellidos,
  avatar_url,
  notificaciones_push,
  notificaciones_email
) ON public.perfiles TO authenticated;

-- ────────────────────────────────────────────────────────────────────────
-- Capa 2 · Trigger de protección (defensa en profundidad)
-- ────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.proteger_columnas_facturacion_perfil()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rol_privilegiado BOOLEAN := current_user IN (
    'service_role', 'postgres', 'supabase_admin', 'supabase_auth_admin'
  );
BEGIN
  IF rol_privilegiado THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    -- Un perfil creado por un rol no privilegiado nunca nace Premium.
    NEW.plan                   := 'free';
    NEW.plan_inicio            := NULL;
    NEW.plan_fin               := NULL;
    NEW.revenuecat_id          := NULL;
    NEW.stripe_customer_id     := NULL;
    NEW.stripe_subscription_id := NULL;
  ELSE -- UPDATE: conservar SIEMPRE los valores de facturación previos.
    NEW.plan                   := OLD.plan;
    NEW.plan_inicio            := OLD.plan_inicio;
    NEW.plan_fin               := OLD.plan_fin;
    NEW.revenuecat_id          := OLD.revenuecat_id;
    NEW.stripe_customer_id     := OLD.stripe_customer_id;
    NEW.stripe_subscription_id := OLD.stripe_subscription_id;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.proteger_columnas_facturacion_perfil() FROM PUBLIC, anon, authenticated;

-- Debe ejecutarse ANTES que trg_perfiles_updated_at (orden alfabético de
-- triggers de la misma fase): el prefijo 'trg_a_' lo coloca primero, aunque
-- el orden no es crítico porque solo reescribe columnas de facturación.
DROP TRIGGER IF EXISTS trg_a_proteger_facturacion_perfil ON public.perfiles;
CREATE TRIGGER trg_a_proteger_facturacion_perfil
  BEFORE INSERT OR UPDATE ON public.perfiles
  FOR EACH ROW
  EXECUTE FUNCTION public.proteger_columnas_facturacion_perfil();
