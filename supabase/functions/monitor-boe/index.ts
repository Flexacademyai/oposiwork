import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type RssItem = {
  title: string
  link: string
  pubDate?: string
  sourceName: string
  sourceScope: string
}

type FuenteConvocatorias = {
  name: string
  scope: string
  url: string
  type: 'rss' | 'atom' | 'html'
}

const SOURCE_URL_OVERRIDES: Record<string, Pick<FuenteConvocatorias, 'url' | 'type'>> = {
  'bop almeria': {
    url: 'https://app.dipalme.org/pandora/index.vm?view=boletines',
    type: 'html',
  },
  'bop granada': {
    url: 'https://bop-admin.dipgra.es/',
    type: 'html',
  },
  'bop huelva': {
    url: 'https://sede.diphuelva.es/servicios/bop',
    type: 'html',
  },
  'bop palencia': {
    url: 'https://www.diputaciondepalencia.es/servicios/boletin-oficial-provincia/?page=0',
    type: 'html',
  },
  'bop tarragona': {
    url: 'https://aplicacions.dipta.cat/bopt/web/es',
    type: 'html',
  },
}

const SOURCE_FETCH_TIMEOUT_MS = 15000
const DETAIL_FETCH_TIMEOUT_MS = 5000
const MAX_DETAIL_ITEMS = 250
const MAX_ITEMS_PER_HTML_SOURCE = 120
const SOURCE_CONCURRENCY = 12
// Presupuesto de tiempo para el bucle de publicación: si se agota, devolvemos lo
// hecho hasta el momento en vez de arriesgar un 502 del gateway (el trabajo
// restante se retoma en la siguiente ejecución diaria).
const PUBLISH_TIME_BUDGET_MS = 60000
// Cuando no se puede extraer el plazo del texto oficial, publicamos igualmente la
// convocatoria con una fecha de fin ESTIMADA para no perderla (el opositor debe
// confirmar en la fuente). 30 días naturales cubre el rango habitual (10-20 días
// hábiles) sin cerrarla antes de tiempo.
const DEFAULT_PLAZO_DIAS_ESTIMADO = 30

const FUENTES_BASE: FuenteConvocatorias[] = [
  {
    name: 'BOE - Oposiciones y concursos',
    scope: 'Estatal',
    url: 'https://www.boe.es/rss/canal.php?c=2',
    type: 'rss',
  },
  {
    name: 'PAGe - Buscador de convocatorias de empleo publico',
    scope: 'Estatal',
    url: 'https://administracion.gob.es/pag_Home/es/empleoPublico/',
    type: 'html',
  },
  {
    name: 'BOA - Aragon',
    scope: 'Aragon',
    url: 'https://www.boa.aragon.es/',
    type: 'html',
  },
  {
    name: 'BOJA - Oposiciones y concursos',
    scope: 'Andalucia',
    url: 'https://www.juntadeandalucia.es/boja/distribucion/s53.xml',
    type: 'atom',
  },
  {
    name: 'BOPA - Asturias',
    scope: 'Asturias',
    url: 'https://sede.asturias.es/bopa',
    type: 'html',
  },
  {
    name: 'BOIB - Illes Balears',
    scope: 'Illes Balears',
    url: 'https://www.caib.es/eboibfront/',
    type: 'html',
  },
  {
    name: 'BOC - Canarias',
    scope: 'Canarias',
    url: 'https://www.gobiernodecanarias.org/boc/',
    type: 'html',
  },
  {
    name: 'BOC - Cantabria',
    scope: 'Cantabria',
    url: 'https://boc.cantabria.es/',
    type: 'html',
  },
  {
    // Feed RSS oficial verificado (la portada HTML fallaba al leerse desde el edge)
    name: 'BOCYL - Castilla y Leon',
    scope: 'Castilla y Leon',
    url: 'https://bocyl.jcyl.es/rss.do',
    type: 'rss',
  },
  {
    name: 'DOCM - Castilla-La Mancha',
    scope: 'Castilla-La Mancha',
    url: 'https://docm.jccm.es/',
    type: 'html',
  },
  {
    name: 'DOGC - Catalunya',
    scope: 'Catalunya',
    url: 'https://dogc.gencat.cat/',
    type: 'html',
  },
  {
    name: 'DOGV - Comunitat Valenciana',
    scope: 'Comunitat Valenciana',
    url: 'https://dogv.gva.es/',
    type: 'html',
  },
  {
    name: 'DOE - Extremadura',
    scope: 'Extremadura',
    url: 'https://doe.juntaex.es/',
    type: 'html',
  },
  {
    name: 'DOG - Galicia',
    scope: 'Galicia',
    url: 'https://www.xunta.gal/diario-oficial-galicia',
    type: 'html',
  },
  {
    name: 'BOCM - Ultimos boletines',
    scope: 'Comunidad de Madrid',
    url: 'https://www.bocm.es/boletines.rss',
    type: 'rss',
  },
  {
    name: 'BOCM - Ordenes del dia',
    scope: 'Comunidad de Madrid',
    url: 'https://www.bocm.es/ultimo-boletin.xml',
    type: 'rss',
  },
  {
    name: 'BORM - Region de Murcia',
    scope: 'Region de Murcia',
    url: 'https://www.borm.es/',
    type: 'html',
  },
  {
    name: 'BON - Navarra',
    scope: 'Navarra',
    url: 'https://bon.navarra.es/',
    type: 'html',
  },
  {
    name: 'BOPV - Pais Vasco',
    scope: 'Pais Vasco',
    url: 'https://www.euskadi.eus/bopv2/datos/Ultimo.shtml',
    type: 'html',
  },
  {
    name: 'BOR - La Rioja',
    scope: 'La Rioja',
    url: 'https://web.larioja.org/bor-portada',
    type: 'html',
  },
  {
    // El boletin de Ceuta se llama BOCCE; la ruta /bome dejo de existir
    name: 'BOCCE - Ceuta',
    scope: 'Ceuta',
    url: 'https://www.ceuta.es/ceuta/bocce',
    type: 'html',
  },
  {
    name: 'BOME - Melilla',
    scope: 'Melilla',
    url: 'https://bomemelilla.es/',
    type: 'html',
  },
  {
    name: 'BOP Alava',
    scope: 'Provincia de Alava',
    url: 'https://www.araba.eus/botha/',
    type: 'html',
  },
  {
    name: 'BOP Albacete',
    scope: 'Provincia de Albacete',
    url: 'https://www.dipualba.es/bop/',
    type: 'html',
  },
  {
    name: 'BOP Alicante',
    scope: 'Provincia de Alicante',
    url: 'https://sede.diputacionalicante.es/consultas-bop/',
    type: 'html',
  },
  {
    name: 'BOP Almeria',
    scope: 'Provincia de Almeria',
    url: 'https://www.dipalme.org/Servicios/Boletin/Boletin.nsf',
    type: 'html',
  },
  {
    name: 'BOP Avila',
    scope: 'Provincia de Avila',
    url: 'https://bop.diputacionavila.es/',
    type: 'html',
  },
  {
    name: 'BOP Badajoz',
    scope: 'Provincia de Badajoz',
    url: 'https://www.dip-badajoz.es/bop/',
    type: 'html',
  },
  {
    name: 'BOP Barcelona - Boletin del dia',
    scope: 'Provincia de Barcelona',
    url: 'https://bop.diba.cat/dades-obertes/butlleti-del-dia/feed',
    type: 'rss',
  },
  {
    name: 'BOP Barcelona - Administracion local',
    scope: 'Provincia de Barcelona',
    url: 'https://bop.diba.cat/dades-obertes/butlleti-del-dia/administracio-local/feed',
    type: 'rss',
  },
  {
    name: 'BOP Bizkaia',
    scope: 'Provincia de Bizkaia',
    url: 'https://www.bizkaia.eus/es/bao',
    type: 'html',
  },
  {
    name: 'BOP Burgos',
    scope: 'Provincia de Burgos',
    url: 'https://bopbur.diputaciondeburgos.es/',
    type: 'html',
  },
  {
    name: 'BOP Caceres',
    scope: 'Provincia de Caceres',
    url: 'https://bop.dip-caceres.es/',
    type: 'html',
  },
  {
    name: 'BOP Cadiz',
    scope: 'Provincia de Cadiz',
    url: 'https://www.bopcadiz.es/index.html',
    type: 'html',
  },
  {
    name: 'BOP Castellon',
    scope: 'Provincia de Castellon',
    url: 'https://bop.dipcas.es/',
    type: 'html',
  },
  {
    name: 'BOP Ciudad Real',
    scope: 'Provincia de Ciudad Real',
    url: 'https://bop.dipucr.es/',
    type: 'html',
  },
  {
    name: 'BOP Cordoba',
    scope: 'Provincia de Cordoba',
    url: 'https://bop.dipucordoba.es/',
    type: 'html',
  },
  {
    name: 'BOP A Coruna',
    scope: 'Provincia de A Coruna',
    url: 'https://bop.dacoruna.gal/',
    type: 'html',
  },
  {
    name: 'BOP Cuenca',
    scope: 'Provincia de Cuenca',
    url: 'https://www.dipucuenca.es/bop',
    type: 'html',
  },
  {
    name: 'BOP Girona',
    scope: 'Provincia de Girona',
    url: 'https://www.ddgi.cat/bop/',
    type: 'html',
  },
  {
    name: 'BOP Granada',
    scope: 'Provincia de Granada',
    url: 'https://bop.dipgra.es/',
    type: 'html',
  },
  {
    name: 'BOP Guadalajara',
    scope: 'Provincia de Guadalajara',
    url: 'https://boletin.dguadalajara.es/',
    type: 'html',
  },
  {
    name: 'BOP Gipuzkoa',
    scope: 'Provincia de Gipuzkoa',
    url: 'https://egoitza.gipuzkoa.eus/es/bog',
    type: 'html',
  },
  {
    name: 'BOP Huelva',
    scope: 'Provincia de Huelva',
    url: 'https://bop.diphuelva.es/',
    type: 'html',
  },
  {
    name: 'BOP Huesca',
    scope: 'Provincia de Huesca',
    url: 'https://bop.dphuesca.es/',
    type: 'html',
  },
  {
    name: 'BOP Jaen',
    scope: 'Provincia de Jaen',
    url: 'https://bop.dipujaen.es/',
    type: 'html',
  },
  {
    name: 'BOP Las Palmas',
    scope: 'Provincia de Las Palmas',
    url: 'https://www.boplaspalmas.net/',
    type: 'html',
  },
  {
    name: 'BOP Leon',
    scope: 'Provincia de Leon',
    url: 'https://bop.dipuleon.es/',
    type: 'html',
  },
  {
    name: 'BOP Lleida',
    scope: 'Provincia de Lleida',
    url: 'https://ebop.diputaciolleida.cat/',
    type: 'html',
  },
  {
    name: 'BOP Lugo',
    scope: 'Provincia de Lugo',
    url: 'https://www.deputacionlugo.gal/gl/bop',
    type: 'html',
  },
  {
    name: 'BOP Malaga',
    scope: 'Provincia de Malaga',
    url: 'https://www.bopmalaga.es/',
    type: 'html',
  },
  {
    name: 'BOP Ourense',
    scope: 'Provincia de Ourense',
    url: 'https://bop.depourense.es/',
    type: 'html',
  },
  {
    name: 'BOP Palencia',
    scope: 'Provincia de Palencia',
    url: 'https://bop.diputaciondepalencia.es/',
    type: 'html',
  },
  {
    name: 'BOP Pontevedra',
    scope: 'Provincia de Pontevedra',
    url: 'https://boppo.depo.gal/',
    type: 'html',
  },
  {
    name: 'BOP Salamanca',
    scope: 'Provincia de Salamanca',
    url: 'https://sede.diputaciondesalamanca.gob.es/bop/',
    type: 'html',
  },
  {
    name: 'BOP Santa Cruz de Tenerife',
    scope: 'Provincia de Santa Cruz de Tenerife',
    url: 'https://www.bopsantacruzdetenerife.es/',
    type: 'html',
  },
  {
    name: 'BOP Segovia',
    scope: 'Provincia de Segovia',
    url: 'https://bopsegovia.dipsegovia.es/',
    type: 'html',
  },
  {
    name: 'BOP Sevilla',
    scope: 'Provincia de Sevilla',
    url: 'https://bopsevilla.dipusevilla.es/publica/consulta-de-bops/index.html',
    type: 'html',
  },
  {
    name: 'BOP Soria',
    scope: 'Provincia de Soria',
    url: 'https://bop.dipsoria.es/',
    type: 'html',
  },
  {
    name: 'BOP Tarragona',
    scope: 'Provincia de Tarragona',
    url: 'https://www.dipta.cat/ebop/',
    type: 'html',
  },
  {
    name: 'BOP Teruel',
    scope: 'Provincia de Teruel',
    url: 'https://bop.dpteruel.es/',
    type: 'html',
  },
  {
    name: 'BOP Toledo',
    scope: 'Provincia de Toledo',
    url: 'https://bop.diputoledo.es/',
    type: 'html',
  },
  {
    name: 'BOP Valencia',
    scope: 'Provincia de Valencia',
    url: 'https://bop.dival.es/',
    type: 'html',
  },
  {
    name: 'BOP Valladolid',
    scope: 'Provincia de Valladolid',
    url: 'https://bop.sede.diputaciondevalladolid.es/',
    type: 'html',
  },
  {
    name: 'BOP Zamora',
    scope: 'Provincia de Zamora',
    url: 'https://bop.diputaciondezamora.es/',
    type: 'html',
  },
  {
    name: 'BOP Zaragoza',
    scope: 'Provincia de Zaragoza',
    url: 'https://bop.dpz.es/',
    type: 'html',
  },
]

const NUMEROS: Record<string, number> = {
  un: 1,
  una: 1,
  dos: 2,
  tres: 3,
  cuatro: 4,
  cinco: 5,
  seis: 6,
  siete: 7,
  ocho: 8,
  nueve: 9,
  diez: 10,
  once: 11,
  doce: 12,
  trece: 13,
  catorce: 14,
  quince: 15,
  veinte: 20,
  treinta: 30,
}

function stripHtml(text: string): string {
  return text
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&aacute;/g, 'á')
    .replace(/&eacute;/g, 'é')
    .replace(/&iacute;/g, 'í')
    .replace(/&oacute;/g, 'ó')
    .replace(/&uacute;/g, 'ú')
    .replace(/&ntilde;/g, 'ñ')
    .replace(/&Aacute;/g, 'Á')
    .replace(/&Eacute;/g, 'É')
    .replace(/&Iacute;/g, 'Í')
    .replace(/&Oacute;/g, 'Ó')
    .replace(/&Uacute;/g, 'Ú')
    .replace(/&Ntilde;/g, 'Ñ')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ')
    .trim()
}

function normalizeText(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
}

function slugify(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 90)
}

function normalizarFuente(source: FuenteConvocatorias): FuenteConvocatorias {
  const key = normalizeText(source.name)
  const override = SOURCE_URL_OVERRIDES[key]
  if (!override) return source
  return {
    ...source,
    url: override.url,
    type: override.type,
  }
}

function parseExtraSources(): FuenteConvocatorias[] {
  const raw = Deno.env.get('CONVOCATORIAS_EXTRA_SOURCES_JSON')
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []
    return parsed
      .filter((source) => source?.name && source?.url)
      .map((source) => ({
        name: String(source.name),
        scope: String(source.scope ?? 'Fuente externa'),
        url: String(source.url),
        type: ['rss', 'atom', 'html'].includes(source.type) ? source.type : 'rss',
      }))
  } catch (_) {
    return []
  }
}

function fuenteDesdeRegistro(row: Record<string, unknown>): FuenteConvocatorias | null {
  const name = row.nombre ?? row.name
  const scope = row.territorio ?? row.scope ?? row.ambito
  const url = row.url
  const type = row.tipo ?? row.type

  if (!name || !scope || !url) return null

  const parsedType = ['rss', 'atom', 'html'].includes(String(type))
    ? String(type) as FuenteConvocatorias['type']
    : 'html'

  return {
    name: String(name),
    scope: String(scope),
    url: String(url),
    type: parsedType,
  }
}

async function cargarFuentesDesdeDb(supabase: ReturnType<typeof createClient>): Promise<FuenteConvocatorias[]> {
  const { data, error } = await supabase
    .from('boletines')
    .select('*')

  if (error || !data) return []

  return data
    .filter((row) => row.activo !== false)
    .sort((a, b) => Number(a.prioridad ?? 100) - Number(b.prioridad ?? 100))
    .map((row) => fuenteDesdeRegistro(row as Record<string, unknown>))
    .filter((source): source is FuenteConvocatorias => source !== null)
}

function combinarFuentes(...groups: FuenteConvocatorias[][]): FuenteConvocatorias[] {
  const seen = new Set<string>()
  const merged: FuenteConvocatorias[] = []

  for (const source of groups.flat()) {
    const normalized = normalizarFuente(source)
    const key = normalized.url.toLowerCase()
    if (seen.has(key)) continue
    seen.add(key)
    merged.push(normalized)
  }

  return merged
}

function absoluteUrl(base: string, href: string): string {
  try {
    return new URL(href, base).toString()
  } catch (_) {
    return href
  }
}

function extractTag(block: string, tag: string): string {
  return stripHtml(
    block.match(new RegExp(`<${tag}\\b[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/${tag}>`, 'i'))?.[1] ??
      block.match(new RegExp(`<${tag}\\b[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'i'))?.[1] ??
      '',
  )
}

function parseFeedItems(xml: string, source: FuenteConvocatorias): RssItem[] {
  const rssItems = (xml.match(/<item\b[^>]*>([\s\S]*?)<\/item>/gi) ?? [])
    .map((item) => {
      const title = extractTag(item, 'title')
      const link = absoluteUrl(
        source.url,
        (
          item.match(/<link\b[^>]*><!\[CDATA\[([\s\S]*?)\]\]><\/link>/i)?.[1] ??
          item.match(/<link\b[^>]*>([\s\S]*?)<\/link>/i)?.[1] ??
          item.match(/rdf:about=["']([^"']+)["']/i)?.[1] ??
          ''
        ).trim(),
      )
      const pubDate =
        extractTag(item, 'pubDate') ||
        extractTag(item, 'dc:date') ||
        extractTag(item, 'date')
      return {
        title,
        link,
        pubDate,
        sourceName: source.name,
        sourceScope: source.scope,
      }
    })
    .filter((item) => item.title && item.link)

  const atomItems = (xml.match(/<entry\b[^>]*>([\s\S]*?)<\/entry>/gi) ?? [])
    .map((entry) => {
      const title = extractTag(entry, 'title')
      const link = absoluteUrl(
        source.url,
        (
          entry.match(/<link[^>]+href=["']([^"']+)["'][^>]*>/)?.[1] ??
          entry.match(/<id>(.*?)<\/id>/)?.[1] ??
          ''
        ).trim(),
      )
      const pubDate = extractTag(entry, 'published') || extractTag(entry, 'updated')
      return {
        title,
        link,
        pubDate,
        sourceName: source.name,
        sourceScope: source.scope,
      }
    })
    .filter((item) => item.title && item.link)

  return [...rssItems, ...atomItems]
}

function parseHtmlItems(html: string, source: FuenteConvocatorias): RssItem[] {
  const items: RssItem[] = []
  const seen = new Set<string>()
  const anchorRegex = /<a\b[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi
  let match: RegExpExecArray | null
  while ((match = anchorRegex.exec(html)) !== null) {
    const link = absoluteUrl(source.url, match[1])
    const anchorTitle = stripHtml(match[2])
    const contextStarts = [
      html.lastIndexOf('<tr', match.index),
      html.lastIndexOf('<li', match.index),
      html.lastIndexOf('<article', match.index),
      html.lastIndexOf('<div', match.index),
    ].filter((index) => index >= 0)
    const contextStart = contextStarts.length > 0 ? Math.max(...contextStarts) : Math.max(0, match.index - 500)
    const contextEnds = [
      html.indexOf('</tr>', match.index),
      html.indexOf('</li>', match.index),
      html.indexOf('</article>', match.index),
      html.indexOf('</div>', match.index),
    ].filter((index) => index > match.index)
    const contextEnd = contextEnds.length > 0
      ? Math.min(...contextEnds) + 10
      : Math.min(html.length, match.index + 900)
    const context = stripHtml(html.slice(contextStart, contextEnd))
    const title = (esTituloGenerico(anchorTitle) && context
      ? context
      : `${anchorTitle} ${context}`.trim())
      // El recorte de contexto puede partir una etiqueta a mitad ("<li"): fuera.
      .replace(/<[^>]*$/, '')
      .replace(/^[^>]*>/, '')
      .trim()
    const key = `${link}|${title.slice(0, 100)}`
    if (!title || seen.has(key) || esTituloGenerico(title) || !esConvocatoriaInscribibleNormalizada(title)) continue
    seen.add(key)
    items.push({
      title: title.slice(0, 500),
      link,
      sourceName: source.name,
      sourceScope: source.scope,
    })
    if (items.length >= MAX_ITEMS_PER_HTML_SOURCE) break
  }
  return items
}

function esTituloGenerico(title: string): boolean {
  const t = normalizeText(title)
  return !t ||
    t.length < 18 ||
    /^(pdf|html|xml|ver|abrir|descargar|descarga|anuncio|documento|texto|sumario|mas informacion|detalle|consultar|enlace)$/.test(t) ||
    // Cabeceras de seccion y artefactos de feeds, no convocatorias reales
    /^(i|ii|iii|iv|v|vi)[.\s]*(oposicion|oposicio|concurso)/.test(t) ||
    /oposicions? e concursos/.test(t) ||
    /^rss/i.test(t) ||
    t.includes('<')
}

function esConvocatoriaInscribibleNormalizada(title: string): boolean {
  const t = normalizeText(title)
  // Exclusiones en castellano, catalan/valenciano, gallego y euskera: actos que
  // NO son convocatorias inscribibles (nombramientos, listas, revocaciones,
  // resoluciones judiciales, bolsas, subvenciones...).
  if (/(nombramiento|nombramientos|nomenament|nomeamento|izendapen|adjudica|adjudican|relacion de aprobados|lista de admitidos|lista provisional|lista definitiva|listaxe|llista|tribunal calificador|tribunal cualificador|bolsa de empleo|bolsa de trabajo|bolsa de emprego|borsa de treball|lista de espera|subvencion|subvenciones|subvencio|axuda|libre designacion|cargo intermedio|ofertan vacantes|personal aspirante seleccionado|organizaciones sindicales|voluntariado|extracto de convocatoria de subvenciones|revocado|revocada|revocacion|revogacion|revocacio|dejado sin efecto|deixa sense efecte|sen efecto|desistimiento|desistimento|desistiment|ejecucion de sentencia|execucion de sentenza|execucio de sentencia|sentenza|sentencia judicial|remision ao tribunal|remision al tribunal|contencioso[- ]administrativ|nulidad|nulidade|nulitat|en practicas|en practiques|funcionaria en practicas|funcionario en practicas|rectificacion da convocatoria|rectificacion de la convocatoria|correccion de erro|correccion de error|modificacion del tribunal|composicion del tribunal|designacion de tribunal)/.test(t)) {
    return false
  }
  return /(oposicion|oposiciones|concurso-oposicion|proceso selectivo|procesos selectivos|proceso de selecc|pruebas selectivas|convocatoria.*plazas|convoca.*plazas|plazas?.*(funcionario|funcionaria|laboral|estatutario|estatutaria|administrativo|auxiliar|tecnico|policia|bombero)|personal .*fijo|profesor permanente laboral|funcionario de carrera|funcionaria de carrera|estatutario fijo|estatutaria fija|concurso oposicion)/.test(t)
}

/**
 * Defensa anti-SSRF: las URLs provienen de la tabla `boletines` y de variables
 * de entorno, no solo de la lista fija. Solo permitimos http(s) hacia hosts
 * públicos; bloqueamos localhost, IPs privadas/loopback y el metadata endpoint
 * de cloud (169.254.169.254).
 */
function esUrlPublicaSegura(url: string): boolean {
  let u: URL
  try {
    u = new URL(url)
  } catch (_) {
    return false
  }
  if (u.protocol !== 'http:' && u.protocol !== 'https:') return false

  const host = u.hostname.toLowerCase()
  if (
    host === 'localhost' ||
    host === '0.0.0.0' ||
    host === '::1' ||
    host.endsWith('.localhost') ||
    host.endsWith('.internal') ||
    host.endsWith('.local')
  ) {
    return false
  }
  // IPv4 privadas / loopback / link-local (incluye metadata 169.254.169.254)
  const m = host.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
  if (m) {
    const [a, b] = [Number(m[1]), Number(m[2])]
    if (
      a === 10 ||
      a === 127 ||
      (a === 192 && b === 168) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 169 && b === 254) ||
      a === 0
    ) {
      return false
    }
  }
  return true
}

// Muchas sedes oficiales bloquean User-Agents no-navegador (falsos positivos de
// WAF). Nos identificamos como un navegador real para un agregador legítimo de
// datos públicos.
const BROWSER_UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

async function fetchWithTimeout(
  url: string,
  timeoutMs: number,
  extraHeaders: Record<string, string> = {},
): Promise<Response | null> {
  if (!esUrlPublicaSegura(url)) return null

  const intento = async (): Promise<Response | null> => {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), timeoutMs)
    try {
      return await fetch(url, {
        signal: controller.signal,
        headers: {
          'User-Agent': BROWSER_UA,
          'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,text/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'es-ES,es;q=0.9',
          ...extraHeaders,
        },
      })
    } catch (_) {
      return null
    } finally {
      clearTimeout(timeout)
    }
  }

  // Hasta 2 intentos ante fallos transitorios (timeout/red/WAF) de sedes lentas,
  // con un breve backoff. Más reintentos alargan la ejecución y provocan 502
  // del gateway sin apenas mejorar la cobertura.
  for (let i = 0; i < 2; i++) {
    const resp = await intento()
    if (resp) return resp
    if (i < 1) await new Promise((r) => setTimeout(r, 500))
  }
  return null
}

async function mapLimit<T, R>(
  values: T[],
  limit: number,
  mapper: (value: T) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(values.length)
  let nextIndex = 0

  async function worker() {
    while (nextIndex < values.length) {
      const index = nextIndex
      nextIndex++
      results[index] = await mapper(values[index])
    }
  }

  await Promise.all(
    Array.from({ length: Math.min(limit, values.length) }, () => worker()),
  )
  return results
}

// ── BOE: API de datos abiertos ──────────────────────────────────────────────
// El RSS del BOE (canal.php) viene vacío. La API oficial de datos abiertos
// devuelve el sumario diario en JSON, del que extraemos la sección "2B"
// (II.B Oposiciones y concursos). Mucho más fiable que raspar HTML/RSS.

function esFuenteBoe(url: string): boolean {
  try {
    const host = new URL(url).hostname.toLowerCase()
    return host === 'boe.es' || host === 'www.boe.es'
  } catch (_) {
    return false
  }
}

function toArray<T>(value: T | T[] | undefined | null): T[] {
  if (value === undefined || value === null) return []
  return Array.isArray(value) ? value : [value]
}

function fechasBoeRecientes(dias: number): string[] {
  const out: string[] = []
  const hoy = new Date()
  for (let i = 0; i < dias; i++) {
    const d = new Date(hoy)
    d.setUTCDate(d.getUTCDate() - i)
    const y = d.getUTCFullYear()
    const m = String(d.getUTCMonth() + 1).padStart(2, '0')
    const day = String(d.getUTCDate()).padStart(2, '0')
    out.push(`${y}${m}${day}`)
  }
  return out
}

async function fetchBoeOposiciones(source: FuenteConvocatorias): Promise<RssItem[]> {
  const items: RssItem[] = []
  const vistos = new Set<string>()

  // BOE publica de lunes a sábado; el cron corre temprano, así que revisamos
  // los últimos días para no perder ediciones recientes.
  for (const fecha of fechasBoeRecientes(3)) {
    const resp = await fetchWithTimeout(
      `https://www.boe.es/datosabiertos/api/boe/sumario/${fecha}`,
      SOURCE_FETCH_TIMEOUT_MS,
      { 'Accept': 'application/json' },
    )
    if (!resp || !resp.ok) continue

    let data: Record<string, unknown>
    try {
      data = await resp.json()
    } catch (_) {
      continue
    }

    const sumario = (data as { data?: { sumario?: { diario?: unknown } } })?.data?.sumario
    const fechaIso = `${fecha.slice(0, 4)}-${fecha.slice(4, 6)}-${fecha.slice(6, 8)}`

    for (const diario of toArray(sumario?.diario as unknown)) {
      for (const seccion of toArray((diario as { seccion?: unknown })?.seccion)) {
        if (String((seccion as { codigo?: unknown })?.codigo ?? '') !== '2B') continue
        for (const dep of toArray((seccion as { departamento?: unknown })?.departamento)) {
          const epigrafes = toArray((dep as { epigrafe?: unknown })?.epigrafe)
          const itemsDep = epigrafes.length > 0
            ? epigrafes.flatMap((ep) => toArray((ep as { item?: unknown })?.item))
            : toArray((dep as { item?: unknown })?.item)

          for (const it of itemsDep) {
            const item = it as { titulo?: unknown; url_html?: unknown; url_pdf?: { texto?: unknown } }
            const titulo = String(item?.titulo ?? '').trim()
            const link = String(item?.url_html ?? item?.url_pdf?.texto ?? '').trim()
            if (!titulo || !link || vistos.has(link)) continue
            vistos.add(link)
            items.push({
              title: titulo,
              link,
              pubDate: fechaIso,
              sourceName: source.name,
              sourceScope: source.scope,
            })
          }
        }
      }
    }
  }

  return items
}

async function fetchFuente(source: FuenteConvocatorias): Promise<RssItem[]> {
  if (esFuenteBoe(source.url)) {
    return await fetchBoeOposiciones(source)
  }
  const response = await fetchWithTimeout(source.url, SOURCE_FETCH_TIMEOUT_MS)
  if (!response) throw new Error('No se pudo conectar con la fuente')
  if (!response.ok) throw new Error(`HTTP ${response.status}`)
  const text = await response.text()
  return source.type === 'html'
    ? parseHtmlItems(text, source)
    : parseFeedItems(text, source)
}

function esConvocatoriaInscribible(title: string): boolean {
  const t = title.toLowerCase()
  if (/(nombramiento|nombramientos|adjudica|adjudican|relacion de aprobados|lista de admitidos|tribunal calificador|bolsa de empleo|subvenci[oó]n|subvenciones|libre designaci[oó]n|cargo intermedio|ofertan vacantes|personal aspirante seleccionado|organizaciones sindicales|voluntariado)/.test(t)) {
    return false
  }
  return /(oposici[oó]n|oposiciones|concurso-oposici[oó]n|proceso selectivo|pruebas selectivas|plazas?|personal .*fijo|profesor permanente laboral|funcionari[oa]|estatutari[oa] fijo)/.test(t)
}

function parseFechaPublicacion(item: RssItem): Date {
  const parsed = item.pubDate ? new Date(item.pubDate) : null
  if (parsed && !Number.isNaN(parsed.getTime())) return parsed
  return new Date()
}

function parseFechaEspanola(texto: string): Date | null {
  const meses: Record<string, number> = {
    enero: 0,
    febrero: 1,
    marzo: 2,
    abril: 3,
    mayo: 4,
    junio: 5,
    julio: 6,
    agosto: 7,
    septiembre: 8,
    setiembre: 8,
    octubre: 9,
    noviembre: 10,
    diciembre: 11,
  }

  const normalizado = texto.toLowerCase()
  const textoFecha = normalizado.match(/(\d{1,2})\s+de\s+([a-záéíóúñ]+)\s+de\s+(\d{4})/)
  if (textoFecha) {
    const mes = meses[textoFecha[2]]
    if (mes !== undefined) {
      return new Date(Number(textoFecha[3]), mes, Number(textoFecha[1]))
    }
  }

  const numerica = normalizado.match(/\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b/)
  if (numerica) {
    return new Date(Number(numerica[3]), Number(numerica[2]) - 1, Number(numerica[1]))
  }

  return null
}

function numeroDesdeTexto(value: string): number | null {
  const limpio = value.toLowerCase().trim()
  if (/^\d+$/.test(limpio)) return Number(limpio)
  return NUMEROS[limpio] ?? null
}

function addDiasNaturales(fecha: Date, dias: number): Date {
  const result = new Date(fecha)
  result.setDate(result.getDate() + dias)
  return result
}

function addDiasHabiles(fecha: Date, dias: number): Date {
  const result = new Date(fecha)
  let restantes = dias
  while (restantes > 0) {
    result.setDate(result.getDate() + 1)
    const day = result.getDay()
    if (day !== 0 && day !== 6) restantes--
  }
  return result
}

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10)
}

function calcularPlazo(texto: string, fechaPublicacion: Date): { inicio: Date; fin: Date; notas: string } | null {
  const lower = texto.toLowerCase()
  const match = lower.match(/plazo de\s+(\d+|un|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce|trece|catorce|quince|veinte|treinta)\s+d[ií]as\s+(h[aá]biles|naturales)/)
  if (!match) return null

  const dias = numeroDesdeTexto(match[1])
  if (!dias) return null

  const tipo = match[2].includes('h') ? 'habiles' : 'naturales'
  const inicio = addDiasNaturales(fechaPublicacion, 1)
  const fin = tipo === 'habiles'
    ? addDiasHabiles(fechaPublicacion, dias)
    : addDiasNaturales(fechaPublicacion, dias)

  return {
    inicio,
    fin,
    notas: `Plazo calculado desde el texto oficial de la fuente: ${dias} dias ${tipo}. No incluye festivos autonomicos o locales.`,
  }
}

function calcularPlazoNormalizado(texto: string, fechaPublicacion: Date): { inicio: Date; fin: Date; notas: string } | null {
  const lower = normalizeText(texto)
  const match =
    lower.match(/plazo(?:\s+de\s+(?:presentacion|solicitudes|instancias|presentacion de solicitudes))?(?:\s+sera)?(?:\s+es)?(?:\s+de)?\s+(\d+|un|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce|trece|catorce|quince|veinte|treinta)\s+dias\s+(habiles|naturales)/) ??
    lower.match(/(\d+|un|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce|trece|catorce|quince|veinte|treinta)\s+dias\s+(habiles|naturales).*?(?:a partir del dia siguiente|desde el dia siguiente|contados a partir)/)
  if (!match) return null

  const dias = numeroDesdeTexto(match[1])
  if (!dias) return null

  const tipo = match[2].includes('habil') ? 'habiles' : 'naturales'
  const inicio = addDiasNaturales(fechaPublicacion, 1)
  const fin = tipo === 'habiles'
    ? addDiasHabiles(fechaPublicacion, dias)
    : addDiasNaturales(fechaPublicacion, dias)

  return {
    inicio,
    fin,
    notas: `Plazo calculado desde el texto oficial de la fuente: ${dias} dias ${tipo}. No incluye festivos autonomicos o locales.`,
  }
}

function extraerPlazas(texto: string): number | null {
  const match = texto.match(/(\d{1,4})\s+plazas?/i)
  if (!match) return null
  const n = Number(match[1])
  // Tope de cordura: una convocatoria individual rara vez supera 2000 plazas;
  // números mayores suelen ser artefactos del raspado (número de boletín, año...).
  return n > 0 && n <= 2000 ? n : null
}

function nombreDesdeTitulo(title: string): string {
  return title
    // Artefactos del raspado: prefijos "PDF - BOP-XX-fecha.pdf" o "PDF" sueltos
    .replace(/^PDF\s*-?\s*[\w.-]*\.pdf\s*/i, '')
    .replace(/^PDF\s+/i, '')
    .replace(/^Resoluci[oó]n.*?,\s*de\s+.*?,\s*/i, '')
    .replace(/^Orden.*?,\s*de\s+.*?,\s*/i, '')
    .replace(/^Anuncio.*?,\s*de\s+.*?,\s*/i, '')
    .replace(/por la que se convocan?/i, 'Convocatoria de')
    .replace(/se convocan?/i, 'Convocatoria de')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 160)
}

/// Ámbito (estatal/autonomico/provincial/local/universidad) y territorio
/// legible, derivados del ámbito de la fuente y del organismo detectado.
/// Alimenta los filtros de búsqueda de la app.
function ambitoYTerritorio(
  sourceScope: string,
  administracion: string,
): { ambito: string; territorio: string } {
  const adminNorm = normalizeText(administracion)
  const scope = sourceScope.trim()

  let ambito: string
  let territorio: string
  if (scope === 'Estatal') {
    ambito = 'estatal'
    territorio = 'España'
  } else if (scope.startsWith('Provincia de ')) {
    ambito = 'provincial'
    territorio = scope.slice('Provincia de '.length)
  } else {
    ambito = 'autonomico'
    territorio = scope
  }

  if (/^(ayuntamiento|concello|ajuntament)/.test(adminNorm)) {
    ambito = 'local'
    const paren = administracion.match(/\(([^)]+)\)/)
    if (paren) territorio = paren[1].trim()
  } else if (adminNorm.startsWith('universidad')) {
    ambito = 'universidad'
    territorio = administracion.replace(/^Universidad (de |del )?/i, '').trim()
  } else if (adminNorm.startsWith('diputacion')) {
    ambito = 'provincial'
    territorio = administracion.replace(/^Diputaci[oó]n (Provincial )?de /i, '').trim()
  }

  return { ambito, territorio }
}

function administracionDesdeTitulo(title: string, fallback: string): string {
  const universidad = title.match(/Universidad de ([A-ZÁÉÍÓÚÑ][^,.]+)/)
  if (universidad) return `Universidad de ${universidad[1].trim()}`

  const ayuntamiento = title.match(/Ayuntamiento de ([A-ZÁÉÍÓÚÑ][^,.]+)/)
  if (ayuntamiento) return `Ayuntamiento de ${ayuntamiento[1].trim()}`

  const diputacion = title.match(/Diputaci[oó]n (?:Provincial )?de ([A-ZÁÉÍÓÚÑ][^,.]+)/)
  if (diputacion) return `Diputacion de ${diputacion[1].trim()}`

  return fallback
}

function valorTexto(value: unknown): string | null {
  if (value === undefined || value === null || value === '') return null
  return String(value)
}

function valorFecha(value: unknown): string | null {
  if (!value) return null
  if (value instanceof Date) return formatDate(value)
  return String(value).slice(0, 10)
}

function detectarCambiosConvocatoria(actual: Record<string, unknown>, nuevo: Record<string, unknown>) {
  const campos = [
    'fecha_publicacion_boe',
    'fecha_inicio_instancias',
    'fecha_fin_instancias',
    'fecha_examen',
    'plazas',
    'estado',
    'notas',
  ]

  return campos
    .map((campo) => ({
      campo,
      anterior: valorTexto(actual[campo]),
      nuevo: valorTexto(nuevo[campo]),
    }))
    .filter((cambio) => cambio.anterior !== cambio.nuevo)
}

function tituloCambio(cambios: Array<{ campo: string }>): string {
  if (cambios.some((c) => c.campo === 'fecha_fin_instancias')) {
    return 'Cambio en el plazo de inscripción'
  }
  if (cambios.some((c) => c.campo === 'fecha_examen')) {
    return 'Cambio en la fecha de examen'
  }
  if (cambios.some((c) => c.campo === 'plazas')) {
    return 'Cambio en el número de plazas'
  }
  return 'Cambio en una convocatoria'
}

async function crearNotificacion(
  supabase: ReturnType<typeof createClient>,
  params: {
    convocatoriaId: string
    oposicionId: string
    tipo: string
    titulo: string
    mensaje: string
    metadata?: Record<string, unknown>
    // "Sigue tu territorio": si viene informado, también se notifica a los
    // usuarios suscritos a este territorio aunque no sigan la oposición.
    territorio?: string | null
  },
) {
  const { data: notificacion, error } = await supabase
    .from('notificaciones_convocatoria')
    .insert({
      convocatoria_id: params.convocatoriaId,
      tipo: params.tipo,
      titulo: params.titulo,
      mensaje: params.mensaje,
      metadata: params.metadata ?? {},
      enviada: false,
    })
    .select('id')
    .single()

  if (error || !notificacion) return

  const destinatarios = new Map<string, { push: boolean; email: boolean }>()

  const { data: seguidores } = await supabase
    .from('usuario_oposiciones')
    .select('usuario_id')
    .eq('oposicion_id', params.oposicionId)
    .eq('activa', true)

  for (const seguidor of seguidores ?? []) {
    destinatarios.set(seguidor.usuario_id, { push: true, email: true })
  }

  // Suscriptores del territorio de la convocatoria ("Sigue tu territorio").
  // Las preferencias push/email reales se respetan en send-notifications.
  if (params.tipo === 'nueva_convocatoria' && params.territorio) {
    const { data: suscriptores } = await supabase
      .from('usuario_territorios')
      .select('usuario_id')
      .eq('territorio', params.territorio)
      .eq('activa', true)

    for (const sus of suscriptores ?? []) {
      destinatarios.set(sus.usuario_id, { push: true, email: true })
    }
  }

  if (params.tipo === 'nueva_convocatoria' && Deno.env.get('NOTIFY_ALL_NEW_CONVOCATORIAS') === 'true') {
    const { data: usuarios } = await supabase
      .from('perfiles')
      .select('id, notificaciones_push, notificaciones_email')

    for (const usuario of usuarios ?? []) {
      destinatarios.set(usuario.id, {
        push: usuario.notificaciones_push !== false,
        email: usuario.notificaciones_email !== false,
      })
    }
  }

  const rows = [...destinatarios.entries()].flatMap(([usuarioId, prefs]) => {
    const canales = ['in_app']
    if (prefs.push) canales.push('push')
    if (prefs.email) canales.push('email')
    return canales.map((canal) => ({
      notificacion_id: notificacion.id,
      usuario_id: usuarioId,
      canal,
      estado: 'pendiente',
    }))
  })

  if (rows.length > 0) {
    await supabase.from('notificacion_destinatarios').upsert(rows, {
      onConflict: 'notificacion_id,usuario_id,canal',
    })
  }
}

// ── SEO con IA ──────────────────────────────────────────────────────────────
// Los títulos de los boletines son largos y burocráticos. Para cada oposición
// nueva pedimos a Claude un título (~60 chars) y una meta description (~155)
// limpios. Best-effort: sin ANTHROPIC_API_KEY o ante cualquier fallo, se omite
// y la página SEO usa el nombre original.
const SEO_IA_TIMEOUT_MS = 9000
const SEO_IA_MAX_POR_EJECUCION = 15

async function generarSeoConIa(
  tituloOficial: string,
  administracion: string,
  plazas: number | null,
): Promise<{ titulo: string; descripcion: string } | null> {
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!apiKey) return null

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), SEO_IA_TIMEOUT_MS)
  try {
    const resp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 300,
        messages: [{
          role: 'user',
          content: `Eres experto en SEO para un portal español de oposiciones. A partir de este anuncio oficial, genera un título SEO y una meta description en castellano.

Anuncio oficial: ${tituloOficial.slice(0, 400)}
Administración: ${administracion}
${plazas ? `Plazas: ${plazas}` : ''}

Reglas:
- titulo: máximo 60 caracteres, claro y buscable (puesto + organismo). Sin comillas ni "Convocatoria de" al inicio si se puede evitar.
- descripcion: máximo 155 caracteres, incluye plazas si las hay y una llamada a consultar plazos y preparar la oposición.

Responde SOLO con JSON válido: {"titulo":"...","descripcion":"..."}`,
        }],
      }),
    })
    if (!resp.ok) return null
    const data = await resp.json()
    const texto: string = data?.content?.[0]?.text ?? ''
    const jsonMatch = texto.match(/\{[\s\S]*\}/)
    if (!jsonMatch) return null
    const parsed = JSON.parse(jsonMatch[0])
    const titulo = String(parsed.titulo ?? '').trim().slice(0, 70)
    const descripcion = String(parsed.descripcion ?? '').trim().slice(0, 170)
    if (!titulo || !descripcion) return null
    return { titulo, descripcion }
  } catch (_) {
    return null
  } finally {
    clearTimeout(timeout)
  }
}

function escapeHtml(texto: string): string {
  return texto
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

/**
 * Envía al administrador un resumen de la ejecución del monitor: cuántas
 * convocatorias se publicaron y, sobre todo, qué fuentes fallaron (posibles
 * huecos de cobertura). Best-effort: si no hay Resend/ADMIN configurado, no hace
 * nada. Requiere RESEND_API_KEY, RESEND_FROM_EMAIL y ADMIN_ALERT_EMAIL.
 */
async function enviarResumenAdmin(resumen: {
  publicadas: number
  publicadasSinPlazo: number
  yaExistentes: number
  descartadasCerradas: number
  fuentesOk: number
  fuentesSinResultados: number
  fuentesError: Array<{ nombre: string; error: string }>
}): Promise<string> {
  const brevoKey = Deno.env.get('BREVO_API_KEY')
  const resendKey = Deno.env.get('RESEND_API_KEY')
  const adminEmail = Deno.env.get('ADMIN_ALERT_EMAIL')
  const from = Deno.env.get('EMAIL_FROM') || Deno.env.get('RESEND_FROM_EMAIL') ||
    'Oposiwork <notificaciones@oposiwork.com>'
  if ((!brevoKey && !resendKey) || !adminEmail) return 'omitido: sin proveedor o sin ADMIN_ALERT_EMAIL'

  const listaErrores = resumen.fuentesError.length > 0
    ? `<ul>${resumen.fuentesError
        .map((f) => `<li>${escapeHtml(f.nombre)} — ${escapeHtml(f.error || 'sin detalle')}</li>`)
        .join('')}</ul>`
    : '<p>Ninguna fuente falló. 🎉</p>'

  const html = `
    <h2>Resumen del monitor de convocatorias</h2>
    <p><strong>${resumen.publicadas}</strong> convocatorias nuevas publicadas
       (${resumen.publicadasSinPlazo} con plazo estimado),
       ${resumen.yaExistentes} ya existentes,
       ${resumen.descartadasCerradas} descartadas por plazo cerrado.</p>
    <p>Fuentes: <strong>${resumen.fuentesOk}</strong> OK,
       ${resumen.fuentesSinResultados} sin resultados,
       <strong>${resumen.fuentesError.length}</strong> con error.</p>
    <h3>Fuentes con error (posibles huecos de cobertura)</h3>
    ${listaErrores}
    <p style="color:#666;font-size:12px">Enviado automáticamente por monitor-boe.</p>
  `

  const asunto = resumen.fuentesError.length > 0
    ? `⚠️ Monitor oposiciones: ${resumen.publicadas} nuevas · ${resumen.fuentesError.length} fuentes con error`
    : `✅ Monitor oposiciones: ${resumen.publicadas} nuevas · todas las fuentes OK`

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 8000)
  try {
    if (brevoKey) {
      // Brevo (Sendinblue): el remitente debe estar verificado en la cuenta.
      const remitente = from.match(/^(.*?)\s*<([^>]+)>$/)
      const sender = remitente
        ? { name: remitente[1].trim() || 'Oposiwork', email: remitente[2].trim() }
        : { name: 'Oposiwork', email: from.trim() }
      const resp = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'api-key': brevoKey,
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify({
          sender,
          to: [{ email: adminEmail }],
          subject: asunto,
          htmlContent: html,
        }),
        signal: controller.signal,
      })
      if (!resp.ok) return `error brevo ${resp.status}: ${(await resp.text()).slice(0, 200)}`
      return 'enviado (brevo)'
    }
    const resp = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ from, to: adminEmail, subject: asunto, html }),
      signal: controller.signal,
    })
    if (!resp.ok) return `error resend ${resp.status}: ${(await resp.text()).slice(0, 200)}`
    return 'enviado (resend)'
  } catch (err) {
    return `excepcion: ${String(err).slice(0, 200)}`
  } finally {
    clearTimeout(timeout)
  }
}

Deno.serve(async (req) => {
  try {
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

    const hoy = new Date()
    const hoyIso = formatDate(hoy)

    const { data: expiradas } = await supabase
      .from('convocatorias')
      .select('id, oposicion_id, fecha_fin_instancias, estado, oposiciones(nombre)')
      .lt('fecha_fin_instancias', hoyIso)
      .eq('estado', 'abierta')

    for (const expirada of expiradas ?? []) {
      await supabase
        .from('convocatorias')
        .update({ estado: 'cerrada' })
        .eq('id', expirada.id)

      await supabase.from('convocatoria_cambios').insert({
        convocatoria_id: expirada.id,
        oposicion_id: expirada.oposicion_id,
        tipo: 'convocatoria_cerrada',
        campo: 'estado',
        valor_anterior: 'abierta',
        valor_nuevo: 'cerrada',
        metadata: { fecha_fin_instancias: expirada.fecha_fin_instancias },
      })

      await crearNotificacion(supabase, {
        convocatoriaId: expirada.id,
        oposicionId: expirada.oposicion_id,
        tipo: 'convocatoria_cerrada',
        titulo: 'Plazo de inscripción cerrado',
        mensaje: `Ha finalizado el plazo de inscripción de ${expirada.oposiciones?.nombre ?? 'una oposición que sigues'}.`,
        metadata: { fecha_fin_instancias: expirada.fecha_fin_instancias },
      })
    }

    const fuentesDb = await cargarFuentesDesdeDb(supabase)
    // FUENTES_BASE va primero: es la lista mantenida en código, con URLs corregidas
    // y overrides. Así, ante URLs equivalentes, gana la del código y no la copia
    // (a menudo peor) de la tabla `boletines`.
    const fuentes = combinarFuentes(FUENTES_BASE, fuentesDb, parseExtraSources())
    const auditoria = await mapLimit(fuentes, SOURCE_CONCURRENCY, async (source) => {
      try {
        const itemsFuente = await fetchFuente(source)
        const estado = itemsFuente.length > 0 ? 'ok' : 'sin_resultados'
        await supabase.from('fuente_auditoria').insert({
          fuente_nombre: source.name,
          fuente_url: source.url,
          ambito: source.scope,
          estado,
          items_detectados: itemsFuente.length,
        })
        return { source, items: itemsFuente, estado, error: null as string | null }
      } catch (err) {
        const mensaje = err.message ?? String(err)
        await supabase.from('fuente_auditoria').insert({
          fuente_nombre: source.name,
          fuente_url: source.url,
          ambito: source.scope,
          estado: 'error',
          items_detectados: 0,
          error: mensaje,
        })
        return { source, items: [] as RssItem[], estado: 'error', error: mensaje }
      }
    })
    const items = auditoria
      .flatMap((a) => a.items)
      .filter((item) => esConvocatoriaInscribibleNormalizada(item.title))
      .slice(0, MAX_DETAIL_ITEMS)
    let publicadas = 0
    let publicadasSinPlazo = 0
    let descartadasCerradas = 0
    let yaExistentes = 0
    let seoGenerados = 0
    const inicioBucle = Date.now()

    for (const item of items) {
      // Presupuesto de tiempo: si se agota, paramos y devolvemos lo hecho.
      if (Date.now() - inicioBucle > PUBLISH_TIME_BUDGET_MS) break
      const existente = await supabase
        .from('convocatorias')
        .select('id, oposicion_id, fecha_publicacion_boe, fecha_inicio_instancias, fecha_fin_instancias, fecha_examen, plazas, estado, notas')
        .eq('url_boe', item.link)
        .maybeSingle()

      let texto = item.title
      const detalle = await fetchWithTimeout(item.link, DETAIL_FETCH_TIMEOUT_MS)
      if (detalle?.ok) {
        const contentType = detalle.headers.get('content-type') ?? ''
        if (!contentType.includes('pdf')) {
          texto = `${item.title} ${stripHtml(await detalle.text())}`
        }
      }

      const fechaPublicacion = item.pubDate
        ? parseFechaPublicacion(item)
        : parseFechaEspanola(texto) ?? parseFechaPublicacion(item)
      const plazoDetectado = calcularPlazoNormalizado(texto, fechaPublicacion) ?? calcularPlazo(texto, fechaPublicacion)
      let plazo = plazoDetectado
      let plazoEstimado = false
      if (!plazo) {
        // No se pudo extraer el plazo del texto: publicamos igualmente con una
        // fecha de fin estimada para no perder la convocatoria.
        plazo = {
          inicio: addDiasNaturales(fechaPublicacion, 1),
          fin: addDiasNaturales(fechaPublicacion, DEFAULT_PLAZO_DIAS_ESTIMADO),
          notas: `Plazo no detectado automaticamente; fecha de fin ESTIMADA (${DEFAULT_PLAZO_DIAS_ESTIMADO} dias). Confirma el plazo real en la fuente oficial.`,
        }
        plazoEstimado = true
      }
      // Si el plazo (real o estimado) ya venció, la consideramos cerrada y no la publicamos.
      if (plazo.fin < hoy) {
        descartadasCerradas++
        continue
      }

      const nombre = nombreDesdeTitulo(item.title)
      const administracion = administracionDesdeTitulo(item.title, item.sourceScope)
      const boeId = item.link.match(/id=([^&]+)/)?.[1]?.toLowerCase() ?? slugify(item.link)
      const slug = slugify(`${nombre}-${boeId}`)
      // Solo del título oficial: el texto completo de la página produce falsos
      // positivos (números de boletín, expedientes...).
      const plazas = extraerPlazas(item.title)

      const clasificacion = ambitoYTerritorio(item.sourceScope, administracion)
      const { data: oposicion, error: opError } = await supabase
        .from('oposiciones')
        .upsert({
          slug,
          nombre,
          cuerpo: nombre,
          administracion,
          nivel: 'N/D',
          ambito: clasificacion.ambito,
          territorio: clasificacion.territorio,
          tiene_psicotecnicos: false,
          tiene_pruebas_fisicas: false,
          activa: true,
        }, { onConflict: 'slug' })
        .select('id')
        .single()

      if (opError || !oposicion) continue

      const nuevaConvocatoria = {
        oposicion_id: oposicion.id,
        fecha_publicacion_boe: formatDate(fechaPublicacion),
        fecha_inicio_instancias: formatDate(plazo.inicio),
        fecha_fin_instancias: formatDate(plazo.fin),
        fecha_examen: null,
        fecha_examen_confirmada: false,
        plazas,
        estado: 'abierta',
        url_boe: item.link,
        notas: `${plazo.notas} Fuente: ${item.sourceName}.`,
      }

      if (existente.data) {
        const cambios = detectarCambiosConvocatoria(existente.data, nuevaConvocatoria)
        if (cambios.length > 0) {
          const { error: updateError } = await supabase
            .from('convocatorias')
            .update(nuevaConvocatoria)
            .eq('id', existente.data.id)

          if (!updateError) {
            await supabase.from('convocatoria_cambios').insert(
              cambios.map((cambio) => ({
                convocatoria_id: existente.data.id,
                oposicion_id: existente.data.oposicion_id,
                tipo: 'cambio_convocatoria',
                campo: cambio.campo,
                valor_anterior: cambio.anterior,
                valor_nuevo: cambio.nuevo,
                fuente_url: item.link,
                metadata: { fuente: item.sourceName },
              })),
            )

            await crearNotificacion(supabase, {
              convocatoriaId: existente.data.id,
              oposicionId: existente.data.oposicion_id,
              tipo: 'cambio_convocatoria',
              titulo: tituloCambio(cambios),
              mensaje: `Se ha detectado una modificación en ${nombre}. Revisa la ficha de la convocatoria.`,
              metadata: { cambios, fuente: item.sourceName, url: item.link },
            })
          }
        }
        yaExistentes++
        continue
      }

      const { data: convocatoria, error: convError } = await supabase
        .from('convocatorias')
        .insert({
          ...nuevaConvocatoria,
        })
        .select('id')
        .single()

      if (!convError && convocatoria) {
        publicadas++
        if (plazoEstimado) publicadasSinPlazo++
        await supabase.from('convocatoria_cambios').insert({
          convocatoria_id: convocatoria.id,
          oposicion_id: oposicion.id,
          tipo: 'nueva_convocatoria',
          campo: 'convocatoria',
          valor_anterior: null,
          valor_nuevo: nombre,
          fuente_url: item.link,
          metadata: { fuente: item.sourceName },
        })

        await crearNotificacion(supabase, {
          convocatoriaId: convocatoria.id,
          oposicionId: oposicion.id,
          tipo: 'nueva_convocatoria',
          titulo: 'Nueva convocatoria abierta',
          mensaje: plazoEstimado
            ? `${nombre} tiene el plazo de inscripción abierto. Confirma la fecha límite en la fuente oficial.`
            : `${nombre} tiene plazo de inscripción abierto hasta el ${formatDate(plazo.fin)}.`,
          metadata: { fuente: item.sourceName, url: item.link, fecha_fin_instancias: formatDate(plazo.fin), plazo_estimado: plazoEstimado },
          territorio: clasificacion.territorio,
        })

        // SEO con IA para la oposición recién creada (best-effort, acotado).
        if (seoGenerados < SEO_IA_MAX_POR_EJECUCION) {
          const seo = await generarSeoConIa(item.title, administracion, plazas)
          if (seo) {
            await supabase
              .from('oposiciones')
              .update({ seo_titulo: seo.titulo, seo_descripcion: seo.descripcion })
              .eq('id', oposicion.id)
            seoGenerados++
          }
        }
      }
    }

    // ── Alerta diaria de salud de fuentes ────────────────────────────────────
    // Enviamos un resumen al administrador para SABER cuándo una fuente deja de
    // funcionar (y por tanto podríamos estar perdiendo convocatorias) en vez de
    // enterarnos por casualidad. Best-effort: nunca hace fallar el monitor.
    const fuentesError = auditoria.filter((a) => a.estado === 'error')
    const fuentesSinResultados = auditoria.filter((a) => a.estado === 'sin_resultados')
    const fuentesOk = auditoria.filter((a) => a.estado === 'ok')
    let emailAlerta = 'no intentado'
    try {
      emailAlerta = await enviarResumenAdmin({
        publicadas,
        publicadasSinPlazo,
        yaExistentes,
        descartadasCerradas,
        fuentesOk: fuentesOk.length,
        fuentesSinResultados: fuentesSinResultados.length,
        fuentesError: fuentesError.map((a) => ({ nombre: a.source.name, error: a.error ?? '' })),
      })
    } catch (err) {
      emailAlerta = `excepcion externa: ${String(err).slice(0, 200)}`
      console.error('monitor-boe: fallo al enviar resumen admin', err)
    }

    return new Response(
      JSON.stringify({
        procesados: items.length,
        fuentes_consultadas: fuentes.length,
        fuentes_ok: fuentesOk.length,
        fuentes_error: fuentesError.length,
        fuentes_sin_resultados: fuentesSinResultados.length,
        publicadas,
        publicadas_sin_plazo_estimado: publicadasSinPlazo,
        seo_ia_generados: seoGenerados,
        email_alerta: emailAlerta,
        ya_existentes: yaExistentes,
        descartadas_cerradas: descartadasCerradas,
        timestamp: new Date().toISOString(),
      }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('monitor-boe error', error)
    return new Response(JSON.stringify({ error: 'Error interno' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
