import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _passwordFormKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();

  final _newPasswordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  bool _loadingBiometrics = true;
  bool _changingPassword = false;
  bool _changingBiometrics = false;

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmation = true;

  @override
  void initState() {
    super.initState();

    _loadBiometricState();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    try {
      final results = await Future.wait([
        AuthService.instance.isBiometricAvailable(),
        AuthService.instance.isBiometricEnabled(),
      ]);

      if (!mounted) return;

      setState(() {
        _biometricAvailable = results[0];
        _biometricEnabled = results[1];
        _loadingBiometrics = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _biometricAvailable = false;
        _biometricEnabled = false;
        _loadingBiometrics = false;
      });
    }
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _changingPassword = true;
    });

    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showMessage(
        'Tu contraseña se actualizó correctamente.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'No se pudo cambiar la contraseña. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  Future<void> _toggleBiometrics(
    bool enabled,
  ) async {
    if (_changingBiometrics || _loadingBiometrics) {
      return;
    }

    if (enabled) {
      await _enableBiometrics();
      return;
    }

    await _disableBiometrics();
  }

  Future<void> _enableBiometrics() async {
    if (!_biometricAvailable) {
      _showMessage(
        'Este dispositivo no tiene una huella o rostro configurado.',
      );

      return;
    }

    final password = await _requestCurrentPassword();

    if (password == null || password.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _changingBiometrics = true;
    });

    try {
      /*
       * Verificamos la contraseña iniciando
       * sesión nuevamente.
       */
      await AuthService.instance.login(
        identifier: widget.user.dni,
        password: password,
      );

      if (!mounted) return;

      /*
       * Después de verificar la contraseña,
       * solicitamos la huella o Face ID.
       */
      await AuthService.instance.enableBiometrics(
        identifier: widget.user.dni,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _biometricEnabled = true;
      });

      _showMessage(
        'Ingreso biométrico activado correctamente.',
      );
    } on BiometricException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'No se pudo activar el ingreso biométrico.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingBiometrics = false;
        });
      }
    }
  }

  Future<void> _disableBiometrics() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.fingerprint_rounded,
            color: AppColors.blue,
            size: 42,
          ),
          title: const Text(
            'Desactivar biometría',
          ),
          content: const Text(
            'La próxima vez deberás ingresar con tu DNI o correo y contraseña.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Desactivar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _changingBiometrics = true;
    });

    try {
      await AuthService.instance.disableBiometrics();

      if (!mounted) return;

      setState(() {
        _biometricEnabled = false;
      });

      _showMessage(
        'El ingreso biométrico fue desactivado.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'No se pudo desactivar la biometría.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingBiometrics = false;
        });
      }
    }
  }

  Future<void> _testBiometrics() async {
    if (_changingBiometrics) return;

    setState(() {
      _changingBiometrics = true;
    });

    try {
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Confirmá tu identidad para comprobar la biometría.',
      );

      if (!mounted) return;

      if (authenticated) {
        _showMessage(
          'Biometría verificada correctamente.',
        );
      } else {
        _showMessage(
          'No se pudo verificar tu identidad.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _changingBiometrics = false;
        });
      }
    }
  }

  Future<String?> _requestCurrentPassword() async {
    final controller = TextEditingController();

    var obscurePassword = true;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            void submit() {
              final value = controller.text;

              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            }

            return AlertDialog(
              icon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.blue,
                size: 40,
              ),
              title: const Text(
                'Confirmá tu contraseña',
              ),
              content: TextField(
                controller: controller,
                obscureText: obscurePassword,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: submit,
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    return password;
  }

  String? _validateCurrentPassword(
    String? value,
  ) {
    if (value == null || value.isEmpty) {
      return 'Ingresá tu contraseña actual.';
    }

    return null;
  }

  String? _validateNewPassword(
    String? value,
  ) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Ingresá una contraseña nueva.';
    }

    if (password.length < 8 || password.length > 72) {
      return 'Debe tener entre 8 y 72 caracteres.';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Debe incluir letras y números.';
    }

    if (password == _currentPasswordController.text) {
      return 'Debe ser diferente de la contraseña actual.';
    }

    return null;
  }

  String? _validateConfirmation(
    String? value,
  ) {
    if (value == null || value.isEmpty) {
      return 'Repetí la contraseña nueva.';
    }

    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Seguridad y biometría',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          32,
        ),
        children: [
          const _SecurityBanner(),
          const SizedBox(height: 22),
          const Text(
            'Ingreso biométrico',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                if (_loadingBiometrics)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else
                  SwitchListTile(
                    value: _biometricEnabled,
                    onChanged: _changingBiometrics ? null : _toggleBiometrics,
                    secondary: Icon(
                      Icons.fingerprint_rounded,
                      color:
                          _biometricEnabled ? AppColors.blue : AppColors.muted,
                      size: 32,
                    ),
                    title: Text(
                      _biometricEnabled
                          ? 'Biometría activada'
                          : 'Activar biometría',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      !_biometricAvailable
                          ? 'No hay huellas o rostros configurados en este dispositivo.'
                          : _biometricEnabled
                              ? 'La app solicitará tu huella o Face ID al abrirse.'
                              : 'Ingresá automáticamente con huella o Face ID.',
                    ),
                  ),
                if (_biometricEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    enabled: !_changingBiometrics,
                    leading: const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.blue,
                    ),
                    title: const Text(
                      'Probar biometría',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                    ),
                    onTap: _testBiometrics,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cambiar contraseña',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      enabled: !_changingPassword,
                      obscureText: _obscureCurrent,
                      textInputAction: TextInputAction.next,
                      validator: _validateCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _changingPassword
                              ? null
                              : () {
                                  setState(
                                    () {
                                      _obscureCurrent = !_obscureCurrent;
                                    },
                                  );
                                },
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: _newPasswordController,
                      enabled: !_changingPassword,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      validator: _validateNewPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña nueva',
                        prefixIcon: const Icon(
                          Icons.key_outlined,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _changingPassword
                              ? null
                              : () {
                                  setState(
                                    () {
                                      _obscureNew = !_obscureNew;
                                    },
                                  );
                                },
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !_changingPassword,
                      obscureText: _obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmation,
                      onFieldSubmitted: (_) {
                        if (!_changingPassword) {
                          _changePassword();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Repetir contraseña nueva',
                        prefixIcon: const Icon(
                          Icons.key_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _changingPassword
                              ? null
                              : () {
                                  setState(
                                    () {
                                      _obscureConfirmation =
                                          !_obscureConfirmation;
                                    },
                                  );
                                },
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _changingPassword ? null : _changePassword,
                      icon: _changingPassword
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.password_rounded,
                            ),
                      label: Text(
                        _changingPassword
                            ? 'Actualizando...'
                            : 'Cambiar contraseña',
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

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.18),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_rounded,
            color: AppColors.blue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Protegé tu cuenta con una contraseña segura y el ingreso mediante huella o Face ID.',
              style: TextStyle(
                color: AppColors.navy,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
