import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/ruta_gen_logo.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    this.initialIdentifier = '',
  });

  final String initialIdentifier;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  late final TextEditingController _identifierController;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  int _step = 1;

  bool _loading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String _identifierUsed = '';

  @override
  void initState() {
    super.initState();

    _identifierController = TextEditingController(
      text: widget.initialIdentifier,
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  /* ============================================================
     PASO 1 - ENVIAR CÓDIGO
  ============================================================ */

  Future<void> _sendCode() async {
    if (_loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_identifierFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final identifier = _identifierController.text.trim();

    try {
      await AuthService.instance.forgotPassword(
        identifier: identifier,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _identifierUsed = identifier;
        _step = 2;
      });

      _showMessage(
        'Si la cuenta existe, enviamos un código al correo registrado.',
      );
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
        'No se pudo solicitar el código. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /* ============================================================
     REENVIAR CÓDIGO
  ============================================================ */

  Future<void> _resendCode() async {
    if (_loading || _identifierUsed.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.instance.forgotPassword(
        identifier: _identifierUsed,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Si la cuenta existe, enviamos un nuevo código al correo registrado.',
      );
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
        'No se pudo reenviar el código. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /* ============================================================
     PASO 2/3 - CAMBIAR CONTRASEÑA
  ============================================================ */

  Future<void> _resetPassword() async {
    if (_loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_resetFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.instance.resetPassword(
        identifier: _identifierUsed,
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _step = 3;
      });
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
        'No se pudo cambiar la contraseña. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /* ============================================================
     MENSAJES
  ============================================================ */

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

  /* ============================================================
     VOLVER
  ============================================================ */

  Future<bool> _handleBack() async {
    if (_loading) {
      return false;
    }

    if (_step == 2) {
      setState(() {
        _step = 1;
      });

      return false;
    }

    return true;
  }

  /* ============================================================
     BUILD
  ============================================================ */

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading && _step != 2,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (didPop) {
          return;
        }

        if (_step == 2 && !_loading) {
          setState(() {
            _step = 1;
          });
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
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
              padding: const EdgeInsets.fromLTRB(
                26,
                22,
                26,
                28,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final canLeave = await _handleBack();

                                if (!mounted) {
                                  return;
                                }

                                if (canLeave) {
                                  navigator.pop();
                                }
                              },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const RutaGenLogo(),
                      const Spacer(),
                      const SizedBox(
                        width: 48,
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    child: switch (_step) {
                      1 => _buildIdentifierStep(),
                      2 => _buildResetStep(),
                      _ => _buildSuccessStep(),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ============================================================
     PASO 1
  ============================================================ */

  Widget _buildIdentifierStep() {
    return Form(
      key: _identifierFormKey,
      child: Column(
        key: const ValueKey(
          'forgot-identifier',
        ),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 62,
            color: AppColors.cyan,
          ),
          const SizedBox(height: 22),
          const Text(
            'Recuperar contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ingresá tu DNI o correo. Vamos a enviar un código de 6 dígitos al email registrado en tu cuenta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.78,
              ),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _identifierController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
            ],
            onFieldSubmitted: (_) {
              if (!_loading) {
                _sendCode();
              }
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
              hintText: 'DNI o correo',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresá tu DNI o correo.';
              }

              return null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _loading ? null : _sendCode,
            child: _loading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enviar código',
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            'Por seguridad, no informamos si el DNI o correo está registrado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.58,
              ),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /* ============================================================
     PASO 2
  ============================================================ */

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey(
          'forgot-reset',
        ),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_rounded,
            size: 62,
            color: AppColors.cyan,
          ),
          const SizedBox(height: 22),
          const Text(
            'Ingresá el código',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enviamos un código de 6 dígitos al correo asociado a tu cuenta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.78,
              ),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cuenta: $_identifierUsed',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.58,
              ),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _codeController,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
            ),
            decoration: const InputDecoration(
              counterText: '',
              prefixIcon: Icon(
                Icons.pin_outlined,
              ),
              hintText: '000000',
            ),
            validator: (value) {
              final code = (value ?? '').trim();

              if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                return 'Ingresá el código de 6 dígitos.';
              }

              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _newPasswordController,
            enabled: !_loading,
            obscureText: _obscureNewPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              hintText: 'Nueva contraseña',
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              final password = value ?? '';

              if (password.isEmpty) {
                return 'Ingresá una nueva contraseña.';
              }

              if (password.length < 8) {
                return 'Debe tener al menos 8 caracteres.';
              }

              if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
                  !RegExp(r'\d').hasMatch(password)) {
                return 'Debe incluir letras y números.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_loading,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            onFieldSubmitted: (_) {
              if (!_loading) {
                _resetPassword();
              }
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.lock_reset_rounded,
              ),
              hintText: 'Repetir nueva contraseña',
              suffixIcon: IconButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Repetí la nueva contraseña.';
              }

              if (value != _newPasswordController.text) {
                return 'Las contraseñas no coinciden.';
              }

              return null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _loading ? null : _resetPassword,
            child: _loading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Cambiar contraseña',
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : _resendCode,
            child: const Text(
              'Reenviar código',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () {
                    setState(() {
                      _step = 1;
                    });
                  },
            child: const Text(
              'Cambiar DNI o correo',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ============================================================
     PASO 3
  ============================================================ */

  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey(
        'forgot-success',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 92,
          height: 92,
          margin: const EdgeInsets.symmetric(
            horizontal: 110,
          ),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(
              alpha: 0.14,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cyan,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 54,
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Contraseña actualizada',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Tu contraseña fue cambiada correctamente. Ya podés volver a iniciar sesión con tu nueva clave.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.78,
            ),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.07,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.fingerprint_rounded,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Por seguridad, si tenías el ingreso biométrico activado, vas a poder configurarlo nuevamente después de iniciar sesión con tu nueva contraseña.',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.78,
                    ),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.login_rounded,
          ),
          label: const Text(
            'Volver a iniciar sesión',
          ),
        ),
      ],
    );
  }
}
