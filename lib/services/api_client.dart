import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_cache_policy.dart';

/* ============================================================
   EXCEPCIONES API
============================================================ */

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

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

/* ============================================================
   ENTRADA DE CACHE
============================================================ */

class _CacheEntry {
  const _CacheEntry({
    required this.data,
    required this.expiresAt,
  });

  final String data;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/* ============================================================
   API CLIENT
============================================================ */

class ApiClient {
  ApiClient._() : _httpClient = http.Client();

  /*
   * Permite verificar el mismo flujo en tests
   * sin realizar peticiones reales.
   */
  ApiClient.forTesting({
    required http.Client httpClient,
  }) : _httpClient = httpClient;

  static final ApiClient instance = ApiClient._();

  bool _sessionInvalidated = false;
  int _cacheGeneration = 0;
  final Map<String, Object> _cacheVersions = {};
  int _sessionGeneration = 0;
  static const int _maxCacheEntries = 128;
  static const int _maxCacheItemBytes = 128 * 1024;

  static const String _accessTokenKey = 'access_token';
  static const String _legacyQrTokenKey = 'qr_token';

  /*
   * flutter_secure_storage >= 10 ya no necesita
   * encryptedSharedPreferences.
   *
   * Esto elimina el warning:
   *
   * encryptedSharedPreferences is deprecated
   */
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final http.Client _httpClient;

  /* ============================================================
     CACHE EN MEMORIA
  ============================================================ */

  /*
   * Cache de respuestas GET.
   *
   * Solamente vive mientras la aplicación está abierta.
   * No se persiste entre reinicios.
   */
  final Map<String, _CacheEntry> _getCache = {};
  final Map<String, DateTime> _serverRefreshPaths = {};

  /*
   * Requests GET actualmente en ejecución.
   *
   * Sirve para que:
   *
   * Home       ┐
   * Cuenta     ├── /auth/me
   * Rewards    ┘
   *
   * no hagan 3 requests simultáneos iguales.
   *
   * Los tres esperan el MISMO Future.
   */
  final Map<String, Future<Map<String, dynamic>>> _pendingGetRequests = {};

  /* ============================================================
     GET NORMAL

     Aplica el TTL permitido por ApiCachePolicy y deduplica consultas.
     Las rutas no incluidas consultan siempre al servidor.
  ============================================================ */

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
    bool forceRefresh = false,
  }) {
    final duration = ApiCachePolicy.durationFor(path);
    if (duration > Duration.zero) {
      return getCached(path,
        queryParameters: queryParameters,
        requiresAuthentication: requiresAuthentication,
        cacheDuration: duration,
        forceRefresh: forceRefresh,
      );
    }
    return _getDeduplicated(path,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );
  }

  /* ============================================================
     GET CON CACHE

     Ejemplo:

     await api.getCached(
       '/rewards',
       cacheDuration: const Duration(minutes: 5),
     );
  ============================================================ */

  Future<Map<String, dynamic>> getCached(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
    Duration cacheDuration = const Duration(minutes: 1),
    bool forceRefresh = false,
  }) async {
    final uri = _buildUri(
      path,
      queryParameters: queryParameters,
    );

    final cacheKey = _buildRequestKey(
      uri,
      requiresAuthentication,
    );

    /*
     * Si no estamos forzando actualización,
     * buscamos primero en memoria.
     */
    if (forceRefresh) invalidateCache(Uri.parse(path).path);
    if (!forceRefresh) {
      final cached = _getCache[cacheKey];

      if (cached != null) {
        if (!cached.isExpired) {
          debugPrint(
            '⚡ API CACHE HIT: ${uri.path}${_queryLog(uri)}',
          );

          /*
           * Devolvemos una copia para evitar que código externo
           * modifique accidentalmente el objeto guardado.
           */
          return jsonDecode(cached.data) as Map<String, dynamic>;
        }

        /*
         * Estaba vencido.
         */
        _getCache.remove(cacheKey);

        debugPrint(
          '⌛ API CACHE EXPIRED: ${uri.path}${_queryLog(uri)}',
        );
      }
    }

    debugPrint(
      forceRefresh
          ? '🔄 API FORCE REFRESH: ${uri.path}${_queryLog(uri)}'
          : '🌐 API CACHE MISS: ${uri.path}${_queryLog(uri)}',
    );

    /*
     * La consulta de red deduplica requests simultáneos sin reingresar al TTL.
     */
    final generation = _cacheGeneration;
    final version = _cacheVersions.putIfAbsent(cacheKey, Object.new);
    try {
      final result = await _getDeduplicated(
        path,
        queryParameters: queryParameters,
        requiresAuthentication: requiresAuthentication,
      );

      // Una invalidación solo impide guardar respuestas del recurso afectado.
      if (cacheDuration > Duration.zero && result['success'] != false &&
          generation == _cacheGeneration &&
          identical(_cacheVersions[cacheKey], version)) {
        final encoded = jsonEncode(result);
        _getCache.removeWhere((key, entry) => entry.isExpired);
        if (utf8.encode(encoded).length <= _maxCacheItemBytes) {
          _getCache.remove(cacheKey);
          while (_getCache.length >= _maxCacheEntries) {
            _getCache.remove(_getCache.keys.first);
          }
          _getCache[cacheKey] = _CacheEntry(
            data: encoded,
            expiresAt: DateTime.now().add(cacheDuration),
          );
        }
      }
      return jsonDecode(jsonEncode(result)) as Map<String, dynamic>;
    } finally {
      // Acotar también los marcadores de versión a caché/consultas vivas.
      _cacheVersions.removeWhere((key, _) =>
          !_getCache.containsKey(key) && !_pendingGetRequests.containsKey(key));
    }
  }

  /* ============================================================
     POST
  ============================================================ */

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

  /* ============================================================
     PUT
  ============================================================ */

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

  /* ============================================================
     PATCH
  ============================================================ */

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

  /* ============================================================
     DELETE
  ============================================================ */

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuthentication = true,
    Duration? requestTimeout,
  }) {
    return _request(
      method: 'DELETE',
      requestTimeout: requestTimeout,
      path: path,
      body: body,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );
  }

  /* ============================================================
     GET DEDUPLICADO
  ============================================================ */

  Future<Map<String, dynamic>> _getDeduplicated(
    String path, {
    Map<String, String>? queryParameters,
    required bool requiresAuthentication,
  }) {
    final uri = _buildUri(
      path,
      queryParameters: queryParameters,
    );

    final requestKey = _buildRequestKey(
      uri,
      requiresAuthentication,
    );

    /*
     * Ya existe exactamente este GET en ejecución.
     */
    final existing = _pendingGetRequests[requestKey];

    if (existing != null) {
      debugPrint(
        '🔗 API GET DEDUPLICADO: '
        '${uri.path}${_queryLog(uri)}',
      );

      return existing.then((data) =>
          jsonDecode(jsonEncode(data)) as Map<String, dynamic>);
    }

    /*
     * Creamos el request una sola vez.
     */
    final future = _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      requiresAuthentication: requiresAuthentication,
    );

    _pendingGetRequests[requestKey] = future;

    /*
     * Cuando termine, sea OK o error,
     * lo eliminamos de pendientes.
     */
    void clearPending() {
      if (identical(_pendingGetRequests[requestKey], future)) {
        _pendingGetRequests.remove(requestKey);
      }
    }

    // Handle the cleanup branch's error too: an ignored whenComplete Future
    // would report an uncaught error even if the caller catches the API error.
    future.then<void>(
      (_) => clearPending(),
      onError: (Object error, StackTrace stackTrace) => clearPending(),
    );

    return future.then((data) =>
        jsonDecode(jsonEncode(data)) as Map<String, dynamic>);
  }

  /* ============================================================
     REQUEST HTTP
  ============================================================ */

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    required bool requiresAuthentication,
    Duration? requestTimeout,
  }) async {
    final session = _sessionGeneration;
    final uri = _buildUri(
      path,
      queryParameters: queryParameters,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final route = Uri.parse(path).path;
    final now = DateTime.now();
    if (method == 'GET' && _serverRefreshPaths.entries.any((entry) =>
        ApiCachePolicy.matchesRoute(route, entry.key) && now.isBefore(entry.value))) {
      headers['Cache-Control'] = 'no-cache';
    }

    /* ============================================================
       AUTENTICACIÓN
    ============================================================ */

    if (requiresAuthentication) {
      final accessToken = await getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException(
          message: 'La sesión no está disponible. Iniciá sesión nuevamente.',
          statusCode: 401,
        );
      }

      if (session != _sessionGeneration) {
        throw const ApiException(message: 'La sesión cambió. Volvé a intentar.', statusCode: 409);
      }
      headers['Authorization'] = 'Bearer ${accessToken.trim()}';
    }

    try {
      late http.Response response;

      final encodedBody = body == null ? null : jsonEncode(body);

      /* ============================================================
         EJECUTAR REQUEST
      ============================================================ */

      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(
                uri,
                headers: headers,
              )
              .timeout(requestTimeout ?? ApiConfig.timeout);

          break;

        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: encodedBody,
              )
              .timeout(requestTimeout ?? ApiConfig.timeout);

          break;

        case 'PUT':
          response = await _httpClient
              .put(
                uri,
                headers: headers,
                body: encodedBody,
              )
              .timeout(requestTimeout ?? ApiConfig.timeout);

          break;

        case 'PATCH':
          response = await _httpClient
              .patch(
                uri,
                headers: headers,
                body: encodedBody,
              )
              .timeout(requestTimeout ?? ApiConfig.timeout);

          break;

        case 'DELETE':
          response = await _httpClient
              .delete(
                uri,
                headers: headers,
                body: encodedBody,
              )
              .timeout(requestTimeout ?? ApiConfig.timeout);

          break;

        default:
          throw ApiException(
            message: 'Método HTTP no compatible: $method.',
          );
      }

      if (session != _sessionGeneration) {
        throw const ApiException(message: 'La sesión cambió. Volvé a intentar.', statusCode: 409);
      }
      final result = _processResponse(response);
      if (method != 'GET' && result['success'] != false) {
        if (method == 'DELETE' && Uri.parse(path).path == '/auth/account') {
          clearCache();
        } else {
          for (final affected in ApiCachePolicy.invalidationsForWrite(method, path).toSet()) {
            invalidateCache(affected);
          }
        }
      }
      return result;
    } on TimeoutException {
      throw const ApiException(
        message:
            'El servidor tardó demasiado en responder. Verificá la conexión.',
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            'No se pudo conectar con el servidor. Verificá que el backend esté encendido.',
      );
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  /* ============================================================
     URI
  ============================================================ */

  Uri _buildUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$normalizedPath',
    );

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: queryParameters,
    );
  }

  /* ============================================================
     KEY PARA CACHE / REQUEST DEDUPLICADO
  ============================================================ */

  String _buildRequestKey(
    Uri uri,
    bool requiresAuthentication,
  ) {
    final authPrefix = requiresAuthentication ? 'AUTH' : 'PUBLIC';

    final keys = uri.queryParametersAll.keys.toList()..sort();
    final canonical = uri.replace(queryParameters: {
      for (final key in keys) key: uri.queryParametersAll[key]!,
    });
    return '$authPrefix|$canonical';
  }

  String _queryLog(Uri uri) {
    if (uri.query.isEmpty) {
      return '';
    }

    return '?${uri.query}';
  }

  /* ============================================================
     RESPONSE
  ============================================================ */

  Map<String, dynamic> _processResponse(
    http.Response response,
  ) {
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
      message: _extractErrorMessage(
        responseBody,
        response.statusCode,
      ),
      statusCode: response.statusCode,
      details: responseBody['details'],
    );
  }

  /* ============================================================
     MENSAJES DE ERROR
  ============================================================ */

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

  /* ============================================================
     INVALIDAR CACHE EXACTO/POR PREFIJO
  ============================================================ */

  /*
   * Ejemplo:
   *
   * invalidateCache('/auth/me');
   *
   * elimina:
   *
   * /auth/me
   * /auth/me?... (si alguna vez existiera)
   */
  void invalidateCache(String path) {
    final route = Uri.parse(path).path.replaceFirst(RegExp(r'/$'), '');
    final normalizedPath = route.startsWith('/') ? route : '/$route';
    final targetPath = _buildUri(normalizedPath).path;
    bool matchesKey(String key) {
      final requestPath = Uri.parse(key.substring(key.indexOf('|') + 1)).path;
      return ApiCachePolicy.matchesRoute(requestPath, targetPath);
    }

    _serverRefreshPaths.removeWhere((_, until) => DateTime.now().isAfter(until));
    if (_serverRefreshPaths.length >= _maxCacheEntries) _serverRefreshPaths.clear();
    _serverRefreshPaths[normalizedPath] = DateTime.now().add(const Duration(seconds: 5));
    // Desvincular respuestas viejas solo de este recurso, incluidas sus páginas.
    _cacheVersions.removeWhere((key, _) => matchesKey(key));
    _pendingGetRequests.removeWhere((key, _) => matchesKey(key));
    var removed = 0;
    _getCache.removeWhere((key, _) {
      if (!matchesKey(key)) return false;
      removed++;
      return true;
    });
    if (removed > 0) {
      debugPrint('🧹 API CACHE INVALIDADO: $normalizedPath ($removed)');
    }
  }

  void invalidateCustomerData({bool includeRewards = false}) {
    for (final path in ApiCachePolicy.customerActivityPaths) {
      invalidateCache(path);
    }
    if (includeRewards) invalidateCache('/rewards');
  }

  void invalidateForNotification(String action) {
    for (final path in ApiCachePolicy.invalidationsForNotification(action).toSet()) {
      invalidateCache(path);
    }
  }

  /*
   * Alias más explícito para endpoints con varios query params.
   *
   * Ejemplo:
   *
   * invalidateCacheStartingWith('/loads/me');
   */
  void invalidateCacheStartingWith(
    String pathPrefix,
  ) {
    invalidateCache(pathPrefix);
  }

  /* ============================================================
     LIMPIAR TODA LA CACHE
  ============================================================ */

  void clearCache() {
    _cacheGeneration += 1;
    _cacheVersions.clear();
    _serverRefreshPaths.clear();
    _pendingGetRequests.clear();
    final amount = _getCache.length;

    _getCache.clear();

    if (amount > 0) {
      debugPrint(
        '🧹 API CACHE COMPLETO LIMPIADO: '
        '$amount entrada(s)',
      );
    }
  }

  /* ============================================================
     INFORMACIÓN DE CACHE PARA DEBUG
  ============================================================ */

  int get cacheEntries => _getCache.length;

  int get pendingGetRequests => _pendingGetRequests.length;

  /* ============================================================
     ACCESS TOKEN
  ============================================================ */

  Future<void> saveAccessToken(
    String accessToken,
  ) async {
    /*
     * Si cambia el usuario/token,
     * no queremos reutilizar respuestas del usuario anterior.
     */
    _sessionGeneration += 1;
    clearCache();

    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );
    _sessionInvalidated = false;
  }

  Future<String?> getAccessToken() {
    if (_sessionInvalidated) return Future.value(null);
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  /* ============================================================
     QR LEGACY
  ============================================================ */

  /*
   * Compatibilidad temporal:
   *
   * El QR actual YA NO vive permanentemente
   * en el teléfono.
   */
  Future<void> saveQrToken(
    String qrToken,
  ) async {
    await clearLegacyQrToken();
  }

  /*
   * Compatibilidad temporal con código viejo.
   */
  Future<String?> getQrToken() async {
    await clearLegacyQrToken();

    return null;
  }

  Future<void> clearLegacyQrToken() {
    return _storage.delete(
      key: _legacyQrTokenKey,
    );
  }

  /* ============================================================
     SESIÓN
  ============================================================ */

  Future<bool> hasSession() async {
    final token = await getAccessToken();

    return token != null && token.trim().isNotEmpty;
  }

  Future<void> clearSession() async {
    _sessionGeneration += 1;
    _sessionInvalidated = true;
    /*
     * Importantísimo:
     *
     * nunca dejar datos cacheados de un usuario
     * cuando inicia sesión otro.
     */
    clearCache();

    await Future.wait([
      _storage.delete(
        key: _accessTokenKey,
      ),
      clearLegacyQrToken(),
    ]);
  }

  Future<void> clearAllSecureData() async {
    _sessionGeneration += 1;
    clearCache();

    _sessionInvalidated = true;
    await _storage.deleteAll();
  }

  /* ============================================================
     CERRAR CLIENTE
  ============================================================ */

  void close() {
    clearCache();
    _pendingGetRequests.clear();

    _httpClient.close();
  }
}
