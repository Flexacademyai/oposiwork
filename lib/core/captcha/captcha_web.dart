// Implementación web del CAPTCHA. Usa librerías solo-web a propósito; este
// archivo nunca se importa en móvil (lo selecciona el export condicional).
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import '../../config/captcha_config.dart';
import 'captcha_stub.dart' show CaptchaHandle;

export 'captcha_stub.dart' show CaptchaHandle;

int _contador = 0;
bool _scriptInyectado = false;

/// Estado interno de un captcha renderizado: guarda el id del widget devuelto
/// por el SDK para poder reiniciarlo.
class _EstadoCaptcha {
  Object? widgetId;
  final String apiNombre =
      CaptchaConfig.proveedor == 'turnstile' ? 'turnstile' : 'hcaptcha';

  void reset() {
    final api = js.context[apiNombre];
    if (api == null) return;
    try {
      if (widgetId != null) {
        (api as js.JsObject).callMethod('reset', [widgetId]);
      } else {
        (api as js.JsObject).callMethod('reset');
      }
    } catch (_) {
      // El SDK aún no estaba listo; sin token previo no hay nada que reiniciar.
    }
  }
}

/// Renderiza el widget de hCaptcha / Cloudflare Turnstile y notifica el token.
///
/// IMPORTANTE: invocar UNA sola vez (p. ej. en initState) y guardar el handle.
CaptchaHandle construirCaptcha({
  required void Function(String token) onToken,
  void Function()? onExpirado,
}) {
  if (!CaptchaConfig.configurado) {
    return CaptchaHandle(widget: const SizedBox.shrink(), reset: () {});
  }

  _inyectarScript();

  final viewType = 'oposiwork-captcha-${_contador++}';
  final divId = '$viewType-box';
  final estado = _EstadoCaptcha();

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final el =
        html.DivElement()
          ..id = divId
          ..style.width = '100%'
          ..style.display = 'flex'
          ..style.justifyContent = 'center';
    _renderizar(divId, estado, onToken, onExpirado);
    return el;
  });

  return CaptchaHandle(
    widget: SizedBox(height: 90, child: HtmlElementView(viewType: viewType)),
    reset: () {
      estado.reset();
      onExpirado?.call();
    },
  );
}

void _inyectarScript() {
  if (_scriptInyectado) return;
  final src =
      CaptchaConfig.proveedor == 'turnstile'
          ? 'https://challenges.cloudflare.com/turnstile/v0/api.js'
          : 'https://js.hcaptcha.com/1/api.js';
  final yaPresente = html.document
      .querySelectorAll('script')
      .any((s) => (s as html.ScriptElement).src.contains(src));
  if (!yaPresente) {
    html.document.head!.append(
      html.ScriptElement()
        ..src = src
        ..async = true
        ..defer = true,
    );
  }
  _scriptInyectado = true;
}

void _renderizar(
  String divId,
  _EstadoCaptcha estado,
  void Function(String token) onToken,
  void Function()? onExpirado,
) {
  var renderizado = false;

  void intentar() {
    if (renderizado) return;
    final api = js.context[estado.apiNombre];
    final elemento = html.document.getElementById(divId);
    // Reintentar hasta que el SDK haya cargado y el div esté en el DOM.
    if (api == null || elemento == null) {
      Future.delayed(const Duration(milliseconds: 200), intentar);
      return;
    }

    final opciones = js.JsObject.jsify({'sitekey': CaptchaConfig.siteKey});
    opciones['callback'] = js.allowInterop(
      (token) => onToken(token.toString()),
    );
    opciones['expired-callback'] = js.allowInterop(([_]) => onExpirado?.call());
    opciones['error-callback'] = js.allowInterop(([_]) => onExpirado?.call());

    try {
      estado.widgetId = (api as js.JsObject).callMethod('render', [
        divId,
        opciones,
      ]);
      renderizado = true;
    } catch (_) {
      Future.delayed(const Duration(milliseconds: 300), intentar);
    }
  }

  intentar();
}
