import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/oposicion.dart';
import '../../data/models/convocatoria.dart';
import '../../data/repositories/oposiciones_repository.dart';
import 'auth_provider.dart';

final oposicionesRepositoryProvider = Provider<OposicionesRepository>((ref) {
  return OposicionesRepository(ref.watch(supabaseClientProvider));
});

final oposicionesActivasProvider = FutureProvider<List<Oposicion>>((ref) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerOposicionesActivas();
});

final oposicionProvider = FutureProvider.family<Oposicion?, String>((ref, id) async {
  return ref.watch(oposicionesRepositoryProvider).obtenerOposicionPorId(id);
});

final convocatoriaActualProvider = FutureProvider.family<Convocatoria?, String>(
  (ref, oposicionId) async {
    return ref
        .watch(oposicionesRepositoryProvider)
        .obtenerConvocatoriaActual(oposicionId);
  },
);
