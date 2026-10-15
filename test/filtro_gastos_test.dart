import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:exploraec/controllers/auth_controller.dart';
import 'package:exploraec/controllers/gastos_controller.dart';
import 'package:exploraec/screens/gastos_screen.dart';
import 'package:exploraec/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Servidor falso con lo mínimo para iniciar sesión y listar gastos de dos
/// categorías. No necesita el backend ni el emulador.
class _Servidor implements HttpClientAdapter {
  final gastos = [
    {'id': 1, 'descripcion': 'Almuerzo en el Mercado Central', 'monto': 6.5, 'categoria': 'comida', 'fecha': '2026-10-08'},
    {'id': 2, 'descripcion': 'Taxi al terminal', 'monto': 3.25, 'categoria': 'transporte', 'fecha': '2026-10-08'},
    {'id': 3, 'descripcion': 'Cena en La Ronda', 'monto': 12.0, 'categoria': 'comida', 'fecha': '2026-10-09'},
  ];

  ResponseBody _json(Object cuerpo, [Map<String, List<String>> cabeceras = const {}]) =>
      ResponseBody.fromString(jsonEncode(cuerpo), 200,
          headers: {Headers.contentTypeHeader: ['application/json'], ...cabeceras});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? cuerpo, Future<void>? cancelar) async {
    switch (o.path) {
      case '/usuarios/token':
        return _json({'access_token': 'tok-a@b.com', 'token_type': 'bearer'});
      case '/usuarios/me':
        return _json({'id': 1, 'email': 'a@b.com'});
      case '/gastos/categorias':
        return _json({'categorias': ['comida', 'transporte', 'entretenimiento', 'otros'], 'limite_por_categoria': 500.0});
      case '/gastos/':
        return _json(gastos, {'x-total-count': ['${gastos.length}']});
    }
    return ResponseBody.fromString(jsonEncode({'detail': 'ruta no prevista: ${o.path}'}), 404,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _esperar(bool Function() condicion) async {
  for (var i = 0; i < 200 && !condicion(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync('hive_filtro').path));
  tearDown(Get.reset);

  testWidgets('El filtro por categoría muestra solo los gastos de «comida» y «Todas» los muestra todos',
      (tester) async {
    late GastosController gastos;
    // Iniciar sesión y cargar la lista usa E/S real (Hive): fuera del reloj simulado.
    await tester.runAsync(() async {
      Get.testMode = true;
      FlutterSecureStorage.setMockInitialValues({});
      Get.put(ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://prueba'))..httpClientAdapter = _Servidor()));
      final auth = Get.put(AuthController());
      await _esperar(() => !auth.restaurando.value);
      await auth.iniciarSesion('a@b.com', 'clave-1234');
      gastos = Get.put(GastosController());
      await _esperar(() => gastos.gastos.length == 3 && gastos.estado.value.name == 'exito');
    });

    await tester.pumpWidget(const GetMaterialApp(home: GastosScreen()));
    await tester.pumpAndSettle();

    // Al principio se ven los tres gastos y los chips «Todas», «comida» y «transporte».
    expect(find.text('Almuerzo en el Mercado Central'), findsOneWidget);
    expect(find.text('Taxi al terminal'), findsOneWidget);
    expect(find.text('Cena en La Ronda'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'transporte'), findsOneWidget);

    // Al elegir «comida», solo se ven los gastos de comida.
    await tester.tap(find.widgetWithText(ChoiceChip, 'comida'));
    await tester.pumpAndSettle();
    expect(find.text('Almuerzo en el Mercado Central'), findsOneWidget);
    expect(find.text('Cena en La Ronda'), findsOneWidget);
    expect(find.text('Taxi al terminal'), findsNothing);

    // «Todas» vuelve a mostrar la lista completa.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
    await tester.pumpAndSettle();
    expect(find.text('Taxi al terminal'), findsOneWidget);
    expect(gastos.gastosFiltrados.length, 3);
  });
}
