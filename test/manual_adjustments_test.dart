import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ruta_gen_app/core/theme/app_colors.dart';
import 'package:ruta_gen_app/data/api_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/models.dart';
import 'package:ruta_gen_app/features/movements/movements_page.dart';
import 'package:ruta_gen_app/services/api_client.dart';

class AdjustmentRepository extends MockRutaGenRepository {
  @override
  Future<List<Movement>> getMovements({int page = 1, int limit = 20}) async => [
        Movement(
            id: 'positive',
            title: 'Ajuste manual',
            subtitle: 'Motivo: Video',
            date: DateTime.utc(2026, 9, 30, 14, 40),
            points: 1000,
            type: MovementType.adjustment),
        Movement(
            id: 'negative',
            title: 'Ajuste manual',
            subtitle: 'Motivo: Corrección de saldo',
            date: DateTime.utc(2026, 9, 30, 14, 35),
            points: -200,
            type: MovementType.adjustment),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('mezcla ajustes con cargas y premios, conserva motivo, signo y fecha',
      () async {
    final paths = <String>[];
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      paths.add(request.url.path);
      expect(request.headers['Authorization'], 'Bearer test-token');
      final path = request.url.path;
      if (path.endsWith('/point-adjustments')) {
        return http.Response(
            jsonEncode({
              'data': {
                'items': [
                  {
                    'id': 'positive',
                    'points': 1000,
                    'reason': 'Video',
                    'createdAt': '2026-09-30T14:40:00Z'
                  },
                  {
                    'id': 'negative',
                    'points': -200,
                    'reason': 'Corrección de saldo',
                    'createdAt': '2026-09-30T14:35:00Z'
                  },
                ]
              }
            }),
            200);
      }
      if (path.endsWith('/loads/me')) {
        return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'load',
                  'pointsEarned': 39,
                  'createdAt': '2026-09-29T21:29:00Z',
                  'stationName': 'Canning 2',
                  'productName': 'INFINIA',
                  'liters': 39.35
                },
              ]
            }),
            200);
      }
      return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'reward',
                'redemptionKind': 'POINTS',
                'pointsCost': 160,
                'rewardName': 'Café',
                'createdAt': '2026-09-29T21:31:00Z'
              },
            ]
          }),
          200);
    }));
    await api.saveAccessToken('test-token');
    final movements = await ApiRutaGenRepository(apiClient: api).getMovements();
    expect(movements.map((m) => m.points), [1000, -200, -160, 39]);
    expect(movements.first.type, MovementType.adjustment);
    expect(movements.first.title, 'Ajuste manual');
    expect(movements.first.subtitle, 'Motivo: Video');
    expect(movements.first.date.toUtc(), DateTime.utc(2026, 9, 30, 14, 40));
    expect(movements.first.isGift, false);
    expect(movements.first.argentinaDate.hour, 11);
    expect(movements.first.argentinaDate.minute, 40);
    expect(paths.any((p) => p.endsWith('/users/me/point-adjustments')), true);
    expect(movements.map((m) => m.id).toSet().length, 4);
  });

  test('el historial sigue paginando después de los primeros 100 registros',
      () async {
    final sourcePages = <int>[];
    final loads = List.generate(
        125,
        (i) => {
              'id': 'load-$i',
              'pointsEarned': 1,
              'createdAt': DateTime.utc(2026, 9, 30)
                  .subtract(Duration(minutes: i))
                  .toIso8601String(),
            });
    final api = ApiClient.forTesting(httpClient: MockClient((request) async {
      if (!request.url.path.endsWith('/loads/me')) {
        return http.Response(
            jsonEncode({
              'data': {'items': []}
            }),
            200);
      }
      final page = int.parse(request.url.queryParameters['page']!);
      final limit = int.parse(request.url.queryParameters['limit']!);
      sourcePages.add(page);
      return http.Response(
          jsonEncode(
              {'data': loads.skip((page - 1) * limit).take(limit).toList()}),
          200);
    }));
    await api.saveAccessToken('test-token');
    final movements = await ApiRutaGenRepository(apiClient: api)
        .getMovements(page: 6, limit: 20);
    expect(sourcePages, [1, 2]);
    expect(movements.length, 20);
    expect(movements.first.id, 'load-100');
    expect(movements.last.id, 'load-119');
  });

  testWidgets(
      'tarjetas de ajuste muestran motivo, fecha, hora y puntos con color correcto',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: MovementsPage(repository: AdjustmentRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Ajuste manual'), findsNWidgets(2));
    expect(find.text('Motivo: Video'), findsOneWidget);
    expect(find.text('30/09/2026 · 11:40'), findsOneWidget);
    expect(find.text('+1.000'), findsOneWidget);
    expect(find.text('-200'), findsOneWidget);
    expect(tester.widget<Text>(find.text('+1.000')).style?.color,
        AppColors.success);
    expect(
        tester.widget<Text>(find.text('-200')).style?.color, AppColors.danger);
    expect(find.byIcon(Icons.tune_rounded), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
