import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../core/theme/app_theme.dart';
import '../home/widgets/route_backdrop.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../../models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onAuthenticated,
  });

  final ValueChanged<UserModel> onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final results = await Future.wait([
      AuthService.instance.isBiometricAvailable(),
      AuthService.instance.isBiometricEnabled(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricAvailable = results[0];
      _biometricEnabled = results[1];
    });
  }

  Future<void> _login() async {
    if (_loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    final identifier = _userController.text.trim();
    final password = _passwordController.text;

    try {
      final user = await AuthService.instance.login(
        identifier: identifier,
        password: password,
      );

      if (!mounted) {
        return;
      }

      try {
        final alreadyEnabled = await AuthService.instance.isBiometricEnabled();

        if (!alreadyEnabled) {
          await _offerBiometricSetup(
            identifier: identifier,
            password: password,
          );
        }
      } catch (_) {
        // La biometría es opcional.
        // El login ya fue completado.
      }

      if (!mounted) {
        return;
      }

      widget.onAuthenticated(user);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Ocurrió un error inesperado. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _offerBiometricSetup({
    required String identifier,
    required String password,
  }) async {
    final available = await AuthService.instance.isBiometricAvailable();

    if (!mounted) {
      return;
    }

    if (!available) {
      _showMessage(
        'Iniciaste sesión correctamente. Para activar la biometría, primero configurá una huella o rostro en el dispositivo.',
      );

      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.fingerprint_rounded,
            size: 42,
            color: AppColors.blue,
          ),
          title: const Text(
            'Activar ingreso biométrico',
          ),
          content: const Text(
            '¿Querés guardar tus credenciales de forma segura para ingresar automáticamente con huella o Face ID la próxima vez?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Ahora no'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(
                Icons.fingerprint_rounded,
              ),
              label: const Text('Activar'),
            ),
          ],
        );
      },
    );

    if (accepted != true || !mounted) {
      return;
    }

    try {
      await AuthService.instance.enableBiometrics(
        identifier: identifier,
        password: password,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _biometricAvailable = true;
        _biometricEnabled = true;
      });

      _showMessage(
        'Ingreso biométrico activado correctamente.',
      );
    } on BiometricException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No se pudo activar el ingreso biométrico.',
      );
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (_loading) {
      return;
    }

    final enabled = await AuthService.instance.isBiometricEnabled();

    if (!mounted) {
      return;
    }

    if (!enabled) {
      _showMessage(
        'El ingreso biométrico todavía no está activado. Ingresá con tu DNI o correo y contraseña para activarlo.',
      );

      return;
    }

    setState(() => _loading = true);

    try {
      final user = await AuthService.instance.loginWithBiometrics();

      if (!mounted) {
        return;
      }

      widget.onAuthenticated(user);
    } on BiometricException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);

      await _loadBiometricState();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No se pudo iniciar sesión con biometría. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openForgotPassword() async {
    if (_loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(
          initialIdentifier: _userController.text.trim(),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    /*
     * La recuperación puede haber deshabilitado
     * la biometría porque la contraseña guardada
     * quedó obsoleta.
     */
    await _loadBiometricState();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkBackgroundOverlay,
      child: Scaffold(
        backgroundColor: const Color(0xFF032A46),
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: AppColors.ice,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x10063D73),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _userController,
                                      enabled: !_loading,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                        AutofillHints.email,
                                      ],
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                        ),
                                        labelText: 'DNI o correo',
                                        fillColor: AppColors.ice,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Ingresá tu DNI o correo.';
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passwordController,
                                      enabled: !_loading,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) {
                                        if (!_loading) {
                                          _login();
                                        }
                                      },
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                        labelText: 'Contraseña',
                                        fillColor: AppColors.ice,
                                        suffixIcon: IconButton(
                                          onPressed: _loading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          tooltip: _obscurePassword
                                              ? 'Mostrar contraseña'
                                              : 'Ocultar contraseña',
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Ingresá tu contraseña.';
                                        }

                                        return null;
                                      },
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _loading
                                            ? null
                                            : _openForgotPassword,
                                        child: const Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            color: AppColors.blue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FilledButton(
                                      onPressed: _loading ? null : _login,
                                      child: _loading
                                          ? const SizedBox.square(
                                              dimension: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Ingresar'),
                                    ),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => RegisterPage(
                                                    onRegistered:
                                                        widget.onAuthenticated,
                                                  ),
                                                ),
                                              );
                                            },
                                      child: const Text(
                                        'Crear cuenta',
                                        style: TextStyle(
                                          color: AppColors.blue,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Text(
                                            'o',
                                            style: TextStyle(
                                                color: AppColors.muted),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    OutlinedButton.icon(
                                      onPressed: _loading
                                          ? null
                                          : _loginWithBiometrics,
                                      icon: const Icon(
                                        Icons.fingerprint_rounded,
                                      ),
                                      label: Text(
                                        _biometricEnabled
                                            ? 'Ingresar con biometría'
                                            : _biometricAvailable
                                                ? 'Activar biometría al ingresar'
                                                : 'Ingresar con biometría',
                                        textAlign: TextAlign.center,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(54),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        foregroundColor: AppColors.blue,
                                        side: const BorderSide(
                                          color: AppColors.blue,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: Stack(
        children: [
          const Positioned.fill(child: RouteBackdrop()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Same original image and crop as HomeHero.
                    ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        widthFactor: .72,
                        heightFactor: .58,
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 104,
                          height: 104,
                          cacheWidth: 360,
                          semanticLabel: 'Ruta GEN',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bienvenido a Ruta GEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD129),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cada carga, más beneficios.',
                      style: TextStyle(
                        color: Color(0xFFE0EBF8),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
