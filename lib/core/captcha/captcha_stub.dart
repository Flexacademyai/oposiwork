import 'package:flutter/widgets.dart';

/// Mango del captcha: el widget a renderizar y una función para reiniciarlo
/// (el token es de un solo uso; tras un intento fallido hay que regenerarlo).
class CaptchaHandle {
  final Widget widget;
  final void Function() reset;
  const CaptchaHandle({required this.widget, required this.reset});
}

/// Implementación para plataformas no-web: no renderiza nada.
/// (En móvil el CAPTCHA se integrará por separado vía WebView si se requiere.)
CaptchaHandle construirCaptcha({
  required void Function(String token) onToken,
  void Function()? onExpirado,
}) => CaptchaHandle(widget: const SizedBox.shrink(), reset: () {});
