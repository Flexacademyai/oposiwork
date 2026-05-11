import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * Verifica el rate limit por usuario autenticado.
 * Devuelve true si la petición está permitida, false si se supera el límite.
 *
 * Internamente llama a check_user_rate_limit() en Postgres, que usa ON CONFLICT
 * DO UPDATE para garantizar incrementos atómicos sin race conditions.
 */
export async function checkUserRateLimit(
  supabase: SupabaseClient,
  usuarioId: string,
  endpoint: string,
  limitePorMinuto: number,
  limitePorHora: number,
): Promise<boolean> {
  const { data, error } = await supabase.rpc('check_user_rate_limit', {
    p_usuario_id:    usuarioId,
    p_endpoint:      endpoint,
    p_limite_minuto: limitePorMinuto,
    p_limite_hora:   limitePorHora,
  })

  if (error) {
    // Fail-open: si falla la función de rate limit no bloqueamos al usuario.
    // El error queda en los logs de Supabase para revisión.
    console.error(`[rate_limit] error en ${endpoint}:`, error.message)
    return true
  }

  return data === true
}

/** Respuesta estándar 429 con cabecera Retry-After. */
export function rateLimitExceededResponse(
  corsHeaders: Record<string, string>,
  scope: 'minuto' | 'hora' = 'minuto',
): Response {
  const retryAfter = scope === 'minuto' ? 60 : 3600
  return new Response(
    JSON.stringify({
      error: scope === 'minuto'
        ? 'Demasiadas peticiones. Espera un momento antes de intentarlo de nuevo.'
        : 'Has alcanzado el límite por hora. Inténtalo más tarde.',
    }),
    {
      status: 429,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'Retry-After': String(retryAfter),
      },
    },
  )
}
