import 'package:flutter/material.dart';

import 'app.dart';
import 'data/api_ruta_gen_repository.dart';
import 'services/api_client.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PushNotificationService.instance.initialize();

  runApp(
    RutaGenApp(
      repository: ApiRutaGenRepository(
        apiClient: ApiClient.instance,
      ),
    ),
  );
}
