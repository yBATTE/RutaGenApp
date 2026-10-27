/// Caché en memoria: los datos personales se limpian al cambiar la sesión.
/// QR, promociones y operaciones de escritura siempre consultan al servidor.
class ApiCachePolicy {
  static Duration durationFor(String path) {
    final route = Uri.parse(path).path.replaceFirst(RegExp(r'/$'), '');
    if (route == '/news' || route.startsWith('/news/')) {
      return const Duration(minutes: 2);
    }
    if (route == '/rewards') return const Duration(seconds: 15);
    if (route == '/draws/events') return const Duration(seconds: 30);
    if (route == '/draws/ranking' || route == '/draws/monthly-ranking' ||
        RegExp(r'^/draws/events/[^/]+$').hasMatch(route)) {
      return const Duration(seconds: 15);
    }
    if (const {
      '/auth/me', '/loads/me', '/rewards/me', '/rewards/gifts/me',
      '/rewards/visit-progress', '/users/me/point-adjustments',
      '/notifications/me',
    }.contains(route)) {
      return const Duration(seconds: 10);
    }
    return Duration.zero;
  }

  /// Datos que pueden cambiar tras una carga, un canje o un ajuste externo.
  static const customerActivityPaths = <String>[
    '/auth/me',
    '/loads/me',
    '/rewards/me',
    '/rewards/gifts/me',
    '/rewards/visit-progress',
    '/users/me/point-adjustments',
    '/draws',
  ];

  static bool matchesRoute(String route, String prefix) =>
      route == prefix || route.startsWith('$prefix/');

  /// Una escritura desconocida conserva un fallback prudente por dominio.
  /// Las operaciones de sesión se limpian aparte al guardar/quitar el token.
  static List<String> invalidationsForWrite(String method, String path) {
    final route = Uri.parse(path).path.replaceFirst(RegExp(r'/$'), '');
    if (route == '/notifications/devices' &&
        (method == 'POST' || method == 'DELETE')) {
      return const [];
    }
    if (route == '/qr/renew' && method == 'POST') {
      return const ['/qr/current'];
    }
    if (const {
      '/auth/login', '/auth/register',
      '/auth/forgot-password', '/auth/reset-password',
    }.contains(route)) {
      return const [];
    }
    if (matchesRoute(route, '/notifications')) {
      return const ['/notifications/me'];
    }
    if (matchesRoute(route, '/users/me')) {
      return const ['/auth/me', '/users/me'];
    }
    if (matchesRoute(route, '/news')) return const ['/news'];
    if (matchesRoute(route, '/draws')) return const ['/draws'];
    if (matchesRoute(route, '/rewards') ||
        matchesRoute(route, '/loads') || matchesRoute(route, '/points')) {
      return [...customerActivityPaths, '/rewards', '/points/promotion'];
    }
    // Evitar datos personales viejos ante una operación futura sin clasificar.
    final segments = route.split('/').where((part) => part.isNotEmpty);
    final domain = segments.isEmpty ? null : segments.first;
    return [...customerActivityPaths, '/rewards', if (domain != null) '/$domain'];
  }

  static List<String> invalidationsForNotification(String action) {
    switch (action.trim().toUpperCase()) {
      case 'NEWS':
        return const ['/notifications/me', '/news'];
      case 'STATIONS':
        return const ['/notifications/me'];
      case 'DRAWS':
        return const ['/notifications/me', '/draws'];
      case 'GIFTS':
      case 'GIFT_REWARDS':
      case 'MOVEMENTS':
      case 'QR':
        return ['/notifications/me', ...customerActivityPaths, '/rewards'];
      case 'REWARDS':
        return ['/notifications/me', ...customerActivityPaths, '/rewards'];
      default:
        // HOME o un aviso sin categoría puede anunciar cualquier novedad.
        return [
          '/notifications/me', ...customerActivityPaths,
          '/rewards', '/news', '/points/promotion',
        ];
    }
  }

}
