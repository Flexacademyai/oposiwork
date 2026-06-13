# MVP de lanzamiento - Oposiwork

Ultima revision local: 2026-06-11.

## Estado listo para MVP

- Landing SEO indexable en la raiz del dominio.
- App Flutter Web servida bajo `/app/`.
- Registro, login, rutas privadas y perfil de usuario.
- Listado y ficha de oposiciones activas desde Supabase.
- Monitor BOE/boletines desplegable y cron preparado en Vercel.
- Notificaciones preparadas para avisar cambios detectados en convocatorias.
- Seguridad base: validacion de formularios, sanitizacion, RLS en tablas sensibles y CSP en Vercel.
- Build de lanzamiento generado en `build/seo`.

## Pagos

Stripe queda activado para web. App Store y Google Play siguen pendientes porque los pagos dentro de apps moviles deben gestionarse con las compras de cada plataforma.

Para compilar la web con Stripe activo:

```powershell
.\scripts\build_seo_web.ps1 -PagosHabilitados
```

Para compilar sin pagos activos:

```powershell
.\scripts\build_seo_web.ps1
```

Estado actual:

- Web: Stripe Checkout activo.
- Web: portal de cliente Stripe disponible para usuarios con `stripe_customer_id`.
- Movil: RevenueCat/App Store/Google Play quedan desactivados hasta configurar productos nativos.
- No se ha realizado una compra real de comprobacion.
- Despliegue web con Stripe activo: `https://oposiwork-7jqrrruon-israels-projects-904acd7c.vercel.app`, aliasado a `https://www.oposiwork.com`.

## Verificaciones realizadas

- `python scripts\verify_text_encoding.py`: OK.
- `flutter analyze`: OK.
- `flutter test`: OK, 37 tests.
- `flutter build web --release --dart-define-from-file=.env`: OK.
- `flutter build web --release --base-href /app/ --dart-define-from-file=.env`: OK.
- Artefacto `build/seo`: contiene landing, app Flutter, APIs y `vercel.json`.
- Vercel production deploy: OK, aliasado a `https://www.oposiwork.com`.
- Vercel production deploy con Stripe web activo: OK.
- `main.dart.js` en produccion contiene `create-stripe-checkout` y texto de pago seguro con Stripe.
- Edge Functions Stripe activas en Supabase: `create-stripe-checkout`, `create-stripe-portal`, `webhook-stripe`.
- Android App Bundle release: OK, firmado y listo para Google Play en `build/app/outputs/bundle/release/app-release.aab`.
- Iconos de Android, iOS y web sustituidos por icono propio de Oposiwork.
- iOS preparado a nivel de proyecto, con `ios/Podfile` y target minimo iOS 13.0. La IPA final requiere macOS/Xcode.

## Estado remoto de datos

Consulta remota Supabase realizada el 2026-06-09:

- Fuentes oficiales activas en catalogo: 63.
- Convocatorias totales: 35.
- Convocatorias abiertas: 30.
- Convocatorias con plazo de inscripcion abierto: 29.

Auditoria historica de fuentes:

- OK: 282 ejecuciones con 5.774 items detectados.
- Error: 728 ejecuciones.
- Sin resultados: 789 ejecuciones.

Conclusion: el MVP puede lanzarse como beta con datos reales, pero no debe prometer todavia cobertura total garantizada de todas las convocatorias de Espana.

## Pendiente antes de anunciar publicamente

- Revisar en Supabase que el monitor esta capturando convocatorias reales de BOE, boletines autonomicos y boletines provinciales.
- Revisar la pantalla de cobertura de fuentes: OK, error y sin resultados.
- Mantener una advertencia interna: no se puede afirmar cobertura total de todas las convocatorias de Espana hasta reducir errores de fuente, revisar parsers provincia por provincia y auditar varios dias consecutivos.
- Completar contenido real para al menos una oposicion prioritaria.
- Revisar textos legales con asesor especializado antes de campanas de pago.
- Completar pagos moviles con RevenueCat, App Store y Google Play cuando se vaya a publicar la version monetizada en tiendas.

## Comando de despliegue recomendado

```powershell
npx vercel --prod build\seo
```

Despues del despliegue:

```powershell
Invoke-WebRequest -Uri https://www.oposiwork.com/ -UseBasicParsing
Invoke-WebRequest -Uri https://www.oposiwork.com/app/ -UseBasicParsing
```
