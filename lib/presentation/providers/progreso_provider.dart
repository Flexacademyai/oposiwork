import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/progreso_repository.dart';
import 'auth_provider.dart';

final progresoRepositoryProvider = Provider<ProgresoRepository>((ref) {
  return ProgresoRepository(ref.watch(supabaseClientProvider));
});

final rachaActualProvider = FutureProvider<int>((ref) async {
  final usuario = ref.watch(usuarioActualProvider);
  if (usuario == null) return 0;
  return ref.watch(progresoRepositoryProvider).obtenerRachaActual(usuario.id);
});

final progresoOposicionProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      oposicionId,
    ) async {
      final usuario = ref.watch(usuarioActualProvider);
      if (usuario == null) return [];
      return ref
          .watch(progresoRepositoryProvider)
          .obtenerProgresoOposicion(usuario.id, oposicionId);
    });
