# Ruta Gen - base Flutter

Base visual de la app de fidelización para clientes de Grupo GEN. Incluye login,
registro, inicio, QR personal, premios, detalle/canje, movimientos, estaciones y
cuenta. Actualmente usa datos de demostración para poder recorrer todo el flujo.

## Crear las carpetas nativas (una sola vez)

Esta entrega mantiene el código fuente limpio y liviano. Con Flutter instalado,
abrí una terminal dentro de esta carpeta y ejecutá:

```bash
flutter create . --org com.grupogen --platforms=android,ios
flutter pub get
flutter run
```

En Windows podés probar Android. Para compilar iOS, usá la misma carpeta en una
Mac con Xcode.

## Acceso de demostración

- DNI o correo: cualquier valor
- Contraseña: cualquier valor

También funciona el botón de biometría simulada.

## Conectar el backend

1. Cambiar `AppConfig.apiBaseUrl` en `lib/core/config/app_config.dart`.
2. Sustituir `MockRutaGenRepository` por `ApiRutaGenRepository` en `main.dart`.
3. Completar los endpoints reales en `lib/data/api_ruta_gen_repository.dart`.

La interfaz consume el contrato `RutaGenRepository`, por lo que se puede migrar
pantalla por pantalla sin modificar el diseño.
