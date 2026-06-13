-- Corrige warnings del Security Advisor:
-- - public/signed-in users can execute SECURITY DEFINER function
-- - fija search_path de la funcion usada solo por trigger interno.

CREATE OR REPLACE FUNCTION public.sincronizar_email_perfil()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.perfiles
  SET email = NEW.email,
      updated_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.sincronizar_email_perfil() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.sincronizar_email_perfil() FROM anon;
REVOKE EXECUTE ON FUNCTION public.sincronizar_email_perfil() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.sincronizar_email_perfil() TO postgres;
GRANT EXECUTE ON FUNCTION public.sincronizar_email_perfil() TO supabase_auth_admin;
