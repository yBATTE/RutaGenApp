import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/ruta_gen_logo.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onRegistered,
  });

  final VoidCallback onRegistered;

  @override
  State<RegisterPage> createState() =>
      _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  int _step = 0;
  bool _accepted = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      setState(() => _step = 1);

      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );

      return;
    }

    if (!_accepted) {
      _showMessage(
        'Debés aceptar los términos y condiciones.',
      );
      return;
    }

    await _register();
  }

  Future<void> _register() async {
    setState(() => _loading = true);

    try {
await AuthService.instance.register(
  firstName: _firstNameController.text.trim(),
  lastName: _lastNameController.text.trim(),
  dni: _dniController.text.trim(),
  email: _emailController.text.trim(),
  password: _passwordController.text,
  acceptedTerms: _accepted,
);

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onRegistered();
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

  Future<void> _goBackStep() async {
    if (_step == 0 || _loading) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _step = 0);

    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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
    final canSubmit =
        !_loading && (_step == 0 || _accepted);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _loading ? null : _goBackStep,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const RutaGenLogo(compact: true),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9FBFE),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  18,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Paso ${_step + 1} de 2',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (_step + 1) / 2,
                      minHeight: 5,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  children: [
                    ListView(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      children: [
                        _RegisterField(
                          controller:
                              _firstNameController,
                          icon: Icons.person_outline,
                          hint: 'Nombre',
                          enabled: !_loading,
                          textInputAction:
                              TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Ingresá tu nombre.';
                            }

                            return null;
                          },
                        ),
                        _RegisterField(
                          controller:
                              _lastNameController,
                          icon: Icons.person_outline,
                          hint: 'Apellido',
                          enabled: !_loading,
                          textInputAction:
                              TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Ingresá tu apellido.';
                            }

                            return null;
                          },
                        ),
                        _RegisterField(
                          controller: _dniController,
                          icon: Icons.badge_outlined,
                          hint: 'DNI',
                          enabled: !_loading,
                          keyboardType:
                              TextInputType.number,
                          textInputAction:
                              TextInputAction.next,
                          validator: (value) {
                            final dni =
                                value?.trim() ?? '';

                            if (dni.isEmpty) {
                              return 'Ingresá tu DNI.';
                            }

                            if (!RegExp(r'^\d+$')
                                .hasMatch(dni)) {
                              return 'El DNI debe contener solamente números.';
                            }

                            return null;
                          },
                        ),
                        _RegisterField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hint: 'Correo electrónico',
                          enabled: !_loading,
                          keyboardType:
                              TextInputType.emailAddress,
                          textInputAction:
                              TextInputAction.next,
                          validator: (value) {
                            final email =
                                value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Ingresá tu correo electrónico.';
                            }

                            if (!email.contains('@') ||
                                !email.contains('.')) {
                              return 'Ingresá un correo válido.';
                            }

                            return null;
                          },
                        ),
                        _RegisterField(
                          controller:
                              _passwordController,
                          icon: Icons.lock_outline,
                          hint: 'Contraseña',
                          enabled: !_loading,
                          obscure: _obscurePassword,
                          textInputAction:
                              TextInputAction.done,
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
                          onFieldSubmitted: (_) {
                            if (!_loading) {
                              _continue();
                            }
                          },
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Ingresá una contraseña.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                    ListView(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      children: [
                        const Text(
                          'Tu estación favorita',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _StationCard(),
                        const SizedBox(height: 12),
                        _RegisterField(
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          hint: 'Teléfono (opcional)',
                          enabled: !_loading,
                          keyboardType:
                              TextInputType.phone,
                          textInputAction:
                              TextInputAction.done,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Después vas a poder activar huella o Face ID desde Seguridad y biometría.',
                          style: TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  24,
                ),
                child: Column(
                  children: [
                    if (_step == 1)
                      CheckboxListTile(
                        value: _accepted,
                        onChanged: _loading
                            ? null
                            : (value) {
                                setState(() {
                                  _accepted =
                                      value ?? false;
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity:
                            ListTileControlAffinity
                                .leading,
                        title: const Text(
                          'Acepto los términos y condiciones',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    FilledButton(
                      onPressed:
                          canSubmit ? _continue : null,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == 0
                                  ? 'Continuar'
                                  : 'Crear mi cuenta',
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.icon,
    required this.hint,
    required this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.local_gas_station_outlined,
            color: AppColors.blue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Combustibles Canning',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.blue,
          ),
        ],
      ),
    );
  }
}