-- Activacion temporal de Premium para pruebas internas.
-- No es una migracion: ejecutar manualmente desde Supabase SQL Editor cuando
-- haya que validar contenido, descargas y rutas premium sin realizar cobros.
--
-- Cambia el email si quieres activar otro usuario de pruebas.

UPDATE public.perfiles AS p
SET
  plan = 'monthly',
  plan_inicio = now(),
  plan_fin = now() + interval '30 days',
  updated_at = now()
FROM auth.users AS u
WHERE u.id = p.id
  AND lower(u.email) = lower('israel.perles@gmail.com')
RETURNING p.id, p.plan, p.plan_inicio, p.plan_fin;

