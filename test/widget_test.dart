import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ruta_gen_app/app.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';

void main() {
  testWidgets('muestra el acceso de Ruta Gen', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(RutaGenApp(repository: MockRutaGenRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a Ruta Gen'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
