import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_gen_app/features/account/terms_content.dart';
import 'package:ruta_gen_app/features/account/terms_page.dart';
import 'package:ruta_gen_app/models/user_model.dart';

void main() {
  test('la evidencia sobrevive a serialización y actualización de perfil', () {
    final user = UserModel.fromJson({
      'id': 'customer',
      'acceptedTermsAt': '2026-10-22T18:00:12Z',
      'acceptedTermsVersion': rutaGenTermsVersion,
      'acceptedTermsDocumentSha256': rutaGenTermsDocumentSha256,
    });
    final restored = UserModel.fromJson(user.toJson()).copyWith(phone: '1234');
    expect(restored.acceptedTermsAt, DateTime.utc(2026, 10, 22, 18, 0, 12));
    expect(restored.acceptedTermsVersion, rutaGenTermsVersion);
    expect(restored.acceptedTermsDocumentSha256, rutaGenTermsDocumentSha256);
    expect(UserModel.fromJson({'id': 'old'}).acceptedTermsVersion, isNull);
  });

  testWidgets('muestra versión aceptada, fecha y hora con zona horaria', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TermsPage(
        acceptedTermsAt: DateTime.utc(2026, 10, 22, 18, 0, 12),
        acceptedTermsVersion: rutaGenTermsVersion,
      ),
    ));
    expect(find.textContaining('Aceptaste los términos versión $rutaGenTermsVersion'), findsOneWidget);
    expect(find.textContaining('22/10/2026 a las'), findsOneWidget);
    expect(find.textContaining('(UTC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fecha histórica no se atribuye a la versión actual', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TermsPage(acceptedTermsAt: DateTime.utc(2026, 10, 1)),
    ));
    expect(find.textContaining('La versión aceptada no quedó registrada.'), findsOneWidget);
    expect(find.textContaining('Aceptaste los términos versión'), findsNothing);
  });

  testWidgets('distingue aceptación de otra versión del documento mostrado', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TermsPage(
        acceptedTermsAt: DateTime.utc(2026, 10, 1),
        acceptedTermsVersion: '0.4',
      ),
    ));
    expect(find.textContaining('Aceptaste los términos versión 0.4'), findsOneWidget);
    expect(find.textContaining('este registro no acredita su aceptación.'), findsOneWidget);
  });

  testWidgets('registro permite leer sin afirmar una aceptación previa', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: TermsPage(acceptedTermsAt: null, showAcceptance: false),
    ));
    expect(find.textContaining('No encontramos registrada'), findsNothing);
    expect(find.textContaining('Aceptaste los términos versión'), findsNothing);
  });
}
