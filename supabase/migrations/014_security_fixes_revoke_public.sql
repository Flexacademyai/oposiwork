-- ════════════════════════════════════════════════════════════════════════
-- 014_security_fixes_revoke_public.sql
-- Elimina EXECUTE de PUBLIC en funciones SECURITY DEFINER.
-- El REVOKE directo a anon/authenticated no es suficiente porque Postgres
-- concede EXECUTE a PUBLIC por defecto. Hay que revocar de PUBLIC primero
-- y re-otorgar solo a los roles que deben invocar estas funciones.
-- ════════════════════════════════════════════════════════════════════════

-- check_rate_limit (invocada por Edge Functions via service_role)
REVOKE EXECUTE ON FUNCTION public.check_rate_limit(text, text, integer, integer) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.check_rate_limit(text, text, integer, integer) TO postgres, service_role;

-- check_user_rate_limit (ídem)
REVOKE EXECUTE ON FUNCTION public.check_user_rate_limit(text, text, integer, integer) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.check_user_rate_limit(text, text, integer, integer) TO postgres, service_role;

-- cleanup_user_rate_limits (invocada por cron/service_role)
REVOKE EXECUTE ON FUNCTION public.cleanup_user_rate_limits() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.cleanup_user_rate_limits() TO postgres, service_role;

-- crear_perfil_nuevo_usuario (invocada solo por trigger en auth.users)
REVOKE EXECUTE ON FUNCTION public.crear_perfil_nuevo_usuario() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.crear_perfil_nuevo_usuario() TO postgres;

-- manejar_nuevo_usuario (ídem — trigger)
REVOKE EXECUTE ON FUNCTION public.manejar_nuevo_usuario() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.manejar_nuevo_usuario() TO postgres;

-- obtener_segundos_usados_mes (invocada desde Edge Functions via service_role)
REVOKE EXECUTE ON FUNCTION public.obtener_segundos_usados_mes(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.obtener_segundos_usados_mes(uuid) TO postgres, service_role;
