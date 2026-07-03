import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type StripeObject = Record<string, unknown>

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function env(name: string): string {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`${name} no configurado`)
  return value
}

function constantTimeEquals(a: string, b: string): boolean {
  if (a.length !== b.length) return false
  let diff = 0
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i)
  }
  return diff === 0
}

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const mac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload))
  return Array.from(new Uint8Array(mac)).map((b) => b.toString(16).padStart(2, '0')).join('')
}

async function verifyStripeSignature(rawBody: string, header: string, secret: string): Promise<boolean> {
  const timestamp = header.split(',').find((part) => part.startsWith('t='))?.slice(2)
  const signatures = header
    .split(',')
    .filter((part) => part.startsWith('v1='))
    .map((part) => part.slice(3))

  if (!timestamp || signatures.length === 0) return false

  // Protección anti-replay: rechazar firmas fuera de la ventana de tolerancia
  // (5 min, igual que el SDK oficial de Stripe). Sin esto, una petición firmada
  // capturada podría reenviarse indefinidamente.
  const TOLERANCIA_SEGUNDOS = 300
  const ts = Number(timestamp)
  const ahora = Math.floor(Date.now() / 1000)
  if (!Number.isFinite(ts) || Math.abs(ahora - ts) > TOLERANCIA_SEGUNDOS) return false

  const expected = await hmacSha256Hex(secret, `${timestamp}.${rawBody}`)
  return signatures.some((signature) => constantTimeEquals(expected, signature))
}

async function getStripeSubscription(subscriptionId: string): Promise<StripeObject | null> {
  const response = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
    headers: { Authorization: `Bearer ${env('STRIPE_SECRET_KEY')}` },
  })
  if (!response.ok) return null
  return await response.json()
}

function periodEndToIso(value: unknown): string | null {
  if (typeof value !== 'number') return null
  return new Date(value * 1000).toISOString()
}

async function upsertPlanFromCheckout(supabase: ReturnType<typeof createClient>, session: StripeObject) {
  const userId = session.client_reference_id as string | undefined
  const metadata = session.metadata as Record<string, string> | undefined
  const plan = metadata?.plan === 'annual' ? 'annual' : 'monthly'
  const subscriptionId = session.subscription as string | undefined
  const customerId = session.customer as string | undefined

  if (!userId || !subscriptionId || !customerId) {
    throw new Error('checkout.session.completed sin user/customer/subscription')
  }

  const subscription = await getStripeSubscription(subscriptionId)
  const planFin = periodEndToIso(subscription?.current_period_end)

  const { error } = await supabase
    .from('perfiles')
    .update({
      plan,
      plan_inicio: new Date().toISOString(),
      plan_fin: planFin,
      stripe_customer_id: customerId,
      stripe_subscription_id: subscriptionId,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId)

  if (error) throw new Error(`update perfil checkout: ${error.message}`)
}

async function updatePlanFromSubscription(
  supabase: ReturnType<typeof createClient>,
  subscription: StripeObject,
  deleted: boolean,
) {
  const metadata = subscription.metadata as Record<string, string> | undefined
  const plan = metadata?.plan === 'annual' ? 'annual' : 'monthly'
  const subscriptionId = subscription.id as string | undefined
  const customerId = subscription.customer as string | undefined
  const planFin = deleted ? new Date().toISOString() : periodEndToIso(subscription.current_period_end)
  const status = subscription.status as string | undefined
  const activo = status === 'active' || status === 'trialing'

  if (!subscriptionId && !customerId) {
    throw new Error('subscription event sin subscription/customer')
  }

  const payload = {
    plan: deleted || !activo ? 'free' : plan,
    plan_fin: planFin,
    stripe_customer_id: customerId,
    stripe_subscription_id: subscriptionId,
    updated_at: new Date().toISOString(),
  }

  let query = supabase.from('perfiles').update(payload)
  if (subscriptionId) {
    query = query.eq('stripe_subscription_id', subscriptionId)
  } else {
    query = query.eq('stripe_customer_id', customerId)
  }

  const { error } = await query
  if (error) throw new Error(`update perfil subscription: ${error.message}`)
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method Not Allowed' }, 405)

  const rawBody = await req.text()
  const signature = req.headers.get('stripe-signature') ?? ''
  const valid = await verifyStripeSignature(rawBody, signature, env('STRIPE_WEBHOOK_SECRET'))
  if (!valid) return json({ error: 'Firma inválida' }, 401)

  const event = JSON.parse(rawBody)
  const supabase = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'))

  try {
    const type = event.type as string
    const object = event.data?.object as StripeObject

    if (type === 'checkout.session.completed') {
      await upsertPlanFromCheckout(supabase, object)
    } else if (type === 'customer.subscription.updated') {
      await updatePlanFromSubscription(supabase, object, false)
    } else if (type === 'customer.subscription.deleted') {
      await updatePlanFromSubscription(supabase, object, true)
    }

    return json({ ok: true, type })
  } catch (error) {
    console.error('webhook-stripe error', error)
    return json({ error: 'Error interno' }, 500)
  }
})
