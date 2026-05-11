import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders, handleOptions } from '../_shared/cors.ts'
import { checkUserRateLimit, rateLimitExceededResponse } from '../_shared/rate_limit.ts'
import { validarTexto, respuestaError400 } from '../_shared/validate.ts'

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;
  const corsHeaders = buildCorsHeaders(req);

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Verificar JWT del usuario
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

    // Verificar plan premium activo (el chat IA es funcionalidad premium)
    const { data: perfil } = await supabase
      .from('perfiles')
      .select('plan, plan_fin')
      .eq('id', user.id)
      .single()

    const esPremium = perfil?.plan !== 'free'
      && perfil?.plan_fin
      && new Date(perfil.plan_fin) > new Date()

    if (!esPremium) {
      return new Response(
        JSON.stringify({ error: 'Se requiere plan premium para usar el asistente de IA' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verificar consentimiento de IA (obligatorio por RGPD)
    const { data: consentimiento } = await supabase
      .from('consentimientos')
      .select('aceptado')
      .eq('usuario_id', user.id)
      .eq('tipo', 'ia')
      .maybeSingle()

    if (!consentimiento?.aceptado) {
      return new Response(
        JSON.stringify({
          error: 'Se requiere consentimiento de uso de IA',
          requiere_consentimiento: true,
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Rate limiting por usuario: 5 consultas/minuto, 20 consultas/hora
    const permitido = await checkUserRateLimit(supabase, user.id, 'chat-rag', 5, 20)
    if (!permitido) {
      return rateLimitExceededResponse(corsHeaders, 'minuto')
    }

    const body = await req.json().catch(() => ({}))
    const preguntaResult = validarTexto(body?.pregunta, 'pregunta', { min: 1, max: 1000 })
    if (!preguntaResult.ok) {
      return respuestaError400(corsHeaders, preguntaResult.mensaje)
    }
    const pregunta = preguntaResult.valor

    // Generar embedding de la pregunta via OpenAI
    const embeddingRes = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'text-embedding-3-small',
        input: pregunta,
      }),
    })
    const embeddingData = await embeddingRes.json()
    const queryEmbedding = embeddingData.data?.[0]?.embedding

    // Buscar fragmentos del temario más similares a la pregunta
    let fragmentos: Array<{ tema_id: string; fragmento: string; similitud: number }> = []
    if (queryEmbedding) {
      const { data: results } = await supabase.rpc('buscar_fragmentos_similares', {
        query_embedding: queryEmbedding,
        limite: 5,
      })
      fragmentos = results ?? []
    }

    const contexto = fragmentos.length > 0
      ? fragmentos.map(f => f.fragmento).join('\n\n---\n\n')
      : 'No se encontró contexto específico en el temario.'

    // Llamar a Claude con el contexto recuperado
    const claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') ?? '',
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        system: `Eres un asistente experto en oposiciones españolas.
Responde SOLO basándote en el contexto del temario proporcionado.
Cita el artículo o fuente exacta siempre que sea posible.
Si no encuentras la respuesta en el contexto, indícalo claramente y no inventes información.
Responde siempre en español.`,
        messages: [{
          role: 'user',
          content: `CONTEXTO DEL TEMARIO:\n${contexto}\n\nPREGUNTA:\n${pregunta}`,
        }],
      }),
    })

    const claudeData = await claudeRes.json()
    const respuesta = claudeData.content?.[0]?.text ?? 'No se pudo generar una respuesta.'

    return new Response(
      JSON.stringify({
        respuesta,
        fuentes: fragmentos,
        aviso: 'Respuesta generada por IA. Verifica siempre en las fuentes oficiales del BOE.',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
