// Punto de entrada del widget de CAPTCHA.
//
// Resuelve a la implementación web (dart:html / dart:ui_web) cuando se compila
// para web, y a un stub no-op en móvil/escritorio. Así el código de las
// pantallas de auth es idéntico en todas las plataformas.
export 'captcha_stub.dart' if (dart.library.html) 'captcha_web.dart';
