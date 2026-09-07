import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final dynamic details;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidationError => statusCode == 400;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._() : _httpClient = http.Client();

  // Permite verificar el mismo flujo sin realizar peticiones a producción.
  ApiClient.forTesting({required http.Client httpClient})
    : _httpClient = httpClient;

  static final ApiClient instance = ApiClient._();

  static const String _accessTokenKey = 'access_token';
  static const String _legacyQrTokenKey = 'qr_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
  }) {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      body: body,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      body: body,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      body: body,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    required bool requiresAuthentication,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuthentication) {
      final accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw const ApiException(
          message: 'La sesión no está disponible. Iniciá sesión nuevamente.',
          statusCode: 401,
        );
      }

      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      late http.Response response;
      final encodedBody = body == null ? null : jsonEncode(body);

      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.timeout);
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.timeout);
          break;
        default:
          throw ApiException(message: 'Método HTTP no compatible: $method.');
      }

      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message:
            'El servidor tardó demasiado en responder. Verificá la conexión.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'No se pudo conectar con el servidor. Verificá que el backend esté encendido.',
      );
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('${ApiConfig.baseUrl}$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> responseBody = {};

    if (response.body.trim().isNotEmpty) {
      final decodedBody = jsonDecode(response.body);

      if (decodedBody is Map<String, dynamic>) {
        responseBody = decodedBody;
      } else {
        throw const FormatException();
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    throw ApiException(
      message: _extractErrorMessage(responseBody, response.statusCode),
      statusCode: response.statusCode,
      details: responseBody['details'],
    );
  }

  String _extractErrorMessage(
    Map<String, dynamic> responseBody,
    int statusCode,
  ) {
    final backendMessage = responseBody['message'];

    if (backendMessage is String && backendMessage.trim().isNotEmpty) {
      return backendMessage.trim();
    }

    switch (statusCode) {
      case 400:
        return 'Los datos enviados no son válidos.';
      case 401:
        return 'La sesión venció. Iniciá sesión nuevamente.';
      case 403:
        return 'No tenés permiso para realizar esta acción.';
      case 404:
        return 'No se encontró la información solicitada.';
      case 409:
        return 'La operación no pudo completarse porque existe un conflicto.';
      case 410:
        return 'El código QR venció. Generá uno nuevo.';
      case 429:
        return 'Realizaste demasiados intentos. Esperá unos minutos.';
      default:
        if (statusCode >= 500) {
          return 'El servidor tuvo un problema. Intentá nuevamente.';
        }

        return 'No se pudo completar la operación.';
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  // Compatibilidad temporal: si AuthService todavía llama a este método,
  // el QR recibido no se guarda. También elimina cualquier QR permanente viejo.
  Future<void> saveQrToken(String qrToken) async {
    await clearLegacyQrToken();
  }

  // Compatibilidad temporal con código antiguo. El QR ya no vive en el teléfono.
  Future<String?> getQrToken() async {
    await clearLegacyQrToken();
    return null;
  }

  Future<void> clearLegacyQrToken() {
    return _storage.delete(key: _legacyQrTokenKey);
  }

  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      clearLegacyQrToken(),
    ]);
  }

  Future<void> clearAllSecureData() async {
    await clearSession();
  }

  void close() {
    _httpClient.close();
  }
}
