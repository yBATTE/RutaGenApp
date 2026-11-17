import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia del dispositivo, independiente del token y de la cuenta.
class OnboardingService {
  static const completedKey = 'ruta_gen_onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completedKey) ?? false;
  }

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(completedKey, true)) {
      throw StateError('No se pudo guardar la bienvenida.');
    }
  }
}
