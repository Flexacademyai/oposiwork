import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { buildCorsHeaders, handleOptions } from '../_shared/cors.ts'
import { checkUserRateLimit, rateLimitExceededResponse } from '../_shared/rate_limit.ts'
import { validarUuid, respuestaError400 } from '../_shared/validate.ts'

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

    // Verificar JWT
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

    // Verificar plan activo
    const { data: perfil } = await supabase
      .from('perfiles')
      .select('plan, plan_fin')
      .eq('id', user.id)
      .single()

    const esPremium = perfil?.plan_fin && new Date(perfil.plan_fin) > new Date()
    if (!esPremium) {
      return new Response(JSON.stringify({ error: 'Se requiere plan premium' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Rate limiting por usuario: 3 intentos/minuto, 10 descargas/hora
    const permitidoUsuario = await checkUserRateLimit(supabase, user.id, 'download-pdf', 3, 10)
    if (!permitidoUsuario) {
      return rateLimitExceededResponse(corsHeaders, 'minuto')
    }

    // Rate limiting por IP como capa adicional (protege contra cuentas compartidas)
    const rawIp = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
      ?? req.headers.get('x-real-ip')
      ?? 'unknown'
    const ipHash = await hashIp(rawIp)
    const { data: permitidoIp } = await supabase.rpc('check_rate_limit', {
      p_ip_hash: ipHash,
      p_endpoint: 'download-pdf',
      p_limite: 15,
      p_ventana_segundos: 3600,
    })
    if (!permitidoIp) {
      return rateLimitExceededResponse(corsHeaders, 'hora')
    }

    const body = await req.json().catch(() => ({}))
    const pdfIdResult = validarUuid(body?.pdfId, 'pdfId')
    if (!pdfIdResult.ok) {
      return respuestaError400(corsHeaders, pdfIdResult.mensaje)
    }
    const pdfId = pdfIdResult.valor

    // Verificar si ya descargó este PDF (UNIQUE constraint en DB lo refuerza también)
    const { data: descargaExistente } = await supabase
      .from('descargas_pdf')
      .select('id')
      .eq('usuario_id', user.id)
      .eq('pdf_id', pdfId)
      .maybeSingle()

    if (descargaExistente) {
      return new Response(
        JSON.stringify({ error: 'Ya descargaste este PDF anteriormente' }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Obtener metadatos del PDF
    const { data: pdf } = await supabase
      .from('temario_pdfs')
      .select('storage_path, nombre')
      .eq('id', pdfId)
      .eq('activo', true)
      .single()

    if (!pdf) {
      return new Response(JSON.stringify({ error: 'PDF no encontrado' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Registrar la descarga antes de generar la URL
    const { error: insertError } = await supabase
      .from('descargas_pdf')
      .insert({ usuario_id: user.id, pdf_id: pdfId })

    if (insertError) {
      const esDescargaDuplicada = insertError.code === '23505'
      return new Response(JSON.stringify({
        error: esDescargaDuplicada
          ? 'Ya descargaste este PDF anteriormente'
          : 'Error al registrar la descarga',
      }), {
        status: esDescargaDuplicada ? 409 : 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // URL firmada que expira en 60 segundos (no reutilizable)
    const { data: signedUrl, error: urlError } = await supabase.storage
      .from('temarios')
      .createSignedUrl(pdf.storage_path, 60)

    if (urlError || !signedUrl) {
      await supabase
        .from('descargas_pdf')
        .delete()
        .eq('usuario_id', user.id)
        .eq('pdf_id', pdfId)

      return new Response(JSON.stringify({ error: 'Error generando URL de descarga' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(
      JSON.stringify({ url: signedUrl.signedUrl, nombre: pdf.nombre }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Content-Disposition': `attachment; filename="${pdf.nombre}"`,
        },
      },
    )
  } catch (error) {
    console.error('download-pdf error', error)
    return new Response(JSON.stringify({ error: 'Error interno' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
