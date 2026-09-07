# Ruta GEN - integración de fidelización

Esta versión de la app consume el backend con verificación de identidad, premios regalados y beneficios mensuales por visitas.

## Cuenta verificada

`GET /api/auth/me` se interpreta con:

- `identityVerified`
- `identityVerifiedAt`
- `identityVerifiedStationSlug`

Mientras `identityVerified` sea `false`:

- el Home muestra el aviso para presentar el DNI;
- la pestaña Mi QR queda bloqueada desde la navegación;
- el catálogo de premios puede consultarse, pero el backend sigue siendo la autoridad para impedir acreditaciones/canjes.

## Mis premios

Se consume:

`GET /api/rewards/gifts/me`

La pantalla "Mis premios" diferencia premios disponibles e historial, muestra su origen y, cuando está disponible, el QR único `RGP_...` para canjear en Tienda.

Orígenes contemplados:

- `RANDOM`
- `WELCOME`
- `VISIT_BONUS`
- `MANUAL_ADMIN`
- `SYSTEM`

## Visitas mensuales

Se consume:

`GET /api/rewards/visit-progress`

El Home muestra el progreso por Canning 1, Canning 2 y Catania, y enlaza al QR del beneficio cuando el backend lo emite.

## Movimientos

`GET /api/rewards/me` ahora se interpreta distinguiendo:

- `POINTS_REDEMPTION` / `POINTS`
- `GIFT_REWARD` / `GIFT`
- `VISIT_BONUS`

Los regalos aparecen con 0 puntos y no como si fueran un canje por puntos.

## Push

En iOS la app espera el token APNs antes de solicitar el token FCM. Se aceptan acciones de navegación futuras como `GIFT_REWARDS`, `STATIONS` y `MOVEMENTS`, además de las actuales `HOME`, `REWARDS`, `QR` y `NOTIFICATIONS`.
