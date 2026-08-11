import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';

class RewardDetailPage extends StatelessWidget {
  const RewardDetailPage({
    super.key,
    required this.repository,
    required this.reward,
    required this.availablePoints,
    required this.onShowQr,
  });

  // Se conserva para mantener la misma firma general de la pantalla.
  // El canje ya no se ejecuta desde la app del cliente.
  final RutaGenRepository repository;
  final Reward reward;
  final int availablePoints;
  final VoidCallback onShowQr;

  String _points(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  void _openQr(BuildContext context) {
    Navigator.of(context).pop();
    onShowQr();
  }

  @override
  Widget build(BuildContext context) {
    final canRedeem =
        availablePoints >= reward.points && reward.stock > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle del premio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Container(
            height: 260,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF4F7FA), Color(0xFFE2ECF7)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: reward.imageUrl != null && reward.imageUrl!.isNotEmpty
                ? Image.network(
                    reward.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      reward.icon,
                      size: 130,
                      color: AppColors.navy,
                    ),
                  )
                : Icon(
                    reward.icon,
                    size: 130,
                    color: AppColors.navy,
                  ),
          ),
          const SizedBox(height: 22),
          Text(
            reward.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          if (reward.subtitle.isNotEmpty)
            Text(
              reward.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_points(reward.points)} puntos',
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Center(
            child: Text(
              reward.stock > 0 ? '✓ Stock disponible' : 'Sin stock disponible',
              style: TextStyle(
                color: reward.stock > 0
                    ? AppColors.success
                    : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFFF0F7FF),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.star_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tenés',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        Text(
                          '${_points(availablePoints)} puntos',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: canRedeem ? () => _openQr(context) : null,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Mostrar mi QR para canjear'),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.muted,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'El playero verificará el premio y confirmará la entrega.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
