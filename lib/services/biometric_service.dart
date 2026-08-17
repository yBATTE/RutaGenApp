import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricCredentials {
  const BiometricCredentials({
    required this.identifier,
    required this.password,
  });

  final String identifier;
  final String password;
}

class BiometricException implements Exception {
  const BiometricException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BiometricService {
  BiometricService._();

  static final BiometricService instance =
      BiometricService._();

  static const String _enabledKey =
      'biometric_login_enabled';

  static const String _identifierKey =
      'biometric_login_identifier';

  static const String _passwordKey =
      'biometric_login_password';

  final LocalAuthentication _localAuth =
      LocalAuthentication();

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<bool> isAvailable() async {
    try {
      final supported =
          await _localAuth.isDeviceSupported();

      if (!supported) {
        return false;
      }

      final availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      return availableBiometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final values = await Future.wait([
      _storage.read(key: _enabledKey),
      _storage.read(key: _identifierKey),
      _storage.read(key: _passwordKey),
    ]);

    return values[0] == 'true' &&
        values[1] != null &&
        values[1]!.trim().isNotEmpty &&
        values[2] != null &&
        values[2]!.isNotEmpty;
  }

  Future<void> enable({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();

    if (cleanIdentifier.isEmpty || password.isEmpty) {
      throw const BiometricException(
        'No se pudieron guardar las credenciales.',
      );
    }

    final available = await isAvailable();

    if (!available) {
      throw const BiometricException(
        'Este dispositivo no tiene una huella o rostro configurado.',
      );
    }

    final authenticated = await authenticate(
      reason:
          'Confirmá tu identidad para activar el ingreso biométrico.',
    );

    if (!authenticated) {
      throw const BiometricException(
        'No se pudo confirmar tu identidad.',
      );
    }

    await _storage.write(
      key: _identifierKey,
      value: cleanIdentifier,
    );

    await _storage.write(
      key: _passwordKey,
      value: password,
    );

    await _storage.write(
      key: _enabledKey,
      value: 'true',
    );
  }

  Future<BiometricCredentials>
      getCredentialsAfterAuthentication() async {
    if (!await isEnabled()) {
      throw const BiometricException(
        'El ingreso biométrico no está activado.',
      );
    }

    final authenticated = await authenticate(
      reason:
          'Confirmá tu identidad para ingresar a Ruta Gen.',
    );

    if (!authenticated) {
      throw const BiometricException(
        'No se pudo confirmar tu identidad.',
      );
    }

    final values = await Future.wait([
      _storage.read(key: _identifierKey),
      _storage.read(key: _passwordKey),
    ]);

    final identifier = values[0];
    final password = values[1];

    if (identifier == null ||
        identifier.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      await disable();

      throw const BiometricException(
        'Las credenciales biométricas no están disponibles. Iniciá sesión normalmente.',
      );
    }

    return BiometricCredentials(
      identifier: identifier,
      password: password,
    );
  }

  Future<bool> authenticate({
    required String reason,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateCredentials({
    required String identifier,
    required String password,
  }) async {
    if (!await isEnabled()) {
      return;
    }

    await Future.wait([
      _storage.write(
        key: _identifierKey,
        value: identifier.trim(),
      ),
      _storage.write(
        key: _passwordKey,
        value: password,
      ),
    ]);
  }

  Future<void> updatePassword(
    String password,
  ) async {
    if (!await isEnabled()) {
      return;
    }

    await _storage.write(
      key: _passwordKey,
      value: password,
    );
  }

  Future<void> disable() async {
    await Future.wait([
      _storage.delete(key: _enabledKey),
      _storage.delete(key: _identifierKey),
      _storage.delete(key: _passwordKey),
    ]);
  }
}