import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type PendingRecipient = {
  id: string
  usuario_id: string
  canal: 'push' | 'email' | 'in_app'
  notificacion_id: string
  notificaciones_convocatoria?: {
    titulo: string
    mensaje: string
    tipo: string
    convocatoria_id: string
    convocatorias?: {
      oposicion_id?: string
    }
  }
  perfiles?: {
    email?: string
    notificaciones_push?: boolean
    notificaciones_email?: boolean
  }
}

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function env(name: string): string {
  return Deno.env.get(name) ?? ''
}

/** Escapa HTML para evitar inyección en el cuerpo del email (parte del texto
 *  proviene de fuentes oficiales raspadas en monitor-boe). */
function escapeHtml(texto: string): string {
  return texto
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

// ── FCM HTTP v1 ─────────────────────────────────────────────────────────────
// La API legacy (https://fcm.googleapis.com/fcm/send con `Authorization: key=`)
// fue apagada por Google en junio de 2024. Usamos la API v1 con un token OAuth2
// firmado desde la service account de Firebase.
// Variables necesarias: FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY.

let fcmTokenCache: { token: string; exp: number } | null = null

function base64UrlEncode(data: string | Uint8Array): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : data
  let bin = ''
  for (const b of bytes) bin += String.fromCharCode(b)
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '')
  const bin = atob(b64)
  const buf = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i)
  return buf.buffer
}

async function getFcmAccessToken(): Promise<string> {
  const ahora = Math.floor(Date.now() / 1000)
  if (fcmTokenCache && fcmTokenCache.exp > ahora + 60) return fcmTokenCache.token

  const clientEmail = env('FCM_CLIENT_EMAIL')
  const privateKeyPem = env('FCM_PRIVATE_KEY').replace(/\\n/g, '\n')
  if (!clientEmail || !privateKeyPem) {
    throw new Error('FCM_CLIENT_EMAIL / FCM_PRIVATE_KEY no configurados')
  }

  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const claim = base64UrlEncode(JSON.stringify({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: ahora,
    exp: ahora + 3600,
  }))
  const unsigned = `${header}.${claim}`

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKeyPem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned))
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(sig))}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  if (!res.ok) throw new Error(`OAuth FCM ${res.status}: ${await res.text()}`)
  const data = await res.json()
  fcmTokenCache = { token: data.access_token, exp: ahora + (data.expires_in ?? 3600) }
  return data.access_token
}

/** Devuelve 'enviado' u 'caducado' (token no registrado: el llamador lo desactiva). */
async function enviarPush(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<'enviado' | 'caducado'> {
  const projectId = env('FCM_PROJECT_ID')
  if (!projectId) throw new Error('FCM_PROJECT_ID no configurado')

  const accessToken = await getFcmAccessToken()
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: { token, notification: { title, body }, data },
      }),
    },
  )

  if (response.ok) return 'enviado'

  // 404 UNREGISTERED / 400 token inválido → el token ya no sirve.
  if (response.status === 404 || response.status === 400) return 'caducado'

  const text = await response.text()
  throw new Error(`FCM ${response.status}: ${text}`)
}

async function enviarEmail(email: string, subject: string, html: string) {
  const apiKey = env('RESEND_API_KEY')
  const from = env('RESEND_FROM_EMAIL') || 'Oposiwork <notificaciones@oposiwork.com>'
  if (!apiKey) throw new Error('RESEND_API_KEY no configurado')

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from, to: email, subject, html }),
  })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`Resend ${response.status}: ${text}`)
  }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method Not Allowed' }, 405)

  const cronSecret = req.headers.get('x-cron-secret') ?? req.headers.get('authorization')?.replace('Bearer ', '')
  if (!cronSecret || cronSecret !== env('CRON_SECRET')) {
    return json({ error: 'No autorizado' }, 401)
  }

  const supabase = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'))

  const { data: pendientes, error } = await supabase
    .from('notificacion_destinatarios')
    .select(`
      id,
      usuario_id,
      canal,
      notificacion_id,
      notificaciones_convocatoria (
        titulo,
        mensaje,
        tipo,
        convocatoria_id,
        convocatorias (
          oposicion_id
        )
      ),
      perfiles (
        email,
        notificaciones_push,
        notificaciones_email
      )
    `)
    .eq('estado', 'pendiente')
    .limit(100)

  if (error) {
    console.error('send-notifications query error', error)
    return json({ error: 'Error interno' }, 500)
  }

  let enviadas = 0
  let fallidas = 0
  let omitidas = 0

  for (const item of (pendientes ?? []) as PendingRecipient[]) {
    const notif = item.notificaciones_convocatoria
    if (!notif) continue

    try {
      if (item.canal === 'in_app') {
        await supabase
          .from('notificacion_destinatarios')
          .update({ estado: 'enviada', enviada_en: new Date().toISOString() })
          .eq('id', item.id)
        enviadas++
        continue
      }

      if (item.canal === 'push') {
        if (item.perfiles?.notificaciones_push === false) {
          await supabase.from('notificacion_destinatarios').update({ estado: 'omitida' }).eq('id', item.id)
          omitidas++
          continue
        }

        const { data: tokens } = await supabase
          .from('usuario_dispositivos')
          .select('fcm_token')
          .eq('usuario_id', item.usuario_id)
          .eq('activo', true)

        if (!tokens?.length) {
          await supabase.from('notificacion_destinatarios').update({ estado: 'omitida', error: 'Sin token FCM activo' }).eq('id', item.id)
          omitidas++
          continue
        }

        for (const token of tokens) {
          const routeId = notif.convocatorias?.oposicion_id || notif.convocatoria_id
          const resultado = await enviarPush(token.fcm_token, notif.titulo, notif.mensaje, {
            route: `/oposiciones/${routeId}`,
            tipo: notif.tipo,
            notificacion_id: item.notificacion_id,
          })
          // Token caducado/no registrado: lo desactivamos para no reintentar siempre.
          if (resultado === 'caducado') {
            await supabase
              .from('usuario_dispositivos')
              .update({ activo: false })
              .eq('fcm_token', token.fcm_token)
          }
        }
      }

      if (item.canal === 'email') {
        if (item.perfiles?.notificaciones_email === false || !item.perfiles?.email) {
          await supabase.from('notificacion_destinatarios').update({ estado: 'omitida', error: 'Email desactivado o no disponible' }).eq('id', item.id)
          omitidas++
          continue
        }

        await enviarEmail(
          item.perfiles.email,
          notif.titulo,
          `<p>${escapeHtml(notif.mensaje)}</p><p><a href="https://www.oposiwork.com/app/#/home">Abrir Oposiwork</a></p>`,
        )
      }

      await supabase
        .from('notificacion_destinatarios')
        .update({ estado: 'enviada', enviada_en: new Date().toISOString(), error: null })
        .eq('id', item.id)
      enviadas++
    } catch (err) {
      await supabase
        .from('notificacion_destinatarios')
        .update({ estado: 'fallida', error: err.message ?? String(err) })
        .eq('id', item.id)
      fallidas++
    }
  }

  await supabase.rpc('marcar_notificaciones_enviadas_si_completas')

  return json({ procesadas: pendientes?.length ?? 0, enviadas, fallidas, omitidas })
})
