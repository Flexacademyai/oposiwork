import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// RevenueCat envía estos tipos de eventos en su webhook
type RCEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'PRODUCT_CHANGE'
  | 'CANCELLATION'
  | 'BILLING_ISSUE'
  | 'SUBSCRIBER_ALIAS'
  | 'EXPIRATION'
  | 'TRANSFER'
  | 'NON_SUBSCRIPTION_PURCHASE'
  | 'TEST'

interface RCWebhookPayload {
  event: {
    type: RCEventType
    app_user_id: string           // Supabase UUID del usuario
    original_app_user_id?: string // Por si viene como alias
    product_id: string
    expiration_at_ms?: number     // Unix ms — cuándo expira el plan
    purchased_at_ms?: number
    price?: number
    currency?: string
    store?: string
    environment?: 'SANDBOX' | 'PRODUCTION'
  }
}

// Map product_id → nombre de plan interno
function planDesdePrducto(productId: string): 'monthly' | 'annual' | null {
  if (productId.includes('monthly') || productId.includes('mensual')) return 'monthly'
  if (productId.includes('annual') || productId.includes('anual') || productId.includes('yearly')) return 'annual'
  return null
}

// Valida la firma HMAC-SHA256 del webhook de RevenueCat
async function verificarFirmaRC(req: Request, secreto: string): Promise<boolean> {
  const firma = req.headers.get('X-RevenueCat-Signature')
  if (!firma) return false

  // RevenueCat firma el body raw con HMAC-SHA256 hex
  const body = await req.text()
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secreto),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const mac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body))
  const hex = Array.from(new Uint8Array(mac)).map(b => b.toString(16).padStart(2, '0')).join('')

  // Comparación de tiempo constante
  if (hex.length !== firma.length) return false
  let diff = 0
  for (let i = 0; i < hex.length; i++) diff |= hex.charCodeAt(i) ^ firma.charCodeAt(i)
  return diff === 0
}

Deno.serve(async (req) => {
  // RevenueCat envía POST — rechazar cualquier otro método
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? ''
  if (!webhookSecret) {
    console.error('REVENUECAT_WEBHOOK_SECRET no configurado')
    return new Response('Internal Server Error', { status: 500 })
  }

  // Clonar para poder leer el body dos veces (verificarFirmaRC consume el stream)
  const reqClone = req.clone()
  const firmaValida = await verificarFirmaRC(req, webhookSecret)
  if (!firmaValida) {
    console.warn('Firma RevenueCat inválida — posible petición no autorizada')
    return new Response(JSON.stringify({ error: 'Firma inválida' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  let payload: RCWebhookPayload
  try {
    payload = await reqClone.json()
  } catch {
    return new Response(JSON.stringify({ error: 'JSON inválido' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const evento = payload?.event
  if (!evento?.type || !evento?.app_user_id) {
    return new Response(JSON.stringify({ error: 'Payload incompleto' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Ignorar eventos de sandbox y tests en producción
  if (evento.environment === 'SANDBOX' && Deno.env.get('ENVIRONMENT') === 'production') {
    console.log(`Ignorando evento sandbox: ${evento.type}`)
    return new Response(JSON.stringify({ ok: true, ignorado: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  const usuarioId = evento.app_user_id
  const tipo = evento.type

  try {
    if (tipo === 'INITIAL_PURCHASE' || tipo === 'RENEWAL' || tipo === 'PRODUCT_CHANGE') {
      const plan = planDesdePrducto(evento.product_id)
      if (!plan) {
        console.warn(`product_id desconocido: ${evento.product_id}`)
        return new Response(JSON.stringify({ ok: true, advertencia: 'product_id no reconocido' }), {
          headers: { 'Content-Type': 'application/json' },
        })
      }

      const planFin = evento.expiration_at_ms
        ? new Date(evento.expiration_at_ms).toISOString()
        : null

      const { error } = await supabase
        .from('perfiles')
        .update({
          plan,
          plan_inicio: evento.purchased_at_ms
            ? new Date(evento.purchased_at_ms).toISOString()
            : new Date().toISOString(),
          plan_fin: planFin,
          revenuecat_id: usuarioId,
          updated_at: new Date().toISOString(),
        })
        .eq('id', usuarioId)

      if (error) throw new Error(`update plan: ${error.message}`)
      console.log(`Plan actualizado a '${plan}' para usuario ${usuarioId}`)

    } else if (tipo === 'CANCELLATION' || tipo === 'EXPIRATION' || tipo === 'BILLING_ISSUE') {
      // Plan expira en la fecha de expiración; no lo cortamos antes de que expire
      // Solo marcamos plan_fin si no está ya establecido o si es expiración inmediata
      const planFin = evento.expiration_at_ms
        ? new Date(evento.expiration_at_ms).toISOString()
        : new Date().toISOString()

      const { error } = await supabase
        .from('perfiles')
        .update({
          plan_fin: planFin,
          updated_at: new Date().toISOString(),
        })
        .eq('id', usuarioId)

      if (error) throw new Error(`update cancelacion: ${error.message}`)
      console.log(`Cancelación/expiración registrada para usuario ${usuarioId}, plan_fin: ${planFin}`)

    } else if (tipo === 'TEST') {
      console.log('Evento TEST recibido — OK')
    } else {
      console.log(`Evento no manejado: ${tipo}`)
    }

    return new Response(JSON.stringify({ ok: true, tipo }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Error procesando webhook RevenueCat:', error)
    // RevenueCat reintenta en 5xx — devolver 500 para que reintente
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
