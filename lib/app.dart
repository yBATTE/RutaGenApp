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
import 'shared/widgets/ruta_gen_logo.dart';

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
    _authenticateOnStartup();
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

  Future<void> _authenticateOnStartup() async {
    await _authenticateWithBiometrics(
      showErrors: false,
    );
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
        value: _checkingSession || _currentUser == null
            ? AppTheme.darkBackgroundOverlay
            : AppTheme.lightBackgroundOverlay,
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navyDeep,
              AppColors.navy,
              Color(
                0xFF00356C,
              ),
            ],
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RutaGenLogo(),
              SizedBox(
                height: 32,
              ),
              CircularProgressIndicator(
                color: AppColors.cyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
