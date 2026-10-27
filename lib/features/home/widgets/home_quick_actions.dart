import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'home_hero.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onQr,
    required this.onRewards,
    required this.onMovements,
  });

  final VoidCallback onQr;
  final VoidCallback onRewards;
  final VoidCallback onMovements;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.qr_code_2_rounded,
        label: 'Mi QR',
        onTap: onQr,
      ),
      _QuickAction(
        icon: Icons.card_giftcard_rounded,
        label: 'Premios',
        onTap: onRewards,
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'Movimientos',
        onTap: onMovements,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(13) > 18;
        if (constraints.maxWidth < 300 || largeText) {
          return Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                actions[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: actions[i]),
            ],
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .97 : 1,
      duration: reduceHomeMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      child: Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: const Color(0x240C4778),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: AppColors.blue, size: 27),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.ink,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the action below the title when accessibility text needs more room.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(
    this.title, {
    super.key,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final titleWidget = Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: -.5,
            ),
          );
          final button = TextButton(
            onPressed: onTap,
            child: Text(action),
          );
          if (MediaQuery.textScalerOf(context).scale(21) > 28 ||
              constraints.maxWidth < 320) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleWidget, button],
            );
          }
          return Row(
            children: [Expanded(child: titleWidget), button],
          );
        },
      );
}
