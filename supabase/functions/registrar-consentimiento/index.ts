import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders, handleOptions } from '../_shared/cors.ts'
import { checkUserRateLimit, rateLimitExceededResponse } from '../_shared/rate_limit.ts'

const TIPOS_VALIDOS = new Set(['ia', 'voz', 'analytics'])

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;
  const corsHeaders = buildCorsHeaders(req);

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Verificar JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No autorizado' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Token inválido' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Rate limiting: 10 cambios/minuto, 30/hora — protege contra spam de consentimientos
    const permitido = await checkUserRateLimit(supabase, user.id, 'registrar-consentimiento', 10, 30)
    if (!permitido) {
      return rateLimitExceededResponse(corsHeaders, 'minuto')
    }

    const body = await req.json().catch(() => ({}))
    const tipo: unknown = body?.tipo
    const aceptado: unknown = body?.aceptado

    if (typeof tipo !== 'string' || !TIPOS_VALIDOS.has(tipo)) {
      return new Response(
        JSON.stringify({ error: `tipo debe ser uno de: ${[...TIPOS_VALIDOS].join(', ')}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (typeof aceptado !== 'boolean') {
      return new Response(
        JSON.stringify({ error: 'aceptado debe ser true o false' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Hash de IP para auditoría (sin almacenar IP real)
    const rawIp = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
      ?? req.headers.get('x-real-ip')
      ?? 'unknown'
    const salt = Deno.env.get('IP_HASH_SALT') ?? 'oposiwork-default-salt'
    const data = new TextEncoder().encode(rawIp + salt)
    const hash = await crypto.subtle.digest('SHA-256', data)
    const ipHash = Array.from(new Uint8Array(hash))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    const { error: upsertError } = await supabase
      .from('consentimientos')
      .upsert({
        usuario_id:  user.id,
        tipo,
        aceptado,
        aceptado_en: aceptado ? new Date().toISOString() : null,
        ip_hash:     ipHash,
        updated_at:  new Date().toISOString(),
      }, { onConflict: 'usuario_id,tipo' })

    if (upsertError) {
      throw new Error(upsertError.message)
    }

    return new Response(
      JSON.stringify({ ok: true, tipo, aceptado }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
