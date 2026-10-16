# Ruta GEN — revisión previa a publicación

Preparado el 16/10/2026. Este paquete contiene una propuesta de términos y su integración para probar localmente en la app. NO es la versión pública definitiva ni una certificación de cumplimiento. La app validada anteriormente se entrega por separado y no fue reemplazada por este borrador.

## Qué incluye

- Términos generales en 20 apartados: máximo de 70 puntos finales por carga, multiplicadores, vencimiento anual, premios, privacidad, reclamos y sorteos con bases propias.
- Los litros reales del despacho se conservan. El máximo no impide cargar más de 70 litros. Ejemplos: 80 L a 1× = 70 puntos; 40 L a 2× = 70 puntos.
- Ejemplo de 50 finalistas: primero se determina el grupo conforme a las bases; después se selecciona al ganador al azar. No se promete un premio a cada finalista ni al primero del ranking.
- Pantalla de términos y acceso para leerlos durante el registro, antes de aceptar. La fecha de aceptación antigua no se presenta como aceptación de esta nueva versión.
- Ficha de información para redactar las bases particulares de cada sorteo; todavía no es una promoción lista para lanzar.

## 1. Datos del responsable incorporados

Conforme a la información facilitada por el usuario, se incorporó como organizador comercial a MAZARA GEN S.A., sociedad anónima, CUIT 30-71712174-7, con domicilio fiscal y sede informados en Av. Varela 15, piso 11, departamento A, código postal 1406, Ciudad Autónoma de Buenos Aires, República Argentina. Contacto del programa: mazara@grupogen.com.ar. Estaciones: https://grupogen.com.ar. Soporte técnico de la app: lbcodeworks@gmail.com. No se realizó una verificación registral independiente de esos datos. El territorio y responsable de cada promoción deben quedar identificados en sus bases, y la política de privacidad debe identificar al responsable real del tratamiento.

Lucas Battelini informó ser el publicador de la app. Ese dato no basta para asignarle o excluirle responsabilidades por el programa: depende de su intervención, contratos, publicidad y demás hechos. No se lo designó automáticamente como organizador ni se incorporó su CUIT como responsable de los premios. Una cláusula de exención tampoco resuelve esa cuestión.

Apple, además, exige en la regla 5.3.1 que sorteos y concursos sean patrocinados por el desarrollador. Hay que revisar la relación entre el titular de la cuenta de desarrollador y el patrocinador real, con asesoramiento y, si corresponde, consulta a App Review o adecuación de la cuenta. No basta declarar que un tercero organiza si la publicación no cumple esa regla. La regla 5.3.2 exige bases oficiales en la app y aclaración de que Apple no participa; esta última aclaración se agregó al borrador.

## 2. Participación sin compra: falta una solución operativa

El artículo 14 del DNU 274/2019 prohíbe promociones con azar cuya participación esté condicionada total o parcialmente a comprar o contratar. El Decreto 961/2017 establece condiciones de información y participación gratuita que deben revisarse para la promoción y su alcance territorial. No alcanza con escribir «sin obligación de compra».

El motor de ranking revisado suma litros de cargas confirmadas con puntos positivos, de clientes activos y verificados. No se identificó una vía de participación gratuita integrada a ese ranking. Registrarse gratis o verificar el DNI no equivale a poder participar en el sorteo en condiciones efectivas.

Antes de lanzar un sorteo basado en ese ranking debe definirse y habilitarse un mecanismo gratuito compatible con la normativa, o modificar la mecánica con asesoramiento. No se deben inventar cargas o litros para simular participaciones gratuitas. Las reglas, la interfaz y el backend tienen que coincidir. El mecanismo concreto requiere revisión legal; este paquete no lo implementa ni lo da por aprobado.

## 3. Cada sorteo necesita bases completas

Deben fijarse antes del inicio: organizador, ámbito, requisitos, exclusiones, fechas y horas argentinas, mecanismo gratuito, cupo, métrica, desempate, selección aleatoria, cantidad y descripción de premios, probabilidades, comunicación, entrega, gastos y suplentes/premios no adjudicados. Para una moto: modelo, estado, documentación y quién paga patentamiento, impuestos, traslado y demás gastos.

El backend actual permite configurar el cupo (hasta 100), congela las reglas principales al comenzar y selecciona un ganador entre los finalistas mediante `crypto.randomInt`. Usa litros reales, no saldo de puntos. En empates de litros utiliza la fecha de la última carga computada y después el identificador de cuenta. Esta conducta técnica debe revisarse para definir un desempate transparente antes de publicarlo; no equivale necesariamente a «el primero que alcanzó esa cantidad». Con menos elegibles que cupos, usa los elegibles existentes.

El campo de condiciones del backend tiene un límite de 2000 caracteres. Una ficha breve podría no alcanzar para las bases completas: evaluar documento o contenido accesible desde la ficha de la promoción y conservar su versión. Los términos generales no sustituyen las bases ni los permisos que correspondan por jurisdicción. Verificar especialmente la provincia/municipio donde se ofrece la promoción.

Google Play permite determinadas recompensas de fidelización en apps que no son juegos, sujetas a su política y a la ley local. Exige, entre otras condiciones, reglas oficiales accesibles, información sobre probabilidades o método de selección, número fijo de ganadores y plazos de inscripción/adjudicación definidos para cada promoción. La política de la tienda no autoriza una mecánica prohibida por la ley argentina.

## 4. Vencimiento anual: texto existente, automatización pendiente

Los términos anteriores ya establecían vencimiento al 31 de diciembre. Se conservó y aclaró esa regla, con horario argentino y separación entre saldo, historial y ranking.

En el backend revisado NO se identificó el proceso que aplica automáticamente el vencimiento anual. Este paquete NO agrega ese proceso. Antes de afirmar que se reinicia automáticamente, implementar y probar el cierre anual sin borrar historial, sin afectar puntos del nuevo año ni premios ya asignados con otra vigencia. Registrar el ajuste y permitir reconstruir el saldo ante reclamos. Revisar también el aviso anticipado a usuarios y las condiciones originalmente ofrecidas.

## 5. Aceptación, cambios y privacidad

El backend actual conserva `acceptedTermsAt`, pero no identifica la versión aceptada. Para esta actualización conviene guardar versión y fecha de aceptación y presentar los cambios relevantes a usuarios existentes. No convertir una aceptación de registro antigua en aceptación de la versión 0.4. El límite de puntos debe informarse para operaciones futuras, respetando los derechos ya adquiridos.

La política de privacidad debe identificar al responsable real, sus datos de contacto, finalidades, destinatarios, conservación y derechos conforme a la Ley 25.326. Hay una ruta de privacidad en el proyecto (`https://rutagen.com.ar/politica-de-privacidad`); este paquete no certifica el contenido hoy publicado allí. Revisar que coincida con el tratamiento real y con estos términos.

No se incluyeron renuncias generales a derechos del consumidor, permisos ilimitados de imagen ni cambios retroactivos discrecionales. La Ley 24.240 exige información clara y limita las cláusulas abusivas. Una buena redacción debe acompañarse con cumplimiento operativo.

## Cómo probar el borrador localmente

Hacer copia de seguridad. Copiar estos tres archivos respetando las rutas sobre `mobile/ruta_gen_app` (o la raíz real que contiene `pubspec.yaml`):

- `lib/features/account/terms_content.dart` (nuevo).
- `lib/features/account/terms_page.dart` (reemplazo).
- `lib/features/auth/register_page.dart` (reemplazo).

Los reemplazos parten del ZIP móvil validado en esta sesión. Si hubo cambios locales posteriores, comparar antes de reemplazar. El borrador conserva un aviso visible de revisión; los datos del organizador y los contactos ya están completos. Usarlo para revisión local. Antes de publicar hay que resolver los pendientes, confirmar los datos incorporados, revisar legalmente el texto, definir la vigencia y sustituir la identificación de borrador por la versión final. Ocultar el aviso sin resolver lo anterior no completa el trabajo.

Desde la raíz Flutter:

```powershell
flutter analyze --no-pub
flutter test
flutter run
```

Aquí se comprobó la sintaxis de los tres archivos Dart y la integridad del ZIP. No hay Flutter instalado en este entorno, por lo que no se ejecutaron el analizador ni los tests de esta nueva revisión. El usuario ejecutó después el analizador sin incidencias y los 42 tests aprobaron sobre la revisión previa a incorporar los datos de MAZARA GEN S.A. Este último cambio de textos solo tiene comprobación local de sintaxis en este entorno. No se publicaron cambios ni se modificó el backend con este paquete.

## Fuentes oficiales consultadas (16/10/2026)

- DNU 274/2019, artículo 14: https://www.argentina.gob.ar/normativa/nacional/norma-322236/texto
- Decreto 961/2017, promociones y concursos: https://www.argentina.gob.ar/normativa/nacional/norma-291621/texto
- Ley 24.240 actualizada, especialmente artículos 4, 7, 8 y 37: https://www.argentina.gob.ar/normativa/nacional/norma-638/actualizacion
- Ley 25.326: https://www.argentina.gob.ar/normativa/nacional/norma-64790/texto
- AAIP, derechos sobre datos personales: https://www.argentina.gob.ar/aaip/datospersonales/derechos
- Apple App Review Guidelines, 5.3.1 y 5.3.2: https://developer.apple.com/app-store/review/guidelines/
- Google Play, gamified loyalty programs: https://support.google.com/googleplay/android-developer/answer/9877032?hl=en

La revisión de un abogado argentino con experiencia en promociones y consumo debe verificar la mecánica concreta, el organizador, el territorio y las autorizaciones aplicables antes del lanzamiento. Este texto sirve de propuesta de trabajo y no garantiza ausencia de reclamos ni aprobación de las tiendas.
