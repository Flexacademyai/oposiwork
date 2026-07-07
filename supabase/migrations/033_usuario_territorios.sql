-- "Sigue tu territorio": suscripción a alertas por provincia/comunidad.
-- Cuando monitor-boe publica una convocatoria nueva cuyo territorio coincide,
-- el usuario recibe notificación (in-app, push y email) aunque no siga
-- ninguna oposición todavía. Diferencial frente a apps de tests y de alertas.

create table if not exists usuario_territorios (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references perfiles(id) on delete cascade,
  territorio text not null,
  activa boolean not null default true,
  created_at timestamptz not null default now(),
  unique (usuario_id, territorio)
);

create index if not exists idx_usuario_territorios_territorio
  on usuario_territorios (territorio) where activa;

alter table usuario_territorios enable row level security;

create policy "usuarios_propios_territorios" on usuario_territorios
  for all using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);
