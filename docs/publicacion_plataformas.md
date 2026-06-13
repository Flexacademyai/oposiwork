# Publicacion de plataformas - Oposiwork MVP

Ultima revision: 2026-06-11.

## Estado ejecutivo

El MVP queda preparado para publicacion web y para generar/subir el paquete Android. iOS queda preparado a nivel de proyecto Flutter/Xcode, pero la IPA final debe generarse en macOS con Xcode porque Apple no permite archivar y subir apps iOS desde Windows.

Pagos Premium por Stripe quedan activados para web. Los pagos dentro de Android/iOS siguen pendientes y deben ir por Google Play Billing / App Store In-App Purchases mediante RevenueCat.

## Android - Google Play

- Application ID: `es.oposiwork.oposiwork`.
- Nombre visible: `Oposiwork`.
- Version: `1.0.0+1`.
- Compile SDK: Android API 35.
- Target SDK: Android API 35.
- Permisos principales: internet y notificaciones.
- Iconos de lanzamiento: personalizados para Oposiwork.
- Firma release: configurada con keystore local.
- Artefacto para subir a Google Play Console:
  - `F:\oposiwork\build\app\outputs\bundle\release\app-release.aab`
- Tamano verificado: 27.783.735 bytes.
- Fecha/hora de generacion verificada: 2026-06-10 21:54:01.

Archivos privados que deben conservarse fuera del repositorio:

- `F:\oposiwork\android\app\oposiwork-upload-key.jks`
- `F:\oposiwork\android\key.properties`

No subir esos archivos a GitHub ni compartirlos por chat. Si se pierden, habra problemas para firmar futuras actualizaciones.

Pendiente externo para Android:

- Crear app en Google Play Console.
- Completar ficha, capturas, clasificacion de contenido y politica de privacidad.
- Subir `app-release.aab`.
- Si se quieren notificaciones push reales, anadir `android/app/google-services.json` desde Firebase antes de publicar la version con push activo.
- Si se activan pagos, configurar Google Play Billing, productos de suscripcion y RevenueCat.

## iOS - App Store

- Bundle ID preparado: `es.oposiwork.oposiwork`.
- Nombre visible: `Oposiwork`.
- iOS deployment target: 13.0.
- `ios/Podfile` incluido.
- Iconos de lanzamiento: personalizados para Oposiwork.

No se puede generar el archivo final `.ipa` en Windows. En un Mac con Xcode:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release --dart-define-from-file=.env
```

Despues se sube la IPA desde Xcode Organizer, Transporter o App Store Connect.

Pendiente externo para iOS:

- Cuenta Apple Developer activa.
- Crear App ID / Bundle ID `es.oposiwork.oposiwork`.
- Certificados, provisioning profiles y Team ID en Xcode.
- Ficha App Store: capturas, descripcion, privacidad, edad, soporte y categoria.
- Si se quieren notificaciones push reales, anadir `ios/Runner/GoogleService-Info.plist` y configurar APNs/Firebase.
- Si se activan pagos, configurar In-App Purchases, RevenueCat y revision de Apple.

## Web - Produccion

- Dominio canonico: `https://www.oposiwork.com`.
- Ultimo despliegue Vercel production verificado:
  - `https://oposiwork-7jqrrruon-israels-projects-904acd7c.vercel.app`
  - Alias: `https://www.oposiwork.com`
- Stripe web: activo en produccion.
- Compra real de comprobacion: no realizada.
- Landing SEO indexable en raiz `/`.
- Aplicacion Flutter Web bajo `/app/`.
- Legal:
  - Politica de privacidad: `https://www.oposiwork.com/privacidad/`
  - Terminos: `https://www.oposiwork.com/terminos/`
  - Contacto: `https://www.oposiwork.com/contacto/`
- Crons Vercel configurados:
  - `/api/monitor-boe`
  - `/api/send-notifications`

Build recomendado:

```powershell
.\scripts\build_seo_web.ps1 -PagosHabilitados
npx vercel --prod build\seo
```

Build sin pagos activos:

```powershell
.\scripts\build_seo_web.ps1
```

## Textos sugeridos para tienda

Nombre:

```text
Oposiwork
```

Descripcion corta:

```text
Convocatorias y preparacion de oposiciones en una sola app.
```

Descripcion larga:

```text
Oposiwork te ayuda a seguir convocatorias publicas y preparar oposiciones con temarios, resumenes, tests, flashcards, supuestos practicos y avisos de cambios. Consulta oposiciones activas, guarda tu progreso y organiza tu estudio desde una unica aplicacion.

El MVP se lanza con cobertura progresiva de fuentes oficiales estatales, autonomicas y provinciales. La disponibilidad de convocatorias depende de la publicacion en boletines oficiales y de la calidad de cada fuente.
```

Categoria recomendada:

```text
Educacion
```

URL de soporte:

```text
https://www.oposiwork.com/contacto/
```

URL de privacidad:

```text
https://www.oposiwork.com/privacidad/
```

## Estado de cobertura de convocatorias

El sistema ya trabaja con fuentes reales y crons preparados, pero no debe prometer "todas las oposiciones de Espana" como garantia absoluta. La comunicacion publica debe decir "cobertura progresiva de fuentes oficiales" hasta que el historico de auditoria muestre varios dias seguidos sin errores relevantes.

Ultimo estado documentado:

- Fuentes oficiales activas: 63.
- Convocatorias totales: 35.
- Convocatorias abiertas: 30.
- Convocatorias con plazo de inscripcion abierto: 29.
- Auditoria historica: 282 ejecuciones OK, 728 con error, 789 sin resultados.

## Verificaciones necesarias antes de publicar

Locales:

```powershell
python scripts\verify_text_encoding.py
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file=.env
.\scripts\build_seo_web.ps1
```

Produccion:

```powershell
Invoke-WebRequest -Uri https://www.oposiwork.com/ -UseBasicParsing
Invoke-WebRequest -Uri https://www.oposiwork.com/app/ -UseBasicParsing
```

Resultado de la ultima verificacion local/produccion:

- `python scripts\verify_text_encoding.py`: OK.
- `flutter analyze`: OK, sin issues.
- `flutter test`: OK, 37 tests.
- `flutter build appbundle --release --dart-define-from-file=.env`: OK.
- Firma AAB: `jar verified`.
- `.\scripts\build_seo_web.ps1`: OK.
- `npx vercel --prod build\seo`: OK, production ready y aliasado a `www.oposiwork.com`.
- Landing `https://www.oposiwork.com/`: HTTP 200, texto principal visible, Open Graph presente, sin placeholder "A new Flutter project".
- App `https://www.oposiwork.com/app/`: HTTP 200, `flutter_bootstrap` presente y render visual de login verificado.
- CanvasKit JS/WASM bajo `/app/canvaskit/`: HTTP 200.
- `robots.txt` y `sitemap.xml`: HTTP 200.
- `/api/monitor-boe` sin autorizacion: HTTP 401.
- `/api/send-notifications` sin autorizacion: HTTP 401.
- Cabeceras de seguridad: CSP y HSTS presentes.
- `main.dart.js` en produccion contiene `create-stripe-checkout`.
- Edge Functions Stripe activas: `create-stripe-checkout`, `create-stripe-portal`, `webhook-stripe`.

## Bloqueadores no tecnicos

- iOS necesita Mac/Xcode para generar y subir IPA.
- Las cuentas de Google Play y Apple deben estar completadas con datos legales, fiscales, privacidad y capturas.
- Las notificaciones push reales requieren Firebase/APNs.
- Los pagos moviles quedan para la ultima fase de tiendas. Stripe web queda activo.
