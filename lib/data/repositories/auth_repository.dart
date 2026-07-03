import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil.dart';
import '../../config/supabase_config.dart';
import '../../core/services/security_service.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get usuarioActual => _supabase.auth.currentUser;

  Stream<AuthState> get estadoAuth => _supabase.auth.onAuthStateChange;

  bool get estaAutenticado => usuarioActual != null;

  Future<AuthResponse> registrarConEmail({
    required String email,
    required String password,
    String? nombre,
    String? apellidos,
    String? captchaToken,
  }) async {
    final nombreLimpio =
        nombre != null ? SecurityService.sanitizarNombre(nombre) : null;
    final apellidosLimpio =
        apellidos != null ? SecurityService.sanitizarNombre(apellidos) : null;

    final response = await _supabase.auth.signUp(
      email: SecurityService.normalizarEmail(email),
      password: password,
      captchaToken: captchaToken,
      data: {
        if (nombreLimpio != null && nombreLimpio.isNotEmpty)
          'nombre': nombreLimpio,
        if (apellidosLimpio != null && apellidosLimpio.isNotEmpty)
          'apellidos': apellidosLimpio,
      },
    );
    return response;
  }

  Future<AuthResponse> iniciarSesionConEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: SecurityService.normalizarEmail(email),
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<bool> iniciarSesionConGoogle() async {
    return await _supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  Future<void> enviarRecuperacionContrasena(
    String email, {
    String? captchaToken,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      SecurityService.normalizarEmail(email),
      captchaToken: captchaToken,
    );
  }

  Future<Perfil?> obtenerPerfil() async {
    final userId = usuarioActual?.id;
    if (userId == null) return null;

    final data =
        await _supabase
            .from(SupabaseConfig.tablaPerfiles)
            .select()
            .eq('id', userId)
            .maybeSingle();

    if (data == null) return null;
    return Perfil.fromMap(data);
  }

  Future<void> actualizarPerfil({
    String? nombre,
    String? apellidos,
    String? avatarUrl,
    bool? notificacionesPush,
    bool? notificacionesEmail,
  }) async {
    final userId = usuarioActual?.id;
    if (userId == null) return;

    final nombreLimpio =
        nombre != null ? SecurityService.sanitizarNombre(nombre) : null;
    final apellidosLimpio =
        apellidos != null ? SecurityService.sanitizarNombre(apellidos) : null;

    await _supabase
        .from(SupabaseConfig.tablaPerfiles)
        .update({
          if (nombreLimpio != null && nombreLimpio.isNotEmpty)
            'nombre': nombreLimpio,
          if (apellidosLimpio != null && apellidosLimpio.isNotEmpty)
            'apellidos': apellidosLimpio,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (notificacionesPush != null)
            'notificaciones_push': notificacionesPush,
          if (notificacionesEmail != null)
            'notificaciones_email': notificacionesEmail,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }
}
