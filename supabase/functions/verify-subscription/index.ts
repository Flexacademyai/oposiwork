import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders, handleOptions } from '../_shared/cors.ts'
import { checkUserRateLimit, rateLimitExceededResponse } from '../_shared/rate_limit.ts'
import { esIdExterno } from '../_shared/validate.ts'

async function hashIp(ip: string): Promise<string> {
  const salt = Deno.env.get('IP_HASH_SALT') ?? 'oposiwork-default-salt';
  const data = new TextEncoder().encode(ip + salt);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;
  const corsHeaders = buildCorsHeaders(req);

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Rate limiting por IP (pre-auth): protege el endpoint de peticiones anónimas
    const rawIp = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
      ?? req.headers.get('x-real-ip')
      ?? 'unknown'
    const ipHash = await hashIp(rawIp)
    const { data: permitidoIp } = await supabase.rpc('check_rate_limit', {
      p_ip_hash: ipHash,
      p_endpoint: 'verify-subscription',
      p_limite: 30,
      p_ventana_segundos: 3600,
    })
    if (!permitidoIp) {
      return new Response(
        JSON.stringify({ premium: false, error: 'Demasiadas solicitudes' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ premium: false }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: { user } } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (!user) {
      return new Response(JSON.stringify({ premium: false }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Rate limiting por usuario autenticado: 5/minuto, 30/hora
    const permitidoUsuario = await checkUserRateLimit(supabase, user.id, 'verify-subscription', 5, 30)
    if (!permitidoUsuario) {
      return new Response(
        JSON.stringify({ premium: false, error: 'Demasiadas peticiones. Espera un momento.' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Retry-After': '60' } }
      )
    }

    const body = await req.json().catch(() => ({}))
    const revenuecatUserId: string | undefined = body?.revenuecatUserId

    // Verificar con RevenueCat si se proporcionó el ID de usuario (y tiene formato válido)
    const rcApiKey = Deno.env.get('REVENUECAT_API_KEY_SECRET')
    if (revenuecatUserId && esIdExterno(revenuecatUserId) && rcApiKey) {
      const rcResponse = await fetch(
        `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(revenuecatUserId)}`,
        {
          headers: {
            Authorization: `Bearer ${rcApiKey}`,
            'Content-Type': 'application/json',
          },
        }
      )

      if (rcResponse.ok) {
        const rcData = await rcResponse.json()
        const entitlements = rcData.subscriber?.entitlements ?? {}
        const premium = entitlements['premium']
        const esPremium = premium && new Date(premium.expires_date) > new Date()

        if (esPremium) {
          // Derivar el plan real (mensual/anual) del producto, no asumir mensual.
          const productId = String(premium.product_identifier ?? '').toLowerCase()
          const plan = /annual|anual|yearly/.test(productId) ? 'annual' : 'monthly'
          await supabase.from('perfiles').update({
            plan,
            plan_fin: premium.expires_date,
            revenuecat_id: revenuecatUserId,
          }).eq('id', user.id)
        }

        return new Response(JSON.stringify({ premium: !!esPremium }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // Fallback: verificar directamente en la base de datos
    const { data: perfil } = await supabase
      .from('perfiles')
      .select('plan, plan_fin')
      .eq('id', user.id)
      .single()

    const esPremium = perfil?.plan !== 'free'
      && perfil?.plan_fin
      && new Date(perfil.plan_fin) > new Date()

    return new Response(JSON.stringify({ premium: !!esPremium }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('verify-subscription error', error)
    return new Response(
      JSON.stringify({ premium: false, error: 'Error interno' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
