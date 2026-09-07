import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';

class VisitProgressCard extends StatelessWidget {
  const VisitProgressCard({
    super.key,
    required this.progress,
    required this.onOpenGifts,
  });

  final VisitProgress progress;
  final VoidCallback onOpenGifts;

  static const _stations = <({String slug, String label})>[
    (slug: 'combustibles-canning-1', label: 'Canning 1'),
    (slug: 'combustibles-canning-2', label: 'Canning 2'),
    (slug: 'catania', label: 'Catania'),
  ];

  bool _visited(String slug) {
    return progress.visitedStations.any((station) => station.slug == slug);
  }

  @override
  Widget build(BuildContext context) {
    if (!progress.enabled) return const SizedBox.shrink();

    final breakfastName =
        progress.secondStationRewardName?.trim().isNotEmpty == true
            ? progress.secondStationRewardName!.trim()
            : 'Desayuno';
    final mealName = progress.thirdStationRewardName?.trim().isNotEmpty == true
        ? progress.thirdStationRewardName!.trim()
        : 'Almuerzo / cena';

    String message;
    if (progress.mealUnlocked) {
      message = '¡Completaste las 3 estaciones y desbloqueaste $mealName!';
    } else if (progress.breakfastUnlocked) {
      message = progress.remainingForMeal == 1
          ? 'Ganaste $breakfastName. Te falta 1 estación para desbloquear $mealName.'
          : 'Ganaste $breakfastName.';
    } else if (progress.stationCount == 1) {
      message = 'Visitá 1 estación distinta más para desbloquear $breakfastName.';
    } else {
      message = 'Visitá estaciones Ruta GEN distintas y desbloqueá beneficios este mes.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EBF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu Ruta GEN este mes',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${progress.stationCount}/3 estaciones distintas',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ..._stations.map((station) {
            final visited = _visited(station.slug);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    visited
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: visited ? AppColors.success : const Color(0xFFB8C2CE),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    station.label,
                    style: TextStyle(
                      color: visited ? AppColors.ink : AppColors.muted,
                      fontWeight: visited ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  progress.breakfastUnlocked
                      ? Icons.card_giftcard_rounded
                      : Icons.info_outline_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (progress.breakfastUnlocked || progress.mealUnlocked) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onOpenGifts,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Ver mis premios'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
