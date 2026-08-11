import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RutaGenLogo extends StatelessWidget {
  const RutaGenLogo({super.key, this.compact = false, this.light = true});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? Colors.white : AppColors.navy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text('R', style: TextStyle(color: foreground, fontSize: compact ? 34 : 64, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: .8)),
                Transform.rotate(
                  angle: -.17,
                  child: Container(
                    width: compact ? 4 : 6,
                    height: compact ? 30 : 52,
                    decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            Text('G', style: TextStyle(color: AppColors.cyan, fontSize: compact ? 32 : 58, fontWeight: FontWeight.w900, height: .85)),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text('Ruta Gen', style: TextStyle(color: foreground, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
          Text('de Grupo GEN', style: TextStyle(color: foreground.withValues(alpha: .82), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}
