import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders, handleOptions } from '../_shared/cors.ts'
import { checkUserRateLimit, rateLimitExceededResponse } from '../_shared/rate_limit.ts'

type Plan = 'monthly' | 'annual'

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

    const body = await req.json().catch(() => ({}))
    const plan = body.plan as Plan
    if (plan !== 'monthly' && plan !== 'annual') {
      return json(req, { error: 'Plan no válido' }, 400)
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
      'create-stripe-checkout',
      3,
      10,
    )
    if (!permitido) {
      return rateLimitExceededResponse(buildCorsHeaders(req), 'minuto')
    }

    const priceId = plan === 'annual'
      ? env('STRIPE_PRICE_ANNUAL')
      : env('STRIPE_PRICE_MONTHLY')
    const appBaseUrl = Deno.env.get('APP_BASE_URL') ?? 'https://www.oposiwork.com'

    const params = new URLSearchParams()
    params.set('mode', 'subscription')
    params.set('line_items[0][price]', priceId)
    params.set('line_items[0][quantity]', '1')
    params.set('client_reference_id', userData.user.id)
    params.set('customer_email', userData.user.email ?? '')
    params.set('success_url', `${appBaseUrl}/app/#/perfil?checkout=success`)
    params.set('cancel_url', `${appBaseUrl}/app/#/suscripcion?checkout=cancelled`)
    params.set('metadata[user_id]', userData.user.id)
    params.set('metadata[plan]', plan)
    params.set('subscription_data[metadata][user_id]', userData.user.id)
    params.set('subscription_data[metadata][plan]', plan)
    params.set('allow_promotion_codes', 'true')

    const stripeResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env('STRIPE_SECRET_KEY')}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    })

    const stripeData = await stripeResponse.json()
    if (!stripeResponse.ok) {
      console.error('Stripe Checkout error', stripeData)
      const stripeMessage =
        typeof stripeData?.error?.message === 'string'
          ? stripeData.error.message
          : 'No se pudo crear la sesion de pago'
      return json(req, { error: `Stripe: ${stripeMessage}` }, 502)
      return json(req, { error: 'No se pudo crear la sesión de pago' }, 502)
    }

    return json(req, { url: stripeData.url })
  } catch (error) {
    console.error('create-stripe-checkout error', error)
    return json(req, { error: error.message ?? 'Error interno' }, 500)
  }
})
