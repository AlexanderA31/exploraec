import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:exploraec/main.dart';
import 'package:exploraec/services/settings_service.dart';
import 'package:exploraec/widgets/empty_view.dart';
import 'package:exploraec/widgets/error_view.dart';
import 'package:exploraec/widgets/loading_view.dart';
import 'package:exploraec/widgets/place_card.dart';

Future<void> _abrirApp(WidgetTester tester) async {
  await tester.pumpWidget(const ExploraEcApp());
  await _esperarCarga(tester);
}

Future<void> _esperarCarga(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Deja que los avisos de `Get.snackbar` terminen antes de cerrar el test.
Future<void> _cerrarAvisos(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _simular(WidgetTester tester, String opcion) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion));
  await tester.pump();
  expect(find.byType(LoadingView), findsOneWidget);
  await _esperarCarga(tester);
}

void main() {
  // Igual que `main()` de la app: Hive con las cajas abiertas antes de
  // construir `ExploraEcApp` (aquí en una carpeta temporal).
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('hive_widgets').path);
    await Hive.openBox<Map>('favoritos');
    await SettingsService.abrir();
  });
  tearDown(Get.reset);

  testWidgets('Inicio muestra carga y luego la lista con el contador', (tester) async {
    await tester.pumpWidget(const ExploraEcApp());
    expect(find.byType(LoadingView), findsOneWidget);

    await _esperarCarga(tester);
    expect(find.byType(PlaceCard), findsWidgets);
    expect(find.text('Parque El Ejido'), findsOneWidget);
    expect(find.text('ExploraEC (6)'), findsOneWidget);
  });

  testWidgets('El menú simula vacío y error (con aviso del worker) vía el controller', (tester) async {
    await _abrirApp(tester);

    await _simular(tester, 'Simular: vacío');
    expect(find.byType(EmptyView), findsOneWidget);

    await _simular(tester, 'Simular: error');
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget); // Get.snackbar del worker `ever`
    await _cerrarAvisos(tester);

    await _simular(tester, 'Simular: normal');
    expect(find.byType(PlaceCard), findsWidgets);
  });

  for (final ancho in [620.0, 1000.0]) {
    testWidgets('Con ${ancho.toInt()} px de ancho Inicio usa GridView sin overflow', (tester) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _abrirApp(tester);
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PlaceCard expone una etiqueta semántica única', (tester) async {
    final handle = tester.ensureSemantics();
    await _abrirApp(tester);

    expect(
      find.bySemanticsLabel('Parque El Ejido, categoría Parques'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('Tocar una tarjeta abre el Detalle con Get.to', (tester) async {
    await _abrirApp(tester);

    await tester.tap(find.text('Museo Casa del Alabado'));
    await tester.pumpAndSettle();
    expect(find.textContaining('arte precolombino'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('ExploraEC (6)'), findsOneWidget);
  });

  testWidgets('El formulario vacío muestra los 3 errores de validación', (tester) async {
    await _abrirApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('La categoría es obligatoria'), findsOneWidget);
    expect(find.text('Escribe al menos 10 caracteres'), findsOneWidget);
  });

  // Último test: agrega un lugar a la lista global en memoria.
  testWidgets('Agregar un lugar sube el contador sin recargar y muestra el aviso', (tester) async {
    await _abrirApp(tester);
    expect(find.text('ExploraEC (6)'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Basílica del Voto Nacional');
    await tester.enterText(find.byType(TextFormField).at(1), 'Iglesias');
    await tester.enterText(find.byType(TextFormField).at(2), 'Templo neogótico con vista al Centro Histórico.');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ExploraEC (7)'), findsOneWidget);
    expect(find.byType(LoadingView), findsNothing); // sin recarga
    expect(find.text('Lugar agregado'), findsOneWidget);
    await _cerrarAvisos(tester);
  });

  // Último: deja una escritura de Hive en curso (E/S real).
  testWidgets('Un favorito se guarda en Hive y aparece en la pestaña Favoritos', (tester) async {
    await _abrirApp(tester);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    // La escritura de Hive es E/S real: se le da tiempo real para terminar.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    expect(find.byIcon(Icons.favorite), findsWidgets);
    expect(Hive.box<Map>('favoritos').containsKey('1'), isTrue);

    await tester.tap(find.text('Favoritos').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PlaceCard, 'Parque El Ejido'), findsOneWidget);
  });
}
