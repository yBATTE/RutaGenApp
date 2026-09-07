# Ruta GEN — Registro, navegación y sesión

## Corrección

El backend proporcionado confirma el registro con data.user, sin data.qrToken.
La app exigía ese QR y lanzaba un error después de haber creado la cuenta.
Ahora, después de un alta confirmada, utiliza el login existente y guarda el
accessToken en FlutterSecureStorage con la misma clave access_token.

El usuario devuelto por ese login pasa al estado de RutaGenApp. Se cierra la ruta
de registro una sola vez y se muestra el AppShell existente, con la pestaña Inicio
(index 0). No se agrega otro sistema de sesión, router o repositorio de usuarios.
No se necesita un segundo /auth/me para completar el alta.

Al reabrir o volver del segundo plano, si no está habilitada la biometría, se usa
restoreSession y /auth/me con el token guardado. Antes se borraba ese token.
Si hay biometría configurada, se conserva el requisito de autenticarse con ella.
Un token rechazado (401/403) se elimina; un fallo transitorio de red no lo borra.
No se habilita acceso offline ni se elude una cuenta bloqueada/deshabilitada.

La biometría se puede configurar después desde el login; ya no se presenta un
paso opcional antes de entrar al inicio tras registrarse. Sus fallos y los del
registro de notificaciones no invalidan un login exitoso.

## Errores y navegación

- Validaciones del formulario, términos y errores del backend conservados.
- Un error de registro no intenta iniciar sesión.
- Si el alta está confirmada pero falla el login/guardado de token, el botón pasa
  a Ingresar a mi cuenta. Reintenta login, no crea otra cuenta.
- Se bloquean envíos simultáneos y la salida con Atrás durante la solicitud.
- Al completar, se habilita el cierre de la ruta y se emite un solo callback.
- Si se pierde la respuesta del propio POST /auth/register, el resultado puede
  ser incierto: no se hacen reintentos automáticos. Se debe probar el login con
  esos datos antes de repetir un alta. El backend conserva su control de duplicados.

## Archivos modificados

- lib/services/auth_service.dart: alta sin dependencia del QR, login y error de
  alta ya confirmada; biometría opcional; cliente inyectable para las pruebas.
- lib/services/api_client.dart: constructor de pruebas para sustituir sólo HTTP.
  El almacenamiento seguro y el protocolo de producción son los existentes.
- lib/features/auth/register_page.dart: entrada directa, protección contra
  duplicados, recuperación de login y navegación con usuario autenticado.
- lib/features/auth/login_page.dart: reutiliza el usuario validado, bloqueo de
  doble envío y tolerancia a fallos opcionales de biometría.
- lib/app.dart: recibe al usuario, abre AppShell y restaura sesión al reabrir
  sin borrarla por no tener biometría.
- test/widget_test.dart: prepara almacenamiento simulado y espera al inicio.
- test/auth_flow_test.dart: cinco casos de alta, errores y restauración.
- test/register_navigation_test.dart: dos casos de navegación única y reintento.

No se cambiaron dependencias, versión de publicación, configuración Firebase,
archivos Android/iOS, recursos, HomePage, AppShell, modelos ni restricciones de
identidad. Se comprobó igualdad byte a byte contra el ZIP original para esos
archivos. Home mantiene el aviso de DNI cuando identityVerified es false.

## Validaciones ejecutadas y límites

- dart format ejecutado correctamente sobre los cinco archivos Dart modificados
  y las pruebas (8 archivos). Eso valida sintaxis/formato, no tipos ni ejecución.
- Comparación de archivos contra ruta-gen-mobile-20260907-115532.zip completada.
- Integridad ZIP y presencia de todos los archivos originales comprobadas.
- Flutter analyze, flutter test y builds Android/iOS NO ejecutados.
  Se intentó preparar Flutter 3.47.2, pero la revisión automática de seguridad
  bloqueó el proceso por un acceso a un endpoint interno de metadatos. Se detuvo
  la preparación y no se eludió el bloqueo. Las pruebas incluidas no se presentan
  como aprobadas. Tampoco se hicieron altas reales ni modificaciones en el backend.

## Aplicar y probar

Este ZIP contiene todo el proyecto recibido más las correcciones. Extraer y copiar
sobre el proyecto local, conservando los archivos locales que no fueron enviados:
por ejemplo claves de firma, key.properties y local.properties. No eliminar esos
archivos ni cambiar la identidad de las aplicaciones.

Con el Flutter habitual de la PC:
flutter pub get
flutter analyze
flutter test
flutter run

Primera prueba real:
1. Crear una cuenta nueva de prueba; debe entrar automáticamente en Inicio.
2. Debe verse el aviso de verificación del DNI pendiente.
3. Cerrar y abrir la app sin biometría; debe restaurar la sesión si el token sigue
   válido. Repetir con biometría activada y comprobar que exige identificación.
4. Comprobar login normal, salir y volver a entrar, QR y apertura de notificaciones.
5. Para publicar en las tiendas, usar la configuración/versionado de publicación
   local. El ZIP original configura Android release con firma debug; esta entrega
   no cambia claves ni prepara una publicación.
