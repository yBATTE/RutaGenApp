import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({'access_token': 'one'}));

  test('registrar/desregistrar push y renovar QR conserva los GET válidos', () async {
    var reads = 0;
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      if (request.method == 'GET') reads++;
      return http.Response('{"success":true}', 200);
    }));
    addTearDown(api.close);
    const routes = ['/auth/me', '/news', '/rewards', '/draws/events'];
    for (final route in routes) {
      await api.get(route);
    }
    await api.post('/notifications/devices', body: {'token': 'push-test'});
    await api.delete('/notifications/devices', body: {'token': 'push-test'});
    await api.post('/qr/renew');
    for (final route in routes) {
      await api.get(route);
    }
    expect(reads, 4);
    expect(api.cacheEntries, 4);
  });

  test('marcar una notificación solo renueva el listado de notificaciones', () async {
    final counts = <String, int>{};
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      if (request.method == 'GET') {
        counts.update(request.url.path, (value) => value + 1, ifAbsent: () => 1);
      }
      return http.Response('{}', 200);
    }));
    addTearDown(api.close);
    const routes = ['/auth/me', '/news', '/rewards', '/notifications/me'];
    for (final route in routes) {
      await api.get(route);
    }
    await api.patch('/notifications/notification-id/read');
    for (final route in routes) {
      await api.get(route);
    }
    expect(counts['/api/notifications/me'], 2);
    expect(counts['/api/auth/me'], 1);
    expect(counts['/api/news'], 1);
    expect(counts['/api/rewards'], 1);
  });

  test('editar perfil renueva auth/me sin descartar novedades ni premios', () async {
    final counts = <String, int>{};
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      if (request.method == 'GET') {
        counts.update(request.url.path, (value) => value + 1, ifAbsent: () => 1);
      }
      return http.Response('{}', 200);
    }));
    addTearDown(api.close);
    for (final route in ['/auth/me', '/news', '/rewards']) {
      await api.get(route);
    }
    await api.patch('/users/me', body: {'phone': '1234'});
    for (final route in ['/auth/me', '/news', '/rewards']) {
      await api.get(route);
    }
    expect(counts['/api/auth/me'], 2);
    expect(counts['/api/news'], 1);
    expect(counts['/api/rewards'], 1);
  });

  test('respuesta invalidada no sobrescribe la nueva y otro GET pendiente conserva caché', () async {
    final oldUser = Completer<http.Response>();
    final news = Completer<http.Response>();
    final started = Completer<void>();
    var userReads = 0;
    var newsReads = 0;
    final api = ApiClient.forTesting(httpClient: MockClient((request) {
      if (request.url.path == '/api/auth/me') {
        userReads++;
        if (userReads == 1) {
          if (newsReads == 1) started.complete();
          return oldUser.future;
        }
        expect(request.headers['Cache-Control'], 'no-cache');
        return Future.value(http.Response('{"balance":20}', 200));
      }
      newsReads++;
      if (userReads == 1 && newsReads == 1) started.complete();
      return news.future;
    }));
    addTearDown(api.close);
    final previousUser = api.get('/auth/me');
    final pendingNews = api.get('/news');
    await started.future;
    api.invalidateCache('/auth/me');
    expect((await api.get('/auth/me'))['balance'], 20);
    oldUser.complete(http.Response('{"balance":10}', 200));
    news.complete(http.Response('{"title":"Vigente"}', 200));
    await Future.wait([previousUser, pendingNews]);
    expect((await api.get('/auth/me'))['balance'], 20);
    expect((await api.get('/news'))['title'], 'Vigente');
    expect(userReads, 2);
    expect(newsReads, 1);
  });

  test('invalidar news incluye páginas y detalles sin afectar newsroom', () async {
    final counts = <String, int>{};
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      counts.update(request.url.path, (value) => value + 1, ifAbsent: () => 1);
      if (request.url.path == '/api/newsroom') {
        expect(request.headers['Cache-Control'], isNull);
      }
      return http.Response('{}', 200);
    }));
    addTearDown(api.close);
    await api.get('/news', queryParameters: {'page': '1'});
    await api.get('/news/detail');
    await api.getCached('/newsroom');
    api.invalidateCache('/news');
    await api.get('/news', queryParameters: {'page': '1'});
    await api.get('/news/detail');
    await api.getCached('/newsroom');
    expect(counts['/api/news'], 2);
    expect(counts['/api/news/detail'], 2);
    expect(counts['/api/newsroom'], 1);
    // Un GET de red a la ruta de nombre parecido tampoco hereda no-cache.
    await api.get('/newsroom');
    expect(counts['/api/newsroom'], 2);
  });

  test('push de movimientos renueva saldo, cargas, canjes, regalos y ranking', () async {
    final counts = <String, int>{};
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      counts.update(request.url.path, (value) => value + 1, ifAbsent: () => 1);
      return http.Response('{}', 200);
    }));
    addTearDown(api.close);
    const routes = [
      '/auth/me', '/loads/me', '/rewards/me', '/rewards/gifts/me',
      '/rewards/visit-progress', '/users/me/point-adjustments',
      '/draws/events', '/rewards', '/news',
    ];
    for (final route in routes) {
      await api.get(route);
    }
    api.invalidateForNotification('MOVEMENTS');
    for (final route in routes) {
      await api.get(route);
      expect(counts['/api$route'], route == '/news' ? 1 : 2);
    }
  });

  test('fallo de escritura no descarta datos; aviso NEWS conserva saldo', () async {
    var userReads = 0;
    var newsReads = 0;
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      if (request.method != 'GET') return http.Response('{}', 409);
      if (request.url.path == '/api/auth/me') userReads++;
      if (request.url.path == '/api/news') newsReads++;
      return http.Response(jsonEncode({'success': true}), 200);
    }));
    addTearDown(api.close);
    await api.get('/auth/me');
    await api.get('/news');
    await expectLater(api.patch('/users/me'), throwsA(isA<ApiException>()));
    api.invalidateForNotification('NEWS');
    await api.get('/auth/me');
    await api.get('/news');
    expect(userReads, 1);
    expect(newsReads, 2);
  });

  test('operación desconocida renueva actividad y mantiene novedades ajenas', () async {
    var userReads = 0;
    var newsReads = 0;
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/auth/me') userReads++;
      if (request.method == 'GET' && request.url.path == '/api/news') newsReads++;
      return http.Response('{}', 200);
    }));
    addTearDown(api.close);
    await api.get('/auth/me');
    await api.get('/news');
    await api.post('/future-operation');
    await api.get('/auth/me');
    await api.get('/news');
    expect(userReads, 2);
    expect(newsReads, 1);
    await api.clearSession();
    expect(api.cacheEntries, 0);
  });
}
