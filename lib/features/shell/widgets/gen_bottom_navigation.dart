import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GenBottomNavigation extends StatelessWidget {
  const GenBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    (label: 'Inicio', icon: Icons.home_outlined, selected: Icons.home_rounded),
    (
      label: 'Estaciones',
      icon: Icons.local_gas_station_outlined,
      selected: Icons.local_gas_station_rounded,
    ),
    (
      label: 'Mi QR',
      icon: Icons.qr_code_2_rounded,
      selected: Icons.qr_code_2_rounded
    ),
    (
      label: 'Premios',
      icon: Icons.card_giftcard_outlined,
      selected: Icons.card_giftcard_rounded,
    ),
    (
      label: 'Sorteos',
      icon: Icons.emoji_events_outlined,
      selected: Icons.emoji_events_rounded,
    ),
    (
      label: 'Cuenta',
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return ColoredBox(
      color: AppColors.ice,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Material(
              color: Colors.white,
              elevation: 8,
              shadowColor: const Color(0x26063D73),
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(11) > 15;
                  final columns = largeText ? 3 : 6;
                  final itemWidth = constraints.maxWidth / columns;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      children: [
                        for (var index = 0;
                            index < _destinations.length;
                            index++)
                          SizedBox(
                            width: itemWidth,
                            child: Semantics(
                              selected: index == selectedIndex,
                              button: true,
                              label: _destinations[index].label,
                              onTap: () => onDestinationSelected(index),
                              child: ExcludeSemantics(
                                child: InkWell(
                                  onTap: () => onDestinationSelected(index),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 3,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedContainer(
                                          duration: reduced
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: index == selectedIndex
                                                ? const Color(0xFFE2EEFF)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            index == selectedIndex
                                                ? _destinations[index].selected
                                                : _destinations[index].icon,
                                            color: index == selectedIndex
                                                ? AppColors.blue
                                                : const Color(0xFF565B63),
                                            size: 25,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _destinations[index].label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: constraints.maxWidth < 350
                                                ? 10
                                                : 11,
                                            height: 1.2,
                                            fontWeight: index == selectedIndex
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: index == selectedIndex
                                                ? AppColors.blue
                                                : const Color(0xFF565B63),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
