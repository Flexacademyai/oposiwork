# OPOSIWORK — Guía Maestra del Proyecto

> Este archivo es leído automáticamente por Codex en cada sesión.
> Contiene toda la arquitectura, reglas y contexto del proyecto.
> NO modificar sin actualizar también la documentación relacionada.

---

## 1. VISIÓN DEL PRODUCTO

**Oposiwork** es una plataforma móvil y web para la preparación de oposiciones en España.
Convierte el contenido oficial del BOE en material de estudio estructurado: resúmenes,
flashcards, tests, psicotécnicos y supuestos prácticos. Incluye seguimiento de progreso,
gamificación, técnicas de estudio y notificaciones de cambios en convocatorias.

**Problema que resuelve:** Los opositores necesitan material actualizado, estructurado y
accesible. Las academias son caras. El BOE es árido y difícil de estudiar directamente.

**Propuesta de valor:** Contenido oficial del BOE procesado por IA, organizado por oposición,
con herramientas de aprendizaje activo y seguimiento personalizado.

---

## 2. OPOSICIONES MVP (FASE 1)

### 2.1 Auxiliar Administrativo del Estado (C2)
- **Fuente BOE:** `boe.es/biblioteca_juridica/index.php?tipo=O`
- **Contenido:** 28 temas en 2 bloques (normativa + ofimática)
- **Tipo de pruebas:** Test tipo examen, supuestos administrativos
- **Psicotécnicos:** No aplica en esta oposición

### 2.2 Policía Nacional (Escala Básica)
- **Fuente BOE:** Convocatoria oficial + normativa policial
- **Contenido:** Temario jurídico + ciencias sociales + inglés
- **Tipo de pruebas:** Test + supuestos + pruebas físicas
- **Psicotécnicos:** SÍ — razonamiento verbal, numérico, espacial, memoria

### 2.3 TES Bomberos Zaragoza (Técnico en Emergencias Sanitarias)
- **Fuente:** Convocatoria Ayuntamiento de Zaragoza + BOE normativa sanitaria
- **Contenido:** Temario técnico sanitario + normativa local
- **Tipo de pruebas:** Test + supuestos prácticos + pruebas físicas
- **Psicotécnicos:** SÍ — razonamiento, memoria, atención

---

## 3. STACK TECNOLÓGICO

### Frontend (App)
- **Framework:** Flutter (Dart) — iOS + Android + Web desde un único codebase
- **Estado:** Riverpod (gestión de estado reactivo)
- **Navegación:** GoRouter
- **UI:** Material Design 3 con tema personalizado Oposiwork

### Backend / Base de Datos
- **Plataforma:** Supabase
  - PostgreSQL como base de datos principal
  - Row Level Security (RLS) en TODAS las tablas
  - Auth integrada (email + Google OAuth)
  - Storage para PDFs de temario
  - Edge Functions para lógica de negocio compleja
  - Realtime para notificaciones en tiempo real

### Procesamiento de Contenido
- **Parser PDF:** Python con `pdfplumber` o `PyMuPDF`
- **IA:** Codex API (Codex-sonnet-4-20250514) para generar resúmenes, tests, flashcards
- **Pipeline:** Script Python que procesa PDFs del BOE → genera contenido → inserta en Supabase

### Notificaciones
- **Push:** Firebase Cloud Messaging (FCM)
- **In-app:** Supabase Realtime
- **Email:** Supabase + Resend

### Pagos
- **Móvil (iOS):** Apple In-App Purchase (obligatorio para App Store)
- **Móvil (Android):** Google Play Billing (obligatorio para Play Store)
- **Web:** Stripe (tarjeta, SEPA)
- **Gestión unificada:** RevenueCat (abstrae iOS + Android + Web en una sola API)

### Infraestructura
- **Repositorio:** GitHub
- **CI/CD:** GitHub Actions
- **Hosting Web:** Vercel
- **Gestión proyecto:** Notion

---

## 4. ARQUITECTURA DE BASE DE DATOS (SUPABASE)

### 4.1 Tablas principales

```sql
-- Oposiciones disponibles en la plataforma
CREATE TABLE oposiciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,           -- 'auxiliar-administrativo-estado'
  nombre TEXT NOT NULL,
  cuerpo TEXT NOT NULL,                -- 'Cuerpo General Administrativo'
  administracion TEXT NOT NULL,        -- 'AGE', 'Zaragoza', 'Nacional'
  nivel TEXT NOT NULL,                 -- 'C1', 'C2', 'A1', 'A2'
  tiene_psicotecnicos BOOLEAN DEFAULT FALSE,
  tiene_pruebas_fisicas BOOLEAN DEFAULT FALSE,
  activa BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Convocatorias (instancias de una oposición)
CREATE TABLE convocatorias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id),
  fecha_publicacion_boe DATE,
  fecha_inicio_instancias DATE,
  fecha_fin_instancias DATE,
  fecha_examen DATE,                   -- Estimada o confirmada
  fecha_examen_confirmada BOOLEAN DEFAULT FALSE,
  plazas INTEGER,
  estado TEXT DEFAULT 'abierta',       -- 'proxima', 'abierta', 'cerrada', 'suspendida'
  url_boe TEXT,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Temas del temario por oposición
CREATE TABLE temas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id),
  numero INTEGER NOT NULL,
  titulo TEXT NOT NULL,
  bloque TEXT,                         -- 'Bloque I: Organización del Estado'
  orden INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Contenido generado por IA para cada tema
CREATE TABLE contenido_temas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tema_id UUID REFERENCES temas(id),
  tipo TEXT NOT NULL,                  -- 'resumen', 'esquema', 'ficha_articulos'
  contenido JSONB NOT NULL,
  version INTEGER DEFAULT 1,
  generado_por TEXT DEFAULT 'Codex-sonnet',
  revisado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Flashcards
CREATE TABLE flashcards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tema_id UUID REFERENCES temas(id),
  pregunta TEXT NOT NULL,
  respuesta TEXT NOT NULL,
  articulo_referencia TEXT,            -- 'Art. 23 CE'
  dificultad INTEGER DEFAULT 1,        -- 1-5
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Preguntas de test
CREATE TABLE preguntas_test (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tema_id UUID REFERENCES temas(id),
  oposicion_id UUID REFERENCES oposiciones(id),
  enunciado TEXT NOT NULL,
  opcion_a TEXT NOT NULL,
  opcion_b TEXT NOT NULL,
  opcion_c TEXT NOT NULL,
  opcion_d TEXT NOT NULL,
  respuesta_correcta TEXT NOT NULL,    -- 'a', 'b', 'c', 'd'
  explicacion TEXT,
  articulo_referencia TEXT,
  dificultad INTEGER DEFAULT 1,        -- 1-5
  veces_fallada INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Psicotécnicos (solo para oposiciones que los requieren)
CREATE TABLE psicotecnicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id),
  tipo TEXT NOT NULL,                  -- 'verbal', 'numerico', 'espacial', 'memoria', 'atencion'
  subtipo TEXT,                        -- 'series_numericas', 'analogias', etc.
  enunciado TEXT NOT NULL,
  datos JSONB,                         -- Datos del ejercicio (imagen, secuencia, etc.)
  opciones JSONB NOT NULL,             -- Array de opciones
  respuesta_correcta TEXT NOT NULL,
  explicacion TEXT,
  dificultad INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Supuestos prácticos
CREATE TABLE supuestos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id),
  tema_id UUID REFERENCES temas(id),
  titulo TEXT NOT NULL,
  enunciado TEXT NOT NULL,
  solucion TEXT NOT NULL,
  normativa_aplicable TEXT[],          -- ['Ley 39/2015', 'Art. 23 LPAC']
  dificultad INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PDFs del temario (Storage de Supabase)
CREATE TABLE temario_pdfs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  oposicion_id UUID REFERENCES oposiciones(id),
  nombre TEXT NOT NULL,
  storage_path TEXT NOT NULL,          -- Path en Supabase Storage
  version TEXT,
  fecha_boe DATE,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Usuarios (extiende auth.users de Supabase)
CREATE TABLE perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  nombre TEXT,
  apellidos TEXT,
  avatar_url TEXT,
  plan TEXT DEFAULT 'free',            -- 'free', 'monthly', 'annual'
  plan_inicio TIMESTAMPTZ,
  plan_fin TIMESTAMPTZ,
  revenuecat_id TEXT,                  -- ID en RevenueCat
  notificaciones_push BOOLEAN DEFAULT TRUE,
  notificaciones_email BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Oposiciones que sigue cada usuario
CREATE TABLE usuario_oposiciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id),
  oposicion_id UUID REFERENCES oposiciones(id),
  fecha_inicio_estudio DATE DEFAULT CURRENT_DATE,
  fecha_examen_objetivo DATE,
  activa BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, oposicion_id)
);

-- Progreso del usuario por tema
CREATE TABLE progreso_temas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id),
  tema_id UUID REFERENCES temas(id),
  porcentaje_completado INTEGER DEFAULT 0,
  ultima_sesion TIMESTAMPTZ,
  tiempo_total_minutos INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, tema_id)
);

-- Resultados de tests y ejercicios
CREATE TABLE resultados_ejercicios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id),
  tipo TEXT NOT NULL,                  -- 'test', 'flashcard', 'psicotecnico', 'supuesto'
  referencia_id UUID NOT NULL,         -- ID del ejercicio correspondiente
  correcto BOOLEAN,
  tiempo_segundos INTEGER,
  respuesta_dada TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Descargas de PDFs (control: 1 descarga por usuario por PDF)
CREATE TABLE descargas_pdf (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id),
  pdf_id UUID REFERENCES temario_pdfs(id),
  descargado_en TIMESTAMPTZ DEFAULT NOW(),
  ip_descarga TEXT,
  UNIQUE(usuario_id, pdf_id)           -- Garantiza 1 sola descarga por usuario por PDF
);

-- Sesiones de estudio (para estadísticas y rachas)
CREATE TABLE sesiones_estudio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id),
  oposicion_id UUID REFERENCES oposiciones(id),
  inicio TIMESTAMPTZ NOT NULL,
  fin TIMESTAMPTZ,
  duracion_minutos INTEGER,
  tipo_actividad TEXT,                 -- 'temario', 'flashcards', 'test', 'psicotecnico'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Gamificación: logros y badges
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
  usuario_id UUID REFERENCES perfiles(id),
  logro_id UUID REFERENCES logros(id),
  obtenido_en TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, logro_id)
);

-- Notificaciones de cambios en convocatorias
CREATE TABLE notificaciones_convocatoria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  convocatoria_id UUID REFERENCES convocatorias(id),
  tipo TEXT NOT NULL,                  -- 'retraso', 'adelanto', 'cambio_normativa', 'nueva_convocatoria', 'plazo_instancias'
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  enviada BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alarmas de estudio configuradas por usuario
CREATE TABLE alarmas_estudio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id),
  oposicion_id UUID REFERENCES oposiciones(id),
  dias_semana INTEGER[],               -- [1,2,3,4,5] = Lun-Vie
  hora TIME NOT NULL,
  activa BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.2 Row Level Security (RLS) — OBLIGATORIO

```sql
-- Habilitar RLS en todas las tablas de usuario
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_oposiciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE progreso_temas ENABLE ROW LEVEL SECURITY;
ALTER TABLE resultados_ejercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE descargas_pdf ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesiones_estudio ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_logros ENABLE ROW LEVEL SECURITY;
ALTER TABLE alarmas_estudio ENABLE ROW LEVEL SECURITY;

-- Políticas: cada usuario solo ve y modifica sus propios datos
CREATE POLICY "usuarios_propios_perfil" ON perfiles
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "usuarios_propias_oposiciones" ON usuario_oposiciones
  FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "usuarios_propio_progreso" ON progreso_temas
  FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "usuarios_propios_resultados" ON resultados_ejercicios
  FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "usuarios_propias_descargas" ON descargas_pdf
  FOR ALL USING (auth.uid() = usuario_id);

-- Contenido público (oposiciones, temas, preguntas) — solo lectura para usuarios autenticados
ALTER TABLE oposiciones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "contenido_publico_oposiciones" ON oposiciones
  FOR SELECT USING (true);

-- Contenido premium — solo usuarios con plan activo
CREATE POLICY "contenido_premium_temas" ON contenido_temas
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM perfiles
      WHERE id = auth.uid()
      AND plan IN ('monthly', 'annual')
      AND plan_fin > NOW()
    )
  );
```

---

## 5. ESTRUCTURA DE CARPETAS FLUTTER

```
lib/
├── main.dart
├── app.dart                           # MaterialApp + GoRouter
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_routes.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── format_utils.dart
│   └── extensions/
├── data/
│   ├── models/                        # Clases Dart que mapean tablas Supabase
│   │   ├── oposicion.dart
│   │   ├── convocatoria.dart
│   │   ├── tema.dart
│   │   ├── flashcard.dart
│   │   ├── pregunta_test.dart
│   │   ├── psicotecnico.dart
│   │   └── perfil.dart
│   ├── repositories/                  # Acceso a datos (Supabase)
│   │   ├── oposiciones_repository.dart
│   │   ├── contenido_repository.dart
│   │   ├── progreso_repository.dart
│   │   └── auth_repository.dart
│   └── services/
│       ├── supabase_service.dart
│       ├── notifications_service.dart  # FCM
│       ├── payments_service.dart       # RevenueCat
│       └── storage_service.dart        # Descarga PDFs
├── presentation/
│   ├── screens/
│   │   ├── splash/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── oposiciones/
│   │   │   ├── oposiciones_screen.dart    # Lista de oposiciones (FREE)
│   │   │   └── oposicion_detail_screen.dart
│   │   ├── temario/
│   │   │   ├── temario_screen.dart        # PREMIUM
│   │   │   └── tema_detail_screen.dart
│   │   ├── flashcards/
│   │   │   └── flashcards_screen.dart     # PREMIUM
│   │   ├── tests/
│   │   │   ├── test_screen.dart           # PREMIUM
│   │   │   └── resultado_test_screen.dart
│   │   ├── psicotecnicos/
│   │   │   └── psicotecnicos_screen.dart  # PREMIUM
│   │   ├── progreso/
│   │   │   └── progreso_screen.dart       # PREMIUM
│   │   ├── estudio/
│   │   │   ├── plan_estudio_screen.dart   # PREMIUM
│   │   │   └── alarmas_screen.dart        # PREMIUM
│   │   ├── perfil/
│   │   │   └── perfil_screen.dart
│   │   └── suscripcion/
│   │       └── paywall_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── loading_widget.dart
│   │   │   ├── error_widget.dart
│   │   │   └── premium_lock_widget.dart   # Candado sobre contenido premium
│   │   ├── flashcard_widget.dart
│   │   ├── progress_ring_widget.dart
│   │   └── streak_widget.dart
│   └── providers/                         # Riverpod providers
│       ├── auth_provider.dart
│       ├── oposiciones_provider.dart
│       ├── progreso_provider.dart
│       └── suscripcion_provider.dart
└── config/
    ├── supabase_config.dart
    ├── revenuecat_config.dart
    └── firebase_config.dart
```

---

## 6. MODELO FREEMIUM Y SUSCRIPCIÓN

### Plan Free (sin registro o con registro gratuito)
- Ver lista de oposiciones disponibles
- Ver fecha de instancias y estado de convocatoria actual
- NADA MÁS — sin contenido, sin tests, sin descargas, sin flashcards
- El objetivo del free es que el usuario vea qué existe y se suscriba

### Plan Premium (suscripción mensual o anual)
- TODO el contenido generado (resúmenes, esquemas, fichas de artículos)
- Flashcards ilimitadas con repaso espaciado
- Tests completos con explicaciones y referencias legales
- Psicotécnicos (donde aplique: Policía, Bomberos)
- Supuestos prácticos
- **Descarga de PDF del temario oficial: 1 SOLA VEZ por usuario por oposición**
  - Enforced en base de datos (UNIQUE constraint en tabla descargas_pdf)
  - Enforced en servidor (Edge Function verifica antes de generar URL firmada)
  - El cliente Flutter NO decide si puede descargar — siempre lo decide el servidor
  - URL firmada expira en 60 segundos (no reutilizable)
- Plan de estudio personalizado
- Seguimiento de progreso completo
- Alarmas y recordatorios de estudio
- Gamificación completa (logros, rachas, rankings)
- Técnicas de estudio integradas
- Notificaciones de cambios en convocatorias

### Precios (definir con RevenueCat)
```
Plan Mensual:   €9.99/mes
Plan Anual:     €79.99/año (ahorro ~33%)
```

### Control de descarga PDF (1 sola vez)
```dart
// Antes de permitir descarga, verificar en tabla descargas_pdf
Future<bool> puedeDescargarPdf(String userId, String pdfId) async {
  final existe = await supabase
    .from('descargas_pdf')
    .select('id')
    .eq('usuario_id', userId)
    .eq('pdf_id', pdfId)
    .maybeSingle();
  return existe == null; // Solo puede descargar si no existe registro previo
}

// Registrar descarga (UNIQUE constraint en DB previene duplicados)
Future<void> registrarDescarga(String userId, String pdfId) async {
  await supabase.from('descargas_pdf').insert({
    'usuario_id': userId,
    'pdf_id': pdfId,
  });
  // Generar URL firmada temporal (expira en 60 segundos)
  final url = await supabase.storage
    .from('temarios')
    .createSignedUrl(pdfPath, 60);
  // Iniciar descarga con la URL firmada
}
```

---

## 7. PIPELINE DE CONTENIDO (BOE → OPOSIWORK)

### 7.1 Script de procesamiento (Python)

```python
# content_pipeline/process_boe.py
import pdfplumber
import anthropic
from supabase import create_client

client = anthropic.Anthropic()

def procesar_tema(texto_tema: str, numero_tema: int, oposicion: str) -> dict:
    """Genera todo el contenido de un tema usando Codex."""
    
    # Resumen ejecutivo
    resumen = client.messages.create(
        model="Codex-sonnet-4-20250514",
        max_tokens=2000,
        messages=[{
            "role": "user",
            "content": f"""Eres un preparador experto de oposiciones españolas.
            
Analiza este tema del temario de {oposicion} y genera:
1. RESUMEN EJECUTIVO (máximo 500 palabras, en puntos clave)
2. ARTÍCULOS CLAVE (los más preguntados en exámenes, con número de artículo y ley)
3. CONCEPTOS IMPRESCINDIBLES (10 conceptos que el opositor DEBE memorizar)

Texto del tema:
{texto_tema}

Responde en JSON con esta estructura exacta:
{{
  "resumen": "...",
  "articulos_clave": [{{"articulo": "Art. X", "ley": "Ley X/XXXX", "contenido": "..."}}],
  "conceptos": ["concepto1", "concepto2", ...]
}}"""
        }]
    )
    
    # Flashcards
    flashcards = client.messages.create(
        model="Codex-sonnet-4-20250514",
        max_tokens=3000,
        messages=[{
            "role": "user", 
            "content": f"""Genera 15 flashcards de estudio para el Tema {numero_tema} de {oposicion}.
            
Cada flashcard debe tener:
- Pregunta directa y concisa
- Respuesta exacta (como respondería en examen)
- Artículo de referencia cuando aplique

Texto del tema:
{texto_tema}

Responde en JSON:
{{"flashcards": [{{"pregunta": "...", "respuesta": "...", "articulo": "..."}}]}}"""
        }]
    )
    
    # Preguntas de test
    test = client.messages.create(
        model="Codex-sonnet-4-20250514",
        max_tokens=4000,
        messages=[{
            "role": "user",
            "content": f"""Genera 20 preguntas de examen tipo test para el Tema {numero_tema} de {oposicion}.
            
Cada pregunta debe:
- Tener 4 opciones (a, b, c, d)
- Solo una respuesta correcta
- Incluir explicación de por qué es correcta
- Citar el artículo/ley de referencia
- Tener dificultad variada (fácil, media, difícil)

Texto del tema:
{texto_tema}

Responde en JSON:
{{"preguntas": [{{"enunciado": "...", "a": "...", "b": "...", "c": "...", "d": "...", 
  "correcta": "a", "explicacion": "...", "articulo": "...", "dificultad": 1}}]}}"""
        }]
    )
    
    return {
        "resumen": resumen,
        "flashcards": flashcards,
        "test": test
    }
```

### 7.2 Generador de psicotécnicos

```python
def generar_psicotecnico(tipo: str, dificultad: int) -> dict:
    """Genera ejercicios psicotécnicos para Policía y Bomberos."""
    
    tipos_prompts = {
        "series_numericas": "Genera una serie numérica con patrón lógico...",
        "analogias_verbales": "Genera una analogía verbal tipo 'A es a B como C es a ___'...",
        "razonamiento_espacial": "Describe un ejercicio de rotación mental de figuras...",
        "memoria": "Genera un ejercicio de memoria secuencial...",
        "atencion": "Genera un ejercicio de búsqueda de diferencias o símbolos...",
    }
    
    respuesta = client.messages.create(
        model="Codex-sonnet-4-20250514",
        max_tokens=1000,
        messages=[{
            "role": "user",
            "content": f"""{tipos_prompts[tipo]}
Dificultad: {dificultad}/5
Formato JSON: {{"enunciado": "...", "opciones": [...], "correcta": "...", "explicacion": "..."}}"""
        }]
    )
    return respuesta
```

---

## 8. SISTEMA DE NOTIFICACIONES

### 8.1 Tipos de notificaciones

```dart
enum TipoNotificacion {
  nuevaConvocatoria,      // 'Nueva convocatoria de Policía Nacional publicada'
  cambioFechaExamen,      // 'El examen de Auxiliar se adelanta al 15 de marzo'
  plazoCierre,            // 'Quedan 3 días para presentar tu solicitud'
  cambioNormativa,        // 'Actualización en la Ley 39/2015 que afecta tu temario'
  recordatorioEstudio,    // Alarmas configuradas por el usuario
  racha,                  // 'Llevas 7 días seguidos estudiando 🔥'
  logroDesbloqueado,      // 'Has completado el Tema 5 ⭐'
  motivacion,             // Mensajes motivacionales diarios
}
```

### 8.2 Monitorización BOE (Supabase Edge Function)

```typescript
// supabase/functions/monitor-boe/index.ts
// Se ejecuta diariamente via cron job
Deno.serve(async () => {
  // 1. Consultar RSS/API del BOE para nuevas publicaciones
  // 2. Detectar cambios en convocatorias seguidas por usuarios
  // 3. Insertar en notificaciones_convocatoria
  // 4. Enviar FCM a usuarios afectados
  // 5. Actualizar fecha updated_at en convocatorias
});
```

---

## 9. GAMIFICACIÓN

### 9.1 Sistema de puntos
- Completar un tema: +50 puntos
- Test con nota >80%: +30 puntos
- Racha de 7 días: +100 puntos
- Primera descarga de PDF: +20 puntos
- Supuesto práctico completado: +40 puntos

### 9.2 Logros predefinidos
```
'primer_tema'          → Completa tu primer tema
'semana_perfecta'      → 7 días estudiando seguidos
'test_perfecto'        → 100% en un test
'psico_master'         → 50 psicotécnicos completados
'temario_completo'     → Todos los temas al 100%
'madrugador'           → Estudia antes de las 8:00 AM
'constante'            → 30 días de racha
```

### 9.3 Técnicas de estudio integradas
- **Pomodoro:** Temporizador 25min estudio / 5min descanso
- **Repaso espaciado:** Algoritmo tipo SM-2 para flashcards
- **Test adaptativo:** Más preguntas de temas fallados
- **Plan semanal:** Distribución automática de temas según fecha de examen

---

## 10. SEGURIDAD

### 10.1 Reglas generales
- RLS habilitado en TODAS las tablas con datos de usuario
- Nunca exponer claves de servicio en el cliente Flutter
- URLs de Storage firmadas con expiración corta (60s para descarga)
- Control de descarga PDF a nivel de base de datos (UNIQUE constraint)
- Verificación de plan activo en Edge Functions, no solo en cliente

### 10.2 Verificación de suscripción
```dart
// SIEMPRE verificar suscripción en el servidor, no solo en cliente
// Edge Function verifica con RevenueCat antes de devolver contenido premium
```

### 10.3 Variables de entorno
```
# .env (NUNCA commitear)
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_KEY=        # Solo backend/scripts
REVENUECAT_API_KEY_IOS=
REVENUECAT_API_KEY_ANDROID=
REVENUECAT_API_KEY_WEB=
STRIPE_SECRET_KEY=
FCM_SERVER_KEY=
ANTHROPIC_API_KEY=           # Solo pipeline de contenido
```

---

## 11. REGLAS DE DESARROLLO

### 11.1 Convenciones de código
- Dart: snake_case para archivos, camelCase para variables, PascalCase para clases
- Commits: `feat:`, `fix:`, `refactor:`, `docs:` (Conventional Commits)
- Todo texto visible en español (la app es para el mercado español)
- Comentarios de código en español

### 11.2 Orden de implementación (MVP)
1. Setup Supabase (schema completo + RLS)
2. Auth (login + registro + Google OAuth)
3. Pantalla de oposiciones (FREE — lista + convocatoria)
4. Paywall (RevenueCat + Stripe)
5. Temario (PREMIUM — resúmenes)
6. Flashcards (PREMIUM)
7. Tests (PREMIUM)
8. Psicotécnicos (PREMIUM — Policía y Bomberos)
9. Progreso y estadísticas
10. Gamificación
11. Alarmas y plan de estudio
12. Notificaciones push
13. Pipeline BOE (procesamiento de PDFs)
14. Descarga controlada de PDFs

### 11.3 Lo que NUNCA hacer
- No guardar datos sensibles en SharedPreferences sin cifrar
- No verificar suscripción solo en el cliente Flutter
- No permitir múltiples descargas del mismo PDF (UNIQUE constraint en DB lo previene)
- No exponer contenido premium sin verificar plan en servidor
- No commitear claves API o variables de entorno

---

## 12. COMANDOS ÚTILES

```bash
# Iniciar proyecto Flutter
flutter create oposiwork --org es.oposiwork

# Dependencias principales
flutter pub add supabase_flutter riverpod flutter_riverpod go_router
flutter pub add purchases_flutter                    # RevenueCat
flutter pub add firebase_messaging firebase_core     # FCM
flutter pub add flutter_local_notifications          # Notificaciones locales

# Supabase CLI
supabase init
supabase start
supabase db push
supabase functions deploy monitor-boe

# Pipeline de contenido Python
pip install pdfplumber anthropic supabase python-dotenv
python content_pipeline/process_boe.py --oposicion auxiliar-administrativo

# Build
flutter build apk --release
flutter build ios --release
flutter build web --release
```

---

## 13. CONTACTO Y RECURSOS

- **BOE Biblioteca Jurídica:** https://www.boe.es/biblioteca_juridica/index.php?tipo=O
- **Supabase Dashboard:** https://supabase.com/dashboard
- **RevenueCat Dashboard:** https://app.revenuecat.com
- **Firebase Console:** https://console.firebase.google.com
- **Vercel Dashboard:** https://vercel.com/dashboard
- **Repositorio:** GitHub (configurar)
- **Gestión proyecto:** Notion (configurar)

---

*Última actualización: Mayo 2026*
*Versión: 1.0.0*
