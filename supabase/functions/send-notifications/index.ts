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

async function enviarPush(token: string, title: string, body: string, data: Record<string, string>) {
  const serverKey = env('FCM_SERVER_KEY')
  if (!serverKey) throw new Error('FCM_SERVER_KEY no configurado')

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      Authorization: `key=${serverKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body },
      data,
    }),
  })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`FCM ${response.status}: ${text}`)
  }
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

  if (error) return json({ error: error.message }, 500)

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
          await enviarPush(token.fcm_token, notif.titulo, notif.mensaje, {
            route: `/oposiciones/${routeId}`,
            tipo: notif.tipo,
            notificacion_id: item.notificacion_id,
          })
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
          `<p>${notif.mensaje}</p><p><a href="https://www.oposiwork.com/app/#/home">Abrir Oposiwork</a></p>`,
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
