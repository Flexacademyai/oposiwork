# Oposiwork - Estado de Lanzamiento

Última revisión local: 2026-05-11.

## Verificado

- `flutter analyze` pasa sin errores.
- `flutter test` pasa con 37 tests.
- `flutter build web --release --dart-define-from-file=.env` genera `build/web`.
- Los archivos revisados están en UTF-8. Si PowerShell muestra caracteres españoles dañados, puede ser un problema de salida de consola y no necesariamente del archivo.
- La URL guardada en `oposiwork_web/deployment-url.txt` responde con protección de Vercel: `Authentication Required`.
- El cliente Flutter ya invoca `download-pdf` desde la pantalla de temario cuando existen registros activos en `temario_pdfs`.
- El pipeline ya evita generar contenido desde solo el título, salvo que se use explícitamente `--permitir-texto-minimo`.
- Hay restricciones nuevas para evitar duplicados de temas, PDFs y contenido generado en Supabase.

## Bloqueadores Antes de Lanzar

1. Publicar Vercel sin Deployment Protection o añadir un dominio público no protegido.
2. Subir contenido real y revisado para una oposición completa.
3. Cargar PDFs oficiales en Supabase Storage y crear registros en `temario_pdfs`.
4. Probar `download-pdf` desde Flutter con un usuario premium real.
5. Probar RevenueCat móvil de extremo a extremo y añadir Stripe para web.
6. Configurar Firebase y probar permisos, token FCM y recepción de push.
7. Ejecutar migraciones en Supabase remoto y verificar RLS con usuarios `free` y `premium`.
8. Hacer QA en Android, iOS y web con datos reales.

## Nota Sobre Build Web Release

En esta máquina el build web debug funciona. Si `flutter build web --release --dart-define-from-file=.env` falla con `Could not start thread DartWorker`, es un agotamiento de recursos del entorno local, no una evidencia directa de error de código. Ejecutarlo en CI o en una máquina con más memoria/hilos disponibles.

## Error de Vercel Investigado

La URL:

`https://oposiwork-landing-ignix6419-israels-projects-904acd7c.vercel.app`

devuelve una página de autenticación de Vercel. Eso significa que el despliegue está protegido y no se puede confirmar públicamente el contenido real sin iniciar sesión o usar un bypass token.

El bloque `Instructions / Identity / Career / Projects / Preferences` no aparece en los archivos locales buscados. Con la información disponible no puedo confirmar que salga de este proyecto. Si aparece en el navegador del usuario, las causas más probables son:

- está viendo otro despliegue o proyecto de Vercel;
- el proyecto de Vercel apunta a un directorio distinto;
- una herramienta externa generó esa página;
- se pegó contenido de memoria/contexto en un archivo no presente en esta carpeta.

## Error CSP en Oposiwork.com

El error de consola del navegador indica que la Content Security Policy bloqueaba recursos necesarios de Flutter Web:

- `https://www.gstatic.com/.../canvaskit.js`
- `https://www.gstatic.com/.../canvaskit.wasm`
- `https://fonts.gstatic.com/.../Roboto...woff2`

Se corrigió `vercel.json` añadiendo `https://www.gstatic.com` a `script-src`, `script-src-elem` y `connect-src`, y `https://fonts.gstatic.com` a `connect-src`.

También se añadió `web/vercel.json` porque `flutter build web` copia el contenido de `web/` a `build/web`. Si el despliegue de Vercel publica directamente `build/web`, necesita tener ahí el `vercel.json` actualizado.

El build de CI fuerza `FLUTTER_WEB_CANVASKIT_URL=/canvaskit/` para servir CanvasKit desde el propio dominio y no depender de `www.gstatic.com` para esos binarios. La CSP sigue permitiendo `www.gstatic.com` y `fonts.gstatic.com` por compatibilidad y fuentes.

Además se añadió `web/flutter_bootstrap.js` con `canvasKitBaseUrl: "/canvaskit/"`, que es la configuración efectiva usada por el loader de Flutter Web.

Se añadió `web/flutter.js.map` como sourcemap mínimo válido para evitar el aviso de Firefox cuando DevTools intenta leer `flutter.js.map`.

Los mensajes `Loading from existing service worker` y `Service worker already active` son informativos. El error de `flutter.js.map` es de DevTools/sourcemaps y no es el bloqueo principal de la app.

Después de desplegar, conviene limpiar caché o desregistrar el service worker desde DevTools > Application > Service Workers para evitar que el navegador use una versión antigua.

## Comandos de Verificación

```powershell
python scripts/verify_text_encoding.py
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=.env --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/
scripts/launch_audit.ps1
```
