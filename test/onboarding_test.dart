import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruta_gen_app/features/onboarding/onboarding_page.dart';
import 'package:ruta_gen_app/services/onboarding_service.dart';

Widget welcome(Future<void> Function() onComplete, {double textScale = 1}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true,
      textScaler: TextScaler.linear(textScale)), child: child!),
  home: OnboardingPage(onComplete: onComplete),
);

Future<void> press(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  test('la bienvenida se conserva entre instancias del servicio', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await OnboardingService().isCompleted(), false);
    await OnboardingService().complete();
    expect(await OnboardingService().isCompleted(), true);
  });

  testWidgets('solo completa al tocar Comenzar y no ofrece Omitir', (tester) async {
    var completed = 0;
    await tester.pumpWidget(welcome(() async { completed++; }));
    expect(find.text('Bienvenido a\nRuta GEN'), findsOneWidget);
    expect(find.text('Omitir'), findsNothing);
    await press(tester, 'Siguiente');
    expect(find.text('Cargá y sumá\npuntos'), findsOneWidget);
    expect(completed, 0);
    await press(tester, 'Siguiente');
    expect(find.text('Elegí tu próximo\npremio'), findsOneWidget);
    expect(completed, 0);
    await press(tester, 'Comenzar');
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la transición conserva cada dibujo y bloquea dobles toques', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: OnboardingPage(onComplete: () async {}),
    ));
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('Cargá y sumá\npuntos'), findsOneWidget);
    expect(find.text('Comenzar'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un fallo al guardar permite reintentar', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(welcome(() async {
      if (++attempts == 1) throw StateError('storage');
    }));
    await press(tester, 'Siguiente');
    await press(tester, 'Siguiente');
    await press(tester, 'Comenzar');
    expect(find.text('No se pudo guardar. Tocá Comenzar para reintentar.'), findsOneWidget);
    await press(tester, 'Comenzar');
    expect(attempts, 2);
  });

  testWidgets('pantalla chica y texto grande permiten completar sin overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(welcome(() async {}, textScale: 1.8));
    await press(tester, 'Siguiente');
    await press(tester, 'Siguiente');
    await press(tester, 'Comenzar');
    expect(tester.takeException(), isNull);
  });
}
