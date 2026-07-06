import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/perfil.dart';
import '../../data/repositories/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).estadoAuth;
});

final usuarioActualProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).usuarioActual;
});

final estaAutenticadoProvider = Provider<bool>((ref) {
  return ref.watch(usuarioActualProvider) != null;
});

final perfilProvider = FutureProvider<Perfil?>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);
  return await repo.obtenerPerfil();
});

final esPremiumProvider = Provider<bool>((ref) {
  final perfilAsync = ref.watch(perfilProvider);
  return perfilAsync.when(
    data: (perfil) => perfil?.esPremium ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> registrar({
    required String email,
    required String password,
    String? nombre,
    String? apellidos,
    String? captchaToken,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.registrarConEmail(
        email: email,
        password: password,
        nombre: nombre,
        apellidos: apellidos,
        captchaToken: captchaToken,
      );
    });
  }

  Future<void> iniciarSesion({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .iniciarSesionConEmail(
            email: email,
            password: password,
            captchaToken: captchaToken,
          );
    });
  }

  Future<void> iniciarSesionGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).iniciarSesionConGoogle();
    });
  }

  Future<void> cerrarSesion() async {
    await ref.read(authRepositoryProvider).cerrarSesion();
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
