import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tema.dart';
import '../models/temario_pdf.dart';
import '../models/flashcard.dart';
import '../models/pregunta_test.dart';
import '../../config/supabase_config.dart';

class ContenidoRepository {
  final SupabaseClient _supabase;

  ContenidoRepository(this._supabase);

  Future<List<Tema>> obtenerTemas(String oposicionId) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaTemas)
        .select()
        .eq('oposicion_id', oposicionId)
        .order('orden');
    return (data as List).map((e) => Tema.fromMap(e)).toList();
  }

  Future<List<TemarioPdf>> obtenerPdfsTemario(String oposicionId) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaTemarioPdfs)
        .select()
        .eq('oposicion_id', oposicionId)
        .eq('activo', true)
        .order('created_at', ascending: false);
    return (data as List).map((e) => TemarioPdf.fromMap(e)).toList();
  }

  Future<Tema?> obtenerTema(String temaId) async {
    final data =
        await _supabase
            .from(SupabaseConfig.tablaTemas)
            .select()
            .eq('id', temaId)
            .maybeSingle();
    if (data == null) return null;
    return Tema.fromMap(data);
  }

  Future<Map<String, dynamic>?> obtenerContenidoTema(
    String temaId,
    String tipo,
  ) async {
    final data =
        await _supabase
            .from(SupabaseConfig.tablaContenidoTemas)
            .select()
            .eq('tema_id', temaId)
            .eq('tipo', tipo)
            .order('version', ascending: false)
            .limit(1)
            .maybeSingle();
    return data;
  }

  Future<List<Flashcard>> obtenerFlashcards(String temaId) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaFlashcards)
        .select()
        .eq('tema_id', temaId)
        .order('dificultad');
    return (data as List).map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<List<Flashcard>> obtenerFlashcardsPorOposicion(
    String oposicionId,
  ) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaFlashcards)
        .select('*, temas!inner(oposicion_id)')
        .eq('temas.oposicion_id', oposicionId);
    return (data as List).map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<List<PreguntaTest>> obtenerPreguntasTest(String temaId) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaPreguntasTest)
        .select()
        .eq('tema_id', temaId)
        .order('dificultad');
    return (data as List).map((e) => PreguntaTest.fromMap(e)).toList();
  }

  Future<List<PreguntaTest>> obtenerPreguntasTestPorOposicion(
    String oposicionId, {
    int limite = 20,
  }) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaPreguntasTest)
        .select()
        .eq('oposicion_id', oposicionId)
        .limit(limite);
    return (data as List).map((e) => PreguntaTest.fromMap(e)).toList();
  }

  Future<void> actualizarProgresoFlashcard(Flashcard flashcard) async {
    // Mantiene compatibilidad — delega al método con calificación
    // usando conversión bool→SM2 (sabia=true → calificacion=2)
    await actualizarProgresoFlashcardConCalificacion(
      flashcardId: flashcard.id,
      usuarioId: '', // sin registro de resultados en llamadas legacy
      calificacion: flashcard.intervalo > 1 ? 2 : 0,
    );
  }

  Future<void> actualizarProgresoFlashcardConCalificacion({
    required String flashcardId,
    required String usuarioId,
    required int calificacion,
  }) async {
    // Lee progreso actual del usuario (tabla por-usuario, no la flashcard compartida)
    final data =
        await _supabase
            .from(SupabaseConfig.tablaProgresoFlashcards)
            .select('intervalo, repeticion, facilidad')
            .eq('usuario_id', usuarioId)
            .eq('flashcard_id', flashcardId)
            .maybeSingle();

    final intervaloActual = data?['intervalo'] as int? ?? 1;
    final repeticionActual = data?['repeticion'] as int? ?? 0;
    final facilidadActual = (data?['facilidad'] as num?)?.toDouble() ?? 2.5;

    double nuevaFacilidad =
        facilidadActual +
        (0.1 - (3 - calificacion) * (0.08 + (3 - calificacion) * 0.02));
    nuevaFacilidad = nuevaFacilidad.clamp(1.3, 2.5);

    int nuevoIntervalo;
    int nuevaRepeticion;
    if (calificacion < 2) {
      nuevoIntervalo = 1;
      nuevaRepeticion = 0;
    } else {
      nuevaRepeticion = repeticionActual + 1;
      nuevoIntervalo = switch (nuevaRepeticion) {
        1 => 1,
        2 => 6,
        _ => (intervaloActual * nuevaFacilidad).round(),
      };
    }

    final proximaRevision = DateTime.now()
        .add(Duration(days: nuevoIntervalo))
        .toIso8601String()
        .substring(0, 10); // solo fecha YYYY-MM-DD

    // Upsert en tabla por-usuario (aislamiento total entre usuarios)
    await _supabase.from(SupabaseConfig.tablaProgresoFlashcards).upsert({
      'usuario_id': usuarioId,
      'flashcard_id': flashcardId,
      'intervalo': nuevoIntervalo,
      'repeticion': nuevaRepeticion,
      'facilidad': nuevaFacilidad,
      'proxima_revision': proximaRevision,
      'ultima_respuesta': calificacion,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'usuario_id,flashcard_id');

    if (usuarioId.isNotEmpty) {
      await _supabase.from(SupabaseConfig.tablaResultadosEjercicios).insert({
        'usuario_id': usuarioId,
        'tipo': 'flashcard',
        'referencia_id': flashcardId,
        'correcto': calificacion >= 2,
        'respuesta_dada': calificacion.toString(),
      });
    }
  }

  // Devuelve las flashcards pendientes para el usuario (SM-2 por usuario)
  Future<List<Flashcard>> obtenerFlashcardsPendientes(
    String oposicionId, {
    String? usuarioId,
  }) async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);

    // Flashcards de esta oposición que el usuario ya ha trabajado y tienen repaso pendiente
    List<String> idsPendientes = [];
    if (usuarioId != null && usuarioId.isNotEmpty) {
      final progreso = await _supabase
          .from(SupabaseConfig.tablaProgresoFlashcards)
          .select('flashcard_id')
          .eq('usuario_id', usuarioId)
          .or('proxima_revision.is.null,proxima_revision.lte.$hoy');
      idsPendientes =
          (progreso as List).map((e) => e['flashcard_id'] as String).toList();
    }

    // Flashcards de la oposición aún no trabajadas por el usuario
    final flashcards = await _supabase
        .from(SupabaseConfig.tablaFlashcards)
        .select('*, temas!inner(oposicion_id)')
        .eq('temas.oposicion_id', oposicionId)
        .order('dificultad', ascending: true)
        .limit(20);

    final todas =
        (flashcards as List).map((e) => Flashcard.fromMap(e)).toList();

    if (idsPendientes.isEmpty) return todas.take(20).toList();

    // Prioriza las pendientes, luego las nuevas
    final pendientes =
        todas.where((f) => idsPendientes.contains(f.id)).toList();
    final nuevas = todas.where((f) => !idsPendientes.contains(f.id)).toList();
    return [...pendientes, ...nuevas].take(20).toList();
  }

  // Devuelve las flashcards cuya fecha de repaso es hoy o anterior (SM-2 por usuario)
  Future<List<Flashcard>> obtenerFlashcardsParaRepasar(
    String oposicionId, {
    String? usuarioId,
  }) async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);

    if (usuarioId == null || usuarioId.isEmpty) {
      final data = await _supabase
          .from(SupabaseConfig.tablaFlashcards)
          .select('*, temas!inner(oposicion_id)')
          .eq('temas.oposicion_id', oposicionId)
          .order('dificultad');
      return (data as List).map((e) => Flashcard.fromMap(e)).toList();
    }

    // IDs con repaso pendiente para este usuario
    final progreso = await _supabase
        .from(SupabaseConfig.tablaProgresoFlashcards)
        .select('flashcard_id, proxima_revision')
        .eq('usuario_id', usuarioId)
        .lte('proxima_revision', hoy)
        .order('proxima_revision');

    final ids =
        (progreso as List).map((e) => e['flashcard_id'] as String).toList();
    if (ids.isEmpty) return [];

    final data = await _supabase
        .from(SupabaseConfig.tablaFlashcards)
        .select('*, temas!inner(oposicion_id)')
        .eq('temas.oposicion_id', oposicionId)
        .inFilter('id', ids);

    final flashcards = (data as List).map((e) => Flashcard.fromMap(e)).toList();
    // Mantiene el orden por proxima_revision devuelto por progreso
    flashcards.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return flashcards;
  }

  Future<List<Map<String, dynamic>>> obtenerPsicotecnicos(
    String oposicionId, {
    String? tipo,
  }) async {
    var query = _supabase
        .from(SupabaseConfig.tablaPsicotecnicos)
        .select()
        .eq('oposicion_id', oposicionId);
    if (tipo != null) {
      query = query.eq('tipo', tipo);
    }
    return List<Map<String, dynamic>>.from(await query.order('dificultad'));
  }
}
