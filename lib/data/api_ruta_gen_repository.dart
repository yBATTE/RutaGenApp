import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import 'models.dart';
import 'ruta_gen_repository.dart';

class ApiRutaGenRepository implements RutaGenRepository, TemporaryQrRepository {
  ApiRutaGenRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is List) return data;

    if (data is Map) {
      final nestedData = data['data'];
      if (nestedData is List) return nestedData;
    }

    return const [];
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '')
            ?.round() ??
        0;
  }

  DateTime _dateValue(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString())?.toLocal() ?? DateTime.now();
  }

  DateTime? _nullableDateValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatDecimal(double value, {int decimals = 2}) {
    if (value == value.roundToDouble()) return value.toInt().toString();

    var text = value.toStringAsFixed(decimals);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return text.replaceAll('.', ',');
  }

  String _formatMoney(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '\$$integerPart,${parts.last}';
  }

  String? _rewardImageUrl(dynamic value) {
    final imagePath = _stringValue(value);
    if (imagePath.isEmpty) return null;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    final separator = imagePath.startsWith('/') ? '' : '/';
    return '${ApiConfig.serverUrl}$separator$imagePath';
  }

  NewsItem _newsFromData(
    Map<String, dynamic> data,
  ) {
    /*
   * Imagen original para el detalle.
   */
    final imageUrl = _rewardImageUrl(
      data['imagePath'] ?? data['imageUrl'],
    );

    if (imageUrl == null) {
      throw const FormatException(
        'La novedad no posee una imagen válida.',
      );
    }

    /*
   * Miniatura para el Home.
   *
   * Si es una novedad antigua que todavía no tiene
   * thumbnailPath, utiliza la imagen original para
   * mantener compatibilidad.
   */
    final thumbnailUrl = _rewardImageUrl(
          data['thumbnailPath'] ?? data['imagePath'] ?? data['imageUrl'],
        ) ??
        imageUrl;

    final title = _stringValue(
      data['title'],
    );

    final description = _stringValue(
      data['description'],
    );

    return NewsItem(
      id: _stringValue(
        data['id'] ?? data['_id'],
      ),
      title: title.isEmpty ? null : title,
      description: description.isEmpty ? null : description,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: _stringValue(
        data['status'],
        fallback: 'PUBLISHED',
      ),
      publishedAt: _nullableDateValue(
        data['publishedAt'],
      ),
      createdAt: _dateValue(
        data['createdAt'],
      ),
      updatedAt: _dateValue(
        data['updatedAt'] ?? data['createdAt'],
      ),
    );
  }

  Movement _movementFromLoad(Map<String, dynamic> data) {
    final stationName = _stringValue(
      data['stationName'],
      fallback: _stringValue(
        data['stationSlug'],
        fallback: 'Estación Grupo Gen',
      ),
    );
    final productName = _stringValue(
      data['productName'],
      fallback: 'Combustible',
    );
    final liters = _doubleValue(data['liters']);
    final amount = _doubleValue(data['amount']);
    final pricePerLiter = _doubleValue(data['pricePerLiter']);
    final points = _intValue(data['pointsEarned']);
    final date = _dateValue(
      data['dispatchAt'] ??
          data['loadedAt'] ??
          data['pointsCreditedAt'] ??
          data['createdAt'],
    );

    final loadDetails = <String>[
      productName,
      '${_formatDecimal(liters)} L',
      if (amount > 0) _formatMoney(amount),
    ].join(' • ');

    return Movement(
      id: _stringValue(data['id'] ?? data['_id']),
      title: 'Carga de combustible',
      subtitle: '$stationName\n$loadDetails',
      date: date,
      points: points,
      type: MovementType.load,
      stationName: stationName,
      productName: productName,
      liters: liters,
      amount: amount,
      pricePerLiter: pricePerLiter,
    );
  }

  Movement _movementFromRedemption(Map<String, dynamic> data) {
    final stationName = _stringValue(
      data['stationName'],
      fallback: _stringValue(
        data['stationSlug'],
        fallback: 'Estación Grupo Gen',
      ),
    );
    final rewardName = _stringValue(
      data['rewardName'],
      fallback: 'Premio',
    );
    final pointsCost = _intValue(
      data['pointsCost'] ?? data['points'],
    ).abs();
    final date = _dateValue(data['createdAt']);

    return Movement(
      id: _stringValue(data['id'] ?? data['_id']),
      title: 'Canje de premio',
      subtitle: '$stationName\n$rewardName',
      date: date,
      points: -pointsCost,
      type: MovementType.redemption,
      stationName: stationName,
      productName: rewardName,
    );
  }

  Reward _rewardFromData(Map<String, dynamic> data) {
    return Reward(
      id: _stringValue(data['id'] ?? data['_id']),
      name: _stringValue(data['name'], fallback: 'Premio'),
      subtitle: _stringValue(
        data['description'],
        fallback: 'Premio Ruta Gen',
      ),
      points: _intValue(data['pointsCost'] ?? data['points']),
      stock: _intValue(data['totalStock'] ?? data['stock']),
      imageUrl: _rewardImageUrl(data['imagePath'] ?? data['imageUrl']),
      icon: Icons.card_giftcard_rounded,
    );
  }

  TemporaryQr _temporaryQrFromResponse(Map<String, dynamic> response) {
    final data = _asMap(response['data']);
    final status = _stringValue(data['status']).toUpperCase();

    if (status == 'CONSUMED') {
      throw const ApiException(
        message: 'El código QR ya fue utilizado. Generá uno nuevo.',
        statusCode: 410,
        details: <String, dynamic>{
          'code': 'QR_CONSUMED',
        },
      );
    }

    if (status == 'EXPIRED') {
      throw const ApiException(
        message: 'El código QR venció. Generá uno nuevo.',
        statusCode: 410,
        details: <String, dynamic>{
          'code': 'QR_EXPIRED',
        },
      );
    }

    final qrToken = _stringValue(data['qrToken']);
    final expiresAtText = _stringValue(data['expiresAt']);
    final expiresAt = DateTime.tryParse(expiresAtText)?.toLocal();
    var expiresInSeconds = _intValue(data['expiresInSeconds']);

    if (qrToken.isEmpty || expiresAt == null) {
      throw const ApiException(
        message: 'El servidor devolvió un código QR incompleto.',
      );
    }

    if (expiresInSeconds <= 0) {
      expiresInSeconds = expiresAt.difference(DateTime.now()).inSeconds;
    }

    return TemporaryQr(
      qrToken: qrToken,
      expiresAt: expiresAt,
      expiresInSeconds: expiresInSeconds < 0 ? 0 : expiresInSeconds,
    );
  }

  @override
  Future<Customer> getCustomer() async {
    final response = await _apiClient.get('/auth/me');
    final data = _asMap(response['data']);
    final userData = data['user'] is Map ? _asMap(data['user']) : data;

    return Customer(
      firstName: _stringValue(userData['firstName']),
      lastName: _stringValue(userData['lastName']),
      memberCode: _stringValue(userData['memberCode']),
      points: _intValue(userData['pointsBalance'] ?? userData['points']),
    );
  }

  @override
  Future<List<Movement>> getMovements({
    int page = 1,
    int limit = 20,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 1 : (limit > 100 ? 100 : limit);
    final requestedCount = safePage * safeLimit;
    final requestedItems = requestedCount > 100 ? 100 : requestedCount;

    final responses = await Future.wait([
      _apiClient.get(
        '/loads/me',
        queryParameters: {
          'page': '1',
          'limit': requestedItems.toString(),
          'status': 'CONFIRMED',
        },
      ),
      _apiClient.get(
        '/rewards/me',
        queryParameters: {
          'page': '1',
          'limit': requestedItems.toString(),
        },
      ),
    ]);

    final movements = <Movement>[
      ..._extractList(responses[0]).whereType<Map>().map(
            (item) => _movementFromLoad(
              Map<String, dynamic>.from(item),
            ),
          ),
      ..._extractList(responses[1]).whereType<Map>().map(
            (item) => _movementFromRedemption(
              Map<String, dynamic>.from(item),
            ),
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final start = (safePage - 1) * safeLimit;
    if (start >= movements.length) return const [];

    final requestedEnd = start + safeLimit;
    final end =
        requestedEnd > movements.length ? movements.length : requestedEnd;
    return movements.sublist(start, end);
  }

  @override
  Future<List<Reward>> getRewards() async {
    final response = await _apiClient.get('/rewards');
    final data = _asMap(response['data']);
    final rawItems = data['items'];

    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map>()
        .map((item) => _rewardFromData(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<NewsItem>> getNews({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      '/news',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final data = _asMap(response['data']);
    final rawItems = data['items'];

    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map>()
        .map(
          (item) => _newsFromData(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  @override
  Future<NewsItem> getNewsDetail(String newsId) async {
    final response = await _apiClient.get('/news/$newsId');
    return _newsFromData(_asMap(response['data']));
  }

  @override
  Future<List<Station>> getStations() async {
    return const [];
  }

  @override
  Future<TemporaryQr> getCurrentQr() async {
    await _apiClient.clearLegacyQrToken();
    final response = await _apiClient.get('/qr/current');
    return _temporaryQrFromResponse(response);
  }

  @override
  Future<TemporaryQr> renewQr() async {
    await _apiClient.clearLegacyQrToken();
    final response = await _apiClient.post('/qr/renew');
    return _temporaryQrFromResponse(response);
  }

  @override
  Future<String> getQrToken() async {
    return (await getCurrentQr()).qrToken;
  }

  @override
  Future<String> redeemReward(String rewardId) async {
    throw const ApiException(
      message: 'El canje debe ser confirmado por el playero desde su panel.',
    );
  }
}
