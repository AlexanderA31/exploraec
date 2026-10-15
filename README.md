# ExploraEC

App del curso *TMO · Desarrolla Aplicaciones Móviles Robustas con Flutter e IA* (CEDIA).
Código base tomado del repositorio de referencia `Patricio-CEDIA/exploraec-app`, con los bloques `TODO` de cada práctica resueltos.

## Sesión 2 — Widgets básicos y avanzados

- `lib/playground/dart_basics.dart`: los 6 ejercicios de Dart activos (`dart run lib/playground/dart_basics.dart`).
- `lib/playground/contador_demo.dart`: `setState()` activo (`flutter run -t lib/playground/contador_demo_main.dart`).
- Modelo `Place` con 6 lugares de ejemplo, `PlaceCard` y lista de Inicio.
- Navegación al Detalle, formulario "Agregar lugar" con validación y barra de navegación inferior.

## Sesión 3 — Tema, estados y accesibilidad

- Paso 1: `theme: AppTheme.theme`.
- Paso 3: `fetchLugaresSimulado` con `Future.delayed` y `FutureBuilder` con `LoadingView` / `ErrorView` / `EmptyView` (menú ⋮ → *Simular*).
- Paso 4: `_buildLista` con `LayoutBuilder` (lista < 600 px, grilla de 2-3 columnas), `childAspectRatio: 2.2`.
- Paso 5: `Semantics` en `PlaceCard` con `excludeSemantics: true`.
- Paso 6 (opcional): `darkTheme: AppTheme.darkTheme` + `themeMode: ThemeMode.system`.

## Sesión 4 — PlacesController compartido con GetX

- Paso 2: `cargarLugares()` llama a `fetchLugaresSimulado` con `try`/`catch` y los 3 estados.
- Paso 3: `HomeScreen` es `GetView<PlacesController>` con `body: Obx(...)`; sin `StatefulWidget` ni recarga manual.
- Paso 4: navegación con `Get.to` / `Get.back` (no queda `Navigator.push`).
- Paso 5: estado derivado `total` (título `ExploraEC (N)`), `Get.snackbar('Lugar agregado', ...)` y worker `ever(estado, ...)`.
- Paso 6 (opcional): favoritos en memoria compartidos con la pestaña Favoritos e idioma español/inglés con `Get.updateLocale`.

## Sesión 5 — Mapas y geolocalización

- Paso 2: permisos de ubicación en `AndroidManifest.xml` e `Info.plist`.
- Paso 3: `Geolocator.checkPermission()` / `requestPermission()` en `LocationService`.
- Paso 4: `MarkerLayer` con la posición del usuario y un marcador por lugar (`flutter_map` + OpenStreetMap).
- Paso 5: distancia real en el Detalle al llegar desde un marcador.
- Paso 7 (opcional): botón «Centrar en mi ubicación» (`mapController.move`) y distancia en las tarjetas de Inicio.

## Sesión 6 — Gastos del viaje desde el backend

- Paso 5: permiso `INTERNET` y `android:usesCleartextTraffic="true"` en `AndroidManifest.xml` (solo desarrollo).
- Paso 7: `GastosController.entrar()` (registro → login con formulario → listar) y `cargarGastos()` con los 3 estados.
- Pasos 8 y 9: errores legibles (sin conexión, 401, 422, tiempo agotado); el timeout quedó en 15 s.
- Paso 10 (opcional): deslizar para actualizar con `RefreshIndicator`.

## Sesión 7 — Persistencia local con Hive

- Paso 2: `cargarGastos()` usa `GastosRepository` (servidor primero, caché `gastos_<id>` por usuario) y banner «Sin conexión».
- Paso 3: favoritos de lugares guardados en la caja `favoritos`.
- Paso 5: `salir()` borra la caja del usuario (`_repository.vaciar()`); el token nunca se guarda en Hive.
- Paso 6 (opcional): idioma guardado en la caja `ajustes`.

## Sesión 8 — Autenticación segura y CRUD completo

- `ApiClient` con `dio` e interceptores (token y 401); token en `flutter_secure_storage`.
- `AuthController`: iniciar sesión, registrar (con validación), restaurar sesión y cerrar sesión que borra token, lista y caja.
- Crear, editar y eliminar gastos (con confirmación) y mensajes del servidor (límite de 500 por categoría).
- Paso 9 (opcional): cambiar contraseña.

## Sesión 10 — Calidad, CI/CD y código con agentes de IA

- Errores no controlados capturados en un solo lugar (`ReporteErrores.instalar()`), sin tokens en los registros.
- Pruebas de widgets (`test/sesion_10_test.dart`) y auditoría de secretos (`.env`, `.claude/settings.local.json` y `CLAUDE.local.md` ignorados).
- CI en GitHub Actions (`.github/workflows/ci.yml`): analiza y prueba en cada push y pull request.
- Arnés del agente: `AGENTS.md` (con reglas propias), `CLAUDE.md` y permisos en `.claude/settings.json` (más un hook de formateo opcional).
- Filtro de gastos por categoría escrito por un agente de código, con su prueba (`test/filtro_gastos_test.dart`), integrado con un pull request.
- Release `v1.0.0` con el APK compilado por `.github/workflows/release-apk.yml`.
- Paso 10 (opcional): «Acerca de» con las licencias de los paquetes.

## Sesión 9 — Asistente ExploraIA

- Pestaña «Asistente»: pide el resumen por categoría al backend y lo envía al proxy (`mock-server/`) con la pregunta (Paso 4).
- Confirmación humana antes de registrar un gasto propuesto por la IA (Paso 5); el backend valida (límite de 500).
- La app no lleva ninguna clave de IA: `GEMINI_API_KEY` vive solo en el entorno del proxy (sin ella, modo de reglas).
- Paso 8: el proxy pide el resumen al MCP del backend (`resumen_gastos`) con el token de la persona; `node mock-server/probar-e2e.js <correo> <contraseña>` da 4 ✅.
- Paso 9 (opcional): preguntas sugeridas.

```bash
cd mock-server
node mock-server.js                         # modo REGLAS (sin clave)
$env:GEMINI_API_KEY="tu-clave"; node mock-server.js   # modo GEMINI (PowerShell)
```

## Ejecutar

```bash
flutter pub get
flutter run                                              # emulador Android: backend en http://10.0.2.2:8000
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

El backend de gastos es otro repositorio (`cj-murillo/proyecto-curso-spec-kit`) y se levanta aparte; su `.env` no se sube.
