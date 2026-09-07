import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/services/api_client.dart';
import 'package:ruta_gen_app/services/auth_service.dart';

const customer = <String, dynamic>{
  'id': 'test-customer',
  'role': 'CUSTOMER',
  'status': 'ACTIVE',
  'firstName': 'Prueba',
  'lastName': 'Registro',
  'dni': '12345678',
  'email': 'prueba@example.com',
  'identityVerified': false,
};
http.Response payload(Map<String, dynamic> data, [int status = 200]) =>
    http.Response(jsonEncode({'data': data}), status);
Future<void> register(AuthService auth) async {
  await auth.register(
    firstName: 'Prueba',
    lastName: 'Registro',
    dni: '12345678',
    email: 'prueba@example.com',
    password: 'Prueba1234',
    acceptedTerms: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'alta sin qrToken inicia login y guarda token, identidad sigue pendiente',
    () async {
      final calls = <String>[];
      final api = ApiClient.forTesting(
        httpClient: MockClient((request) async {
          calls.add(request.url.path);
          if (request.url.path.endsWith('/register'))
            return payload({'user': customer}, 201);
          return payload({'user': customer, 'accessToken': 'session-test'});
        }),
      );
      final auth = AuthService.forTesting(apiClient: api);
      await register(auth);
      expect(calls.map((p) => p.split('/').last), ['register', 'login']);
      expect(await api.getAccessToken(), 'session-test');
      final user = await auth.getCurrentUser();
      expect(user.identityVerified, false);
      expect(user.isActive, true);
    },
  );
  test('un alta rechazada no ejecuta login ni guarda sesion', () async {
    var count = 0;
    final api = ApiClient.forTesting(
      httpClient: MockClient((_) async {
        count++;
        return http.Response('{"message":"DNI existente"}', 409);
      }),
    );
    await expectLater(
      register(AuthService.forTesting(apiClient: api)),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
    expect(count, 1);
    expect(await api.hasSession(), false);
  });
  test('error de login despues del alta distingue cuenta ya creada', () async {
    final api = ApiClient.forTesting(
      httpClient: MockClient(
        (r) async => r.url.path.endsWith('/register')
            ? payload({'user': customer}, 201)
            : http.Response('{"message":"Error temporal"}', 503),
      ),
    );
    await expectLater(
      register(AuthService.forTesting(apiClient: api)),
      throwsA(isA<AccountCreatedException>()),
    );
    expect(await api.hasSession(), false);
  });
  test(
    'sesion persiste en una nueva instancia y se restaura por auth/me',
    () async {
      final first = ApiClient.forTesting(
        httpClient: MockClient(
          (_) async =>
              payload({'user': customer, 'accessToken': 'saved-token'}),
        ),
      );
      await AuthService.forTesting(apiClient: first)
          .login(identifier: '12345678', password: 'Prueba1234');
      final second = ApiClient.forTesting(
        httpClient: MockClient((r) async {
          expect(r.url.path.endsWith('/auth/me'), true);
          expect(r.headers['Authorization'], 'Bearer saved-token');
          return payload({'user': customer});
        }),
      );
      expect(
        (await AuthService.forTesting(apiClient: second).restoreSession())?.id,
        'test-customer',
      );
    },
  );
  test(
    'token rechazado se elimina; fallo temporal conserva el token',
    () async {
      var status = 503;
      final api = ApiClient.forTesting(
        httpClient: MockClient(
          (_) async => http.Response('{"message":"error"}', status),
        ),
      );
      await api.saveAccessToken('saved-token');
      final auth = AuthService.forTesting(apiClient: api);
      await expectLater(auth.restoreSession(), throwsA(isA<ApiException>()));
      expect(await api.getAccessToken(), 'saved-token');
      status = 401;
      expect(await auth.restoreSession(), null);
      expect(await api.hasSession(), false);
    },
  );
}
