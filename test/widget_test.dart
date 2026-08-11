import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_gen_app/app.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';

void main() {
  testWidgets('muestra el acceso de Ruta Gen', (tester) async {
    await tester.pumpWidget(RutaGenApp(repository: MockRutaGenRepository()));
    expect(find.text('Bienvenido a Ruta Gen'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
