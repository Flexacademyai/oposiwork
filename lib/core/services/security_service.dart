/// Validacion y saneamiento de entradas en el cliente Flutter.
///
/// El SDK de Supabase usa peticiones parametrizadas y RLS en servidor. Este
/// servicio anade defensa en profundidad: normaliza entradas, bloquea payloads
/// obvios y evita enviar texto malformado a la base de datos o Edge Functions.
class SecurityService {
  SecurityService._();

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static final _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@([A-Za-z0-9-]+\.)+[A-Za-z]{2,63}$",
  );

  static final _nombre = RegExp(r"^[\p{L}\s'\-]{1,100}$", unicode: true);
  static final _passwordSegura = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,128}$');
  static final _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
  static final _htmlTags = RegExp(r'<[^>]*>');
  static final _payloadMalicioso = RegExp(
    r"(<\s*script|javascript:|on\w+\s*=|--|/\*|\*/|;\s*(drop|alter|truncate|delete|insert|update)\b|\bunion\s+select\b|\bor\s+1\s*=\s*1\b)",
    caseSensitive: false,
  );

  static String sanitizar(String input) {
    return input.replaceAll(_controlChars, '').replaceAll(_htmlTags, '').trim();
  }

  static String normalizarEmail(String input) => sanitizar(input).toLowerCase();

  static String sanitizarNombre(String input) {
    return sanitizar(
      input,
    ).replaceAll(RegExp(r"[^\p{L}\s'\-]", unicode: true), '').trim();
  }

  static bool esUuidValido(String valor) => _uuid.hasMatch(valor);

  static bool esEmailValido(String email) => _email.hasMatch(email);

  static bool esNombreValido(String nombre) =>
      nombre.isNotEmpty && _nombre.hasMatch(nombre);

  static bool esPasswordValida(String password) =>
      _passwordSegura.hasMatch(password) && !contienePayloadMalicioso(password);

  static bool contienePayloadMalicioso(String texto) =>
      _payloadMalicioso.hasMatch(texto);

  static bool longitudValida(String texto, {int min = 1, int max = 1000}) =>
      texto.length >= min && texto.length <= max;

  static String? validarEmail(String? value) {
    final email = normalizarEmail(value ?? '');
    if (email.isEmpty) return 'Campo requerido';
    if (!longitudValida(email, min: 6, max: 254) || !esEmailValido(email)) {
      return 'Email invalido';
    }
    if (contienePayloadMalicioso(email)) return 'Entrada no permitida';
    return null;
  }

  static String? validarNombre(String? value, {bool requerido = true}) {
    final nombre = sanitizarNombre(value ?? '');
    if (nombre.isEmpty) return requerido ? 'Campo requerido' : null;
    if (!longitudValida(nombre, min: 1, max: 100) || !esNombreValido(nombre)) {
      return 'Solo letras, espacios, guiones y apostrofes';
    }
    if (contienePayloadMalicioso(value ?? '')) return 'Entrada no permitida';
    return null;
  }

  static String? validarPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Campo requerido';
    if (!esPasswordValida(password)) {
      return 'Minimo 8 caracteres, con letras y numeros';
    }
    return null;
  }

  static String? validarTextoLibre(
    String? value, {
    int min = 1,
    int max = 500,
    bool requerido = true,
  }) {
    final texto = sanitizar(value ?? '');
    if (texto.isEmpty) return requerido ? 'Campo requerido' : null;
    if (!longitudValida(texto, min: min, max: max)) {
      return 'Debe tener entre $min y $max caracteres';
    }
    if (contienePayloadMalicioso(value ?? '')) return 'Entrada no permitida';
    return null;
  }
}
