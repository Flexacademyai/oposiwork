// Sitemap dinámico: combina las páginas estáticas de la landing con las
// oposiciones activas de Supabase. Así, cada convocatoria que el monitor-boe
// publica aparece automáticamente en el sitemap sin intervención manual.
const SUPABASE_URL =
  process.env.SUPABASE_URL || 'https://gklwylkqykjjxwutfehw.supabase.co';
// La anon key es pública por diseño (la seguridad la provee RLS).
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrbHd5bGtxeWtqanh3dXRmZWh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MzE4NTcsImV4cCI6MjA5MzUwNzg1N30.Zyiv61ZsgUP7e3xsKxz0O_U2ziHH_4T6NATPp_NiqZE';

const BASE = 'https://www.oposiwork.com';

// Páginas estáticas de la landing (se sirven como archivos; el sitemap las lista).
const STATIC_URLS = [
  { loc: '/', changefreq: 'daily', priority: '1.0' },
  { loc: '/oposiciones/', changefreq: 'daily', priority: '0.9' },
  { loc: '/oposiciones/auxiliar-administrativo-estado/', changefreq: 'weekly', priority: '0.9' },
  { loc: '/oposiciones/policia-nacional/', changefreq: 'weekly', priority: '0.9' },
  { loc: '/oposiciones/bomberos/', changefreq: 'weekly', priority: '0.9' },
  { loc: '/oposiciones/auxiliar-administrativo-universidad-cadiz/', changefreq: 'weekly', priority: '0.9' },
  { loc: '/blog/', changefreq: 'weekly', priority: '0.7' },
  { loc: '/blog/oposiciones-en-mi-provincia/', changefreq: 'monthly', priority: '0.65' },
  { loc: '/blog/oposiciones-con-la-eso-2026/', changefreq: 'monthly', priority: '0.65' },
  { loc: '/blog/oposiciones-ayuntamientos-menos-competencia/', changefreq: 'monthly', priority: '0.65' },
  { loc: '/blog/como-practicar-psicotecnicos/', changefreq: 'monthly', priority: '0.65' },
  { loc: '/blog/preparar-auxiliar-administrativo/', changefreq: 'monthly', priority: '0.6' },
  { loc: '/blog/leer-convocatoria-oposicion/', changefreq: 'monthly', priority: '0.6' },
  { loc: '/blog/oposiwork-free-premium/', changefreq: 'monthly', priority: '0.6' },
  { loc: '/blog/plan-estudio-oposiciones/', changefreq: 'monthly', priority: '0.6' },
  { loc: '/privacidad/', changefreq: 'monthly', priority: '0.4' },
  { loc: '/terminos/', changefreq: 'monthly', priority: '0.4' },
  { loc: '/cookies/', changefreq: 'monthly', priority: '0.3' },
  { loc: '/contacto/', changefreq: 'monthly', priority: '0.3' },
  { loc: '/aviso-legal/', changefreq: 'monthly', priority: '0.3' },
  { loc: '/seguridad/', changefreq: 'monthly', priority: '0.3' },
  { loc: '/suscripcion/', changefreq: 'monthly', priority: '0.3' },
  { loc: '/reembolso/', changefreq: 'monthly', priority: '0.3' },
];

function xmlEscape(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

module.exports = async function handler(req, res) {
  res.setHeader('Content-Type', 'application/xml; charset=utf-8');
  // Cache en el edge de Vercel: 1h fresco, hasta 24h sirviendo obsoleto mientras
  // se regenera. Supabase no recibe más de ~1 petición/hora por esta vía.
  res.setHeader('Cache-Control', 's-maxage=3600, stale-while-revalidate=86400');

  const vistos = new Set(STATIC_URLS.map((u) => u.loc));
  const urls = [...STATIC_URLS];

  try {
    const resp = await fetch(
      `${SUPABASE_URL}/rest/v1/oposiciones?select=slug,created_at&activa=eq.true&order=created_at.desc&limit=2000`,
      {
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
      },
    );
    if (resp.ok) {
      const oposiciones = await resp.json();
      for (const op of oposiciones) {
        if (!op.slug) continue;
        const loc = `/oposiciones/${op.slug}/`;
        if (vistos.has(loc)) continue;
        vistos.add(loc);
        urls.push({
          loc,
          changefreq: 'weekly',
          priority: '0.8',
          lastmod: op.created_at ? String(op.created_at).slice(0, 10) : undefined,
        });
      }
    }
  } catch (_) {
    // Si Supabase no responde, servimos al menos las URLs estáticas:
    // un sitemap parcial es mejor que un error 500 de cara a Google.
  }

  const body = urls
    .map((u) => {
      const lastmod = u.lastmod ? `<lastmod>${u.lastmod}</lastmod>` : '';
      return `  <url><loc>${BASE}${xmlEscape(u.loc)}</loc>${lastmod}<changefreq>${u.changefreq}</changefreq><priority>${u.priority}</priority></url>`;
    })
    .join('\n');

  res.status(200).send(
    `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${body}\n</urlset>\n`,
  );
};
