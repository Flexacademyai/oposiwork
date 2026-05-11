import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oposicion.dart';
import '../models/convocatoria.dart';
import '../../config/supabase_config.dart';

class OposicionesRepository {
  final SupabaseClient _supabase;

  OposicionesRepository(this._supabase);

  Future<List<Oposicion>> obtenerOposicionesActivas() async {
    final data = await _supabase
        .from(SupabaseConfig.tablaOposiciones)
        .select()
        .eq('activa', true)
        .order('nombre');
    return (data as List).map((e) => Oposicion.fromMap(e)).toList();
  }

  Future<Oposicion?> obtenerOposicionPorSlug(String slug) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaOposiciones)
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (data == null) return null;
    return Oposicion.fromMap(data);
  }

  Future<Oposicion?> obtenerOposicionPorId(String id) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaOposiciones)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Oposicion.fromMap(data);
  }

  Future<Convocatoria?> obtenerConvocatoriaActual(String oposicionId) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaConvocatorias)
        .select()
        .eq('oposicion_id', oposicionId)
        .neq('estado', 'suspendida')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return Convocatoria.fromMap(data);
  }

  Future<List<Convocatoria>> obtenerHistorialConvocatorias(String oposicionId) async {
    final data = await _supabase
        .from(SupabaseConfig.tablaConvocatorias)
        .select()
        .eq('oposicion_id', oposicionId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Convocatoria.fromMap(e)).toList();
  }
}
