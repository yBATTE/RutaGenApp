# Ruta GEN — App Flutter 1.0.3+6

Cambios preparados sobre la app enviada el 16/10/2026 a las 09:42. Requiere el backend actualizado en esta conversación.

## Aplicar en tu proyecto

1. Cerrá la ejecución de Flutter con Ctrl+C si está abierta y conservá una copia de tu proyecto actual.
2. Extraé este ZIP. Copiá el contenido de `lib`, `test` y el archivo `pubspec.yaml` sobre los correspondientes de:

   `C:\Users\lucki\Desktop\Ruta Gen\mobile\ruta_gen_app`

   Aceptá reemplazar archivos. No hace falta borrar la carpeta del proyecto ni ejecutar los scripts antiguos `Aplicar-*.ps1`.
3. Se conservan las dependencias y los archivos nativos Android/iOS de tu app. No se modificaron las configuraciones de Firebase ni la URL del backend.
4. La versión queda en `1.0.3+6`, incrementando el número de compilación de 5 a 6.

## Verificar y ejecutar en tu PC

```powershell
Set-Location "$env:USERPROFILE\Desktop\Ruta Gen\mobile\ruta_gen_app"
flutter pub get
flutter analyze
flutter test
```

Revisá esos resultados antes de generar una compilación para distribuir.

Para abrirla en un emulador o dispositivo conectado:

```powershell
flutter devices
flutter run
```

Para generar la APK, después de verificar los resultados y probar el circuito:

```powershell
flutter build apk --release
```

Resultado habitual: `build\app\outputs\flutter-apk\app-release.apk`.

## Cambios realizados

### Inicio y novedades

- Los avisos para completar DNI y verificar identidad aparecen arriba de las novedades.
- El aviso de DNI mantiene el acceso al formulario para completarlo. Después de guardarlo pasa a explicar la verificación presencial.
- La explicación indica que se puede presentar DNI físico o digital al personal de una estación.
- El carrusel se mantiene y sus imágenes se muestran en recuadros 1:1, con el título debajo. Se elimina el texto y el sombreado superpuestos al diseño.
- Las imágenes se ajustan completas con `BoxFit.contain`: si una imagen antigua es rectangular, quedan márgenes en vez de recortarla o deformarla.
- El listado de novedades usa el mismo diseño.
- El detalle muestra la imagen original completa; tocarla abre una vista de pantalla completa con zoom.

### Movimientos y regalos

- La app solicita `GET /api/rewards/me?giftEvents=true` para obtener recepción y canje como eventos separados, tal como quedó preparado en el backend.
- “Premio recibido”: muestra el premio y su estado actual, incluyendo disponible, ya canjeado, vencido o cancelado.
- “Regalo canjeado”: muestra la estación y la fecha/hora real del canje, con ícono de confirmación.
- Los regalos dicen “Gratis” en vez de “0 pts”, tanto en el inicio como en movimientos.
- En “Mis premios” y en el detalle también se indica “Gratis”. El detalle del regalo incluye fecha/hora del canje y estación.
- Las fechas del regalo se muestran en horario de Argentina.
- Un regalo cuyo vencimiento ya pasó no se presenta como disponible ni muestra el QR, aunque su estado guardado todavía sea AVAILABLE.
- No se calculan puntos ni se acreditan regalos desde el teléfono. Esas operaciones siguen a cargo del backend.

### Abrir el premio desde una notificación

- Se conserva `giftId` al abrir una notificación con la app cerrada, en segundo plano o usando el botón “Ver” de un aviso recibido con la app abierta.
- El historial de notificaciones también conserva el ID del regalo al marcar el aviso como leído y abrirlo.
- Se consulta `GET /api/rewards/gifts/me/:giftId` con la sesión del cliente. Así no se depende de que el premio esté entre los primeros 100 del listado.
- Se abre el detalle del regalo correcto, con su QR si sigue disponible, o el estado de canje si ya fue utilizado.
- Si falla la apertura, se muestra un aviso con “Reintentar”. Un rechazo del backend no se reemplaza por un QR de otra cuenta.
- Los avisos antiguos sin `giftId` siguen abriendo el listado de premios.

### Café de primera carga

La app muestra el título y el mensaje enviados por el backend. Las nuevas notificaciones usan el texto actualizado en la etapa anterior:

> ¡Felicitaciones por tu primera carga con Ruta GEN! Te regalamos un café. ☕ Acercate a la tienda y presentá el QR de tu regalo para canjearlo.

No se reescriben las notificaciones antiguas ya guardadas.

### Puntos y vendedores

- Las condiciones del cartel de multiplicadores indican el máximo final de 70 puntos por carga, después del multiplicador. El valor se toma del backend; el cálculo y los litros reales siguen en el servidor.
- El control de rol ya existía en el login y en la restauración de sesión: la app solo acepta CUSTOMER activo. Se conserva y el mensaje ahora dirige a los vendedores al sistema de Playa.
- El backend mantiene el bloqueo por rol. Esta actualización no identifica a un vendedor que se registre por separado con otra cuenta de cliente.

## Verificación y límites de esta entrega

- Se revisó la sintaxis de todos los archivos Dart con un parser de Dart; no se encontraron errores de sintaxis.
- Se contrastaron rutas, parámetros y campos con el backend entregado en esta conversación.
- Se comprobó que no se modificaran archivos nativos ni dependencias.
- Se agregó `test/gift_updates_test.dart`, con casos para eventos de regalos, fechas, consulta del premio por ID, rol vendedor, datos de notificación, regalos vencidos, valor Gratis y reintento de apertura.
- **Este entorno no dispone del SDK de Flutter ni Dart. No se ejecutaron `flutter analyze`, `flutter test`, la compilación ni el emulador.** La revisión de sintaxis no reemplaza esas comprobaciones. Los comandos de arriba deben ejecutarse en tu PC.
- No se generó una APK ni se enviaron notificaciones reales.

## Circuito para probar

1. Ingresar con un cliente sin DNI: comprobar que el aviso aparezca antes de Novedades y que abra el formulario.
2. Completar DNI sin verificar todavía: comprobar el aviso de verificación presencial y el acceso a las estaciones.
3. Verificar la cuenta desde Tienda y actualizar el inicio: el aviso debe desaparecer.
4. Recorrer varias novedades y abrir una imagen: no debe recortarse el diseño y el título debe quedar debajo.
5. Crear una campaña pequeña desde el panel. Comprobar que solo el ganador reciba el aviso.
6. Tocar el aviso con la app cerrada y con la app abierta; repetir desde el historial. Debe abrir el regalo correcto.
7. Canjearlo en Tienda y actualizar movimientos: deben verse la recepción y el canje, Gratis, estación y la hora correspondiente.
8. Confirmar que no se pueda utilizar el QR una segunda vez; esa validación se hace en el backend.
9. Probar credenciales de vendedor: la app de clientes debe rechazarlas y Playa debe seguir funcionando.
10. En una carga de más de 70 litros o con multiplicador, comprobar que saldo y movimiento reflejen el tope definido por el backend, conservando los litros reales.

## Revisión posterior a las pruebas en tu PC

La salida recibida de Flutter confirmó 42 pruebas correctas. El analizador informó siete sugerencias de const y una advertencia de aserción de no nulidad innecesaria. Esta revisión aplica las correcciones correspondientes en `home_page.dart`, `news_detail_page.dart` e `identity_verification_banner.dart`. No se modifica la versión 1.0.3+6. Volvé a ejecutar `flutter analyze --no-pub` para confirmar que no queden avisos.
