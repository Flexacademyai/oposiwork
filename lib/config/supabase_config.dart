class SupabaseConfig {
  SupabaseConfig._();

  // Inyectadas en tiempo de compilación con --dart-define-from-file=.env
  // La anon key es pública por diseño — la seguridad real la provee RLS
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Lanza StateError si faltan variables de entorno obligatorias.
  /// Llamar en main() antes de inicializar Supabase.
  static void validate() {
    if (url.isEmpty) {
      throw StateError(
        'SUPABASE_URL no configurado.\n'
        'Ejecuta: flutter run --dart-define-from-file=.env\n'
        'O copia .env.example en .env y rellena los valores.',
      );
    }
    if (anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY no configurado.\n'
        'Ejecuta: flutter run --dart-define-from-file=.env',
      );
    }
  }

  // Storage buckets
  static const String bucketTemarios = 'temarios';

  // Tablas
  static const String tablaOposiciones = 'oposiciones';
  static const String tablaConvocatorias = 'convocatorias';
  static const String tablaTemas = 'temas';
  static const String tablaContenidoTemas = 'contenido_temas';
  static const String tablaFlashcards = 'flashcards';
  static const String tablaPreguntasTest = 'preguntas_test';
  static const String tablaPsicotecnicos = 'psicotecnicos';
  static const String tablaSupuestos = 'supuestos';
  static const String tablaTemarioPdfs = 'temario_pdfs';
  static const String tablaPerfiles = 'perfiles';
  static const String tablaUsuarioOposiciones = 'usuario_oposiciones';
  static const String tablaProgresoTemas = 'progreso_temas';
  static const String tablaResultadosEjercicios = 'resultados_ejercicios';
  static const String tablaDescargasPdf = 'descargas_pdf';
  static const String tablaSesionesEstudio = 'sesiones_estudio';
  static const String tablaLogros = 'logros';
  static const String tablaUsuarioLogros = 'usuario_logros';
  static const String tablaNotificaciones = 'notificaciones_convocatoria';
  static const String tablaAlarmasEstudio = 'alarmas_estudio';
  static const String tablaProgresoFlashcards = 'progreso_flashcards';
  static const String tablaSimulacros = 'simulacros';
  static const String tablaConsentimientos = 'consentimientos';
}
