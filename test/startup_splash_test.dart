import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_gen_app/shared/widgets/startup_splash.dart';

class _GifBundle extends CachingAssetBundle {
  _GifBundle(this.data);
  final String? data;

  @override
  Future<ByteData> load(String key) async {
    if (data == null) throw FlutterError('Asset no disponible');
    return ByteData.sublistView(base64Decode(data!));
  }
}

// GIFs de dos cuadros. Se usan sus duraciones reales, no un reloj simulado
// del reproductor: los cuadros se decodifican con el codec de Flutter.
const _shortGif = 'R0lGODlhCAAIAIEAAAAA/wAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQAKAAAACwAAAAACAAIAAAIDwABCBxIsKDBgwgTKkwYEAAh+QQBKAABACwAAAAACAAIAIH//wAAAAAAAAAAAAAIDwABCBxIsKDBgwgTKkwYEAA7';
const _longGif = 'R0lGODlhCAAIAIEAAAAA/wAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQAkAEAACwAAAAACAAIAAAIDwABCBxIsKDBgwgTKkwYEAAh+QQBkAEBACwAAAAACAAIAIH//wAAAAAAAAAAAAAIDwABCBxIsKDBgwgTKkwYEAA7';

Future<void> _decode(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pump();
}

Future<void> _show(WidgetTester tester, String? gif, VoidCallback onReady) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(MaterialApp(home: StartupSplash(
    assetBundle: _GifBundle(gif), onReady: onReady,
  )));
  // Completar carga/decodificación del primer cuadro antes de medir su tiempo.
  for (var i = 0; i < 20; i++) {
    await _decode(tester);
    if (gif == null || find.byType(RawImage).evaluate().isNotEmpty) return;
  }
  fail('No se pudo decodificar el fixture GIF');
}

void main() {
  testWidgets('espera 2 segundos desde el primer cuadro pintado', (tester) async {
    var ready = 0;
    await _show(tester, _shortGif, () => ready++);
    await tester.pump(const Duration(milliseconds: 400));
    await _decode(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(ready, 0);
    await tester.pump(const Duration(milliseconds: 1199));
    expect(ready, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(ready, 1);
  });

  testWidgets('un GIF largo se detiene a los 2 segundos sin seguir acumulando cuadros', (tester) async {
    var ready = 0;
    await _show(tester, _longGif, () => ready++);
    await tester.pump(const Duration(milliseconds: 1600));
    await _decode(tester);
    await tester.pump(const Duration(milliseconds: 399));
    expect(ready, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(ready, 1);
    final lastImage = tester.widget<RawImage>(find.byType(RawImage)).image;
    await tester.pump(const Duration(seconds: 3));
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(lastImage));
    expect(ready, 1);
  });

  testWidgets('el tiempo en segundo plano no acorta la reproducción', (tester) async {
    var ready = 0;
    await _show(tester, _shortGif, () => ready++);
    await tester.pump(const Duration(milliseconds: 200));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(ready, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    // Dar el tiempo visible necesario tras volver. Stopwatch usa el reloj
    // real; los Timer de esta prueba avanzan mediante pump.
    await tester.pump(const Duration(milliseconds: 400));
    await _decode(tester);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(ready, 1);
  });

  testWidgets('si falla el GIF muestra fallback y respeta el mínimo', (tester) async {
    var ready = 0;
    await _show(tester, null, () => ready++);
    expect(find.text('Cargando Ruta GEN…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(ready, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(ready, 1);
  });

  testWidgets('salir mientras carga cancela los temporizadores', (tester) async {
    var ready = 0;
    await _show(tester, _longGif, () => ready++);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(ready, 0);
    expect(tester.takeException(), isNull);
  });
}
