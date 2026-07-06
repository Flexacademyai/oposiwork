-- Título y descripción SEO generados por IA para las oposiciones autopublicadas.
-- Los rellena monitor-boe (best-effort, requiere ANTHROPIC_API_KEY en secrets);
-- las páginas dinámicas /oposiciones/<slug>/ los usan cuando existen.
alter table oposiciones
  add column if not exists seo_titulo text,
  add column if not exists seo_descripcion text;

comment on column oposiciones.seo_titulo is 'Título SEO limpio generado por IA (max ~60 chars). Null = usar nombre.';
comment on column oposiciones.seo_descripcion is 'Meta description SEO generada por IA (max ~155 chars). Null = generar desde datos.';
