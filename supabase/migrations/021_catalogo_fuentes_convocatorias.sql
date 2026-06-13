-- Catalogo gestionable de fuentes oficiales para convocatorias.
-- Cubre:
-- - Nacional: BOE y Punto de Acceso General de empleo publico.
-- - Regional: boletines oficiales autonomicos y ciudades autonomas.
-- - Provincial/local: BOP provinciales, donde publican ayuntamientos y diputaciones.

CREATE TABLE IF NOT EXISTS public.boletines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT,
  source_key TEXT,
  nombre TEXT,
  ambito TEXT,
  territorio TEXT,
  url TEXT,
  tipo TEXT,
  activo BOOLEAN DEFAULT true,
  prioridad INTEGER DEFAULT 100,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS codigo TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS source_key TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS nombre TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS ambito TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS territorio TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS url TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS tipo TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS prioridad INTEGER DEFAULT 100;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS notas TEXT;
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.boletines ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS idx_boletines_source_key_unique
  ON public.boletines(source_key)
  WHERE source_key IS NOT NULL;

UPDATE public.boletines
SET codigo = COALESCE(codigo, source_key)
WHERE codigo IS NULL
  AND source_key IS NOT NULL;

ALTER TABLE public.boletines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS boletines_lectura_autenticada ON public.boletines;
CREATE POLICY boletines_lectura_autenticada
ON public.boletines
FOR SELECT
TO authenticated
USING (true);

INSERT INTO public.boletines (codigo, source_key, nombre, ambito, territorio, url, tipo, activo, prioridad, notas)
VALUES
  ('boe-oposiciones', 'boe-oposiciones', 'BOE - Oposiciones y concursos', 'nacional', 'Espana', 'https://www.boe.es/rss/canal.php?c=2', 'rss', true, 10, 'Canal RSS oficial del BOE.'),
  ('page-empleo-publico', 'page-empleo-publico', 'PAGe - Buscador de convocatorias de empleo publico', 'nacional', 'Espana', 'https://administracion.gob.es/pag_Home/es/empleoPublico/', 'html', true, 15, 'Punto de Acceso General de empleo publico.'),
  ('boa-aragon', 'BOA - Aragon', 'autonomico', 'Aragon', 'https://www.boa.aragon.es/', 'html', true, 50, NULL),
  ('boja-andalucia', 'BOJA - Oposiciones y concursos', 'autonomico', 'Andalucia', 'https://www.juntadeandalucia.es/boja/distribucion/s53.xml', 'atom', true, 50, NULL),
  ('bopa-asturias', 'BOPA - Asturias', 'autonomico', 'Asturias', 'https://sede.asturias.es/bopa', 'html', true, 50, NULL),
  ('boib-balears', 'BOIB - Illes Balears', 'autonomico', 'Illes Balears', 'https://www.caib.es/eboibfront/', 'html', true, 50, NULL),
  ('boc-canarias', 'BOC - Canarias', 'autonomico', 'Canarias', 'https://www.gobiernodecanarias.org/boc/', 'html', true, 50, NULL),
  ('boc-cantabria', 'BOC - Cantabria', 'autonomico', 'Cantabria', 'https://boc.cantabria.es/', 'html', true, 50, NULL),
  ('bocyl-castilla-leon', 'BOCYL - Castilla y Leon', 'autonomico', 'Castilla y Leon', 'https://bocyl.jcyl.es/', 'html', true, 50, NULL),
  ('docm-castilla-la-mancha', 'DOCM - Castilla-La Mancha', 'autonomico', 'Castilla-La Mancha', 'https://docm.jccm.es/', 'html', true, 50, NULL),
  ('dogc-catalunya', 'DOGC - Catalunya', 'autonomico', 'Catalunya', 'https://dogc.gencat.cat/', 'html', true, 50, NULL),
  ('dogv-comunitat-valenciana', 'DOGV - Comunitat Valenciana', 'autonomico', 'Comunitat Valenciana', 'https://dogv.gva.es/', 'html', true, 50, NULL),
  ('doe-extremadura', 'DOE - Extremadura', 'autonomico', 'Extremadura', 'https://doe.juntaex.es/', 'html', true, 50, NULL),
  ('dog-galicia', 'DOG - Galicia', 'autonomico', 'Galicia', 'https://www.xunta.gal/diario-oficial-galicia', 'html', true, 50, NULL),
  ('bocm-rss', 'BOCM - Ultimos boletines', 'autonomico', 'Comunidad de Madrid', 'https://www.bocm.es/boletines.rss', 'rss', true, 50, NULL),
  ('bocm-ultimo', 'BOCM - Ordenes del dia', 'autonomico', 'Comunidad de Madrid', 'https://www.bocm.es/ultimo-boletin.xml', 'rss', true, 50, NULL),
  ('borm-murcia', 'BORM - Region de Murcia', 'autonomico', 'Region de Murcia', 'https://www.borm.es/', 'html', true, 50, NULL),
  ('bon-navarra', 'BON - Navarra', 'autonomico', 'Navarra', 'https://bon.navarra.es/', 'html', true, 50, NULL),
  ('bopv-pais-vasco', 'BOPV - Pais Vasco', 'autonomico', 'Pais Vasco', 'https://www.euskadi.eus/bopv2/datos/Ultimo.shtml', 'html', true, 50, NULL),
  ('bor-la-rioja', 'BOR - La Rioja', 'autonomico', 'La Rioja', 'https://web.larioja.org/bor-portada', 'html', true, 50, NULL),
  ('bome-ceuta', 'BOME - Ceuta', 'autonomico', 'Ceuta', 'https://www.ceuta.es/ceuta/bome', 'html', true, 50, NULL),
  ('bome-melilla', 'BOME - Melilla', 'autonomico', 'Melilla', 'https://bomemelilla.es/', 'html', true, 50, NULL),
  ('bop-alava', 'BOP Alava', 'provincial', 'Alava', 'https://www.araba.eus/botha/', 'html', true, 80, NULL),
  ('bop-albacete', 'BOP Albacete', 'provincial', 'Albacete', 'https://www.dipualba.es/bop/', 'html', true, 80, NULL),
  ('bop-alicante', 'BOP Alicante', 'provincial', 'Alicante', 'https://bop.diputacionalicante.es/', 'html', true, 80, NULL),
  ('bop-almeria', 'BOP Almeria', 'provincial', 'Almeria', 'https://www.dipalme.org/Servicios/Boletin/Boletin.nsf', 'html', true, 80, NULL),
  ('bop-avila', 'BOP Avila', 'provincial', 'Avila', 'https://bop.diputacionavila.es/', 'html', true, 80, NULL),
  ('bop-badajoz', 'BOP Badajoz', 'provincial', 'Badajoz', 'https://www.dip-badajoz.es/bop/', 'html', true, 80, NULL),
  ('bop-barcelona-feed', 'BOP Barcelona - Boletin del dia', 'provincial', 'Barcelona', 'https://bop.diba.cat/dades-obertes/butlleti-del-dia/feed', 'rss', true, 80, NULL),
  ('bop-barcelona-local-feed', 'BOP Barcelona - Administracion local', 'provincial', 'Barcelona', 'https://bop.diba.cat/dades-obertes/butlleti-del-dia/administracio-local/feed', 'rss', true, 80, NULL),
  ('bop-bizkaia', 'BOP Bizkaia', 'provincial', 'Bizkaia', 'https://www.bizkaia.eus/lehendakaritza/Bao_bob/Boletines', 'html', true, 80, NULL),
  ('bop-burgos', 'BOP Burgos', 'provincial', 'Burgos', 'https://bopbur.diputaciondeburgos.es/', 'html', true, 80, NULL),
  ('bop-caceres', 'BOP Caceres', 'provincial', 'Caceres', 'https://bop.dip-caceres.es/', 'html', true, 80, NULL),
  ('bop-cadiz', 'BOP Cadiz', 'provincial', 'Cadiz', 'https://www.bopcadiz.es/index.html', 'html', true, 80, NULL),
  ('bop-castellon', 'BOP Castellon', 'provincial', 'Castellon', 'https://bop.dipcas.es/', 'html', true, 80, NULL),
  ('bop-ciudad-real', 'BOP Ciudad Real', 'provincial', 'Ciudad Real', 'https://bop.dipucr.es/', 'html', true, 80, NULL),
  ('bop-cordoba', 'BOP Cordoba', 'provincial', 'Cordoba', 'https://bop.dipucordoba.es/', 'html', true, 80, NULL),
  ('bop-a-coruna', 'BOP A Coruna', 'provincial', 'A Coruna', 'https://bop.dacoruna.gal/', 'html', true, 80, NULL),
  ('bop-cuenca', 'BOP Cuenca', 'provincial', 'Cuenca', 'https://www.dipucuenca.es/bop', 'html', true, 80, NULL),
  ('bop-girona', 'BOP Girona', 'provincial', 'Girona', 'https://ssl4.ddgi.cat/bopV1/', 'html', true, 80, NULL),
  ('bop-granada', 'BOP Granada', 'provincial', 'Granada', 'https://bop.dipgra.es/', 'html', true, 80, NULL),
  ('bop-guadalajara', 'BOP Guadalajara', 'provincial', 'Guadalajara', 'https://boletin.dguadalajara.es/', 'html', true, 80, NULL),
  ('bop-gipuzkoa', 'BOP Gipuzkoa', 'provincial', 'Gipuzkoa', 'https://egoitza.gipuzkoa.eus/gao-bog/', 'html', true, 80, NULL),
  ('bop-huelva', 'BOP Huelva', 'provincial', 'Huelva', 'https://bop.diphuelva.es/', 'html', true, 80, NULL),
  ('bop-huesca', 'BOP Huesca', 'provincial', 'Huesca', 'https://bop.dphuesca.es/', 'html', true, 80, NULL),
  ('bop-jaen', 'BOP Jaen', 'provincial', 'Jaen', 'https://bop.dipujaen.es/', 'html', true, 80, NULL),
  ('bop-las-palmas', 'BOP Las Palmas', 'provincial', 'Las Palmas', 'https://www.boplaspalmas.net/', 'html', true, 80, NULL),
  ('bop-leon', 'BOP Leon', 'provincial', 'Leon', 'https://bop.dipuleon.es/', 'html', true, 80, NULL),
  ('bop-lleida', 'BOP Lleida', 'provincial', 'Lleida', 'https://ebop.diputaciolleida.cat/', 'html', true, 80, NULL),
  ('bop-lugo', 'BOP Lugo', 'provincial', 'Lugo', 'https://www.deputacionlugo.gal/gl/bop', 'html', true, 80, NULL),
  ('bop-malaga', 'BOP Malaga', 'provincial', 'Malaga', 'https://www.bopmalaga.es/', 'html', true, 80, NULL),
  ('bop-ourense', 'BOP Ourense', 'provincial', 'Ourense', 'https://bop.depourense.es/', 'html', true, 80, NULL),
  ('bop-palencia', 'BOP Palencia', 'provincial', 'Palencia', 'https://bop.diputaciondepalencia.es/', 'html', true, 80, NULL),
  ('bop-pontevedra', 'BOP Pontevedra', 'provincial', 'Pontevedra', 'https://boppo.depo.gal/', 'html', true, 80, NULL),
  ('bop-salamanca', 'BOP Salamanca', 'provincial', 'Salamanca', 'https://sede.diputaciondesalamanca.gob.es/bop/', 'html', true, 80, NULL),
  ('bop-santa-cruz-tenerife', 'BOP Santa Cruz de Tenerife', 'provincial', 'Santa Cruz de Tenerife', 'https://www.bopsantacruzdetenerife.es/', 'html', true, 80, NULL),
  ('bop-segovia', 'BOP Segovia', 'provincial', 'Segovia', 'https://bopsegovia.dipsegovia.es/', 'html', true, 80, NULL),
  ('bop-sevilla', 'BOP Sevilla', 'provincial', 'Sevilla', 'https://bopsevilla.dipusevilla.es/publica/consulta-de-bops/index.html', 'html', true, 80, NULL),
  ('bop-soria', 'BOP Soria', 'provincial', 'Soria', 'https://bop.dipsoria.es/', 'html', true, 80, NULL),
  ('bop-tarragona', 'BOP Tarragona', 'provincial', 'Tarragona', 'https://www.dipta.cat/ebop/', 'html', true, 80, NULL),
  ('bop-teruel', 'BOP Teruel', 'provincial', 'Teruel', 'https://236ws.dpteruel.es/DPT/bopt.nsf', 'html', true, 80, NULL),
  ('bop-toledo', 'BOP Toledo', 'provincial', 'Toledo', 'https://bop.diputoledo.es/', 'html', true, 80, NULL),
  ('bop-valencia', 'BOP Valencia', 'provincial', 'Valencia', 'https://bop.dival.es/', 'html', true, 80, NULL),
  ('bop-valladolid', 'BOP Valladolid', 'provincial', 'Valladolid', 'https://bop.sede.diputaciondevalladolid.es/', 'html', true, 80, NULL),
  ('bop-zamora', 'BOP Zamora', 'provincial', 'Zamora', 'https://bop.diputaciondezamora.es/', 'html', true, 80, NULL),
  ('bop-zaragoza', 'BOP Zaragoza', 'provincial', 'Zaragoza', 'https://bop.dpz.es/', 'html', true, 80, NULL)
ON CONFLICT (source_key) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  ambito = EXCLUDED.ambito,
  territorio = EXCLUDED.territorio,
  url = EXCLUDED.url,
  tipo = EXCLUDED.tipo,
  activo = EXCLUDED.activo,
  prioridad = EXCLUDED.prioridad,
  notas = EXCLUDED.notas,
  updated_at = NOW();
