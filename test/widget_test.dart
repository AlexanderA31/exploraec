import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exploraec/main.dart';
import 'package:exploraec/widgets/empty_view.dart';
import 'package:exploraec/widgets/error_view.dart';
import 'package:exploraec/widgets/loading_view.dart';
import 'package:exploraec/widgets/place_card.dart';

Future<void> _esperarCarga(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
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
  testWidgets('Inicio muestra carga y luego la lista de lugares', (tester) async {
    await tester.pumpWidget(const ExploraEcApp());
    expect(find.byType(LoadingView), findsOneWidget);

    await _esperarCarga(tester);
    expect(find.byType(PlaceCard), findsWidgets);
    expect(find.text('Parque El Ejido'), findsOneWidget);
  });

  testWidgets('El menú simula los estados vacío, error y normal', (tester) async {
    await tester.pumpWidget(const ExploraEcApp());
    await _esperarCarga(tester);

    await _simular(tester, 'Simular: vacío');
    expect(find.byType(EmptyView), findsOneWidget);

    await _simular(tester, 'Simular: error');
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await _simular(tester, 'Simular: normal');
    expect(find.byType(PlaceCard), findsWidgets);
  });

  for (final ancho in [620.0, 1000.0]) {
    testWidgets('Con ${ancho.toInt()} px de ancho Inicio usa GridView sin overflow', (tester) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ExploraEcApp());
      await _esperarCarga(tester);
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PlaceCard expone una etiqueta semántica única', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const ExploraEcApp());
    await _esperarCarga(tester);

    expect(
      find.bySemanticsLabel('Parque El Ejido, categoría Parques'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('Tocar una tarjeta abre el Detalle y las pestañas cambian', (tester) async {
    await tester.pumpWidget(const ExploraEcApp());
    await _esperarCarga(tester);

    await tester.tap(find.text('Museo Casa del Alabado'));
    await tester.pumpAndSettle();
    expect(find.textContaining('arte precolombino'), findsOneWidget);
    await tester.pageBack();
    await _esperarCarga(tester);

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Próximamente: mapa'), findsOneWidget);
  });

  testWidgets('El formulario vacío muestra los 3 errores de validación', (tester) async {
    await tester.pumpWidget(const ExploraEcApp());
    await _esperarCarga(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('La categoría es obligatoria'), findsOneWidget);
    expect(find.text('Escribe al menos 10 caracteres'), findsOneWidget);
  });
}
