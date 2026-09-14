import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (error) {
    debugPrint(
      '❌ PUSH BACKGROUND: no se pudo inicializar Firebase: $error',
    );
  }
}

class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  final ApiClient _apiClient = ApiClient.instance;

  final StreamController<PushMessage> _foregroundController =
      StreamController<PushMessage>.broadcast();

  final ValueNotifier<String?> actionNotifier =
      ValueNotifier<String?>(null);

  bool _available = false;
  bool _listenersReady = false;
  bool _initializing = false;

  StreamSubscription<String>? _tokenSubscription;

  Stream<PushMessage> get foregroundMessages =>
      _foregroundController.stream;

  /* ============================================================
     INICIALIZACIÓN FIREBASE / PUSH
  ============================================================ */

  Future<void> initialize() async {
    if (_initializing) {
      debugPrint(
        '⚠️ PUSH: ya hay una inicialización de Firebase en curso.',
      );
      return;
    }

    _initializing = true;

    try {
      debugPrint('');
      debugPrint('==========================================');
      debugPrint('🔥 PUSH: INICIALIZANDO FIREBASE');
      debugPrint('==========================================');

      if (Firebase.apps.isEmpty) {
        debugPrint('🔥 PUSH: inicializando Firebase...');
        await Firebase.initializeApp();
      } else {
        debugPrint('✅ PUSH: Firebase ya estaba inicializado.');
      }

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      debugPrint('🔔 PUSH: solicitando permisos...');

      final settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
        '🔔 PUSH: autorización = ${settings.authorizationStatus}',
      );

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _available = true;

      _configureListeners();

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          '📨 PUSH: la app se abrió desde una notificación.',
        );

        _openRemoteMessage(initialMessage);
      }

      debugPrint('✅ PUSH: Firebase disponible.');
      debugPrint('==========================================');
      debugPrint('');
    } catch (error, stackTrace) {
      _available = false;

      debugPrint('');
      debugPrint('==========================================');
      debugPrint('❌ PUSH: ERROR INICIALIZANDO FIREBASE');
      debugPrint('Error: $error');
      debugPrint('$stackTrace');
      debugPrint('==========================================');
      debugPrint('');
    } finally {
      _initializing = false;
    }
  }

  /* ============================================================
     LISTENERS DE NOTIFICACIONES
  ============================================================ */

  void _configureListeners() {
    if (_listenersReady) {
      return;
    }

    _listenersReady = true;

    FirebaseMessaging.onMessage.listen(
      (message) {
        final notification = message.notification;

        debugPrint('');
        debugPrint('📨 PUSH: notificación recibida en foreground');
        debugPrint(
          'Título: ${notification?.title ?? 'Ruta Gen'}',
        );
        debugPrint(
          'Mensaje: ${notification?.body ?? ''}',
        );

        _foregroundController.add(
          PushMessage(
            title: notification?.title ?? 'Ruta Gen',
            body:
                notification?.body ??
                'Tenés una nueva notificación.',
            action: _actionFromMessage(message),
          ),
        );
      },
      onError: (Object error) {
        debugPrint(
          '❌ PUSH: error escuchando mensajes foreground: $error',
        );
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        debugPrint(
          '📲 PUSH: usuario abrió una notificación.',
        );

        _openRemoteMessage(message);
      },
      onError: (Object error) {
        debugPrint(
          '❌ PUSH: error al abrir notificación: $error',
        );
      },
    );
  }

  /* ============================================================
     ACCIONES
  ============================================================ */

  String _actionFromMessage(RemoteMessage message) {
    final action =
        (
              message.data['destination'] ??
              message.data['action'] ??
              'NOTIFICATIONS'
            )
            .toString()
            .trim()
            .toUpperCase();

    return action.isEmpty ? 'NOTIFICATIONS' : action;
  }

  void _openRemoteMessage(RemoteMessage message) {
    openAction(
      _actionFromMessage(message),
    );
  }

  void openAction(String action) {
    final cleanAction = action.trim().toUpperCase();

    actionNotifier.value =
        cleanAction.isEmpty ? 'NOTIFICATIONS' : cleanAction;
  }

  String? consumePendingAction() {
    final action = actionNotifier.value;

    actionNotifier.value = null;

    return action;
  }

  /* ============================================================
     VINCULAR PUSH AL USUARIO LOGUEADO
  ============================================================ */

  Future<void> bindToCurrentUser() async {
    debugPrint('');
    debugPrint('==========================================');
    debugPrint('🔥 PUSH: VINCULANDO DISPOSITIVO');
    debugPrint('==========================================');

    try {
      /*
       * Antes simplemente hacíamos:
       *
       * if (!_available) return;
       *
       * Eso hacía que un fallo de Firebase al iniciar la app
       * dejara las notificaciones deshabilitadas silenciosamente.
       *
       * Ahora reintentamos.
       */

      if (!_available) {
        debugPrint(
          '⚠️ PUSH: Firebase no estaba disponible.',
        );

        debugPrint(
          '🔄 PUSH: reintentando inicialización...',
        );

        await initialize();
      }

      if (!_available) {
        debugPrint(
          '❌ PUSH: Firebase sigue sin estar disponible.',
        );

        debugPrint(
          '❌ PUSH: no se registrará este dispositivo.',
        );

        return;
      }

      debugPrint(
        '✅ PUSH: Firebase disponible.',
      );

      debugPrint(
        '📱 PUSH: plataforma = ${Platform.isIOS ? 'IOS' : 'ANDROID'}',
      );

      /*
       * Escuchamos cambios de token ANTES de continuar.
       *
       * De esta forma, si Firebase renueva el token posteriormente,
       * lo mandamos automáticamente al backend.
       */

      await _configureTokenRefreshListener();

      /*
       * iOS necesita primero un token APNs.
       */

      if (Platform.isIOS) {
        debugPrint(
          '🍎 PUSH: esperando token APNs...',
        );

        final apnsReady = await _waitForApnsToken();

        if (!apnsReady) {
          debugPrint(
            '❌ PUSH IOS: APNs todavía no entregó token.',
          );

          debugPrint(
            '⚠️ PUSH IOS: revisar configuración APNs si persiste.',
          );

          return;
        }

        debugPrint(
          '✅ PUSH IOS: token APNs disponible.',
        );
      }

      /*
       * Pedimos token FCM.
       */

      debugPrint(
        '🔥 PUSH: solicitando token FCM...',
      );

      final token =
          await FirebaseMessaging.instance.getToken();

      if (token == null || token.trim().isEmpty) {
        debugPrint(
          '❌ PUSH: Firebase no devolvió token FCM.',
        );

        return;
      }

      final cleanToken = token.trim();

      debugPrint(
        '✅ PUSH: token FCM obtenido.',
      );

      debugPrint(
        '🔑 PUSH TOKEN: ${_maskToken(cleanToken)}',
      );

      /*
       * Registramos token en backend.
       */

      await _registerToken(cleanToken);

      debugPrint(
        '✅ PUSH: dispositivo vinculado correctamente.',
      );
    } catch (error, stackTrace) {
      debugPrint('');
      debugPrint(
        '❌ PUSH: ERROR VINCULANDO DISPOSITIVO',
      );

      debugPrint(
        'Error: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      debugPrint('==========================================');
      debugPrint('');
    }
  }

  /* ============================================================
     TOKEN REFRESH
  ============================================================ */

  Future<void> _configureTokenRefreshListener() async {
    await _tokenSubscription?.cancel();

    _tokenSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        try {
          final cleanToken = newToken.trim();

          if (cleanToken.isEmpty) {
            return;
          }

          debugPrint('');
          debugPrint(
            '♻️ PUSH: Firebase renovó el token.',
          );

          debugPrint(
            '🔑 NUEVO TOKEN: ${_maskToken(cleanToken)}',
          );

          await _registerToken(cleanToken);

          debugPrint(
            '✅ PUSH: nuevo token registrado en backend.',
          );
        } catch (error) {
          debugPrint(
            '❌ PUSH: error registrando token renovado: $error',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          '❌ PUSH: error escuchando cambios de token: $error',
        );
      },
    );
  }

  /* ============================================================
     APNS - IOS
  ============================================================ */

  Future<bool> _waitForApnsToken() async {
    /*
     * Esperamos hasta 15 segundos.
     *
     * A veces iOS tarda algunos segundos después de aceptar
     * los permisos antes de entregar el token APNs.
     */

    const maxAttempts = 30;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        final token =
            await FirebaseMessaging.instance.getAPNSToken();

        if (token != null && token.trim().isNotEmpty) {
          debugPrint(
            '✅ PUSH IOS: APNs entregó token '
            'en intento $attempt/$maxAttempts.',
          );

          debugPrint(
            '🍎 APNS TOKEN: ${_maskToken(token.trim())}',
          );

          return true;
        }
      } catch (error) {
        debugPrint(
          '⚠️ PUSH IOS: error consultando APNs '
          '(intento $attempt/$maxAttempts): $error',
        );
      }

      debugPrint(
        '⏳ PUSH IOS: esperando APNs '
        '($attempt/$maxAttempts)...',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );
    }

    debugPrint(
      '❌ PUSH IOS: APNs no entregó token después de '
      '${maxAttempts ~/ 2} segundos.',
    );

    return false;
  }

  /* ============================================================
     REGISTRAR TOKEN EN BACKEND
  ============================================================ */

  Future<void> _registerToken(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      debugPrint(
        '❌ PUSH: intento de registrar token vacío.',
      );

      return;
    }

    final platform =
        Platform.isIOS ? 'IOS' : 'ANDROID';

    debugPrint('');
    debugPrint(
      '📡 PUSH: registrando dispositivo en backend...',
    );

    debugPrint(
      '📱 Plataforma: $platform',
    );

    debugPrint(
      '🔑 Token: ${_maskToken(cleanToken)}',
    );

    try {
      await _apiClient.post(
        '/notifications/devices',
        body: {
          'token': cleanToken,
          'platform': platform,
        },
      );

      debugPrint(
        '✅ PUSH: POST /notifications/devices OK',
      );
    } catch (error) {
      debugPrint(
        '❌ PUSH: POST /notifications/devices falló.',
      );

      debugPrint(
        '❌ PUSH: $error',
      );

      rethrow;
    }
  }

  /* ============================================================
     DESREGISTRAR AL CERRAR SESIÓN
  ============================================================ */

  Future<void> unregisterCurrentDevice() async {
    debugPrint('');
    debugPrint(
      '🔥 PUSH: desregistrando dispositivo...',
    );

    try {
      if (!_available) {
        debugPrint(
          '⚠️ PUSH: Firebase no disponible al cerrar sesión.',
        );

        await _tokenSubscription?.cancel();
        _tokenSubscription = null;

        return;
      }

      /*
       * En iOS, no necesitamos esperar APNs para desregistrar:
       * usamos el token FCM que ya pueda existir.
       */

      final token =
          await FirebaseMessaging.instance.getToken();

      if (token != null && token.trim().isNotEmpty) {
        final cleanToken = token.trim();

        debugPrint(
          '📡 PUSH: desactivando token en backend...',
        );

        await _apiClient.delete(
          '/notifications/devices',
          body: {
            'token': cleanToken,
          },
        );

        debugPrint(
          '✅ PUSH: dispositivo desregistrado.',
        );
      } else {
        debugPrint(
          '⚠️ PUSH: no había token FCM para desregistrar.',
        );
      }
    } catch (error) {
      debugPrint(
        '❌ PUSH: no se pudo desregistrar el celular: $error',
      );
    } finally {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
    }
  }

  /* ============================================================
     UTILIDAD PARA NO MOSTRAR TOKEN COMPLETO
  ============================================================ */

  String _maskToken(String token) {
    if (token.length <= 24) {
      return token;
    }

    return '${token.substring(0, 12)}...'
        '${token.substring(token.length - 12)}';
  }
}