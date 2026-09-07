import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/features/auth/register_page.dart';
import 'package:ruta_gen_app/services/api_client.dart';
import 'package:ruta_gen_app/services/auth_service.dart';

import 'auth_flow_test.dart' show customer, payload;

Future<void> openForm(
  WidgetTester tester,
  AuthService auth,
  VoidCallback completed,
) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RegisterPage(
                  authService: auth,
                  onRegistered: (user) {
                    expect(user.identityVerified, false);
                    completed();
                  },
                ),
              ),
            ),
            child: const Text('Abrir registro'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir registro'));
  await tester.pumpAndSettle();
  final fields = find.byType(TextFormField);
  const values = [
    'Prueba',
    'Registro',
    '12345678',
    'prueba@example.com',
    'Prueba1234',
  ];
  for (var i = 0; i < values.length; i++) {
    await tester.enterText(fields.at(i), values[i]);
  }
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'doble toque crea una cuenta, guarda sesion y sale una sola vez',
    (tester) async {
      var registers = 0;
      var navigations = 0;
      final response = Completer<http.Response>();
      final api = ApiClient.forTesting(
        httpClient: MockClient((r) async {
          if (r.url.path.endsWith('/register')) {
            registers++;
            return response.future;
          }
          return payload({'user': customer, 'accessToken': 'session-test'});
        }),
      );
      await openForm(
        tester,
        AuthService.forTesting(apiClient: api),
        () => navigations++,
      );
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.tap(find.text('Crear mi cuenta'));
      await tester.pump();
      response.complete(payload({'user': customer}, 201));
      await tester.pumpAndSettle();
      expect(registers, 1);
      expect(navigations, 1);
      expect(find.byType(RegisterPage), findsNothing);
      expect(await api.getAccessToken(), 'session-test');
    },
  );
  testWidgets('fallo de login permite reintentar sin enviar otra alta', (
    tester,
  ) async {
    var registers = 0;
    var logins = 0;
    var navigations = 0;
    final api = ApiClient.forTesting(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/register')) {
          registers++;
          return payload({'user': customer}, 201);
        }
        logins++;
        return logins == 1
            ? http.Response('{"message":"Temporal"}', 503)
            : payload({'user': customer, 'accessToken': 'session-test'});
      }),
    );
    await openForm(
      tester,
      AuthService.forTesting(apiClient: api),
      () => navigations++,
    );
    await tester.tap(find.text('Crear mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresar a mi cuenta'), findsOneWidget);
    expect(navigations, 0);
    await tester.tap(find.text('Ingresar a mi cuenta'));
    await tester.pumpAndSettle();
    expect(registers, 1);
    expect(logins, 2);
    expect(navigations, 1);
  });
}
