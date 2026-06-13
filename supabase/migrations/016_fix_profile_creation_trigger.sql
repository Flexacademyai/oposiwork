-- El perfil se crea desde un trigger con privilegios de servidor.
-- El cliente Flutter no debe insertar en perfiles durante signUp porque RLS
-- puede bloquearlo si el email aún no está confirmado.

CREATE OR REPLACE FUNCTION public.manejar_nuevo_usuario()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre, apellidos, plan)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'nombre',
    NEW.raw_user_meta_data->>'apellidos',
    'free'
  )
  ON CONFLICT (id) DO UPDATE SET
    nombre = COALESCE(EXCLUDED.nombre, public.perfiles.nombre),
    apellidos = COALESCE(EXCLUDED.apellidos, public.perfiles.apellidos),
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.manejar_nuevo_usuario();

REVOKE EXECUTE ON FUNCTION public.manejar_nuevo_usuario() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manejar_nuevo_usuario() TO postgres;

INSERT INTO public.perfiles (id, nombre, apellidos, plan)
SELECT
  u.id,
  u.raw_user_meta_data->>'nombre',
  u.raw_user_meta_data->>'apellidos',
  'free'
FROM auth.users u
LEFT JOIN public.perfiles p ON p.id = u.id
WHERE p.id IS NULL;
