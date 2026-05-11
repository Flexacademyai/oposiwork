-- =============================================
-- OPOSIWORK — Schema inicial completo
-- =============================================

-- Oposiciones disponibles en la plataforma
CREATE TABLE oposiciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  nombre TEXT NOT NULL,
  cuerpo TEXT NOT NULL,
  administracion TEXT NOT NULL,
  nivel TEXT NOT NULL,
  tiene_psicotecnicos BOOLEAN DEFAULT FALSE,
  tiene_pruebas_fisicas BOOLEAN DEFAULT FALSE,
  activa BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Convocatorias
CREATE TABLE convocatorias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  fecha_publicacion_boe DATE,
  fecha_inicio_instancias DATE,
  fecha_fin_instancias DATE,
  fecha_examen DATE,
  fecha_examen_confirmada BOOLEAN DEFAULT FALSE,
  plazas INTEGER,
  estado TEXT DEFAULT 'abierta' CHECK (estado IN ('proxima', 'abierta', 'cerrada', 'suspendida')),
  url_boe TEXT,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Temas del temario
CREATE TABLE temas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  numero INTEGER NOT NULL,
  titulo TEXT NOT NULL,
  bloque TEXT,
  orden INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Contenido generado por IA
CREATE TABLE contenido_temas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tema_id UUID REFERENCES temas(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('resumen', 'esquema', 'ficha_articulos')),
  contenido JSONB NOT NULL,
  version INTEGER DEFAULT 1,
  generado_por TEXT DEFAULT 'claude-sonnet',
  revisado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Flashcards
CREATE TABLE flashcards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tema_id UUID REFERENCES temas(id) ON DELETE CASCADE,
  pregunta TEXT NOT NULL,
  respuesta TEXT NOT NULL,
  articulo_referencia TEXT,
  dificultad INTEGER DEFAULT 1 CHECK (dificultad BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Preguntas de test
CREATE TABLE preguntas_test (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tema_id UUID REFERENCES temas(id) ON DELETE CASCADE,
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  enunciado TEXT NOT NULL,
  opcion_a TEXT NOT NULL,
  opcion_b TEXT NOT NULL,
  opcion_c TEXT NOT NULL,
  opcion_d TEXT NOT NULL,
  respuesta_correcta TEXT NOT NULL CHECK (respuesta_correcta IN ('a', 'b', 'c', 'd')),
  explicacion TEXT,
  articulo_referencia TEXT,
  dificultad INTEGER DEFAULT 1 CHECK (dificultad BETWEEN 1 AND 5),
  veces_fallada INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Psicotécnicos
CREATE TABLE psicotecnicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('verbal', 'numerico', 'espacial', 'memoria', 'atencion')),
  subtipo TEXT,
  enunciado TEXT NOT NULL,
  datos JSONB,
  opciones JSONB NOT NULL,
  respuesta_correcta TEXT NOT NULL,
  explicacion TEXT,
  dificultad INTEGER DEFAULT 1 CHECK (dificultad BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Supuestos prácticos
CREATE TABLE supuestos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  tema_id UUID REFERENCES temas(id),
  titulo TEXT NOT NULL,
  enunciado TEXT NOT NULL,
  solucion TEXT NOT NULL,
  normativa_aplicable TEXT[],
  dificultad INTEGER DEFAULT 1 CHECK (dificultad BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PDFs del temario
CREATE TABLE temario_pdfs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  version TEXT,
  fecha_boe DATE,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Perfiles de usuario
CREATE TABLE perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT,
  apellidos TEXT,
  avatar_url TEXT,
  plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'monthly', 'annual')),
  plan_inicio TIMESTAMPTZ,
  plan_fin TIMESTAMPTZ,
  revenuecat_id TEXT,
  notificaciones_push BOOLEAN DEFAULT TRUE,
  notificaciones_email BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Oposiciones que sigue cada usuario
CREATE TABLE usuario_oposiciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  fecha_inicio_estudio DATE DEFAULT CURRENT_DATE,
  fecha_examen_objetivo DATE,
  activa BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, oposicion_id)
);

-- Progreso por tema
CREATE TABLE progreso_temas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  tema_id UUID REFERENCES temas(id) ON DELETE CASCADE,
  porcentaje_completado INTEGER DEFAULT 0 CHECK (porcentaje_completado BETWEEN 0 AND 100),
  ultima_sesion TIMESTAMPTZ,
  tiempo_total_minutos INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, tema_id)
);

-- Resultados de ejercicios
CREATE TABLE resultados_ejercicios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('test', 'flashcard', 'psicotecnico', 'supuesto')),
  referencia_id UUID NOT NULL,
  correcto BOOLEAN,
  tiempo_segundos INTEGER,
  respuesta_dada TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Descargas de PDFs (1 por usuario por PDF)
CREATE TABLE descargas_pdf (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  pdf_id UUID REFERENCES temario_pdfs(id) ON DELETE CASCADE,
  descargado_en TIMESTAMPTZ DEFAULT NOW(),
  ip_descarga TEXT,
  UNIQUE(usuario_id, pdf_id)
);

-- Sesiones de estudio
CREATE TABLE sesiones_estudio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  inicio TIMESTAMPTZ NOT NULL,
  fin TIMESTAMPTZ,
  duracion_minutos INTEGER,
  tipo_actividad TEXT CHECK (tipo_actividad IN ('temario', 'flashcards', 'test', 'psicotecnico', 'supuesto')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Logros
CREATE TABLE logros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  nombre TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  icono TEXT NOT NULL,
  puntos INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE usuario_logros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  logro_id UUID REFERENCES logros(id) ON DELETE CASCADE,
  obtenido_en TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, logro_id)
);

-- Notificaciones de convocatorias
CREATE TABLE notificaciones_convocatoria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  convocatoria_id UUID REFERENCES convocatorias(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('retraso', 'adelanto', 'cambio_normativa', 'nueva_convocatoria', 'plazo_instancias')),
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  enviada BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alarmas de estudio
CREATE TABLE alarmas_estudio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  oposicion_id UUID REFERENCES oposiciones(id) ON DELETE CASCADE,
  dias_semana INTEGER[],
  hora TIME NOT NULL,
  activa BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ÍNDICES
-- =============================================

CREATE INDEX idx_temas_oposicion ON temas(oposicion_id);
CREATE INDEX idx_flashcards_tema ON flashcards(tema_id);
CREATE INDEX idx_preguntas_test_tema ON preguntas_test(tema_id);
CREATE INDEX idx_preguntas_test_oposicion ON preguntas_test(oposicion_id);
CREATE INDEX idx_progreso_usuario ON progreso_temas(usuario_id);
CREATE INDEX idx_resultados_usuario ON resultados_ejercicios(usuario_id);
CREATE INDEX idx_sesiones_usuario ON sesiones_estudio(usuario_id);
CREATE INDEX idx_sesiones_inicio ON sesiones_estudio(inicio);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

-- Contenido público
ALTER TABLE oposiciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE convocatorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE temas ENABLE ROW LEVEL SECURITY;
ALTER TABLE logros ENABLE ROW LEVEL SECURITY;

CREATE POLICY "oposiciones_publicas" ON oposiciones FOR SELECT USING (true);
CREATE POLICY "convocatorias_publicas" ON convocatorias FOR SELECT USING (true);
CREATE POLICY "temas_publicos" ON temas FOR SELECT USING (true);
CREATE POLICY "logros_publicos" ON logros FOR SELECT USING (true);

-- Contenido premium
ALTER TABLE contenido_temas ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE preguntas_test ENABLE ROW LEVEL SECURITY;
ALTER TABLE psicotecnicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE supuestos ENABLE ROW LEVEL SECURITY;
ALTER TABLE temario_pdfs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "contenido_premium" ON contenido_temas FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid()
    AND plan IN ('monthly', 'annual')
    AND plan_fin > NOW()
  )
);

CREATE POLICY "flashcards_premium" ON flashcards FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid()
    AND plan IN ('monthly', 'annual')
    AND plan_fin > NOW()
  )
);

CREATE POLICY "preguntas_premium" ON preguntas_test FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid()
    AND plan IN ('monthly', 'annual')
    AND plan_fin > NOW()
  )
);

CREATE POLICY "psicotecnicos_premium" ON psicotecnicos FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid()
    AND plan IN ('monthly', 'annual')
    AND plan_fin > NOW()
  )
);

CREATE POLICY "supuestos_premium" ON supuestos FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid()
    AND plan IN ('monthly', 'annual')
    AND plan_fin > NOW()
  )
);

CREATE POLICY "pdfs_premium" ON temario_pdfs FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM perfiles
    WHERE id = auth.uid()
    AND plan IN ('monthly', 'annual')
    AND plan_fin > NOW()
  )
);

-- Datos de usuario
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_oposiciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE progreso_temas ENABLE ROW LEVEL SECURITY;
ALTER TABLE resultados_ejercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE descargas_pdf ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesiones_estudio ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_logros ENABLE ROW LEVEL SECURITY;
ALTER TABLE alarmas_estudio ENABLE ROW LEVEL SECURITY;

CREATE POLICY "perfil_propio" ON perfiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "oposiciones_propias" ON usuario_oposiciones FOR ALL USING (auth.uid() = usuario_id);
CREATE POLICY "progreso_propio" ON progreso_temas FOR ALL USING (auth.uid() = usuario_id);
CREATE POLICY "resultados_propios" ON resultados_ejercicios FOR ALL USING (auth.uid() = usuario_id);
CREATE POLICY "descargas_propias" ON descargas_pdf FOR ALL USING (auth.uid() = usuario_id);
CREATE POLICY "sesiones_propias" ON sesiones_estudio FOR ALL USING (auth.uid() = usuario_id);
CREATE POLICY "logros_propios" ON usuario_logros FOR ALL USING (auth.uid() = usuario_id);
CREATE POLICY "alarmas_propias" ON alarmas_estudio FOR ALL USING (auth.uid() = usuario_id);

-- =============================================
-- TRIGGER: crear perfil al registrarse
-- =============================================

CREATE OR REPLACE FUNCTION public.manejar_nuevo_usuario()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre, apellidos)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'nombre',
    NEW.raw_user_meta_data->>'apellidos'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.manejar_nuevo_usuario();
