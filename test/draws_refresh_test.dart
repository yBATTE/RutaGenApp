import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/models.dart';
import 'package:ruta_gen_app/features/draws/draws_page.dart';
import 'package:ruta_gen_app/models/user_model.dart';

class _DrawRepository extends MockRutaGenRepository {
  final requests = <Completer<List<DrawEvent>>>[];

  @override
  Future<List<DrawEvent>> getDrawEvents() {
    final request = Completer<List<DrawEvent>>();
    requests.add(request);
    return request.future;
  }
}

const _user = UserModel(
  id: 'draw-test', role: 'CUSTOMER', status: 'ACTIVE',
  firstName: 'Cliente', lastName: 'Prueba', dni: '',
  email: 'test@example.com', pointsBalance: 0,
  lifetimePointsEarned: 0, lifetimePointsRedeemed: 0,
  emailVerified: false, phoneVerified: false, identityVerified: false,
);

DrawEvent _event(String title) => DrawEvent(
  id: title, title: title, prizeName: 'Premio', status: 'OPEN',
  startAt: null, endAt: null, drawAt: null,
);

Widget _host(_DrawRepository repository, {bool active = true, int version = 0}) =>
    MaterialApp(home: DrawsPage(
      repository: repository, user: _user,
      isActive: active, refreshVersion: version,
    ));

void main() {
  testWidgets('reactivar Sorteos actualiza datos sin devolver Future desde setState', (tester) async {
    final repository = _DrawRepository();
    await tester.pumpWidget(_host(repository, active: false));
    repository.requests.single.complete([_event('Anterior')]);
    await tester.pumpAndSettle();
    expect(find.text('Anterior'), findsOneWidget);

    await tester.pumpWidget(_host(repository));
    expect(repository.requests, hasLength(2));
    repository.requests.last.complete([_event('Actualizado')]);
    await tester.pumpAndSettle();
    expect(find.text('Actualizado'), findsOneWidget);
    expect(find.text('Anterior'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cambios rápidos y actualización manual reutilizan la consulta pendiente', (tester) async {
    final repository = _DrawRepository();
    await tester.pumpWidget(_host(repository));
    await tester.pumpWidget(_host(repository, active: false));
    await tester.pumpWidget(_host(repository, version: 1));
    final refreshing = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    expect(repository.requests, hasLength(1));
    repository.requests.single.complete([_event('Inicial')]);
    await refreshing;
    await tester.pumpAndSettle();
    expect(find.text('Inicial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la respuesta tardía tras salir de la página no actualiza estado desmontado', (tester) async {
    final repository = _DrawRepository();
    await tester.pumpWidget(_host(repository));
    repository.requests.single.complete([]);
    await tester.pumpAndSettle();
    final refreshing = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repository.requests.last.complete([_event('Tardío')]);
    await refreshing;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('un fallo se muestra y permite volver a consultar', (tester) async {
    final repository = _DrawRepository();
    await tester.pumpWidget(_host(repository));
    repository.requests.single.completeError(StateError('sin conexión'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar los sorteos.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(repository.requests, hasLength(2));
    repository.requests.last.complete([_event('Recuperado')]);
    await tester.pumpAndSettle();
    expect(find.text('Recuperado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
