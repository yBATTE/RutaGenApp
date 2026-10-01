import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/services/api_client.dart';
import 'package:ruta_gen_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'access_token': 'session-test',
        'qr_token': 'legacy-qr',
        'biometric_login_enabled': 'true',
        'biometric_login_identifier': 'one@example.com',
        'biometric_login_password': 'Test123',
      }));

  test(
      'uses authenticated endpoint and removes all local credentials after success',
      () async {
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/auth/account');
      expect(request.headers['Authorization'], 'Bearer session-test');
      expect(jsonDecode(request.body),
          {'password': 'Test123', 'confirmDelete': true});
      return http.Response('{"success":true}', 200);
    }));
    final auth = AuthService.forTesting(apiClient: api);
    await auth.deleteAccount(password: 'Test123');
    await auth.clearDeletedAccountSession();
    expect(await api.hasSession(), false);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    expect(api.cacheEntries, 0);
  });

  test('wrong password preserves session and biometric credentials for retry',
      () async {
    final api = ApiClient.forTesting(
        httpClient: MockClient((_) async => http.Response(
            '{"message":"La contraseña actual es incorrecta."}', 401)));
    await expectLater(
        AuthService.forTesting(apiClient: api).deleteAccount(password: 'wrong'),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    expect(await api.getAccessToken(), 'session-test');
    expect(
        await const FlutterSecureStorage()
            .read(key: 'biometric_login_password'),
        'Test123');
  });

  test('unconfirmed response never removes local credentials', () async {
    final api = ApiClient.forTesting(
        httpClient: MockClient((_) async => http.Response('{}', 200)));
    await expectLater(
        AuthService.forTesting(apiClient: api)
            .deleteAccount(password: 'Test123'),
        throwsA(isA<ApiException>()));
    expect(await api.hasSession(), true);
  });

  test('late GET cannot refill the cache after deletion cleanup', () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    final api = ApiClient.forTesting(httpClient: MockClient((_) async {
      started.complete();
      return response.future;
    }));
    final pending = api.getCached('/auth/me');
    await started.future;
    await api.clearAllSecureData();
    response.complete(http.Response('{"data":{"user":{"name":"Old"}}}', 200));
    await pending;
    expect(api.cacheEntries, 0);
    expect(await api.hasSession(), false);
  });
}
