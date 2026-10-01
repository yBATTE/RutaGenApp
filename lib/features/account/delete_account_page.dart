import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage(
      {super.key,
      required this.onAccountDeleted,
      this.deleteAccount,
      this.clearDeletedSession});
  final VoidCallback onAccountDeleted;
  final Future<void> Function(String password)? deleteAccount;
  final Future<void> Function()? clearDeletedSession;
  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();
  bool _confirmation = false;
  bool _busy = false;
  bool _serverDeleted = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AuthService.instance.accountDeletionInProgress = true;
  }

  @override
  void dispose() {
    AuthService.instance.accountDeletionInProgress = false;
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy) return;
    if (!_serverDeleted && _password.text.isEmpty) {
      setState(() => _error = 'Ingresá tu contraseña actual.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_serverDeleted) {
        if (widget.deleteAccount != null) {
          await widget.deleteAccount!(_password.text);
        } else {
          await AuthService.instance.deleteAccount(password: _password.text);
        }
        _serverDeleted = true;
        _password.clear();
      }
      // Un reintento tras éxito del servidor solo repite la limpieza local.
      if (widget.clearDeletedSession != null) {
        await widget.clearDeletedSession!();
      } else {
        await AuthService.instance.clearDeletedAccountSession();
        await PushNotificationService.instance.clearAfterAccountDeletion();
      }
      if (mounted) widget.onAccountDeleted();
    } catch (error) {
      debugPrint(
          'Account deletion failed (${error is ApiException ? error.statusCode : error.runtimeType}).');
      if (!mounted) return;
      setState(() {
        _error = _serverDeleted
            ? 'Tu cuenta fue eliminada. Tocá «Completar cierre de sesión» para terminar de borrar los datos de este dispositivo.'
            : error is ApiException &&
                    const [400, 401, 403, 409, 429].contains(error.statusCode)
                ? error.message
                : 'No se pudo completar la eliminación. Verificá tu conexión e intentá nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFB42318);
    return PopScope(
      canPop: !_busy && !_serverDeleted,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
            title: const Text('Eliminar cuenta'),
            automaticallyImplyLeading: !_busy && !_serverDeleted),
        body: ListView(padding: const EdgeInsets.all(22), children: [
          const Icon(Icons.delete_forever_outlined, size: 58, color: danger),
          const SizedBox(height: 20),
          Text(
              _confirmation
                  ? '¿Confirmás que querés eliminar tu cuenta?'
                  : 'Eliminar cuenta',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text(
              _confirmation
                  ? 'Esta acción es permanente. Ingresá tu contraseña actual para confirmar que sos el titular de la cuenta.'
                  : 'Si eliminás tu cuenta de Ruta GEN, perderás el acceso a tu cuenta, puntos, beneficios y premios asociados. Esta acción no se puede deshacer.',
              style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 16),
          const Text(
              'Los registros de cargas se conservarán sin tus datos personales para mantener los totales de las estaciones y evitar acreditar dos veces el mismo despacho.',
              style: TextStyle(color: Color(0xFF667085), height: 1.5)),
          if (_confirmation && !_serverDeleted) ...[
            const SizedBox(height: 24),
            TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    suffixIcon: IconButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _obscure = !_obscure),
                        tooltip: _obscure
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined)))),
          ],
          if (_error != null) ...[
            const SizedBox(height: 18),
            Semantics(
                liveRegion: true,
                child: Text(_error!, style: const TextStyle(color: danger))),
          ],
          const SizedBox(height: 28),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: danger,
                  minimumSize: const Size.fromHeight(54)),
              onPressed: _busy
                  ? null
                  : _confirmation
                      ? _delete
                      : () => setState(() {
                            _confirmation = true;
                            _error = null;
                          }),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_serverDeleted
                      ? 'Completar cierre de sesión'
                      : _confirmation
                          ? 'Eliminar definitivamente'
                          : 'Continuar')),
          if (!_serverDeleted) ...[
            const SizedBox(height: 12),
            TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        if (_confirmation) {
                          _password.clear();
                          setState(() {
                            _confirmation = false;
                            _error = null;
                          });
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(_confirmation ? 'Volver' : 'Cancelar')),
          ],
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Eliminando cuenta… Esperá a que finalice.',
                    textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}
