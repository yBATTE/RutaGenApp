import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_gen_app/features/account/delete_account_page.dart';
import 'package:ruta_gen_app/services/api_client.dart';

Future<void> press(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {

  testWidgets('two confirmations, password and cleanup precede completion',
      (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
        home: DeleteAccountPage(
      deleteAccount: (password) async {
        expect(password, 'Test123');
        calls.add('delete');
      },
      clearDeletedSession: () async {
        calls.add('cleanup');
      },
      onAccountDeleted: () {
        calls.add('done');
      },
    )));
    expect(find.text('Eliminar definitivamente'), findsNothing);
    await press(tester, 'Continuar');
    expect(calls, isEmpty);
    await press(tester, 'Eliminar definitivamente');
    expect(find.text('Ingresá tu contraseña actual.'), findsOneWidget);
    expect(calls, isEmpty);
    await tester.enterText(find.byType(TextField), 'Test123');
    await press(tester, 'Eliminar definitivamente');
    expect(calls, ['delete', 'cleanup', 'done']);
  });

  testWidgets('API error permits retry without cleanup or logout',
      (tester) async {
    var attempts = 0;
    var cleaned = false;
    var completed = false;
    await tester.pumpWidget(MaterialApp(
        home: DeleteAccountPage(
      deleteAccount: (_) async {
        attempts++;
        if (attempts == 1) {
          throw const ApiException(
              message: 'La contraseña actual es incorrecta.', statusCode: 401);
        }
      },
      clearDeletedSession: () async {
        cleaned = true;
      },
      onAccountDeleted: () {
        completed = true;
      },
    )));
    await press(tester, 'Continuar');
    await tester.enterText(find.byType(TextField), 'Test123');
    await press(tester, 'Eliminar definitivamente');
    expect(find.text('La contraseña actual es incorrecta.'), findsOneWidget);
    expect(cleaned, false);
    expect(completed, false);
    await press(tester, 'Eliminar definitivamente');
    expect(attempts, 2);
    expect(cleaned, true);
    expect(completed, true);
  });

  testWidgets('local cleanup retry does not repeat backend deletion',
      (tester) async {
    var deleted = 0;
    var cleaned = 0;
    var completed = false;
    await tester.pumpWidget(MaterialApp(
        home: DeleteAccountPage(
      deleteAccount: (_) async {
        deleted++;
      },
      clearDeletedSession: () async {
        cleaned++;
        if (cleaned == 1) throw StateError('storage');
      },
      onAccountDeleted: () {
        completed = true;
      },
    )));
    await press(tester, 'Continuar');
    await tester.enterText(find.byType(TextField), 'Test123');
    await press(tester, 'Eliminar definitivamente');
    expect(deleted, 1);
    expect(completed, false);
    await press(tester, 'Completar cierre de sesión');
    expect(deleted, 1);
    expect(cleaned, 2);
    expect(completed, true);
  });

  testWidgets('Volver cancels confirmation without requesting deletion',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var deleted = false;
    await tester.pumpWidget(MaterialApp(
        home: DeleteAccountPage(
      deleteAccount: (_) async {
        deleted = true;
      },
      clearDeletedSession: () async {},
      onAccountDeleted: () {},
    )));
    await press(tester, 'Continuar');
    await press(tester, 'Volver');
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(deleted, false);
  });
}
