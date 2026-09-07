# Firebase Cloud Messaging - Ruta GEN

El proyecto ya contiene los archivos nativos registrados para:

- Android: `com.grupogen.ruta_gen_app`
- iOS: `com.grupogen.rutaGenApp`

Ubicaciones:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Antes de compilar ejecutar:

```powershell
flutter clean
flutter pub get
```

## Android

El proyecto ya utiliza `firebase_core`, `firebase_messaging` y el plugin `com.google.gms.google-services`.

En Android 13 o superior Firebase Messaging solicitará el permiso de notificaciones desde la app.

## iOS

En Firebase debe estar cargada la APNs Authentication Key `.p8` para desarrollo y producción.

En la Mac abrir `ios/Runner.xcworkspace` y verificar en Runner > Signing & Capabilities:

- Push Notifications
- Background Modes > Remote notifications

El `Info.plist` ya incluye `remote-notification`.

La app espera a que exista el token APNs antes de registrar el token FCM en el backend.

## Backend

Después del login la app registra el token en:

`POST /api/notifications/devices`

con plataforma `ANDROID` o `IOS`.
