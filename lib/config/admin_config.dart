/// Cuentas con acceso a pantallas internas (cobertura de fuentes, etc.).
/// El resto de usuarios no ve esas rutas ni sus accesos en la UI.
class AdminConfig {
  AdminConfig._();

  static const Set<String> emailsAdmin = {
    'flamencoworkllc@gmail.com',
    'israel.perles@gmail.com',
    'perles2209@hotmail.com',
  };

  static bool esAdmin(String? email) =>
      email != null && emailsAdmin.contains(email.toLowerCase());
}
