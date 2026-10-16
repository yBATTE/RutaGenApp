import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/data/api_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/models.dart';
import 'package:ruta_gen_app/data/notification_destination.dart';
import 'package:ruta_gen_app/data/points_promotion.dart';
import 'package:ruta_gen_app/data/ruta_gen_repository.dart';
import 'package:ruta_gen_app/features/gifts/gift_rewards_page.dart';
import 'package:ruta_gen_app/features/movements/movements_page.dart';
import 'package:ruta_gen_app/features/notifications/notifications_page.dart';
import 'package:ruta_gen_app/services/api_client.dart';
import 'package:ruta_gen_app/services/auth_service.dart';
import 'package:ruta_gen_app/services/push_notification_service.dart';

class GiftRepository extends MockRutaGenRepository implements GiftRewardDetailRepository {
  String? requestedId;
  bool fail = false;
  final gift = GiftReward(id: 'gift-target', giftCode: 'RG-TARGET', source: 'RANDOM',
    status: 'REDEEMED', rewardName: 'Café de campaña', rewardDescription: '',
    issuedAt: DateTime.utc(2026, 10, 15, 13),
    redeemedAt: DateTime.utc(2026, 10, 16, 14, 25), redeemedStationName: 'Catania');

  @override
  Future<List<GiftReward>> getGiftRewards({String? status}) async => [];

  @override
  Future<GiftReward> getGiftReward(String giftId) async {
    requestedId = giftId;
    if (fail) throw StateError('Sin conexión');
    return gift;
  }

  @override
  Future<List<Movement>> getMovements({int page = 1, int limit = 20}) async => [
    Movement(id: 'received', title: 'Premio recibido', subtitle: 'Café · Disponible para canjear',
      date: DateTime.utc(2026, 10, 15, 13), points: 0, type: MovementType.gift, giftEvent: 'GIFT_RECEIVED'),
    Movement(id: 'redeemed', title: 'Regalo canjeado', subtitle: 'Café\nCatania',
      date: DateTime.utc(2026, 10, 16, 14, 25), points: 0, type: MovementType.gift, giftEvent: 'GIFT_REDEEMED'),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PushNotificationService.instance.actionNotifier.value = null;
  });

  test('push e historial conservan giftId; acciones repetidas se pueden consumir', () {
    final target = NotificationDestination.fromData({'action': ' gift_rewards ', 'giftId': ' aBc123 '});
    expect(target.action, 'GIFT_REWARDS'); expect(target.giftId, 'aBc123');
    final notice = AppNotification.fromJson({'id': 'notice', 'giftId': 'aBc123', 'action': 'GIFT_REWARDS'});
    expect(notice.copyWithRead().giftId, 'aBc123');
    for (var attempt = 0; attempt < 2; attempt++) {
      PushNotificationService.instance.openAction(target.action, giftId: target.giftId);
      final pending = PushNotificationService.instance.consumePendingAction();
      expect(pending?.giftId, 'aBc123'); expect(pending?.action, 'GIFT_REWARDS');
      expect(PushNotificationService.instance.consumePendingAction(), isNull);
    }
    expect(NotificationDestination.fromData({}).giftId, isNull);
  });

  test('repositorio solicita los dos eventos del regalo y conserva sus fechas', () async {
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer session-test');
      if (request.url.path.endsWith('/rewards/me')) {
        expect(request.url.queryParameters['giftEvents'], 'true');
        return http.Response(jsonEncode({'data': [
          {'id': 'gift:redeemed', 'giftId': 'gift', 'redemptionKind': 'GIFT', 'movementType': 'GIFT_REDEEMED',
            'rewardName': 'Café', 'status': 'REDEEMED', 'redeemedAt': '2026-10-16T14:25:00Z',
            'createdAt': '2026-10-15T13:00:00Z', 'occurredAt': '2026-10-16T14:25:00Z', 'stationName': 'Catania'},
          {'id': 'gift', 'giftId': 'gift', 'redemptionKind': 'GIFT', 'movementType': 'GIFT_RECEIVED',
            'rewardName': 'Café', 'status': 'REDEEMED', 'issuedAt': '2026-10-15T13:00:00Z'},
        ]}), 200);
      }
      return http.Response('{"data":[]}', 200);
    }));
    await api.saveAccessToken('session-test');
    final items = await ApiRutaGenRepository(apiClient: api).getMovements();
    expect(items.length, 2); expect(items[0].title, 'Regalo canjeado');
    expect(items[0].isGiftRedeemed, true); expect(items[0].argentinaDate.hour, 11);
    expect(items[0].argentinaDate.minute, 25); expect(items[0].stationName, 'Catania');
    expect(items[1].title, 'Premio recibido'); expect(items[1].isGiftRedeemed, false);
    expect(items[1].subtitle, contains('Ya canjeado')); expect(items.every((m) => m.points == 0), true);
  });

  test('consulta regalo por ID con sesión y respeta un rechazo de otra cuenta', () async {
    var forbidden = false;
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      expect(request.url.path, endsWith('/rewards/gifts/me/abc123'));
      expect(request.headers['Authorization'], 'Bearer session-test');
      if (forbidden) return http.Response('{"message":"No se encontró ese regalo en tu cuenta."}', 404);
      return http.Response(jsonEncode({'data': {'gift': {
        'id': 'abc123', 'giftCode': 'RG-CODE', 'qrToken': 'private-token',
        'status': 'AVAILABLE', 'source': 'RANDOM', 'reward': {'name': 'Café'},
        'issuedAt': '2026-10-16T12:00:00Z',
      }}}), 200);
    }));
    await api.saveAccessToken('session-test');
    final repository = ApiRutaGenRepository(apiClient: api);
    expect((await repository.getGiftReward('abc123')).qrToken, 'private-token');
    forbidden = true;
    await expectLater(repository.getGiftReward('abc123'), throwsA(isA<ApiException>()));
  });

  test('vendedor no guarda sesión y no restaura un token como cliente', () async {
    final api = ApiClient.forTesting(httpClient: MockClient((request) async => http.Response(jsonEncode({'data': {
      'accessToken': 'staff-token', 'user': {'id': 'seller', 'role': 'PLAYERO', 'status': 'ACTIVE', 'firstName': 'Vendedor'},
    }}), 200)));
    final auth = AuthService.forTesting(apiClient: api);
    await expectLater(auth.login(identifier: 'seller@example.com', password: 'test'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)));
    expect(await api.hasSession(), false);
    await api.saveAccessToken('old-token');
    expect(await auth.restoreSession(), isNull); expect(await api.hasSession(), false);
  });

  test('un regalo disponible con vencimiento pasado no muestra QR', () {
    final gift = GiftReward(id: 'expired', giftCode: 'RG-EXPIRED', source: 'RANDOM',
      status: 'AVAILABLE', rewardName: 'Café', rewardDescription: '',
      issuedAt: DateTime.utc(2020), expiresAt: DateTime.utc(2020, 2), qrToken: 'old-token');
    expect(gift.canShowQr, false); expect(gift.statusLabel, 'Vencido');
    expect(PointsPromotion.fromJson({'multiplier': 2, 'minimumFuelLiters': 40, 'maxPointsPerLoad': 70}).conditions,
      contains('Máximo 70 puntos por carga, después del multiplicador'));
  });

  testWidgets('movimientos distinguen recibido/canjeado y muestran Gratis', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MovementsPage(repository: GiftRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Premio recibido'), findsOneWidget);
    expect(find.text('Regalo canjeado'), findsOneWidget);
    expect(find.text('Gratis'), findsNWidgets(2)); expect(find.text('0 pts'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('11:25'), findsOneWidget);
  });

  testWidgets('abre el regalo del aviso aunque no aparezca en la primera página', (tester) async {
    final repository = GiftRepository();
    await tester.pumpWidget(MaterialApp(home: GiftRewardsPage(repository: repository, initialGiftId: 'gift-target')));
    await tester.pumpAndSettle();
    expect(repository.requestedId, 'gift-target'); expect(find.text('Café de campaña'), findsOneWidget);
    expect(find.text('Catania'), findsOneWidget); expect(find.text('16/10/2026 · 11:25'), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
  });

  testWidgets('permite reintentar una apertura de regalo fallida', (tester) async {
    final repository = GiftRepository()..fail = true;
    await tester.pumpWidget(MaterialApp(home: GiftRewardsPage(repository: repository, initialGiftId: 'gift-target')));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    repository.fail = false; await tester.tap(find.text('Reintentar')); await tester.pumpAndSettle();
    expect(find.text('Café de campaña'), findsOneWidget);
  });
}
