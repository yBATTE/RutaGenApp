import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ApiClient _apiClient = ApiClient.instance;

  /* ============================================================
     REGISTRAR CLIENTE

     El backend devuelve el usuario y el qrToken.
     Después del registro se inicia sesión automáticamente.
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
        message: 'Debés aceptar los términos y condiciones.',
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

    if (qrToken is! String || qrToken.trim().isEmpty) {
      throw const ApiException(
        message:
            'La cuenta fue creada, pero no se pudo guardar el código QR.',
      );
    }

    await _apiClient.saveQrToken(qrToken.trim());

    /*
     * El registro no devuelve accessToken.
     * Por eso iniciamos sesión automáticamente.
     */
    try {
      return await login(
        identifier: cleanDni,
        password: password,
      );
    } catch (error) {
      /*
       * Conservamos el QR porque la cuenta ya fue creada.
       * El usuario podrá iniciar sesión manualmente.
       */
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
     INICIAR SESIÓN

     identifier puede ser el DNI o el email del cliente.
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

    return user;
  }

  /* ============================================================
     OBTENER SESIÓN ACTUAL
  ============================================================ */

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/auth/me');
    final data = _extractData(response);
    final user = _extractUser(data);

    _validateCustomer(user);

    return user;
  }

  /* ============================================================
     RESTAURAR SESIÓN AL ABRIR LA APP

     Devuelve el usuario si el token sigue siendo válido.
     Devuelve null si no existe sesión o si venció.
  ============================================================ */

  Future<UserModel?> restoreSession() async {
    final hasSession = await _apiClient.hasSession();

    if (!hasSession) {
      return null;
    }

    try {
      return await getCurrentUser();
    } on ApiException catch (error) {
      if (error.isUnauthorized || error.isForbidden) {
        await _apiClient.clearSession();
        return null;
      }

      rethrow;
    }
  }

  /* ============================================================
     CERRAR SESIÓN

     Se elimina el accessToken, pero se conserva el qrToken.
  ============================================================ */

  Future<void> logout() async {
    await _apiClient.clearSession();
  }

  /* ============================================================
     QR DEL CLIENTE
  ============================================================ */

  Future<String?> getQrToken() {
    return _apiClient.getQrToken();
  }

  Future<bool> hasQrToken() async {
    final qrToken = await getQrToken();

    return qrToken != null && qrToken.isNotEmpty;
  }

  Future<void> saveQrToken(String qrToken) async {
    final cleanQrToken = qrToken.trim();

    if (cleanQrToken.isEmpty) {
      throw const ApiException(
        message: 'El código QR recibido no es válido.',
      );
    }

    await _apiClient.saveQrToken(cleanQrToken);
  }

  /* ============================================================
     ELIMINAR TODOS LOS DATOS LOCALES

     Usar únicamente cuando se quiera borrar también el QR.
  ============================================================ */

  Future<void> clearAllLocalData() async {
    await _apiClient.clearAllSecureData();
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

    /*
     * También permite que /auth/me devuelva directamente
     * el usuario dentro de data.
     */
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

  void _validateCustomer(UserModel user) {
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