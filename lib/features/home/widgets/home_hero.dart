import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'route_backdrop.dart';

const rutaYellow = Color(0xFFFFD129);

bool reduceHomeMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context);

class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.firstName,
    required this.formattedPoints,
    required this.unreadNotifications,
    required this.onOpenNotifications,
    required this.onRewardsTap,
    required this.horizontalPadding,
  });

  final String firstName;
  final String formattedPoints;
  final int unreadNotifications;
  final VoidCallback onOpenNotifications;
  final VoidCallback onRewardsTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          bottom: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            child: RouteBackdrop(),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              14,
              horizontalPadding,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Use the actual bundled brand asset, cropping only its
                    // surrounding blank space, without redrawing the logo.
                    ClipRect(
                      child: Align(
                        widthFactor: .72,
                        heightFactor: .58,
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 104,
                          height: 104,
                          cacheWidth: 360,
                          semanticLabel: 'Ruta GEN',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onOpenNotifications,
                      tooltip: unreadNotifications > 0
                          ? '$unreadNotifications notificaciones sin leer'
                          : 'Notificaciones',
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: Badge(
                        isLabelVisible: unreadNotifications > 0,
                        label: Text(unreadNotifications > 99
                            ? '99+'
                            : '$unreadNotifications'),
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hola, $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 9),
                const _YellowAccent(),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: reduceHomeMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: GenPointsCard(
                    formattedPoints: formattedPoints,
                    onRewardsTap: onRewardsTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GenPointsCard extends StatelessWidget {
  const GenPointsCard({
    super.key,
    required this.formattedPoints,
    required this.onRewardsTap,
  });

  final String formattedPoints;
  final VoidCallback onRewardsTap;

  @override
  Widget build(BuildContext context) {
    final reduced = reduceHomeMotion(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26063D73),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned.fill(child: RouteBackdrop(card: true)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF25BBFF), width: 1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                    TextSpan(
                      text: 'Tus puntos ',
                      children: [
                        TextSpan(
                          text: 'Ruta GEN',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    liveRegion: true,
                    label: '$formattedPoints puntos disponibles',
                    child: ExcludeSemantics(
                      // Only animate the current balance's appearance. Never
                      // interpolate money-like values or show a stale balance.
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(formattedPoints),
                        tween: Tween(begin: .96, end: 1),
                        duration: reduced
                            ? Duration.zero
                            : const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          alignment: Alignment.centerLeft,
                          child: child,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  formattedPoints,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'puntos',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    _YellowAccent(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: onRewardsTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.card_giftcard_outlined, size: 23),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ver premios',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YellowAccent extends StatelessWidget {
  const _YellowAccent();

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: rutaYellow,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
