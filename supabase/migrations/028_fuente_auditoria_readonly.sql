-- Permite que usuarios autenticados vean el estado de las fuentes oficiales.
-- No permite insertar, modificar ni borrar auditorias desde el cliente.

ALTER TABLE public.fuente_auditoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fuente_auditoria_lectura_autenticada
ON public.fuente_auditoria;

CREATE POLICY fuente_auditoria_lectura_autenticada
ON public.fuente_auditoria
FOR SELECT
TO authenticated
USING (true);

