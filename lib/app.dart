import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/ruta_gen_repository.dart';
import 'features/auth/login_page.dart';
import 'features/shell/app_shell.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/push_notification_service.dart';

class RutaGenApp extends StatefulWidget {
  const RutaGenApp({
    super.key,
    required this.repository,
  });

  final RutaGenRepository repository;

  @override
  State<RutaGenApp> createState() => _RutaGenAppState();
}

class _RutaGenAppState extends State<RutaGenApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  UserModel? _currentUser;

  bool _checkingSession = true;
  bool _biometricFlowRunning = false;

  StreamSubscription<PushMessage>? _pushSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _pushSubscription =
        PushNotificationService.instance.foregroundMessages.listen(
      _showForegroundNotification,
    );

    /*
     * La biometría se solicita únicamente cuando
     * Ruta Gen inicia desde cero.
     *
     * Si el usuario minimiza la app, cambia a otra
     * aplicación o bloquea momentáneamente el teléfono,
     * no se vuelve a pedir Face ID / huella.
     *
     * Si el usuario cierra completamente Ruta Gen
     * y luego vuelve a abrirla, initState se ejecuta
     * nuevamente y se solicita la biometría.
     */
    // Esperar a que el motor dibuje el loader antes de abrir Face ID.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startAfterLoadingFrame());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushSubscription?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Reintenta el registro push después de habilitar permisos en Ajustes
    // o si APNs no entregó el token durante el primer inicio de sesión.
    // La sesión sigue abierta y no se vuelve a solicitar biometría.
    if (state == AppLifecycleState.resumed &&
        _currentUser != null &&
        !_checkingSession) {
      unawaited(_bindPushAfterAuthentication());
    }
  }

  /* ============================================================
     INICIO DE LA APP
  ============================================================ */

  Future<void> _startAfterLoadingFrame() async {
    final binding = WidgetsBinding.instance;
    // En pruebas de widgets no hay rasterización del motor nativo.
    if (binding is WidgetsFlutterBinding) {
      await binding.waitUntilFirstFrameRasterized;
    }
    if (!mounted) return;
    await _authenticateOnStartup();
  }

  Future<void> _authenticateOnStartup() async {
    await _authenticateWithBiometrics(
      showErrors: false,
    );

    // Con sesión, _bindPushAfterAuthentication ya inicializa Firebase.
    // Sin sesión, preparar las notificaciones después de mostrar el login.
    // Ningún permiso de notificaciones bloquea el primer frame ni Face ID.
    if (mounted && _currentUser == null) {
      await PushNotificationService.instance.initialize();
    }
  }

  /* ============================================================
     AUTENTICACIÓN BIOMÉTRICA AL INICIAR
  ============================================================ */

  Future<void> _authenticateWithBiometrics({
    required bool showErrors,
  }) async {
    if (_biometricFlowRunning) {
      return;
    }

    _biometricFlowRunning = true;

    if (mounted) {
      setState(() {
        _checkingSession = true;
      });
    }

    try {
      final enabled = await AuthService.instance.isBiometricEnabled();

      final user = enabled
          ? await AuthService.instance.loginWithBiometrics()
          : await AuthService.instance.restoreSession();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = user;
        _checkingSession = false;
      });

      if (user != null) {
        unawaited(
          _bindPushAfterAuthentication(),
        );
      }
    } on BiometricException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = null;
        _checkingSession = false;
      });

      if (showErrors) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = null;
        _checkingSession = false;
      });

      if (showErrors) {
        _showMessage(
          'No se pudo recuperar la sesión. Revisá la conexión o ingresá con tu DNI o correo.',
        );
      }
    } finally {
      _biometricFlowRunning = false;
    }
  }

  /* ============================================================
     LOGIN O REGISTRO COMPLETADO
  ============================================================ */

  void _handleAuthenticated(
    UserModel user,
  ) {
    if (!mounted) {
      return;
    }

    /*
     * Login ya validó al cliente y guardó el token.
     *
     * Evitamos realizar inmediatamente otro /auth/me,
     * ya que un problema momentáneo de conexión podría
     * devolver al usuario al login después de un inicio
     * o registro exitoso.
     */
    setState(() {
      _currentUser = user;
      _checkingSession = false;
    });

    unawaited(
      _bindPushAfterAuthentication(),
    );
  }

  Future<void> _bindPushAfterAuthentication() async {
    try {
      await PushNotificationService.instance.bindToCurrentUser();
    } catch (_) {
      /*
       * Un fallo al registrar notificaciones
       * no debe impedir el inicio de sesión.
       */
    }
  }

  /* ============================================================
     CERRAR SESIÓN
  ============================================================ */

  void _handleAccountDeleted() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _checkingSession = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogContext = _navigatorKey.currentContext;
      if (!mounted || dialogContext == null) return;
      showDialog<void>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Cuenta eliminada'),
          content: const Text('Tu cuenta fue eliminada correctamente.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'))
          ],
        ),
      );
    });
  }

  Future<void> _logout() async {
    await PushNotificationService.instance.unregisterCurrentDevice();

    await AuthService.instance.logout();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = null;
      _checkingSession = false;
    });
  }

  /* ============================================================
     MENSAJES
  ============================================================ */

  void _showMessage(
    String message,
  ) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
    );
  }

  void _showForegroundNotification(
    PushMessage notification,
  ) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${notification.title}\n${notification.body}',
              ),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Ver',
                onPressed: () {
                  PushNotificationService.instance.openAction(
                    notification.action,
                    giftId: notification.giftId,
                  );
                },
              ),
            ),
          );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'Ruta Gen',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _checkingSession || _currentUser != null
            ? AppTheme.lightBackgroundOverlay
            : AppTheme.darkBackgroundOverlay,
        child: child ?? const SizedBox.shrink(),
      ),
      scaffoldMessengerKey: _messengerKey,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_checkingSession) {
      return const _SessionLoadingPage();
    }

    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: 280,
      ),
      child: _currentUser != null
          ? AppShell(
              key: const ValueKey('app'),
              repository: widget.repository,
              user: _currentUser!,
              onLogout: _logout,
              onAccountDeleted: _handleAccountDeleted,
            )
          : LoginPage(
              key: const ValueKey('login'),
              onAuthenticated: _handleAuthenticated,
            ),
    );
  }
}

class _SessionLoadingPage extends StatelessWidget {
  const _SessionLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 500 / 540,
                child: Image.asset(
                  'assets/animations/ruta_gen_loader.gif',
                  fit: BoxFit.contain,
                  semanticLabel: 'Ruta GEN. Cargando…',
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) return const _LoadingFallback();
                    return child;
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const _LoadingFallback(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingFallback extends StatelessWidget {
  const _LoadingFallback();

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.blue,
              strokeWidth: 3,
              semanticsLabel: 'Cargando Ruta GEN',
            ),
          ),
          SizedBox(height: 16),
          Text('Cargando Ruta GEN…', style: TextStyle(color: AppColors.muted)),
        ],
      );
}
