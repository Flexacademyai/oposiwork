class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String oposiciones = '/oposiciones';
  static const String cobertura = '/cobertura';
  static const String oposicionDetail = '/oposiciones/:id';
  static const String temario = '/oposiciones/:id/temario';
  static const String temaDetail = '/oposiciones/:id/temario/:temaId';
  static const String flashcards = '/oposiciones/:id/flashcards';
  static const String test = '/oposiciones/:id/test';
  static const String resultadoTest = '/oposiciones/:id/test/resultado';
  static const String supuestos = '/oposiciones/:id/supuestos';
  static const String psicotecnicos = '/oposiciones/:id/psicotecnicos';
  static const String progreso = '/progreso';
  static const String planEstudio = '/estudio/plan';
  static const String alarmas = '/estudio/alarmas';
  static const String perfil = '/perfil';
  static const String notificaciones = '/notificaciones';
  static const String suscripcion = '/suscripcion';
  static const String simulacro = '/simulacro';
  static const String resultadoSimulacro = '/simulacro/resultado';
  static const String chat = '/oposiciones/:id/chat';
  static const String voz = '/oposiciones/:id/voz';
}
