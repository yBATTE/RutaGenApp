/// The backend resolves schedules in Argentina and returns the active factor.
/// This model describes that response; balances always come from the server.
class PointsPromotion {
  const PointsPromotion({
    required this.multiplier,
    required this.minimumFuelLiters,
    this.promotionName,
  });

  final double multiplier;
  final double minimumFuelLiters;
  final String? promotionName;

  bool get shouldDisplay => multiplier != 1;
  bool get isBonus => multiplier > 1;

  String get multiplierLabel => '${formatNumber(multiplier)}×';

  String get headline {
    if (multiplier == 2) return '¡Sumá el doble de puntos!';
    if (multiplier == 3) return '¡Sumá el triple de puntos!';
    if (isBonus) {
      final percentage = double.parse(
        ((multiplier - 1) * 100).toStringAsFixed(6),
      );
      return '¡Sumá ${formatNumber(percentage)}% más puntos!';
    }
    return 'Multiplicador de puntos vigente';
  }

  String get equivalence =>
      'Cada litro suma ${formatNumber(multiplier)} puntos.';

  String get conditions => minimumFuelLiters > 0
      ? 'En cargas desde ${formatNumber(minimumFuelLiters)} L. '
          'Los puntos se redondean al entero más cercano.'
      : 'Los puntos se redondean al entero más cercano.';

  static String formatNumber(double value) {
    final text = value.toString().replaceFirst(RegExp(r'\.0$'), '');
    return text.replaceAll('.', ',');
  }

  factory PointsPromotion.fromJson(Map<String, dynamic> json) {
    double readNumber(String key) {
      final raw = json[key];
      final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (value == null || !value.isFinite) {
        throw FormatException('Configuración de puntos inválida: $key');
      }
      return value;
    }

    final multiplier = readNumber('multiplier');
    final minimum = readNumber('minimumFuelLiters');
    if (multiplier <= 0 || multiplier > 1000000 || minimum < 0) {
      throw const FormatException('Configuración de puntos fuera de rango.');
    }
    final rawName = json['promotionName'];
    final name = rawName is String ? rawName.trim() : '';
    return PointsPromotion(
      multiplier: multiplier,
      minimumFuelLiters: minimum,
      promotionName: name.isEmpty ? null : name,
    );
  }
}
