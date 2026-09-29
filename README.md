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

## Ejecutar

```bash
flutter pub get
flutter run
```
