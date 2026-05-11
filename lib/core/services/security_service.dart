/// Validación y saneamiento de entradas en el cliente Flutter.
///
/// Nota: el SDK de Supabase usa queries parametrizadas — no hay inyección SQL
/// posible a través de la app. Este servicio añade defensa en profundidad:
/// rechaza o limpia datos malformados antes de enviarlos al backend.
class SecurityService {
  SecurityService._();

  // ── Expresiones regulares ───────────────────────────────────────────────

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static final _email = RegExp(
    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
  );

  // Nombre de persona: letras (incluyendo acentos/diacríticos), espacios, guiones y apóstrofes
  static final _nombre = RegExp(r"^[\p{L}\s'\-]{1,100}$", unicode: true);

  // Caracteres de control ASCII (excluye \t \n \r que son legítimos)
  static final _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

  // Tags HTML
  static final _htmlTags = RegExp(r'<[^>]*>');

  // ── Saneamiento ─────────────────────────────────────────────────────────

  /// Elimina caracteres de control y tags HTML. Uso general para texto libre.
  static String sanitizar(String input) {
    return input
        .replaceAll(_controlChars, '')
        .replaceAll(_htmlTags, '')
        .trim();
  }

  /// Saneamiento estricto para campos de nombre de persona.
  /// Permite letras Unicode, espacios, guiones y apóstrofes.
  static String sanitizarNombre(String input) {
    return sanitizar(input).replaceAll(RegExp(r"[^\p{L}\s'\-]", unicode: true), '').trim();
  }

  // ── Validadores ─────────────────────────────────────────────────────────

  static bool esUuidValido(String valor) => _uuid.hasMatch(valor);

  static bool esEmailValido(String email) => _email.hasMatch(email);

  static bool esNombreValido(String nombre) =>
      nombre.isNotEmpty && _nombre.hasMatch(nombre);

  static bool longitudValida(String texto, {int min = 1, int max = 1000}) =>
      texto.length >= min && texto.length <= max;
}
