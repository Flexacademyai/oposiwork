import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cobertura_fuente.dart';
import '../models/oposicion.dart';
import '../models/convocatoria.dart';
import '../../config/supabase_config.dart';

class OposicionesRepository {
  final SupabaseClient _supabase;

  OposicionesRepository(this._supabase);

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
