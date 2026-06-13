import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class ProgresoRepository {
  final SupabaseClient _supabase;

  ProgresoRepository(this._supabase);

  Future<Map<String, dynamic>?> obtenerProgresoTema(
    String userId,
    String temaId,
  ) async {
    return await _supabase
        .from(SupabaseConfig.tablaProgresoTemas)
        .select()
        .eq('usuario_id', userId)
        .eq('tema_id', temaId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> obtenerProgresoOposicion(
    String userId,
    String oposicionId,
  ) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaProgresoTemas)
        .select('*, temas!inner(oposicion_id, numero, titulo)')
        .eq('usuario_id', userId)
        .eq('temas.oposicion_id', oposicionId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> actualizarProgresoTema({
    required String userId,
    required String temaId,
    required int porcentaje,
    required int tiempoMinutos,
  }) async {
    await _supabase.from(SupabaseConfig.tablaProgresoTemas).upsert({
      'usuario_id': userId,
      'tema_id': temaId,
      'porcentaje_completado': porcentaje,
      'ultima_sesion': DateTime.now().toIso8601String(),
      'tiempo_total_minutos': tiempoMinutos,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> registrarResultadoEjercicio({
    required String userId,
    required String tipo,
    required String referenciaId,
    required bool correcto,
    int? tiempoSegundos,
    String? respuestaDada,
  }) async {
    await _supabase.from(SupabaseConfig.tablaResultadosEjercicios).insert({
      'usuario_id': userId,
      'tipo': tipo,
      'referencia_id': referenciaId,
      'correcto': correcto,
      if (tiempoSegundos != null) 'tiempo_segundos': tiempoSegundos,
      if (respuestaDada != null) 'respuesta_dada': respuestaDada,
    });
  }

  Future<void> iniciarSesionEstudio({
    required String userId,
    required String oposicionId,
    required String tipoActividad,
  }) async {
    await _supabase.from(SupabaseConfig.tablaSesionesEstudio).insert({
      'usuario_id': userId,
      'oposicion_id': oposicionId,
      'inicio': DateTime.now().toIso8601String(),
      'tipo_actividad': tipoActividad,
    });
  }

  Future<int> obtenerRachaActual(String userId) async {
    final hoy = DateTime.now();
    final hace30Dias = hoy.subtract(const Duration(days: 30));

    final data = await _supabase
        .from(SupabaseConfig.tablaSesionesEstudio)
        .select('inicio')
        .eq('usuario_id', userId)
        .gte('inicio', hace30Dias.toIso8601String())
        .order('inicio', ascending: false);

    if ((data as List).isEmpty) return 0;

    final diasConSesion = <String>{};
    for (final sesion in data) {
      final fecha = DateTime.parse(sesion['inicio'] as String);
      diasConSesion.add('${fecha.year}-${fecha.month}-${fecha.day}');
    }

    int racha = 0;
    DateTime diaActual = hoy;

    while (true) {
      final key = '${diaActual.year}-${diaActual.month}-${diaActual.day}';
      if (!diasConSesion.contains(key)) break;
      racha++;
      diaActual = diaActual.subtract(const Duration(days: 1));
    }

    return racha;
  }

  Future<Map<String, dynamic>> obtenerResumenProgreso(String userId) async {
    final sesiones = await _supabase
        .from(SupabaseConfig.tablaSesionesEstudio)
        .select('duracion_minutos')
        .eq('usuario_id', userId);
    final minutos = (sesiones as List).fold<int>(
      0,
      (sum, s) => sum + ((s['duracion_minutos'] as int?) ?? 0),
    );

    final progreso = await _supabase
        .from(SupabaseConfig.tablaProgresoTemas)
        .select('porcentaje_completado')
        .eq('usuario_id', userId);
    final temasConProgreso = (progreso as List).length;
    final completados =
        progreso
            .where((p) => (p['porcentaje_completado'] as int? ?? 0) >= 100)
            .length;

    final racha = await obtenerRachaActual(userId);

    return {
      'racha_actual': racha,
      'temas_totales': temasConProgreso,
      'temas_completados': completados,
      'minutos_totales': minutos,
      'puntos_totales': completados * 50,
    };
  }
}
