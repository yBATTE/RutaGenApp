import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class IdentityVerificationBanner extends StatelessWidget {
  const IdentityVerificationBanner({
    super.key,
    required this.onViewStations,
  });

  final VoidCallback onViewStations;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD58A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFFFE2A8),
                foregroundColor: Color(0xFF8A5700),
                child: Icon(Icons.badge_outlined, size: 21),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activá tu cuenta',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Presentá tu DNI en una estación Ruta GEN para comenzar a sumar puntos, canjear premios y participar de beneficios.',
                      style: TextStyle(
                        color: Color(0xFF755A2B),
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onViewStations,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE9BE),
                foregroundColor: const Color(0xFF6F4800),
              ),
              icon: const Icon(Icons.local_gas_station_rounded),
              label: const Text('Ver estaciones para verificarme'),
            ),
          ),
        ],
      ),
    );
  }
}
