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
  await Firebase.initializeApp();
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
  StreamSubscription<String>? _tokenSubscription;

  Stream<PushMessage> get foregroundMessages =>
      _foregroundController.stream;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
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
        _openRemoteMessage(initialMessage);
      }
    } catch (error) {
      _available = false;
      debugPrint(
        'Firebase todavía no está configurado: $error',
      );
    }
  }

  void _configureListeners() {
    if (_listenersReady) return;
    _listenersReady = true;

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      _foregroundController.add(
        PushMessage(
          title: notification?.title ?? 'Ruta Gen',
          body: notification?.body ?? 'Tenés una nueva notificación.',
          action: _actionFromMessage(message),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
      _openRemoteMessage,
    );
  }

  String _actionFromMessage(RemoteMessage message) {
    final action = (
      message.data['destination'] ??
          message.data['action'] ??
          'NOTIFICATIONS'
    ).toString().trim().toUpperCase();

    return action.isEmpty ? 'NOTIFICATIONS' : action;
  }

  void _openRemoteMessage(RemoteMessage message) {
    openAction(_actionFromMessage(message));
  }

  void openAction(String action) {
    actionNotifier.value = action.trim().toUpperCase();
  }

  String? consumePendingAction() {
    final action = actionNotifier.value;
    actionNotifier.value = null;
    return action;
  }

  Future<void> bindToCurrentUser() async {
    if (!_available) return;

    try {
      if (Platform.isIOS) {
        await _waitForApnsToken();
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _registerToken(token);
      }

      await _tokenSubscription?.cancel();
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) {
          _registerToken(newToken).catchError((_) {});
        },
      );
    } catch (error) {
      debugPrint('No se pudo registrar el celular para push: $error');
    }
  }


  Future<void> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 12; attempt += 1) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null && token.trim().isNotEmpty) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    debugPrint(
      'APNs todavía no entregó un token. FCM volverá a intentarlo al refrescar el token.',
    );
  }

  Future<void> _registerToken(String token) async {
    await _apiClient.post(
      '/notifications/devices',
      body: {
        'token': token,
        'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
      },
    );
  }

  Future<void> unregisterCurrentDevice() async {
    if (!_available) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _apiClient.delete(
          '/notifications/devices',
          body: {
            'token': token,
          },
        );
      }
    } catch (error) {
      debugPrint('No se pudo desregistrar el celular: $error');
    } finally {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
    }
  }
}
