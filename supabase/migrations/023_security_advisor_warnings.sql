-- Corrige warnings restantes del Security Advisor.

ALTER FUNCTION public.convocatoria_esta_activa(text, date, date)
  SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.buscar_oposiciones_activas(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  boolean,
  integer,
  integer
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.buscar_oposiciones_activas(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  boolean,
  integer,
  integer
) TO postgres, service_role;

REVOKE EXECUTE ON FUNCTION public.cerrar_convocatorias_expiradas()
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.cerrar_convocatorias_expiradas()
  TO postgres, service_role;
