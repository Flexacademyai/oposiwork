// Orígenes permitidos para peticiones de browser.
// Las apps móviles (iOS/Android) no usan CORS — solo aplica a web.
const ALLOWED_ORIGINS: ReadonlySet<string> = new Set([
  'https://app.oposiwork.com',
  // Desarrollo local — Flutter web y herramientas típicas
  'http://localhost:5000',
  'http://localhost:5001',
  'http://localhost:8080',
  'http://localhost:3000',
  'http://localhost:4200',
]);

/**
 * Devuelve las cabeceras CORS correctas para el origen de la petición.
 * Si el origen no está en la lista, responde con el dominio de producción
 * para que el browser rechace la petición por política de mismo origen.
 */
export function buildCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('Origin') ?? '';
  const allowed = ALLOWED_ORIGINS.has(origin) ? origin : 'https://app.oposiwork.com';
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Vary': 'Origin',
  };
}

/** Respuesta estándar al preflight OPTIONS. */
export function handleOptions(req: Request): Response | null {
  if (req.method !== 'OPTIONS') return null;
  return new Response('ok', { headers: buildCorsHeaders(req) });
}
