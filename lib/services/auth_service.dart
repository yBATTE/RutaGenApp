import '../models/user_model.dart';
import 'api_client.dart';
import 'biometric_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ApiClient _apiClient = ApiClient.instance;
  final BiometricService _biometricService =
      BiometricService.instance;

  /* ============================================================
     REGISTRAR CLIENTE
  ============================================================ */

  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String dni,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanDni = dni.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (!acceptedTerms) {
      throw const ApiException(
        message:
            'Debés aceptar los términos y condiciones.',
      );
    }

    final response = await _apiClient.post(
      '/auth/register',
      requiresAuthentication: false,
      body: {
        'firstName': cleanFirstName,
        'lastName': cleanLastName,
        'dni': cleanDni,
        'email': cleanEmail,
        'password': password,
        'acceptedTerms': acceptedTerms,
      },
    );

    final data = _extractData(response);
    final qrToken = data['qrToken'];

    if (qrToken is! String ||
        qrToken.trim().isEmpty) {
      throw const ApiException(
        message:
            'La cuenta fue creada, pero no se pudo guardar el código QR.',
      );
    }

    await _apiClient.saveQrToken(
      qrToken.trim(),
    );

    try {
      return await login(
        identifier: cleanDni,
        password: password,
      );
    } catch (error) {
      if (error is ApiException) {
        throw ApiException(
          message:
              'La cuenta fue creada correctamente, pero no se pudo iniciar sesión automáticamente. ${error.message}',
          statusCode: error.statusCode,
          details: error.details,
        );
      }

      rethrow;
    }
  }

  /* ============================================================
     INICIAR SESIÓN MANUAL
  ============================================================ */

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();

    if (cleanIdentifier.isEmpty) {
      throw const ApiException(
        message: 'Ingresá tu DNI o email.',
      );
    }

    if (password.isEmpty) {
      throw const ApiException(
        message: 'Ingresá tu contraseña.',
      );
    }

    final response = await _apiClient.post(
      '/auth/login',
      requiresAuthentication: false,
      body: {
        'identifier': cleanIdentifier,
        'password': password,
      },
    );

    final data = _extractData(response);
    final accessToken = data['accessToken'];
    final user = _extractUser(data);

    if (accessToken is! String ||
        accessToken.trim().isEmpty) {
      throw const ApiException(
        message:
            'El servidor no devolvió un token de sesión válido.',
      );
    }

    _validateCustomer(user);

    await _apiClient.saveAccessToken(
      accessToken.trim(),
    );

    /*
     * Si la biometría ya estaba habilitada,
     * actualizamos las credenciales guardadas.
     */
    if (await _biometricService.isEnabled()) {
      await _biometricService.updateCredentials(
        identifier: cleanIdentifier,
        password: password,
      );
    }

    return user;
  }

  /* ============================================================
     INICIAR SESIÓN CON BIOMETRÍA
  ============================================================ */

  Future<UserModel> loginWithBiometrics() async {
    final credentials =
        await _biometricService
            .getCredentialsAfterAuthentication();

    /*
     * Primero intentamos utilizar el token actual.
     * La biometría igualmente ya fue solicitada.
     */
    final restoredUser = await restoreSession();

    if (restoredUser != null) {
      return restoredUser;
    }

    try {
      return await login(
        identifier: credentials.identifier,
        password: credentials.password,
      );
    } on ApiException catch (error) {
      /*
       * Si las credenciales dejaron de ser válidas,
       * deshabilitamos la biometría para evitar
       * intentos automáticos repetidos.
       */
      if (error.isUnauthorized) {
        await _biometricService.disable();
      }

      rethrow;
    }
  }

  /* ============================================================
     OBTENER USUARIO ACTUAL
  ============================================================ */

  Future<UserModel> getCurrentUser() async {
    final response =
        await _apiClient.get('/auth/me');

    final data = _extractData(response);
    final user = _extractUser(data);

    _validateCustomer(user);

    return user;
  }

  /* ============================================================
     RESTAURAR TOKEN
  ============================================================ */

  Future<UserModel?> restoreSession() async {
    final hasSession =
        await _apiClient.hasSession();

    if (!hasSession) {
      return null;
    }

    try {
      return await getCurrentUser();
    } on ApiException catch (error) {
      if (error.isUnauthorized ||
          error.isForbidden) {
        await _apiClient.clearSession();
        return null;
      }

      rethrow;
    }
  }

  /* ============================================================
     ACTUALIZAR TELÉFONO
  ============================================================ */

  Future<UserModel> updatePhone(
    String phone,
  ) async {
    final response = await _apiClient.patch(
      '/users/me',
      body: {
        'phone': phone.trim(),
      },
    );

    final data = _extractData(response);
    final user = _extractUser(data);

    _validateCustomer(user);

    return user;
  }

  /* ============================================================
     CAMBIAR CONTRASEÑA
  ============================================================ */

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch(
      '/users/me/password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    /*
     * Si la biometría estaba activa, guardamos
     * la nueva contraseña cifrada.
     */
    await _biometricService.updatePassword(
      newPassword,
    );
  }

  /* ============================================================
     CERRAR SESIÓN

     Se elimina el token, pero se mantienen las
     credenciales biométricas.
  ============================================================ */

  Future<void> logout({
    bool removeBiometrics = false,
  }) async {
    await _apiClient.clearSession();

    if (removeBiometrics) {
      await _biometricService.disable();
    }
  }

  /* ============================================================
     BIOMETRÍA
  ============================================================ */

  Future<bool> isBiometricAvailable() {
    return _biometricService.isAvailable();
  }

  Future<bool> isBiometricEnabled() {
    return _biometricService.isEnabled();
  }

  Future<void> enableBiometrics({
    required String identifier,
    required String password,
  }) {
    return _biometricService.enable(
      identifier: identifier,
      password: password,
    );
  }

  Future<void> disableBiometrics() {
    return _biometricService.disable();
  }

  /* ============================================================
     QR DEL CLIENTE
  ============================================================ */

  Future<String?> getQrToken() {
    return _apiClient.getQrToken();
  }

  Future<bool> hasQrToken() async {
    final qrToken = await getQrToken();

    return qrToken != null &&
        qrToken.isNotEmpty;
  }

  Future<void> saveQrToken(
    String qrToken,
  ) async {
    final cleanQrToken = qrToken.trim();

    if (cleanQrToken.isEmpty) {
      throw const ApiException(
        message:
            'El código QR recibido no es válido.',
      );
    }

    await _apiClient.saveQrToken(
      cleanQrToken,
    );
  }

  /* ============================================================
     ELIMINAR TODOS LOS DATOS LOCALES
  ============================================================ */

  Future<void> clearAllLocalData() async {
    await Future.wait([
      _apiClient.clearAllSecureData(),
      _biometricService.disable(),
    ]);
  }

  /* ============================================================
     FUNCIONES INTERNAS
  ============================================================ */

  Map<String, dynamic> _extractData(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(
        data,
      );
    }

    throw const ApiException(
      message:
          'El servidor devolvió una respuesta incompleta.',
    );
  }

  UserModel _extractUser(
    Map<String, dynamic> data,
  ) {
    final user = data['user'];

    if (user is Map<String, dynamic>) {
      return UserModel.fromJson(user);
    }

    if (user is Map) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(user),
      );
    }

    if (data.containsKey('id') ||
        data.containsKey('_id') ||
        data.containsKey('dni')) {
      return UserModel.fromJson(data);
    }

    throw const ApiException(
      message:
          'El servidor no devolvió la información del usuario.',
    );
  }

  void _validateCustomer(
    UserModel user,
  ) {
    if (!user.isCustomer) {
      throw const ApiException(
        message:
            'Esta aplicación es exclusivamente para clientes.',
        statusCode: 403,
      );
    }

    if (!user.isActive) {
      throw const ApiException(
        message:
            'Tu cuenta no está activa. Comunicate con un administrador.',
        statusCode: 403,
      );
    }
  }
}