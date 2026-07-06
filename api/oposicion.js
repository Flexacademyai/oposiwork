// Página SEO dinámica por oposición. Las 5 páginas curadas de web/landing/
// existen como archivos estáticos y Vercel las sirve con prioridad; cualquier
// otro slug (las oposiciones que autopublica monitor-boe) cae aquí y se
// renderiza desde Supabase. Así el SEO crece solo, sin tocar código.
const SUPABASE_URL =
  process.env.SUPABASE_URL || 'https://gklwylkqykjjxwutfehw.supabase.co';
// La anon key es pública por diseño (la seguridad la provee RLS).
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrbHd5bGtxeWtqanh3dXRmZWh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MzE4NTcsImV4cCI6MjA5MzUwNzg1N30.Zyiv61ZsgUP7e3xsKxz0O_U2ziHH_4T6NATPp_NiqZE';

function escapeHtml(text) {
  return String(text ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function fechaLarga(iso) {
  if (!iso) return null;
  const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
  const d = new Date(`${String(iso).slice(0, 10)}T00:00:00Z`);
  if (Number.isNaN(d.getTime())) return null;
  return `${d.getUTCDate()} de ${meses[d.getUTCMonth()]} de ${d.getUTCFullYear()}`;
}

async function supaGet(path) {
  const resp = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
  });
  if (!resp.ok) return null;
  return await resp.json();
}

module.exports = async function handler(req, res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  const slug = String(req.query?.slug ?? '').trim();
  // El slug lo genera slugify() en monitor-boe: solo minúsculas, dígitos y guiones.
  if (!slug || !/^[a-z0-9-]{1,120}$/.test(slug)) {
    res.setHeader('Cache-Control', 's-maxage=300');
    return res.status(404).send('<!doctype html><html lang="es"><head><meta charset="utf-8"><title>No encontrado - Oposiwork</title><meta name="robots" content="noindex"></head><body><h1>Oposición no encontrada</h1><p><a href="/oposiciones/">Ver todas las oposiciones</a></p></body></html>');
  }

  const oposiciones = await supaGet(
    `oposiciones?select=id,slug,nombre,administracion,nivel,tiene_psicotecnicos&slug=eq.${encodeURIComponent(slug)}&activa=eq.true&limit=1`,
  );
  const op = oposiciones?.[0];

  if (!op) {
    res.setHeader('Cache-Control', 's-maxage=300');
    return res.status(404).send('<!doctype html><html lang="es"><head><meta charset="utf-8"><title>No encontrado - Oposiwork</title><meta name="robots" content="noindex"></head><body><h1>Oposición no encontrada</h1><p><a href="/oposiciones/">Ver todas las oposiciones</a></p></body></html>');
  }

  const convocatorias = await supaGet(
    `convocatorias?select=estado,plazas,fecha_publicacion_boe,fecha_fin_instancias,url_boe,notas&oposicion_id=eq.${op.id}&order=fecha_publicacion_boe.desc&limit=1`,
  );
  const conv = convocatorias?.[0];

  const nombre = escapeHtml(op.nombre);
  const admin = escapeHtml(op.administracion || 'Administración pública');
  const nivel = op.nivel && op.nivel !== 'N/D' ? escapeHtml(op.nivel) : null;
  const urlCanonica = `https://www.oposiwork.com/oposiciones/${escapeHtml(op.slug)}/`;
  const finInstancias = fechaLarga(conv?.fecha_fin_instancias);
  const publicadaEl = fechaLarga(conv?.fecha_publicacion_boe);
  const abierta = conv?.estado === 'abierta';
  const plazoEstimado = /ESTIMADA/i.test(conv?.notas ?? '');

  const tituloSeo = `${op.nombre} | Convocatoria, plazas y preparación - Oposiwork`.slice(0, 200);
  const descripcion = [
    `Convocatoria de ${op.nombre} (${op.administracion || 'España'})`,
    conv?.plazas ? `${conv.plazas} plazas` : null,
    abierta && finInstancias ? `plazo de instancias hasta el ${finInstancias}` : null,
    'Consulta los datos gratis y prepárala con tests y temario en Oposiwork.',
  ].filter(Boolean).join('. ').slice(0, 300);

  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Inicio', item: 'https://www.oposiwork.com/' },
          { '@type': 'ListItem', position: 2, name: 'Oposiciones', item: 'https://www.oposiwork.com/oposiciones/' },
          { '@type': 'ListItem', position: 3, name: op.nombre, item: urlCanonica },
        ],
      },
      {
        '@type': 'Article',
        headline: `Convocatoria: ${op.nombre}`,
        datePublished: conv?.fecha_publicacion_boe ?? undefined,
        author: { '@type': 'Organization', name: 'Oposiwork', url: 'https://www.oposiwork.com/' },
        publisher: { '@type': 'Organization', name: 'Oposiwork' },
        mainEntityOfPage: urlCanonica,
      },
    ],
  };

  const filasDatos = [
    ['Administración', admin],
    nivel ? ['Grupo / nivel', nivel] : null,
    conv?.plazas ? ['Plazas', escapeHtml(String(conv.plazas))] : null,
    publicadaEl ? ['Publicada en boletín', escapeHtml(publicadaEl)] : null,
    finInstancias
      ? [
          plazoEstimado ? 'Fin de instancias (estimado)' : 'Fin de instancias',
          escapeHtml(finInstancias),
        ]
      : null,
    conv ? ['Estado', abierta ? 'Plazo abierto' : 'Plazo cerrado'] : null,
  ].filter(Boolean);

  const html = `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(tituloSeo)}</title>
  <meta name="description" content="${escapeHtml(descripcion)}">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="${urlCanonica}">
  <link rel="icon" href="/favicon.png">
  <link rel="stylesheet" href="/styles.css">
  <meta property="og:type" content="article">
  <meta property="og:locale" content="es_ES">
  <meta property="og:site_name" content="Oposiwork">
  <meta property="og:title" content="${escapeHtml(tituloSeo)}">
  <meta property="og:description" content="${escapeHtml(descripcion)}">
  <meta property="og:url" content="${urlCanonica}">
  <meta property="og:image" content="https://www.oposiwork.com/icons/Icon-512.png">
  <script type="application/ld+json">${JSON.stringify(jsonLd)}</script>
</head>
<body>
  <header class="site-header">
    <a class="brand" href="/" aria-label="Oposiwork"><img src="/icons/Icon-192.png" width="34" height="34" alt="">Oposiwork</a>
    <nav class="nav-links" aria-label="Principal">
      <a href="/oposiciones/">Oposiciones</a>
      <a href="/#precios">Precios</a>
      <a href="/app/login" class="button primary">Empezar gratis</a>
    </nav>
  </header>
  <main id="contenido">
    <section class="section">
      <nav class="breadcrumb" aria-label="Migas de pan"><a href="/">Inicio</a> › <a href="/oposiciones/">Oposiciones</a> › <span>${nombre}</span></nav>
      <div class="section-header">
        <h1>${nombre}</h1>
        <p>Convocatoria de ${admin}. Consulta gratis el estado, las plazas y el plazo de instancias, y prepara la oposición con tests, flashcards y seguimiento de progreso en Oposiwork.</p>
      </div>
      <div class="hero-actions">
        <a class="button primary" href="/app/login?utm_source=seo&utm_medium=oposicion_auto&utm_campaign=${escapeHtml(op.slug)}">Empezar gratis</a>
        <a class="button secondary" href="/app/oposiciones?utm_source=seo&utm_medium=oposicion_auto&utm_campaign=${escapeHtml(op.slug)}">Ver en la app</a>
      </div>
    </section>
    <section class="section alt">
      <div class="section-header"><h2>Datos de la convocatoria</h2></div>
      <article class="legal-card">
        <ul>
          ${filasDatos.map(([k, v]) => `<li><strong>${k}:</strong> ${v}</li>`).join('\n          ')}
          ${conv?.url_boe ? `<li><strong>Fuente oficial:</strong> <a href="${escapeHtml(conv.url_boe)}" rel="nofollow noopener" target="_blank">Ver boletín oficial</a></li>` : ''}
        </ul>
        ${plazoEstimado ? '<p><em>La fecha de fin de instancias es estimada. Confirma siempre el plazo en el boletín oficial.</em></p>' : ''}
      </article>
    </section>
    <section class="section">
      <div class="section-header"><h2>Cómo te ayuda Oposiwork</h2></div>
      <ul class="feature-list">
        <li><strong>Convocatoria gratis:</strong> estado, plazas, plazo y enlace al boletín oficial.</li>
        <li><strong>Alertas:</strong> aviso si cambia el plazo, la fecha de examen o las plazas.</li>
        <li><strong>Tests y flashcards</strong> para preparar el temario cuando esté disponible.</li>
        <li><strong>Seguimiento de progreso</strong> con rachas y estadísticas de estudio.</li>
      </ul>
    </section>
    <section class="section final-cta">
      <h2>Sigue esta convocatoria gratis</h2>
      <p>Crea tu cuenta, marca la oposición y recibe avisos automáticos de cualquier cambio.</p>
      <a class="button" href="/app/login?utm_source=seo&utm_medium=oposicion_auto&utm_campaign=${escapeHtml(op.slug)}_cta">Entrar en Oposiwork</a>
    </section>
  </main>
  <footer class="site-footer">
    <div class="footer-inner">
      <span>© 2026 Oposiwork. Plataforma de preparación de oposiciones en España.</span>
      <nav class="footer-links" aria-label="Legal">
        <a href="/oposiciones/">Oposiciones</a>
        <a href="/privacidad/">Privacidad</a>
        <a href="/terminos/">Términos</a>
        <a href="/contacto/">Contacto</a>
      </nav>
    </div>
  </footer>
</body>
</html>`;

  // Cache edge: 1h fresco + 24h stale-while-revalidate. El contenido cambia como
  // mucho una vez al día (cron del monitor), así que es más que suficiente.
  res.setHeader('Cache-Control', 's-maxage=3600, stale-while-revalidate=86400');
  return res.status(200).send(html);
};
