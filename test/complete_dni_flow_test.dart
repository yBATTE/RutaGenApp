import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_gen_app/features/account/complete_dni_page.dart';
import 'package:ruta_gen_app/shared/widgets/identity_verification_banner.dart';

void main() {
  testWidgets('sin DNI dirige a completar y no a las estaciones', (tester) async {
    var completeCalls = 0;
    var stationCalls = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: IdentityVerificationBanner(
      needsDni: true,
      onCompleteDni: () => completeCalls++,
      onViewStations: () => stationCalls++,
    ))));
    await tester.tap(find.text('Completar mi DNI'));
    expect(completeCalls, 1);
    expect(stationCalls, 0);
    expect(find.text('Ver estaciones para verificarme'), findsNothing);
  });

  testWidgets('con DNI dirige a la verificación presencial', (tester) async {
    var stationCalls = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: IdentityVerificationBanner(
      onViewStations: () => stationCalls++,
    ))));
    await tester.tap(find.text('Ver estaciones para verificarme'));
    expect(stationCalls, 1);
    expect(find.text('Completar mi DNI'), findsNothing);
  });

  testWidgets('DNI incompleto no abre confirmación ni guarda', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CompleteDniPage()));
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.ensureVisible(find.text('Guardar DNI'));
    await tester.tap(find.text('Guardar DNI'));
    await tester.pump();
    expect(find.text('Ingresá un DNI de 7 a 9 números.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('DNI válido requiere confirmación y permite revisar sin guardar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CompleteDniPage()));
    await tester.enterText(find.byType(TextFormField), '12345678');
    await tester.ensureVisible(find.text('Guardar DNI'));
    await tester.tap(find.text('Guardar DNI'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmá tu DNI'), findsOneWidget);
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('12345678'), findsOneWidget);
  });
}
