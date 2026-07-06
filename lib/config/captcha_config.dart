import 'package:flutter/foundation.dart';

/// Configuración del CAPTCHA exigido por Supabase Auth cuando está activada la
/// protección anti-bots (Authentication → Settings → Bot and Abuse Protection).
///
/// La *site key* es PÚBLICA (se incrusta en el cliente); no es un secreto.
/// Se inyecta en compilación con --dart-define-from-file=.env, igual que el
/// resto de configuración del proyecto.
class CaptchaConfig {
  CaptchaConfig._();

  /// Proveedor activo en Supabase: 'hcaptcha' (por defecto) o 'turnstile'.
  /// DEBE coincidir con el seleccionado en el dashboard de Supabase.
  static const String proveedor = String.fromEnvironment(
    'CAPTCHA_PROVIDER',
    defaultValue: 'hcaptcha',
  );

  /// Site key pública del proveedor. Vacío = captcha desactivado.
  static const String siteKey = String.fromEnvironment(
    'CAPTCHA_SITE_KEY',
    defaultValue: '',
  );

  /// Hay una site key configurada.
  static bool get configurado => siteKey.isNotEmpty;

  /// El widget de captcha solo se renderiza en web (móvil se integrará aparte).
  static bool get activoEnWeb => kIsWeb && configurado;
}
