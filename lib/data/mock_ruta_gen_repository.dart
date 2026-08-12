import 'package:flutter/material.dart';

import 'models.dart';
import 'ruta_gen_repository.dart';

class MockRutaGenRepository implements RutaGenRepository {
  static const _delay = Duration(milliseconds: 350);

  @override
  Future<Customer> getCustomer() async {
    await Future<void>.delayed(_delay);
    return const Customer(
      firstName: 'Lucas',
      lastName: 'Battelini',
      memberCode: 'RG-001248',
      points: 12450,
    );
  }

  @override
  Future<List<Reward>> getRewards() async {
    await Future<void>.delayed(_delay);
    return const [
      Reward(
        id: 'termo',
        name: 'Termo Ruta Gen',
        subtitle: '750 ml',
        points: 8000,
        stock: 12,
        icon: Icons.thermostat_rounded,
      ),
      Reward(
        id: 'gorra',
        name: 'Gorra Ruta Gen',
        subtitle: 'Edición oficial',
        points: 6000,
        stock: 8,
        icon: Icons.sports_baseball_rounded,
      ),
    ];
  }

  @override
  Future<List<Movement>> getMovements({
    int page = 1,
    int limit = 20,
  }) async {
    await Future<void>.delayed(_delay);
    final now = DateTime.now();
    final movements = [
      Movement(
        id: 'mock-load-1',
        title: 'Carga de combustible',
        subtitle: 'Canning 1\nInfinia • 32,4 L',
        date: now.subtract(const Duration(hours: 2)),
        points: 32,
        type: MovementType.load,
        stationName: 'Canning 1',
        productName: 'Infinia',
        liters: 32.4,
        amount: 48600,
        pricePerLiter: 1500,
      ),
    ];

    final start = (page - 1) * limit;
    if (start >= movements.length) return const [];
    final end = (start + limit) > movements.length
        ? movements.length
        : start + limit;
    return movements.sublist(start, end);
  }

  @override
  Future<List<NewsItem>> getNews({
    int page = 1,
    int limit = 10,
  }) async {
    await Future<void>.delayed(_delay);
    return const [];
  }

  @override
  Future<NewsItem> getNewsDetail(String newsId) async {
    await Future<void>.delayed(_delay);
    throw StateError('Novedad mock no encontrada.');
  }

  @override
  Future<List<Station>> getStations() async {
    await Future<void>.delayed(_delay);
    return const [];
  }

  @override
  Future<String> getQrToken() async {
    await Future<void>.delayed(_delay);
    return 'TOKEN-DE-PRUEBA';
  }

  @override
  Future<String> redeemReward(String rewardId) async {
    await Future<void>.delayed(_delay);
    return 'CANJE DE PRUEBA';
  }
}
