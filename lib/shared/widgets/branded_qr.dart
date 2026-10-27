import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Presentación compartida. El token se codifica sin modificarlo.
class BrandedQr extends StatelessWidget {
  const BrandedQr({
    super.key,
    required this.data,
    this.size = 220,
    this.moduleColor = AppColors.navy,
  });

  final String data;
  final double size;
  final Color moduleColor;

  @override
  Widget build(BuildContext context) {
    final validation = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );
    final qr = validation.qrCode;
    if (qr == null) {
      return SizedBox.square(
        dimension: size,
        child: const Center(
          child: Text(
            'No pudimos mostrar el QR. Volvé a generarlo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Margen blanco exterior de cuatro módulos, según la densidad del QR.
    final moduleSize = size / (qr.moduleCount + 8);
    final quietZone = moduleSize * 4;
    // El fondo del logo ocupa el 20% del lado útil (4% de su superficie).
    final badgeSize = (size - quietZone * 2) * 0.20;

    return Semantics(
      label: 'Código QR de Ruta GEN',
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView.withQr(
              qr: qr,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              size: size,
              padding: EdgeInsets.all(quietZone),
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.navy,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: moduleColor,
              ),
            ),
            IgnorePointer(
              child: Container(
                width: badgeSize,
                height: badgeSize,
                padding: EdgeInsets.all(badgeSize * 0.10),
                color: Colors.white,
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
