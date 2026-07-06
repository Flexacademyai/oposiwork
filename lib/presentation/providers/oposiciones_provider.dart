import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cobertura_fuente.dart';
import '../../data/models/oposicion.dart';
import '../../data/models/convocatoria.dart';
import '../../data/repositories/oposiciones_repository.dart';
import 'auth_provider.dart';

final oposicionesRepositoryProvider = Provider<OposicionesRepository>((ref) {
  return OposicionesRepository(ref.watch(supabaseClientProvider));
});

/// Todas las oposiciones activas (con o sin convocatoria abierta) — listado general.
final todasLasOposicionesProvider = FutureProvider<List<Oposicion>>((
  ref,
) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerTodasLasOposiciones();
});

/// Todas las oposiciones activas con su estado de inscripción (para badges).
final oposicionesConEstadoProvider = FutureProvider<List<OposicionConEstado>>((
  ref,
) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerOposicionesConEstado();
});

/// Solo oposiciones con convocatoria abierta hoy (para destacar/filtrar).
final oposicionesActivasProvider = FutureProvider<List<Oposicion>>((ref) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerOposicionesActivas();
});

final resumenCoberturaProvider = FutureProvider<ResumenCobertura>((ref) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerResumenCobertura();
});

final fuentesCoberturaProvider = FutureProvider<List<FuenteCobertura>>((
  ref,
) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerFuentesCobertura();
});

final oposicionProvider = FutureProvider.family<Oposicion?, String>((
  ref,
  id,
) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerOposicionPorId(id);
});

final convocatoriaActualProvider = FutureProvider.family<Convocatoria?, String>(
  (ref, oposicionId) async {
    return ref
        .watch(oposicionesRepositoryProvider)
        .obtenerConvocatoriaActual(oposicionId);
  },
);

final usuarioSigueOposicionProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, oposicionId) async {
      final userId = ref.watch(usuarioActualProvider)?.id;
      if (userId == null) return false;
      return ref
          .watch(oposicionesRepositoryProvider)
          .usuarioSigueOposicion(usuarioId: userId, oposicionId: oposicionId);
    });

final seguimientoOposicionControllerProvider =
    Provider<SeguimientoOposicionController>((ref) {
      return SeguimientoOposicionController(ref);
    });

class SeguimientoOposicionController {
  SeguimientoOposicionController(this._ref);

  final Ref _ref;

  Future<void> cambiarSeguimiento({
    required String oposicionId,
    required bool seguir,
  }) async {
    final userId = _ref.read(usuarioActualProvider)?.id;
    if (userId == null) return;
    final repository = _ref.read(oposicionesRepositoryProvider);
    if (seguir) {
      await repository.seguirOposicion(
        usuarioId: userId,
        oposicionId: oposicionId,
      );
    } else {
      await repository.dejarDeSeguirOposicion(
        usuarioId: userId,
        oposicionId: oposicionId,
      );
    }
    _ref.invalidate(usuarioSigueOposicionProvider(oposicionId));
  }
}
