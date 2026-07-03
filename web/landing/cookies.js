/*
 * Banner de consentimiento de cookies — Oposiwork
 * Cumplimiento RGPD / LSSI-CE / guía AEPD.
 *
 * Actualmente el sitio solo usa cookies/almacenamiento propios y técnicos
 * (no hay analítica ni rastreadores de terceros), por lo que el banner es
 * informativo con aceptación expresa. Si en el futuro se añade analítica o
 * marketing, NO debe cargarse hasta comprobar:
 *     window.oposiworkConsent && oposiworkConsent.aceptaAnaliticas()
 * (es decir, consentimiento previo y granular, opt-in por defecto NO).
 */
(function () {
  'use strict';
  var CLAVE = 'oposiwork_cookie_consent_v1';

  function leer() {
    try { return JSON.parse(localStorage.getItem(CLAVE) || 'null'); }
    catch (_) { return null; }
  }
  function guardar(valor) {
    try { localStorage.setItem(CLAVE, JSON.stringify(valor)); } catch (_) {}
  }

  // API pública para gating de scripts no esenciales en el futuro.
  window.oposiworkConsent = {
    estado: leer(),
    aceptaAnaliticas: function () {
      var e = leer();
      return !!(e && e.analiticas === true);
    }
  };

  // Si ya hay decisión registrada, no mostramos nada.
  if (leer()) return;

  function crearBanner() {
    var wrap = document.createElement('div');
    wrap.setAttribute('role', 'dialog');
    wrap.setAttribute('aria-live', 'polite');
    wrap.setAttribute('aria-label', 'Aviso de cookies');
    wrap.style.cssText = [
      'position:fixed', 'left:16px', 'right:16px', 'bottom:16px', 'z-index:9999',
      'max-width:880px', 'margin:0 auto', 'background:#0f172a', 'color:#f1f5f9',
      'border:1px solid #334155', 'border-radius:12px', 'padding:18px 20px',
      'box-shadow:0 10px 40px rgba(0,0,0,.35)', 'font-size:14px', 'line-height:1.5',
      'display:flex', 'flex-wrap:wrap', 'gap:14px', 'align-items:center',
      'justify-content:space-between',
      'font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif'
    ].join(';');

    var texto = document.createElement('p');
    texto.style.cssText = 'margin:0;flex:1 1 320px;min-width:260px;';
    texto.innerHTML = 'Usamos cookies y almacenamiento propios necesarios para el ' +
      'funcionamiento del sitio. No utilizamos rastreadores de terceros. ' +
      'Consulta nuestra <a href="/cookies/" style="color:#7dd3fc;text-decoration:underline;">' +
      'Política de Cookies</a>.';

    var botones = document.createElement('div');
    botones.style.cssText = 'display:flex;gap:10px;flex:0 0 auto;';

    function boton(label, primario) {
      var b = document.createElement('button');
      b.type = 'button';
      b.textContent = label;
      b.style.cssText = [
        'cursor:pointer', 'border-radius:8px', 'padding:10px 18px',
        'font-size:14px', 'font-weight:600', 'border:1px solid',
        primario ? 'background:#2563eb;border-color:#2563eb;color:#fff'
                 : 'background:transparent;border-color:#475569;color:#e2e8f0'
      ].join(';');
      return b;
    }

    var aceptar = boton('Aceptar', true);
    var rechazar = boton('Solo necesarias', false);

    function cerrar(analiticas) {
      guardar({ necesarias: true, analiticas: analiticas, fecha: new Date().toISOString() });
      window.oposiworkConsent.estado = leer();
      if (wrap.parentNode) wrap.parentNode.removeChild(wrap);
    }
    aceptar.addEventListener('click', function () { cerrar(true); });
    rechazar.addEventListener('click', function () { cerrar(false); });

    botones.appendChild(rechazar);
    botones.appendChild(aceptar);
    wrap.appendChild(texto);
    wrap.appendChild(botones);
    return wrap;
  }

  function montar() { document.body.appendChild(crearBanner()); }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', montar);
  } else {
    montar();
  }
})();
