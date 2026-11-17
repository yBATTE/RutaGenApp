import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'data/ruta_gen_repository.dart';
import 'features/auth/login_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'services/onboarding_service.dart';
import 'features/shell/app_shell.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/push_notification_service.dart';
import 'shared/widgets/startup_splash.dart';

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

  final _onboarding = OnboardingService();
  bool _onboardingCompleted = true;
  bool _checkingSession = true;
  bool _startupSplashVisible = true;
  final Completer<void> _splashFinished = Completer<void>();
  Timer? _splashExitTimer;
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
    // Empezar la preparación de sesión después del primer frame de la app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startAfterLoadingFrame());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushSubscription?.cancel();
    _splashExitTimer?.cancel();
    if (!_splashFinished.isCompleted) _splashFinished.complete();

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
        !_checkingSession &&
        !_startupSplashVisible) {
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
    try {
      _onboardingCompleted = await _onboarding.isCompleted();
    } catch (_) {
      // Una preferencia local no debe bloquear el acceso a la cuenta.
      _onboardingCompleted = true;
    }
    if (!mounted) return;
    await _authenticateWithBiometrics(
      showErrors: false,
    );

    // No mostrar permisos nativos encima del GIF en reproducción.
    await _splashFinished.future;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (_currentUser != null) {
      await _bindPushAfterAuthentication();
    }
    // Los permisos push se solicitan al autenticar, no sobre la bienvenida.
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
      // Leer la configuración en paralelo al splash. La verificación nativa
      // espera a que termine y a que se pinte la pantalla estática de acceso.
      final enabled = await AuthService.instance.isBiometricEnabled();
      if (enabled) {
        await _splashFinished.future;
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
      }

      final user = enabled
          ? await AuthService.instance.loginWithBiometrics()
          : await AuthService.instance.restoreSession();

      if (!mounted) {
        return;
      }

      if (user != null) {
        // Usuarios existentes tampoco vuelven a verla después de cerrar sesión.
        try { await _onboarding.complete(); } catch (_) {}
        if (!mounted) return;
      }
      setState(() {
        _currentUser = user;
        if (user != null) _onboardingCompleted = true;
        _checkingSession = false;
      });

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

  Future<void> _completeOnboarding() async {
    await _onboarding.complete();
    if (!mounted) return;
    setState(() => _onboardingCompleted = true);
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
        value: _checkingSession || _startupSplashVisible || _currentUser != null || !_onboardingCompleted
            ? AppTheme.lightBackgroundOverlay
            : AppTheme.darkBackgroundOverlay,
        child: child ?? const SizedBox.shrink(),
      ),
      scaffoldMessengerKey: _messengerKey,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: 280,
      ),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _startupSplashVisible
          ? StartupSplash(
              key: const ValueKey('startup-splash'),
              onReady: () {
                if (!mounted || !_startupSplashVisible) return;
                setState(() {
                  _startupSplashVisible = false;
                });
                // Esperar el fundido antes de abrir el diálogo del sistema.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _splashExitTimer = Timer(const Duration(milliseconds: 280), () {
                    if (!_splashFinished.isCompleted) _splashFinished.complete();
                  });
                });
              },
            )
          : _checkingSession
          ? const _AccessLoadingPage(key: ValueKey('access-loading'))
          : _currentUser != null
          ? AppShell(
              key: const ValueKey('app'),
              repository: widget.repository,
              user: _currentUser!,
              onLogout: _logout,
              onAccountDeleted: _handleAccountDeleted,
            )
          : !_onboardingCompleted
          ? OnboardingPage(
              key: const ValueKey('onboarding'),
              onComplete: _completeOnboarding,
            )
          : LoginPage(
              key: const ValueKey('login'),
              onAuthenticated: _handleAuthenticated,
            ),
    );
  }
}


/// Estado estático después del GIF, mientras se verifica la identidad/sesión.
class _AccessLoadingPage extends StatelessWidget {
  const _AccessLoadingPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFFFCFCFC),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 36, color: Color(0xFF01315C)),
                SizedBox(height: 16),
                Text('Verificando tu acceso…',
                    style: TextStyle(color: Color(0xFF01315C), fontSize: 16)),
                SizedBox(height: 20),
                SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      );
}
