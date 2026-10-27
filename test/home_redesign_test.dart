import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_gen_app/core/theme/app_theme.dart';
import 'package:ruta_gen_app/data/mock_ruta_gen_repository.dart';
import 'package:ruta_gen_app/data/models.dart';
import 'package:ruta_gen_app/features/home/home_page.dart';
import 'package:ruta_gen_app/features/home/widgets/home_hero.dart';
import 'package:ruta_gen_app/features/home/widgets/home_quick_actions.dart';
import 'package:ruta_gen_app/features/movements/movements_page.dart';
import 'package:ruta_gen_app/features/shell/widgets/gen_bottom_navigation.dart';
import 'package:ruta_gen_app/models/user_model.dart';
import 'package:ruta_gen_app/shared/widgets/visit_progress_card.dart';

const _progress = VisitProgress(
  monthKey: '2026-10',
  visitedStations: [
    VisitStation(slug: 'combustibles-canning-1', name: 'Combustibles Canning'),
  ],
  stationCount: 1,
  enabled: true,
  secondStationStatus: 'PENDING',
  thirdStationStatus: 'PENDING',
  remainingForBreakfast: 1,
  remainingForMeal: 2,
);

class _HomeRepository extends MockRutaGenRepository {
  bool fail = false;
  Completer<List<NewsItem>>? pendingNews;

  @override
  Future<List<NewsItem>> getNews({int page = 1, int limit = 10}) async {
    if (fail) throw StateError('sin conexión');
    return pendingNews?.future ?? <NewsItem>[];
  }

  @override
  Future<List<Movement>> getMovements({int page = 1, int limit = 20}) async {
    if (fail) throw StateError('sin conexión');
    return [];
  }

  @override
  Future<VisitProgress> getVisitProgress() async {
    if (fail) throw StateError('sin conexión');
    return _progress;
  }
}

UserModel _user(double points, {String name = 'Lucas'}) => UserModel(
      id: 'test-user',
      role: 'CUSTOMER',
      status: 'ACTIVE',
      firstName: name,
      lastName: 'Prueba',
      dni: '12345678',
      email: 'test@example.com',
      pointsBalance: points,
      lifetimePointsEarned: points,
      lifetimePointsRedeemed: 0,
      emailVerified: true,
      phoneVerified: false,
      identityVerified: true,
      memberCode: 'NO-DEBE-MOSTRARSE',
    );

Widget _home(
  _HomeRepository repository, {
  double points = 34,
  double scale = 1,
  bool reduced = true,
  String name = 'Lucas',
  ValueChanged<int>? onNavigate,
  VoidCallback? onNotifications,
}) =>
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: const ValueKey('home-preview'),
        child: Scaffold(
          body: HomePage(
            repository: repository,
            user: _user(points, name: name),
            onNavigate: onNavigate ?? (_) {},
            onRefreshUser: () async {},
            onOpenNotifications: onNotifications ?? () {},
            unreadNotifications: 2,
            onOpenGiftRewards: () {},
            onCompleteDni: () {},
          ),
          bottomNavigationBar: GenBottomNavigation(
            selectedIndex: 0,
            onDestinationSelected: onNavigate ?? (_) {},
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  // Optional local visual QA; production assets/data are never substituted.
  setUpAll(() async {
    final fonts = Platform.environment['RUTA_GEN_TEST_FONT_DIR'];
    if (fonts != null) {
      final loader = FontLoader('Roboto');
      for (final name in ['regular', 'bold', 'black']) {
        loader.addFont(Future.value(
          ByteData.sublistView(
            File('$fonts/roboto-$name.ttf').readAsBytesSync(),
          ),
        ));
      }
      await loader.load();
      final defaultFont = FontLoader('Ahem')
        ..addFont(Future.value(ByteData.sublistView(
          File('$fonts/roboto-regular.ttf').readAsBytesSync(),
        )));
      await defaultFont.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(
          File('$fonts/materialicons-regular.otf').readAsBytesSync(),
        )));
      await icons.load();
    }
  });

  testWidgets('saldo real: cero, miles, decimales y actualización inmediata',
      (tester) async {
    final repository = _HomeRepository();
    for (final entry in <double, String>{
      0: '0',
      9999: '9.999',
      123456789.25: '123.456.789,25',
      34: '34',
    }.entries) {
      await tester.pumpWidget(
        _home(repository, points: entry.key, reduced: false),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(entry.value), findsOneWidget);
      expect(find.textContaining('NO-DEBE-MOSTRARSE'), findsNothing);
      expect(find.text('PUNTOS DISPONIBLES'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('sin overflow en $size con escala $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_home(
          _HomeRepository(),
          points: 9999999.75,
          scale: scale,
          name: 'María de los Ángeles',
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 20; i++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -250),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Todavía no tenés movimientos'), findsOneWidget);
      });
    }
  }

  testWidgets('premios, notificaciones, QR e historial conservan destinos',
      (tester) async {
    final selected = <int>[];
    var notifications = 0;
    await tester.pumpWidget(_home(
      _HomeRepository(),
      onNavigate: selected.add,
      onNotifications: () => notifications++,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver premios'));
    await tester.tap(find.byTooltip('2 notificaciones sin leer'));
    expect(selected, [3]);
    expect(notifications, 1);

    final quickQr = find.descendant(
      of: find.byType(HomeQuickActions),
      matching: find.text('Mi QR'),
    );
    await tester.scrollUntilVisible(
      quickQr,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(quickQr);
    expect(selected, [3, 2]);

    final history = find.byTooltip('Ver historial de movimientos');
    await tester.scrollUntilVisible(
      history,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(history);
    await tester.pumpAndSettle();
    expect(find.byType(MovementsPage), findsOneWidget);
  });

  testWidgets('los seis destinos y selección del menú son accesibles',
      (tester) async {
    final selected = <int>[];
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: GenBottomNavigation(
          selectedIndex: 3,
          onDestinationSelected: selected.add,
        ),
      ),
    ));
    final labels = [
      'Inicio',
      'Estaciones',
      'Mi QR',
      'Premios',
      'Sorteos',
      'Cuenta'
    ];
    for (final label in labels) {
      await tester.tap(find.text(label));
    }
    expect(selected, [0, 1, 2, 3, 4, 5]);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Premios')),
      matchesSemantics(
        label: 'Premios',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('carga, vacío y error conservan un inicio utilizable',
      (tester) async {
    final repository = _HomeRepository()
      ..pendingNews = Completer<List<NewsItem>>();
    await tester.pumpWidget(_home(repository));
    await tester.pump();
    expect(find.text('34'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    repository.pendingNews!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No hay novedades publicadas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_home(_HomeRepository()..fail = true));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar las novedades'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tu ruta del mes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movimiento reducido y vista para revisión local',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_home(_HomeRepository()));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(GenPointsCard), findsOneWidget);
    final preview = Platform.environment['RUTA_GEN_PREVIEW_PATH'];
    if (preview != null) {
      debugDisableShadows = false;
      await tester.pumpWidget(_home(_HomeRepository()));
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('home-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(preview).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      debugDisableShadows = true;
    }
  });

  testWidgets('progreso mensual representa datos reales y habilita historial',
      (tester) async {
    var history = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VisitProgressCard(
          progress: _progress,
          onOpenGifts: () {},
          onHistory: () => history++,
        ),
      ),
    ));
    expect(find.text('1/3 estaciones distintas'), findsOneWidget);
    expect(find.text('Combustibles Canning'), findsOneWidget);
    await tester.tap(find.byTooltip('Ver historial de movimientos'));
    expect(history, 1);
  });
}
