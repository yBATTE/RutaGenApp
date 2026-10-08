import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/data/api_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/points_promotion.dart';
import 'package:ruta_gen_app/data/ruta_gen_repository.dart';
import 'package:ruta_gen_app/services/api_client.dart';
import 'package:ruta_gen_app/shared/widgets/points_promotion_banner.dart';

class PromotionRepository extends MockRutaGenRepository
    implements PointsPromotionRepository {
  PointsPromotion? value;
  bool fail = false;
  int requests = 0;
  Completer<PointsPromotion?>? pending;

  @override
  Future<PointsPromotion?> getPointsPromotion() async {
    requests++;
    if (pending != null) return pending!.future;
    if (fail) throw StateError('sin conexión');
    return value;
  }
}

Widget banner(
  PromotionRepository repository, {
  bool active = true,
  int refresh = 0,
  double scale = 1,
}) =>
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: PointsPromotionBanner(
                repository: repository,
                isActive: active,
                refreshVersion: refresh,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('factor base oculto, factor personalizado y equivalencia del servidor',
      () {
    final base =
        PointsPromotion.fromJson({'multiplier': 1, 'minimumFuelLiters': 40});
    expect(base.shouldDisplay, false);
    final bonus = PointsPromotion.fromJson({
      'multiplier': '1.25',
      'minimumFuelLiters': 40,
      'promotionName': '  Puntos extra  ',
    });
    expect(bonus.multiplierLabel, '1,25×');
    expect(bonus.headline, '¡Sumá 25% más puntos!');
    expect(bonus.promotionName, 'Puntos extra');
    expect(bonus.equivalence, 'Cada litro suma 1,25 puntos.');
    expect(bonus.conditions, contains('40 L'));
    expect(
        PointsPromotion.fromJson({'multiplier': 1.1, 'minimumFuelLiters': 0})
            .headline,
        '¡Sumá 10% más puntos!');
  });

  test('valores inválidos no se convierten en una promoción ficticia', () {
    for (final value in [null, 0, -1, 'NaN', 'Infinity', 1000001]) {
      expect(
          () => PointsPromotion.fromJson(
              {'multiplier': value, 'minimumFuelLiters': 40}),
          throwsFormatException);
    }
    expect(() => PointsPromotion.fromJson({'multiplier': 2}),
        throwsFormatException);
  });

  test('repositorio consulta autenticado sin cache y acepta backend anterior',
      () async {
    var requests = 0;
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      requests++;
      expect(request.url.path, endsWith('/points/promotion'));
      expect(request.headers['Authorization'], 'Bearer test-token');
      if (requests == 3) {
        return http.Response('{"message":"No encontrado"}', 404);
      }
      return http.Response(
          jsonEncode({
            'data': {
              'multiplier': requests == 1 ? 2 : 1,
              'minimumFuelLiters': 40,
              'promotionName': 'Domingos X2',
            }
          }),
          200);
    }));
    await api.saveAccessToken('test-token');
    final repository = ApiRutaGenRepository(apiClient: api);
    expect((await repository.getPointsPromotion())!.multiplier, 2);
    expect((await repository.getPointsPromotion())!.shouldDisplay, false);
    expect(await repository.getPointsPromotion(), isNull);
    expect(requests, 3);
  });

  testWidgets('actualiza cada minuto y oculta una promoción finalizada',
      (tester) async {
    final repository = PromotionRepository()
      ..value = const PointsPromotion(
          multiplier: 2, minimumFuelLiters: 40, promotionName: 'Domingos X2');
    await tester.pumpWidget(banner(repository));
    await tester.pump();
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('¡Sumá el doble de puntos!'), findsOneWidget);
    repository.value =
        const PointsPromotion(multiplier: 1, minimumFuelLiters: 40);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(find.text('2×'), findsNothing);
    expect(repository.requests, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('al salir del inicio pausa consultas; al volver actualiza',
      (tester) async {
    final repository = PromotionRepository()
      ..value = const PointsPromotion(multiplier: 1.5, minimumFuelLiters: 40);
    await tester.pumpWidget(banner(repository));
    await tester.pump();
    await tester.pumpWidget(banner(repository, active: false));
    await tester.pump(const Duration(minutes: 2));
    expect(repository.requests, 1);
    expect(find.text('1,5×'), findsNothing);
    await tester.pumpWidget(banner(repository));
    await tester.pump();
    expect(repository.requests, 2);
    expect(find.text('1,5×'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('error de conexión oculta el valor anterior sin romper el inicio',
      (tester) async {
    final repository = PromotionRepository()
      ..value = const PointsPromotion(multiplier: 2, minimumFuelLiters: 40);
    await tester.pumpWidget(banner(repository));
    await tester.pump();
    repository.fail = true;
    await tester.pumpWidget(banner(repository, refresh: 1));
    await tester.pump();
    expect(find.text('2×'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ignora respuesta recibida después de cambiar de pestaña',
      (tester) async {
    final repository = PromotionRepository()
      ..pending = Completer<PointsPromotion?>();
    await tester.pumpWidget(banner(repository));
    await tester.pumpWidget(banner(repository, active: false));
    repository.pending!
        .complete(const PointsPromotion(multiplier: 2, minimumFuelLiters: 40));
    await tester.pump();
    expect(find.text('2×'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reanuda consulta al volver del segundo plano', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final repository = PromotionRepository()
      ..value = const PointsPromotion(multiplier: 2, minimumFuelLiters: 40);
    await tester.pumpWidget(banner(repository));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 2));
    expect(repository.requests, 1);
    repository.value =
        const PointsPromotion(multiplier: 3, minimumFuelLiters: 40);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('3×'), findsOneWidget);
    expect(repository.requests, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('se adapta a pantalla estrecha y texto grande', (tester) async {
    final repository = PromotionRepository()
      ..value = const PointsPromotion(
          multiplier: 1.25,
          minimumFuelLiters: 40,
          promotionName:
              'Promoción especial de puntos para todos los domingos');
    await tester.pumpWidget(banner(repository, scale: 2));
    await tester.pump();
    expect(find.text('1,25×'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
