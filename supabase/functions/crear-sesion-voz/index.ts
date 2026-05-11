import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders, handleOptions } from '../_shared/cors.ts'
import { checkUserRateLimit, rateLimitExceededResponse } from '../_shared/rate_limit.ts'

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

    // Rate limiting por usuario: 2 sesiones/minuto, 5 sesiones/hora
    const permitido = await checkUserRateLimit(supabase, user.id, 'crear-sesion-voz', 2, 5)
    if (!permitido) {
      return rateLimitExceededResponse(corsHeaders, 'minuto')
    }

    // Verificar consentimiento de voz (RGPD — obligatorio antes de grabar audio)
    const { data: consentimiento } = await supabase
      .from('consentimientos')
      .select('aceptado')
      .eq('usuario_id', user.id)
      .eq('tipo', 'voz')
      .maybeSingle()

    if (!consentimiento?.aceptado) {
      return new Response(
        JSON.stringify({
          error: 'Se requiere consentimiento explícito para usar el asistente de voz',
          requiere_consentimiento: true,
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verificar plan premium activo
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
        JSON.stringify({ error: 'Se requiere plan premium para usar el asistente de voz' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calcular cuota mensual según plan
    const limiteMensual = perfil?.plan === 'annual'
      ? 3600
      : parseInt(Deno.env.get('VOICE_MONTHLY_LIMIT_SECONDS') ?? '1800')

    const { data: segundosUsados } = await supabase.rpc(
      'obtener_segundos_usados_mes',
      { uid: user.id }
    )

    const usados = (segundosUsados as number) ?? 0
    const restantes = Math.max(0, limiteMensual - usados)

    if (usados >= limiteMensual) {
      return new Response(
        JSON.stringify({
          error: `Has agotado tu cuota mensual de ${Math.round(limiteMensual / 60)} minutos de voz`,
          cuota_restante_segundos: 0,
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Crear sesión de voz con OpenAI Realtime API
    const openaiRes = await fetch('https://api.openai.com/v1/realtime/sessions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: Deno.env.get('OPENAI_REALTIME_MODEL') ?? 'gpt-4o-realtime-preview',
        voice: Deno.env.get('OPENAI_VOICE') ?? 'alloy',
        instructions: `Eres Opi, un asistente de voz especializado en preparación de oposiciones españolas.
Explica los temas de forma clara, concisa y adaptada al nivel del opositor.
Cita el número de artículo y la ley exacta cuando sea relevante.
Si el opositor comete un error conceptual, corrígelo amablemente.
Habla siempre en español. Sé motivador pero preciso.`,
      }),
    })

    if (!openaiRes.ok) {
      const err = await openaiRes.text()
      throw new Error(`Error OpenAI Realtime: ${openaiRes.status} — ${err}`)
    }

    const sessionData = await openaiRes.json()

    // Registrar la sesión en la base de datos para control de cuota
    await supabase.from('sesiones_voz').insert({
      usuario_id: user.id,
      session_id_openai: sessionData.id,
      modelo: Deno.env.get('OPENAI_REALTIME_MODEL') ?? 'gpt-4o-realtime-preview',
    })

    return new Response(
      JSON.stringify({
        session_id: sessionData.id,
        client_secret: sessionData.client_secret?.value ?? null,
        cuota_restante_segundos: restantes,
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          // Aviso legal obligatorio sobre uso de IA de voz
          'X-Voice-AI-Warning': 'Esta sesión usa voz generada por inteligencia artificial',
        },
      }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
