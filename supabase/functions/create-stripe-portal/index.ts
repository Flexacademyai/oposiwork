import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders, handleOptions } from '../_shared/cors.ts'
import { checkUserRateLimit, rateLimitExceededResponse } from '../_shared/rate_limit.ts'

function json(req: Request, body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...buildCorsHeaders(req),
      'Content-Type': 'application/json',
    },
  })
}

function env(name: string): string {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`${name} no configurado`)
  return value
}

Deno.serve(async (req) => {
  const options = handleOptions(req)
  if (options) return options

  if (req.method !== 'POST') {
    return json(req, { error: 'Method Not Allowed' }, 405)
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return json(req, { error: 'Usuario no autenticado' }, 401)
    }

    const supabase = createClient(
      env('SUPABASE_URL'),
      env('SUPABASE_SERVICE_ROLE_KEY'),
      { global: { headers: { Authorization: authHeader } } },
    )

    const token = authHeader.replace('Bearer ', '')
    const { data: userData, error: userError } = await supabase.auth.getUser(token)
    if (userError || !userData.user) {
      return json(req, { error: 'Usuario no autenticado' }, 401)
    }

    const permitido = await checkUserRateLimit(
      supabase,
      userData.user.id,
      'create-stripe-portal',
      3,
      10,
    )
    if (!permitido) {
      return rateLimitExceededResponse(buildCorsHeaders(req), 'minuto')
    }

    const { data: perfil, error: perfilError } = await supabase
      .from('perfiles')
      .select('stripe_customer_id')
      .eq('id', userData.user.id)
      .maybeSingle()

    if (perfilError) throw new Error(perfilError.message)

    const customerId = perfil?.stripe_customer_id as string | undefined
    if (!customerId) {
      return json(req, { error: 'No hay cliente Stripe asociado' }, 409)
    }

    const appBaseUrl = Deno.env.get('APP_BASE_URL') ?? 'https://www.oposiwork.com'
    const params = new URLSearchParams()
    params.set('customer', customerId)
    params.set('return_url', `${appBaseUrl}/app/#/perfil`)

    const stripeResponse = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env('STRIPE_SECRET_KEY')}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    })

    const stripeData = await stripeResponse.json()
    if (!stripeResponse.ok) {
      console.error('Stripe Portal error', stripeData)
      return json(req, { error: 'No se pudo abrir el portal de cliente' }, 502)
    }

    return json(req, { url: stripeData.url })
  } catch (error) {
    console.error('create-stripe-portal error', error)
    return json(req, { error: 'Error interno' }, 500)
  }
})
