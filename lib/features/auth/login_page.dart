import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../shared/widgets/ruta_gen_logo.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onAuthenticated,
  });

  final VoidCallback onAuthenticated;

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _userController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

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
      AuthService.instance
          .isBiometricAvailable(),
      AuthService.instance
          .isBiometricEnabled(),
    ]);

    if (!mounted) return;

    setState(() {
      _biometricAvailable = results[0];
      _biometricEnabled = results[1];
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    final identifier =
        _userController.text.trim();

    final password =
        _passwordController.text;

    try {
      await AuthService.instance.login(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      final alreadyEnabled =
          await AuthService.instance
              .isBiometricEnabled();

      if (!alreadyEnabled) {
        await _offerBiometricSetup(
          identifier: identifier,
          password: password,
        );
      }

      if (!mounted) return;

      widget.onAuthenticated();
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

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
    final available = await AuthService
        .instance
        .isBiometricAvailable();

    if (!mounted) return;

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
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Ahora no'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
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
      await AuthService.instance
          .enableBiometrics(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _biometricAvailable = true;
        _biometricEnabled = true;
      });

      _showMessage(
        'Ingreso biométrico activado correctamente.',
      );
    } on BiometricException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'No se pudo activar el ingreso biométrico.',
      );
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (_loading) return;

    final enabled = await AuthService
        .instance
        .isBiometricEnabled();

    if (!mounted) return;

    if (!enabled) {
      _showMessage(
        'El ingreso biométrico todavía no está activado. Ingresá con tu DNI o correo y contraseña para activarlo.',
      );

      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.instance
          .loginWithBiometrics();

      if (!mounted) return;

      widget.onAuthenticated();
    } on BiometricException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);

      await _loadBiometricState();
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'No se pudo iniciar sesión con biometría. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navyDeep,
              AppColors.navy,
              Color(0xFF00356C),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              26,
              40,
              26,
              24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context)
                            .height -
                        88,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const RutaGenLogo(),
                    const SizedBox(height: 50),
                    const Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          text: 'Bienvenido a ',
                          children: [
                            TextSpan(
                              text: 'Ruta Gen',
                              style: TextStyle(
                                color:
                                    AppColors.cyan,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller:
                          _userController,
                      enabled: !_loading,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration:
                          const InputDecoration(
                        prefixIcon: Icon(
                          Icons
                              .person_outline_rounded,
                        ),
                        hintText:
                            'DNI o correo',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
                          return 'Ingresá tu DNI o correo.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller:
                          _passwordController,
                      enabled: !_loading,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) {
                        if (!_loading) {
                          _login();
                        }
                      },
                      decoration:
                          InputDecoration(
                        prefixIcon: const Icon(
                          Icons
                              .lock_outline_rounded,
                        ),
                        hintText: 'Contraseña',
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
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Ingresá tu contraseña.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed:
                          _loading ? null : _login,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 22,
                              child:
                                  CircularProgressIndicator(
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
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RegisterPage(
                                    onRegistered:
                                        widget
                                            .onAuthenticated,
                                  ),
                                ),
                              );
                            },
                      child: const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          color: AppColors.cyan,
                          decoration:
                              TextDecoration
                                  .underline,
                          decorationColor:
                              AppColors.cyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white
                                .withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          child: Text(
                            'o',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white
                                .withValues(
                              alpha: 0.35,
                            ),
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
                        Icons
                            .fingerprint_rounded,
                      ),
                      label: Text(
                        _biometricEnabled
                            ? 'Ingresar con biometría'
                            : _biometricAvailable
                                ? 'Activar biometría al ingresar'
                                : 'Ingresar con biometría',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(
                          54,
                        ),
                        foregroundColor:
                            AppColors.cyan,
                        side: const BorderSide(
                          color: AppColors.blue,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
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
      ),
    );
  }
}