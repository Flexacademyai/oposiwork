/**
 * Validación y saneamiento de entradas para edge functions.
 *
 * Nota: el SDK de Supabase usa queries parametrizadas — no existe inyección
 * SQL directa. Este módulo añade defensa en profundidad: rechaza datos
 * malformados antes de que lleguen a la base de datos o a APIs externas.
 */

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const SAFE_EXTERNAL_ID_REGEX = /^[a-zA-Z0-9_\-]{1,256}$/
// Caracteres de control ASCII (excepto \t \n \r que son legítimos en texto)
const CONTROL_CHARS = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g
const HTML_TAGS = /<[^>]*>/g

// ── Validadores de formato ─────────────────────────────────────────────────

export function esUuid(valor: unknown): valor is string {
  return typeof valor === 'string' && UUID_REGEX.test(valor)
}

/** IDs externos (RevenueCat, Firebase, etc.): alfanumérico + guiones */
export function esIdExterno(valor: unknown): valor is string {
  return typeof valor === 'string' && SAFE_EXTERNAL_ID_REGEX.test(valor)
}

// ── Saneamiento de texto libre ─────────────────────────────────────────────

/**
 * Elimina caracteres de control y tags HTML. No trunca — el llamador elige el límite.
 * No eliminamos comillas ni caracteres SQL porque el SDK los parametriza.
 */
export function sanitizarTexto(texto: string): string {
  return texto
    .replace(CONTROL_CHARS, '')
    .replace(HTML_TAGS, '')
    .trim()
}

// ── Validadores compuestos ─────────────────────────────────────────────────

type ValidacionOk = { ok: true; valor: string }
type ValidacionError = { ok: false; mensaje: string }
type ResultadoValidacion = ValidacionOk | ValidacionError

export function validarTexto(
  valor: unknown,
  campo: string,
  { min = 1, max = 2000 }: { min?: number; max?: number } = {},
): ResultadoValidacion {
  if (typeof valor !== 'string') {
    return { ok: false, mensaje: `${campo}: se esperaba texto` }
  }
  const limpio = sanitizarTexto(valor)
  if (limpio.length < min) {
    return { ok: false, mensaje: `${campo}: demasiado corto (mínimo ${min} caracteres)` }
  }
  if (limpio.length > max) {
    return { ok: false, mensaje: `${campo}: demasiado largo (máximo ${max} caracteres)` }
  }
  return { ok: true, valor: limpio }
}

export function validarUuid(valor: unknown, campo: string): ResultadoValidacion {
  if (!esUuid(valor)) {
    return { ok: false, mensaje: `${campo}: formato UUID no válido` }
  }
  return { ok: true, valor: valor as string }
}

export function validarIdExterno(valor: unknown, campo: string): ResultadoValidacion {
  if (!esIdExterno(valor)) {
    return { ok: false, mensaje: `${campo}: formato de identificador no válido` }
  }
  return { ok: true, valor: valor as string }
}

// ── Respuesta de error estándar ────────────────────────────────────────────

export function respuestaError400(
  corsHeaders: Record<string, string>,
  mensaje: string,
): Response {
  return new Response(
    JSON.stringify({ error: mensaje }),
    { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  )
}
