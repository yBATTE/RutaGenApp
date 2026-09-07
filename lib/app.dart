import 'dart:async';

import 'package:flutter/material.dart';

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
  const RutaGenApp({super.key, required this.repository});

  final RutaGenRepository repository;

  @override
  State<RutaGenApp> createState() => _RutaGenAppState();
}

class _RutaGenAppState extends State<RutaGenApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  UserModel? _currentUser;

  bool _checkingSession = true;
  bool _biometricFlowRunning = false;
  bool _requiresUnlockOnResume = false;
  StreamSubscription<PushMessage>? _pushSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _pushSubscription = PushNotificationService.instance.foregroundMessages
        .listen(_showForegroundNotification);

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

    /*
     * Cuando Ruta Gen pasa a segundo plano ocultamos
     * inmediatamente la información del usuario.
     */
    if (state == AppLifecycleState.paused &&
        _currentUser != null &&
        !_biometricFlowRunning) {
      _requiresUnlockOnResume = true;

      if (mounted) {
        setState(() {
          _checkingSession = true;
        });
      }

      return;
    }

    /*
     * Cuando vuelve al primer plano se solicita
     * automáticamente la biometría.
     */
    if (state == AppLifecycleState.resumed &&
        _requiresUnlockOnResume &&
        !_biometricFlowRunning) {
      _requiresUnlockOnResume = false;

      _authenticateWithBiometrics(showErrors: true);
    }
  }

  /* ============================================================
     INICIO DE LA APP
  ============================================================ */

  Future<void> _authenticateOnStartup() async {
    await _authenticateWithBiometrics(showErrors: false);
  }

  /* ============================================================
     AUTENTICACIÓN BIOMÉTRICA AUTOMÁTICA
  ============================================================ */

  Future<void> _authenticateWithBiometrics({required bool showErrors}) async {
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

      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _checkingSession = false;
      });

      if (user != null) unawaited(_bindPushAfterAuthentication());
    } on BiometricException catch (error) {
      if (!mounted) return;

      setState(() {
        _currentUser = null;
        _checkingSession = false;
      });

      if (showErrors) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (!mounted) return;

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

  void _handleAuthenticated(UserModel user) {
    if (!mounted) return;
    _requiresUnlockOnResume = false;
    // Login ya validó al cliente y guardó el token. Evitamos otro /auth/me
    // que podría fallar por red y devolver al login después de un alta exitosa.
    setState(() {
      _currentUser = user;
      _checkingSession = false;
    });
    unawaited(_bindPushAfterAuthentication());
  }

  Future<void> _bindPushAfterAuthentication() async {
    try {
      await PushNotificationService.instance.bindToCurrentUser();
    } catch (_) {
      // Un fallo al registrar notificaciones no debe bloquear el inicio.
    }
  }

  /* ============================================================
     CERRAR SESIÓN

     Conserva las credenciales biométricas.
     No vuelve a abrir automáticamente la huella
     hasta que se reinicie o reabra la app.
  ============================================================ */

  Future<void> _logout() async {
    await PushNotificationService.instance.unregisterCurrentDevice();
    await AuthService.instance.logout();

    if (!mounted) return;

    _requiresUnlockOnResume = false;

    setState(() {
      _currentUser = null;
      _checkingSession = false;
    });
  }

  void _showMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    });
  }

  void _showForegroundNotification(PushMessage notification) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${notification.title}\n${notification.body}'),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruta Gen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: _messengerKey,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_checkingSession) {
      return const _SessionLoadingPage();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _currentUser != null
          ? AppShell(
              key: const ValueKey('app'),
              repository: widget.repository,
              user: _currentUser!,
              onLogout: _logout,
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navyDeep, AppColors.navy, Color(0xFF00356C)],
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RutaGenLogo(),
              SizedBox(height: 32),
              CircularProgressIndicator(color: AppColors.cyan),
            ],
          ),
        ),
      ),
    );
  }
}
