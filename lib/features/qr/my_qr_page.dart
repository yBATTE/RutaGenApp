import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import '../../services/api_client.dart';

class MyQrPage extends StatefulWidget {
  const MyQrPage({
    super.key,
    required this.repository,
    required this.isActive,
    required this.onSessionExpired,
  });

  final RutaGenRepository repository;
  final bool isActive;
  final VoidCallback onSessionExpired;

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  late final Future<Customer> _customer = widget.repository.getCustomer();

  TemporaryQr? _qr;
  DateTime? _localExpiresAt;
  String? _errorMessage;
  bool _loading = false;
  bool _requestInProgress = false;
  bool _loggingOut = false;
  Timer? _countdownTimer;
  Timer? _statusTimer;

  TemporaryQrRepository? get _qrRepository {
    final repository = widget.repository;

    if (repository is! TemporaryQrRepository) {
      return null;
    }

    return repository as TemporaryQrRepository;
  }

  int get _remainingSeconds {
    final expiresAt = _localExpiresAt;
    if (expiresAt == null) return 0;

    final milliseconds = expiresAt.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / 1000).ceil();
  }

  String get _countdownText {
    final seconds = _remainingSeconds;
    final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsPart = (seconds % 60).toString().padLeft(2, '0');
    return '$minutesPart:$secondsPart';
  }

  @override
  void initState() {
    super.initState();
    _startTimers();

    if (widget.isActive) {
      _loadCurrentQr(showLoading: true);
    }
  }

  @override
  void didUpdateWidget(covariant MyQrPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Cada vez que el usuario vuelve a abrir la pestaña consultamos MongoDB.
    // El backend devuelve el mismo QR vigente o reemplaza el vencido.
    if (widget.isActive && !oldWidget.isActive) {
      _loadCurrentQr(showLoading: _qr == null);
    }
  }

  void _startTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !widget.isActive) return;

      setState(() {});
    });

    // GET /qr/current es idempotente: devuelve el mismo QR si sigue activo y
    // uno nuevo si el anterior fue consumido por una carga o un canje.
    _statusTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted ||
          !widget.isActive ||
          _qr == null ||
          _remainingSeconds == 0) {
        return;
      }
      _loadCurrentQr(showLoading: false);
    });
  }

  Future<void> _loadCurrentQr({required bool showLoading}) {
    return _loadQr(renew: false, showLoading: showLoading);
  }

  Future<void> _renewQr() {
    return _loadQr(renew: true, showLoading: true);
  }

  Future<void> _loadQr({
    required bool renew,
    required bool showLoading,
  }) async {
    if (_requestInProgress) return;

    final wasCheckingActiveQr = !renew && _qr != null;

    final repository = _qrRepository;
    if (repository == null) {
      setState(() {
        _errorMessage = 'La versión actual del repositorio no admite QR temporal.';
      });
      return;
    }

    _requestInProgress = true;

    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = renew
          ? await repository.renewQr()
          : await repository.getCurrentQr();

      if (!mounted) return;

      // Si el QR visible venció mientras se consultaba su estado, no mostramos
      // otro automáticamente. El usuario deberá generarlo con el botón.
      if (wasCheckingActiveQr && _remainingSeconds == 0) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final safeSeconds = result.expiresInSeconds > 0
          ? result.expiresInSeconds
          : result.expiresAt.difference(DateTime.now()).inSeconds;

      setState(() {
        _qr = result;
        _localExpiresAt = DateTime.now().add(
          Duration(seconds: safeSeconds < 0 ? 0 : safeSeconds),
        );
        _errorMessage = null;
        _loading = false;
      });

      if (renew) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generamos un QR nuevo. El anterior ya no es válido.'),
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.isUnauthorized) {
        _expireSession();
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No se pudo obtener el código QR. Intentá nuevamente.';
        _loading = false;
      });
    } finally {
      _requestInProgress = false;
    }
  }

  void _expireSession() {
    if (_loggingOut) return;
    _loggingOut = true;
    widget.onSessionExpired();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qr = _qr;
    final expired = qr != null && _remainingSeconds == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi QR',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          if (_qr != null && _remainingSeconds == 0) {
            return Future<void>.value();
          }
          return _loadCurrentQr(showLoading: false);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildQrContent(qr, expired),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Mostralo al playero',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Sirve para sumar puntos o confirmar el canje de un premio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    if (qr != null && !expired) ...[
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _renewQr,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Generar otro QR'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FutureBuilder<Customer>(
              future: _customer,
              builder: (context, snapshot) {
                final customer = snapshot.data;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      child: Text(
                        customer?.initials ?? 'RG',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(
                      customer == null
                          ? 'Cargando...'
                          : '${customer.firstName} ${customer.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('Socio ${customer?.memberCode ?? ''}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrContent(TemporaryQr? qr, bool expired) {
    if (_loading && qr == null) {
      return const SizedBox.square(
        key: ValueKey('loading'),
        dimension: 235,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && qr == null) {
      return SizedBox(
        key: const ValueKey('error'),
        height: 235,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _loadCurrentQr(showLoading: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (qr == null) {
      return SizedBox(
        key: const ValueKey('empty'),
        height: 235,
        child: Center(
          child: FilledButton.icon(
            onPressed: () => _loadCurrentQr(showLoading: true),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Generar mi QR'),
          ),
        ),
      );
    }

    if (expired) {
      return SizedBox(
        key: const ValueKey('expired'),
        height: 285,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_off_rounded,
                size: 48,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'QR vencido',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este código ya no es válido.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _loading ? null : _renewQr,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.3,
                        ),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: Text(
                  _loading ? 'Generando...' : 'Generar nuevo QR',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      key: ValueKey(qr.qrToken),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.blue, width: 3),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: qr.qrToken,
              size: 220,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.navy,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                color: AppColors.navy,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 19,
                color: AppColors.blue,
              ),
              const SizedBox(width: 7),
              Text(
                'Vence en $_countdownText',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
