-- ═══════════════════════════════════════════════════════════════════════
-- 013_security_fixes.sql
-- Corrige todos los avisos del security linter de Supabase (10/05/2026)
-- ═══════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────────────
-- 1. SEARCH_PATH MUTABLE
--    Fija search_path = public en cada función para que no pueda ser
--    manipulado por un atacante con control del search_path de sesión.
-- ────────────────────────────────────────────────────────────────────────

ALTER FUNCTION public.update_updated_at_column()
  SET search_path = public;

ALTER FUNCTION public.check_rate_limit(text, text, integer, integer)
  SET search_path = public;

ALTER FUNCTION public.check_user_rate_limit(text, text, integer, integer)
  SET search_path = public;

ALTER FUNCTION public.cleanup_user_rate_limits()
  SET search_path = public;

ALTER FUNCTION public.crear_perfil_nuevo_usuario()
  SET search_path = public;

ALTER FUNCTION public.manejar_nuevo_usuario()
  SET search_path = public;

ALTER FUNCTION public.obtener_segundos_usados_mes(uuid)
  SET search_path = public;

-- ────────────────────────────────────────────────────────────────────────
-- 2. REVOKE EXECUTE en funciones SECURITY DEFINER
--    Estas funciones ejecutan con privilegios del propietario (postgres).
--    Exponerlas a anon/authenticated permite escalada de privilegios.
--    Solo las invocan Edge Functions via service role o triggers internos.
-- ────────────────────────────────────────────────────────────────────────

REVOKE EXECUTE ON FUNCTION public.check_rate_limit(text, text, integer, integer)
  FROM anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.check_user_rate_limit(text, text, integer, integer)
  FROM anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.cleanup_user_rate_limits()
  FROM anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.crear_perfil_nuevo_usuario()
  FROM anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.manejar_nuevo_usuario()
  FROM anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.obtener_segundos_usados_mes(uuid)
  FROM anon, authenticated;

-- ────────────────────────────────────────────────────────────────────────
-- 3. EXTENSIÓN vector — mover al schema extensions
--
--    NOTA: la tabla public.tema_embeddings tiene columna embedding de tipo
--    vector. DROP EXTENSION CASCADE destruiría esa columna y su índice IVFFlat.
--    ALTER EXTENSION SET SCHEMA mueve la extensión sin pérdida de datos:
--    Postgres actualiza automáticamente las referencias internas de tipo.
-- ────────────────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS extensions;
ALTER EXTENSION vector SET SCHEMA extensions;
