import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruta_gen_app/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ruta_gen_app/app.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';

void main() {
  testWidgets('muestra el acceso de Ruta Gen', (tester) async {
    SharedPreferences.setMockInitialValues({OnboardingService.completedKey: true});
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(RutaGenApp(repository: MockRutaGenRepository()));
    // El splash usa temporizadores entre cuadros: pumpAndSettle por sí solo
    // puede terminar antes del cuadro siguiente. Dar tiempo al codec nativo.
    for (var i = 0; i < 300; i++) {
      if (find.text('Bienvenido a Ruta GEN').evaluate().isNotEmpty) break;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a Ruta GEN'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
