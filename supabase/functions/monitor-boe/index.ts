import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Se ejecuta diariamente via cron job
// Verifica autenticación con CRON_SECRET en el header x-cron-secret

Deno.serve(async (req) => {
  try {
    // Verificar que la llamada viene del cron job autorizado
    const cronSecret = req.headers.get('x-cron-secret')
    if (cronSecret !== Deno.env.get('CRON_SECRET')) {
      return new Response(JSON.stringify({ error: 'No autorizado' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Obtener oposiciones activas para comparar con el BOE
    const { data: oposiciones } = await supabase
      .from('oposiciones')
      .select('id, slug, nombre, cuerpo')
      .eq('activa', true)

    if (!oposiciones?.length) {
      return new Response(
        JSON.stringify({ procesados: 0, nuevas_notificaciones: 0, timestamp: new Date().toISOString() }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Consultar RSS del BOE (sección empleo público/oposiciones)
    const rssUrl = 'https://www.boe.es/rss/canal.php?c=2'
    const rssRes = await fetch(rssUrl, {
      headers: { 'User-Agent': 'Oposiwork-Monitor/1.0' },
    })

    if (!rssRes.ok) {
      throw new Error(`Error consultando BOE RSS: ${rssRes.status}`)
    }

    const rssText = await rssRes.text()

    // Extraer items del RSS con regex (DOMParser no disponible en Deno Edge)
    const items = rssText.match(/<item>([\s\S]*?)<\/item>/g) ?? []
    let procesados = 0
    let nuevasNotificaciones = 0

    for (const item of items) {
      procesados++

      const titleMatch = item.match(/<title><!\[CDATA\[(.*?)\]\]><\/title>/)
        ?? item.match(/<title>(.*?)<\/title>/)
      const linkMatch = item.match(/<link>(.*?)<\/link>/)

      const titulo = titleMatch?.[1]?.trim() ?? ''
      const link = linkMatch?.[1]?.trim() ?? ''

      if (!titulo || !link) continue

      // Buscar si alguna oposición activa está mencionada en el item del BOE
      const oposicionRelacionada = oposiciones.find(op => {
        const keywords = [op.nombre, op.cuerpo, op.slug.replace(/-/g, ' ')].join(' ').toLowerCase()
        const tituloLower = titulo.toLowerCase()
        return keywords.split(' ').some(word => word.length > 4 && tituloLower.includes(word))
      })

      if (!oposicionRelacionada) continue

      // Verificar si ya existe una notificación con este link
      const { data: existente } = await supabase
        .from('convocatorias')
        .select('id')
        .eq('url_boe', link)
        .maybeSingle()

      if (existente) continue

      // Insertar nueva notificación de convocatoria
      // Primero obtenemos la convocatoria activa más reciente de esta oposición
      const { data: convocatoria } = await supabase
        .from('convocatorias')
        .select('id')
        .eq('oposicion_id', oposicionRelacionada.id)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (convocatoria) {
        await supabase.from('notificaciones_convocatoria').insert({
          convocatoria_id: convocatoria.id,
          tipo: 'nueva_convocatoria',
          titulo: `Novedad BOE: ${oposicionRelacionada.nombre}`,
          mensaje: titulo,
          enviada: false,
        })
        nuevasNotificaciones++
      }
    }

    return new Response(
      JSON.stringify({
        procesados,
        nuevas_notificaciones: nuevasNotificaciones,
        timestamp: new Date().toISOString(),
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
