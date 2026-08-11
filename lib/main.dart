import 'package:flutter/material.dart';

import 'app.dart';
import 'data/api_ruta_gen_repository.dart';
import 'services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    RutaGenApp(
      repository: ApiRutaGenRepository(
        apiClient: ApiClient.instance,
      ),
    ),
  );
}