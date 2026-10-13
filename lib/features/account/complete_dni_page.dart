import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

/// Completar el DNI no verifica la identidad; requiere el documento en estación.
class CompleteDniPage extends StatefulWidget {
  const CompleteDniPage({super.key});

  @override
  State<CompleteDniPage> createState() => _CompleteDniPageState();
}

class _CompleteDniPageState extends State<CompleteDniPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final dni = _controller.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmá tu DNI'),
        content: Text('Vas a guardar el DNI $dni. Revisá que sea correcto: una vez guardado, no podrás cambiarlo desde la app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Revisar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Guardar DNI')),
        ],
      ),
    );
    if (!mounted || confirmed != true || _saving) return;
    setState(() => _saving = true);
    try {
      final user = await AuthService.instance.completeDni(dni);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('DNI guardado. Ahora presentá el documento físico en la estación para verificar tu identidad.'),
      ));
      Navigator.of(context).pop(user);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar el DNI. Intentá nuevamente.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(title: const Text('Completar DNI')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const Icon(Icons.badge_outlined, size: 52, color: AppColors.blue),
                const SizedBox(height: 18),
                const Text('Prepará tu cuenta para verificarla', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
                const SizedBox(height: 10),
                const Text('Ingresá el DNI que figura en tu documento. Es necesario para verificar tu identidad presencialmente y acceder a los puntos y beneficios de Ruta GEN.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  validator: (value) => RegExp(r'^\d{7,9}$').hasMatch(value?.trim() ?? '') ? null : 'Ingresá un DNI de 7 a 9 números.',
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(labelText: 'DNI', hintText: 'Sin puntos ni espacios', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 16),
                const Text('Guardar el DNI no verifica tu cuenta. Después, presentá el documento físico en playa o tienda para que el personal confirme tu identidad.', style: TextStyle(color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando…' : 'Guardar DNI'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
