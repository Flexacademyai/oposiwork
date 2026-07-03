import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cobertura_fuente.dart';
import '../models/oposicion.dart';
import '../models/convocatoria.dart';
import '../../config/supabase_config.dart';

/// Estado de inscripción derivado de las convocatorias de una oposición.
enum EstadoInscripcion { abierta, proxima, cerrada, sinConvocatoria }

/// Oposición junto con su estado de inscripción calculado.
class OposicionConEstado {
  final Oposicion oposicion;
  final EstadoInscripcion estado;
  const OposicionConEstado({required this.oposicion, required this.estado});
}

class OposicionesRepository {
  final SupabaseClient _supabase;

  OposicionesRepository(this._supabase);

  /// Todas las oposiciones activas, tengan o no convocatoria abierta ahora.
  /// El estado concreto de la convocatoria se muestra en el detalle.
  Future<List<Oposicion>> obtenerTodasLasOposiciones() async {
    final data = await _supabase
        .from(SupabaseConfig.tablaOposiciones)
        .select()
        .eq('activa', true)
        .order('nombre');
    return (data as List).map((e) => Oposicion.fromMap(e)).toList();
  }

  /// Todas las oposiciones activas con su estado de inscripción calculado,
  /// en una sola consulta (sin N+1). Para el listado con badges.
  Future<List<OposicionConEstado>> obtenerOposicionesConEstado() async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _supabase
        .from(SupabaseConfig.tablaOposiciones)
        .select(
          '*, convocatorias(estado, fecha_inicio_instancias, fecha_fin_instancias)',
        )
        .eq('activa', true)
        .order('nombre');

    return (data as List).map((row) {
      final convocatorias =
          ((row['convocatorias'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
      return OposicionConEstado(
        oposicion: Oposicion.fromMap(row),
        estado: _calcularEstado(convocatorias, hoy),
      );
    }).toList();
  }

  EstadoInscripcion _calcularEstado(
    List<Map<String, dynamic>> convocatorias,
    String hoy,
  ) {
    if (convocatorias.isEmpty) return EstadoInscripcion.sinConvocatoria;
    var hayProxima = false;
    for (final c in convocatorias) {
      final estado = c['estado'] as String?;
      final ini = c['fecha_inicio_instancias'] as String?;
      final fin = c['fecha_fin_instancias'] as String?;
      // Abierta hoy (comparación lexicográfica válida en formato YYYY-MM-DD).
      if (estado == 'abierta' &&
          ini != null &&
          fin != null &&
          ini.compareTo(hoy) <= 0 &&
          fin.compareTo(hoy) >= 0) {
        return EstadoInscripcion.abierta;
      }
      if (ini != null &&
          ini.compareTo(hoy) > 0 &&
          estado != 'cerrada' &&
          estado != 'suspendida') {
        hayProxima = true;
      }
    }
    return hayProxima ? EstadoInscripcion.proxima : EstadoInscripcion.cerrada;
  }

  /// Solo oposiciones con convocatoria de inscripción abierta hoy.
  /// El listado general usa [obtenerTodasLasOposiciones] para que TODAS
  /// sean visibles; este método sirve para destacar/filtrar abiertas.
  Future<List<Oposicion>> obtenerOposicionesActivas() async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _supabase
        .from(SupabaseConfig.tablaOposiciones)
        .select('*, convocatorias!inner(id)')
        .eq('activa', true)
        .eq('convocatorias.estado', 'abierta')
        .lte('convocatorias.fecha_inicio_instancias', hoy)
        .gte('convocatorias.fecha_fin_instancias', hoy)
        .order('nombre');

    final porId = <String, Oposicion>{};
    for (final row in data as List) {
      final oposicion = Oposicion.fromMap(row);
      porId[oposicion.id] = oposicion;
    }
    return porId.values.toList();
  }

  Future<Oposicion?> obtenerOposicionPorSlug(String slug) async {
    final data =
        await _supabase
            .from(SupabaseConfig.tablaOposiciones)
            .select()
            .eq('slug', slug)
            .maybeSingle();
    if (data == null) return null;
    return Oposicion.fromMap(data);
  }

  Future<Oposicion?> obtenerOposicionPorId(String id) async {
    final data =
        await _supabase
            .from(SupabaseConfig.tablaOposiciones)
            .select()
            .eq('id', id)
            .maybeSingle();
    if (data == null) return null;
    return Oposicion.fromMap(data);
  }

  Future<Convocatoria?> obtenerConvocatoriaActual(String oposicionId) async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final vigente =
        await _supabase
            .from(SupabaseConfig.tablaConvocatorias)
            .select()
            .eq('oposicion_id', oposicionId)
            .eq('estado', 'abierta')
            .lte('fecha_inicio_instancias', hoy)
            .gte('fecha_fin_instancias', hoy)
            .order('fecha_fin_instancias', ascending: true)
            .limit(1)
            .maybeSingle();

    if (vigente != null) return Convocatoria.fromMap(vigente);

    final ultima =
        await _supabase
            .from(SupabaseConfig.tablaConvocatorias)
            .select()
            .eq('oposicion_id', oposicionId)
            .neq('estado', 'suspendida')
            .order('fecha_publicacion_boe', ascending: false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
    if (ultima == null) return null;
    return Convocatoria.fromMap(ultima);
  }

  Future<List<Convocatoria>> obtenerHistorialConvocatorias(
    String oposicionId,
  ) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaConvocatorias)
        .select()
        .eq('oposicion_id', oposicionId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Convocatoria.fromMap(e)).toList();
  }

  Future<ResumenCobertura> obtenerResumenCobertura() async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final fuentes = await _supabase
        .from('boletines')
        .select('ambito, activo')
        .order('ambito');
    final convocatorias = await _supabase
        .from(SupabaseConfig.tablaConvocatorias)
        .select('estado, fecha_inicio_instancias, fecha_fin_instancias');
    final auditorias = await _supabase
        .from('fuente_auditoria')
        .select('fuente_url, estado, items_detectados, ejecutado_en')
        .gte(
          'ejecutado_en',
          DateTime.now()
              .subtract(const Duration(days: 7))
              .toUtc()
              .toIso8601String(),
        )
        .order('ejecutado_en', ascending: false)
        .limit(500);

    final fuentesList = (fuentes as List).cast<Map<String, dynamic>>();
    final convocatoriasList =
        (convocatorias as List).cast<Map<String, dynamic>>();
    final auditoriasList = (auditorias as List).cast<Map<String, dynamic>>();
    final ultimasPorFuente = <String, Map<String, dynamic>>{};
    for (final auditoria in auditoriasList) {
      final url = auditoria['fuente_url']?.toString();
      if (url == null || ultimasPorFuente.containsKey(url)) continue;
      ultimasPorFuente[url] = auditoria;
    }

    final fuentesActivas = fuentesList.where((f) => f['activo'] != false);
    final auditoriasUltimas = ultimasPorFuente.values.toList();
    DateTime? ultimaAuditoria;
    for (final auditoria in auditoriasUltimas) {
      final fecha = DateTime.tryParse(
        auditoria['ejecutado_en']?.toString() ?? '',
      );
      if (fecha != null &&
          (ultimaAuditoria == null || fecha.isAfter(ultimaAuditoria))) {
        ultimaAuditoria = fecha;
      }
    }

    return ResumenCobertura(
      fuentesTotales: fuentesList.length,
      fuentesActivas: fuentesActivas.length,
      fuentesNacionales:
          fuentesList
              .where((f) => f['ambito'] == 'nacional' && f['activo'] != false)
              .length,
      fuentesAutonomicas:
          fuentesList
              .where((f) => f['ambito'] == 'autonomico' && f['activo'] != false)
              .length,
      fuentesProvinciales:
          fuentesList
              .where((f) => f['ambito'] == 'provincial' && f['activo'] != false)
              .length,
      convocatoriasTotales: convocatoriasList.length,
      convocatoriasAbiertas:
          convocatoriasList.where((c) => c['estado'] == 'abierta').length,
      convocatoriasInscripcionAbierta:
          convocatoriasList.where((c) {
            return c['estado'] == 'abierta' &&
                (c['fecha_inicio_instancias']?.toString() ?? '').compareTo(
                      hoy,
                    ) <=
                    0 &&
                (c['fecha_fin_instancias']?.toString() ?? '').compareTo(hoy) >=
                    0;
          }).length,
      fuentesAuditadas: auditoriasUltimas.length,
      fuentesOk: auditoriasUltimas.where((a) => a['estado'] == 'ok').length,
      fuentesSinResultados:
          auditoriasUltimas
              .where((a) => a['estado'] == 'sin_resultados')
              .length,
      fuentesConError:
          auditoriasUltimas.where((a) => a['estado'] == 'error').length,
      ultimaAuditoria: ultimaAuditoria,
    );
  }

  Future<List<FuenteCobertura>> obtenerFuentesCobertura() async {
    final fuentes = await _supabase
        .from('boletines')
        .select('nombre, ambito, territorio, url, tipo, activo, prioridad')
        .order('prioridad')
        .order('nombre');
    final auditorias = await _supabase
        .from('fuente_auditoria')
        .select('fuente_url, estado, items_detectados, error, ejecutado_en')
        .gte(
          'ejecutado_en',
          DateTime.now()
              .subtract(const Duration(days: 7))
              .toUtc()
              .toIso8601String(),
        )
        .order('ejecutado_en', ascending: false)
        .limit(500);

    final ultimasPorUrl = <String, Map<String, dynamic>>{};
    for (final row in (auditorias as List).cast<Map<String, dynamic>>()) {
      final url = row['fuente_url']?.toString();
      if (url == null || ultimasPorUrl.containsKey(url)) continue;
      ultimasPorUrl[url] = row;
    }

    return (fuentes as List).cast<Map<String, dynamic>>().map((fuente) {
      final url = fuente['url']?.toString();
      final auditoria = url != null ? ultimasPorUrl[url] : null;
      return FuenteCobertura(
        nombre: fuente['nombre']?.toString() ?? 'Fuente sin nombre',
        ambito: fuente['ambito']?.toString() ?? 'sin ambito',
        territorio: fuente['territorio']?.toString(),
        url: url,
        tipo: fuente['tipo']?.toString() ?? 'html',
        activa: fuente['activo'] != false,
        prioridad: int.tryParse(fuente['prioridad']?.toString() ?? '') ?? 100,
        estadoAuditoria: auditoria?['estado']?.toString(),
        itemsDetectados:
            int.tryParse(auditoria?['items_detectados']?.toString() ?? '') ?? 0,
        error: auditoria?['error']?.toString(),
        ejecutadoEn: DateTime.tryParse(
          auditoria?['ejecutado_en']?.toString() ?? '',
        ),
      );
    }).toList();
  }

  Future<bool> usuarioSigueOposicion({
    required String usuarioId,
    required String oposicionId,
  }) async {
    final data =
        await _supabase
            .from('usuario_oposiciones')
            .select('id')
            .eq('usuario_id', usuarioId)
            .eq('oposicion_id', oposicionId)
            .eq('activa', true)
            .maybeSingle();
    return data != null;
  }

  Future<void> seguirOposicion({
    required String usuarioId,
    required String oposicionId,
  }) async {
    await _supabase.from('usuario_oposiciones').upsert({
      'usuario_id': usuarioId,
      'oposicion_id': oposicionId,
      'activa': true,
    }, onConflict: 'usuario_id,oposicion_id');
  }

  Future<void> dejarDeSeguirOposicion({
    required String usuarioId,
    required String oposicionId,
  }) async {
    await _supabase
        .from('usuario_oposiciones')
        .update({'activa': false})
        .eq('usuario_id', usuarioId)
        .eq('oposicion_id', oposicionId);
  }
}
