import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class IdentityVerificationBanner extends StatelessWidget {
  const IdentityVerificationBanner({
    super.key,
    required this.onViewStations,
    this.needsDni = false,
    this.onCompleteDni,
  });

  final VoidCallback onViewStations;
  final bool needsDni;
  final VoidCallback? onCompleteDni;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFFFE2A8),
                foregroundColor: Color(0xFF8A5700),
                child: Icon(Icons.badge_outlined, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      needsDni ? 'Completá tu DNI' : 'Verificá tu identidad',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      needsDni
                          ? 'Para verificar tu identidad, primero cargá tu DNI desde la app. Después presentá el documento físico en una estación Ruta GEN.'
                          : 'Presentá tu DNI en una estación Ruta GEN para comenzar a sumar puntos, canjear premios y participar de beneficios.',
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
              onPressed: needsDni ? onCompleteDni : onViewStations,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE9BE),
                foregroundColor: const Color(0xFF6F4800),
              ),
              icon: Icon(needsDni ? Icons.badge_outlined : Icons.local_gas_station_rounded),
              label: Text(needsDni ? 'Completar mi DNI' : 'Ver estaciones para verificarme'),
            ),
          ),
        ],
      ),
    );
  }
}
