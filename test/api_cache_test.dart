import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/services/api_client.dart';
import 'package:ruta_gen_app/services/api_cache_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({'access_token': 'one'}));

  test('20 concurrent reads share one request; nested responses are independent', () async {
    var calls = 0;
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final api = ApiClient.forTesting(httpClient: MockClient((_) {
      calls++;
      started.complete();
      return response.future;
    }));
    addTearDown(api.close);
    final requests = List.generate(20, (_) => api.get('/auth/me'));
    await started.future;
    response.complete(http.Response('{"data":{"points":10}}', 200));
    final results = await Future.wait(requests);
    results.first['data']['points'] = 999;
    expect(results.last['data']['points'], 10);
    expect((await api.get('/auth/me'))['data']['points'], 10);
    expect(calls, 1);
  });

  test('manual refresh detaches an old in-flight result without stale refill', () async {
    final firstResponse = Completer<http.Response>();
    final started = Completer<void>();
    var calls = 0;
    final api = ApiClient.forTesting(httpClient: MockClient((_) {
      calls++;
      if (calls == 1) { started.complete(); return firstResponse.future; }
      return Future.value(http.Response('{"sequence":$calls}', 200));
    }));
    addTearDown(api.close);
    final old = api.get('/auth/me');
    await started.future;
    expect((await api.get('/auth/me', forceRefresh: true))['sequence'], 2);
    firstResponse.complete(http.Response('{"sequence":1}', 200));
    await old;
    expect((await api.get('/auth/me'))['sequence'], 2);
    expect(calls, 2);
  });

  test('TTL expires, query order coalesces and pages remain separate', () async {
    var calls = 0;
    final api = ApiClient.forTesting(httpClient: MockClient((_) async =>
        http.Response('{"sequence":${++calls}}', 200)));
    addTearDown(api.close);
    await api.get('/news', queryParameters: {'page': '1', 'limit': '5'});
    await api.get('/news', queryParameters: {'limit': '5', 'page': '1'});
    expect(calls, 1);
    await api.get('/news', queryParameters: {'page': '2', 'limit': '5'});
    expect(calls, 2);
    await api.getCached('/short', cacheDuration: const Duration(milliseconds: 10));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await api.getCached('/short', cacheDuration: const Duration(milliseconds: 10));
    expect(calls, 4);
  });

  test('session switch discards pending response and sends the new token', () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    final api = ApiClient.forTesting(httpClient: MockClient((request) {
      if (request.headers['Authorization'] == 'Bearer one') {
        started.complete(); return response.future;
      }
      return Future.value(http.Response('{"owner":"two"}', 200));
    }));
    addTearDown(api.close);
    final old = api.get('/auth/me');
    final rejected = expectLater(old, throwsA(isA<ApiException>().having((e) => e.statusCode, 'session changed', 409)));
    await started.future;
    await api.saveAccessToken('two');
    expect((await api.get('/auth/me'))['owner'], 'two');
    response.complete(http.Response('{"owner":"one"}', 200));
    await rejected;
    expect((await api.get('/auth/me'))['owner'], 'two');
    await api.clearSession();
    expect(api.cacheEntries, 0);
  });

  test('successful writes invalidate data; errors and QR are never cached', () async {
    var reads = 0;
    var failWrite = false;
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      if (request.method != 'GET') return http.Response('{}', failWrite ? 409 : 200);
      reads++;
      if (request.url.path.endsWith('/error')) return http.Response('{}', 500);
      return http.Response(jsonEncode({'sequence': reads}), 200);
    }));
    addTearDown(api.close);
    await api.get('/auth/me');
    failWrite = true;
    await expectLater(api.patch('/users/me'), throwsA(isA<ApiException>()));
    await api.get('/auth/me');
    expect(reads, 1);
    failWrite = false;
    await api.patch('/users/me');
    await api.get('/auth/me');
    expect(reads, 2);
    await api.get('/qr/current'); await api.get('/qr/current');
    expect(reads, 4);
    for (var i = 0; i < 2; i++) {
      await expectLater(api.getCached('/error'), throwsA(isA<ApiException>()));
    }
    expect(reads, 6);
  });

  test('cache is bounded and critical routes have no automatic TTL', () async {
    final api = ApiClient.forTesting(httpClient: MockClient((_) async => http.Response('{}', 200)));
    addTearDown(api.close);
    for (var i = 0; i < 140; i++) { await api.get('/news/$i'); }
    expect(api.cacheEntries, lessThanOrEqualTo(128));
    for (final path in ['/qr/current', '/points/promotion', '/rewards/gifts/me/id', '/auth/login']) {
      expect(ApiCachePolicy.durationFor(path), Duration.zero);
    }
  });
}
