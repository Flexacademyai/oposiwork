import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityService {
  final SupabaseClient _supabase;

  const SecurityService(this._supabase);

  static const _limites = {
    'login': (minuto: 5, hora: 20),
    'registro': (minuto: 3, hora: 10),
  };

  /// Llama a la función RPC [verificar_rate_limit] de Supabase.
  /// Devuelve [true] si la acción está permitida, [false] si se superó el límite.
  /// En caso de error en la llamada devuelve [true] (fail-open) para no bloquear
  /// al usuario por problemas de red.
  Future<bool> checkRateLimit(String accion) async {
    final limites = _limites[accion];
    if (limites == null) return true;

    try {
      final resultado = await _supabase.rpc(
        'verificar_rate_limit',
        params: {
          'p_accion': accion,
          'p_limite_minuto': limites.minuto,
          'p_limite_hora': limites.hora,
        },
      );
      return resultado as bool? ?? true;
    } catch (_) {
      return true;
    }
  }
}
