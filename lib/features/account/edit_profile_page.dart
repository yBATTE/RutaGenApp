import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _phoneController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _phoneController = TextEditingController(
      text: widget.user.phone ?? '',
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final updatedUser = await AuthService.instance.updatePhone(
        _phoneController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Tus datos se actualizaron correctamente.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.of(context).pop(
        updatedUser,
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'No se pudieron actualizar tus datos. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    /*
     * El teléfono es opcional.
     * Si se deja vacío se elimina.
     */
    if (phone.isEmpty) {
      return null;
    }

    if (phone.length < 6 || phone.length > 25) {
      return 'Ingresá un teléfono válido.';
    }

    if (!RegExp(
      r'^[0-9+()\-\s]+$',
    ).hasMatch(phone)) {
      return 'El teléfono contiene caracteres no válidos.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mis datos',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              32,
            ),
            children: [
              const _InformationBanner(),
              const SizedBox(height: 20),
              const Text(
                'Información de la cuenta',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _ReadOnlyField(
                icon: Icons.person_outline_rounded,
                label: 'Nombre y apellido',
                value: widget.user.fullName,
              ),
              const SizedBox(height: 12),
              _ReadOnlyField(
                icon: Icons.badge_outlined,
                label: 'DNI',
                value: widget.user.dni,
              ),
              const SizedBox(height: 12),
              _ReadOnlyField(
                icon: Icons.email_outlined,
                label: 'Correo electrónico',
                value: widget.user.email,
              ),
              const SizedBox(height: 22),
              const Text(
                'Datos de contacto',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [
                  AutofillHints.telephoneNumber,
                ],
                validator: _validatePhone,
                onFieldSubmitted: (_) {
                  if (!_saving) {
                    _save();
                  }
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                  ),
                  labelText: 'Número de teléfono',
                  hintText: '+54 9 11 1234-5678',
                  helperText:
                      'Podés dejarlo vacío si no querés registrar un teléfono.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                      ),
                label: Text(
                  _saving ? 'Guardando...' : 'Guardar cambios',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationBanner extends StatelessWidget {
  const _InformationBanner();

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
            Icons.info_outline_rounded,
            color: AppColors.blue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Por seguridad, el DNI y el correo electrónico no pueden modificarse desde la aplicación.',
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

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE3EC),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.navy,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}
