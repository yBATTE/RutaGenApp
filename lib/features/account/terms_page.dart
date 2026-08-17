import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({
    super.key,
    required this.acceptedTermsAt,
  });

  final DateTime? acceptedTermsAt;

  static final Uri _personalDataLawUrl = Uri.parse(
    'https://www.argentina.gob.ar/normativa/nacional/ley-25326-64790/actualizacion',
  );

  static final Uri _consumerLawUrl = Uri.parse(
    'https://www.argentina.gob.ar/normativa/nacional/ley-24240-638/actualizacion',
  );

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');

    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  Future<void> _openUrl(
    BuildContext context,
    Uri url,
  ) async {
    final opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el enlace.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Términos y condiciones',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          36,
        ),
        children: [
          const _TermsHeader(),
          const SizedBox(height: 14),
          _AcceptanceCard(
            acceptedTermsAt: acceptedTermsAt,
            formattedDate: acceptedTermsAt == null
                ? null
                : _formatDate(
                    acceptedTermsAt!,
                  ),
          ),
          const SizedBox(height: 22),
          const _TermSection(
            number: '1',
            title: 'Objeto',
            content:
                'Ruta Gen es un programa de fidelización destinado a clientes de las estaciones participantes de Grupo GEN. La aplicación permite consultar puntos, movimientos, novedades, premios disponibles y generar códigos QR para operar dentro del programa.',
          ),
          const _TermSection(
            number: '2',
            title: 'Registro y cuenta',
            content:
                'Para utilizar Ruta Gen, la persona debe registrarse proporcionando información verdadera, completa y actualizada. Cada cuenta es personal y no debe compartirse con terceros. El usuario es responsable de mantener protegida su contraseña y los métodos biométricos configurados en su dispositivo.',
          ),
          const _TermSection(
            number: '3',
            title: 'Acumulación de puntos',
            content:
                'Los puntos podrán acreditarse por compras, cargas de combustible, promociones u otras acciones informadas por Grupo GEN. La cantidad de puntos dependerá de las reglas vigentes al momento de cada operación. La acreditación puede requerir la identificación del cliente mediante su código QR.',
          ),
          const _TermSection(
            number: '4',
            title: 'Correcciones y controles',
            content:
                'Grupo GEN podrá revisar operaciones cuando existan errores, duplicaciones, inconsistencias, cargas manuales o indicios de uso indebido. Si se comprueba una acreditación incorrecta, el saldo podrá ser corregido dejando registro de la modificación.',
          ),
          const _TermSection(
            number: '5',
            title: 'Uso de los puntos',
            content:
                'Los puntos no representan dinero, no generan intereses y no pueden cambiarse por efectivo. Son personales y no pueden venderse ni transferirse, salvo que una promoción indique expresamente lo contrario.',
          ),
          const _TermSection(
            number: '6',
            title: 'Canje de premios',
            content:
                'Los canjes están sujetos a la cantidad de puntos disponible, al stock del premio y a las condiciones informadas en la aplicación. La visualización de un premio no garantiza su disponibilidad hasta que el canje sea confirmado.',
          ),
          const _TermSection(
            number: '7',
            title: 'Código QR',
            content:
                'El código QR es personal y debe utilizarse únicamente para identificar la cuenta del cliente. No debe compartirse mediante capturas de pantalla, mensajes u otros medios. Ruta Gen podrá renovar o invalidar códigos cuando sea necesario por razones de seguridad.',
          ),
          const _TermSection(
            number: '8',
            title: 'Seguridad y biometría',
            content:
                'La huella o Face ID se procesa localmente mediante los mecanismos de seguridad del dispositivo. Ruta Gen no recibe ni almacena imágenes de huellas o rostros. La biometría solamente se utiliza para autorizar el acceso a las credenciales protegidas en el dispositivo.',
          ),
          const _TermSection(
            number: '9',
            title: 'Datos personales',
            content:
                'Los datos proporcionados podrán utilizarse para administrar la cuenta, acreditar puntos, registrar canjes, prevenir operaciones irregulares, brindar soporte y comunicar información relacionada con Ruta Gen. El usuario podrá solicitar la actualización, corrección o supresión de sus datos mediante los canales oficiales, sujeto a las obligaciones legales de conservación aplicables.',
          ),
          const _TermSection(
            number: '10',
            title: 'Disponibilidad',
            content:
                'Ruta Gen puede presentar interrupciones temporales por mantenimiento, conectividad, actualizaciones o causas externas. Cuando una operación no pueda completarse normalmente, podrán utilizarse mecanismos de contingencia sujetos a revisión.',
          ),
          const _TermSection(
            number: '11',
            title: 'Suspensión de cuentas',
            content:
                'Una cuenta podrá ser bloqueada o deshabilitada ante uso fraudulento, manipulación de operaciones, incumplimiento de estos términos o riesgos para la seguridad del programa. El usuario podrá comunicarse con Grupo GEN para solicitar información sobre su situación.',
          ),
          const _TermSection(
            number: '12',
            title: 'Cambios en el programa',
            content:
                'Grupo GEN podrá actualizar las reglas del programa, los beneficios, las equivalencias de puntos y estos términos. Los cambios importantes serán informados mediante la aplicación o por los canales disponibles antes de entrar en vigencia cuando corresponda.',
          ),
          const _TermSection(
            number: '13',
            title: 'Derechos del consumidor',
            content:
                'Estos términos no limitan los derechos reconocidos por la normativa argentina de defensa del consumidor y protección de datos personales.',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.blue,
                  ),
                  title: const Text(
                    'Protección de datos personales',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Consultar Ley 25.326',
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                  ),
                  onTap: () => _openUrl(
                    context,
                    _personalDataLawUrl,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.blue,
                  ),
                  title: const Text(
                    'Defensa del consumidor',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Consultar Ley 24.240',
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                  ),
                  onTap: () => _openUrl(
                    context,
                    _consumerLawUrl,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'Ruta Gen · Términos versión 0.1\nÚltima actualización: 17/08/2026',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsHeader extends StatelessWidget {
  const _TermsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyDeep,
            AppColors.navy,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            color: AppColors.cyan,
            size: 34,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Condiciones de uso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Leé las condiciones aplicables al uso de Ruta Gen, la acumulación de puntos y el canje de premios.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptanceCard extends StatelessWidget {
  const _AcceptanceCard({
    required this.acceptedTermsAt,
    required this.formattedDate,
  });

  final DateTime? acceptedTermsAt;
  final String? formattedDate;

  @override
  Widget build(BuildContext context) {
    final accepted = acceptedTermsAt != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: accepted ? const Color(0xFFEAF8F1) : const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accepted
              ? const Color(0xFF16865A).withValues(alpha: 0.25)
              : const Color(0xFFD98A00).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            accepted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: accepted ? const Color(0xFF16865A) : const Color(0xFFD98A00),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              accepted
                  ? 'Aceptaste los términos el $formattedDate.'
                  : 'No encontramos registrada la fecha de aceptación.',
              style: TextStyle(
                color: accepted
                    ? const Color(
                        0xFF126C49,
                      )
                    : const Color(
                        0xFF8A5A00,
                      ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  const _TermSection({
    required this.number,
    required this.title,
    required this.content,
  });

  final String number;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(
                  0xFFE8F3FF,
                ),
                foregroundColor: AppColors.blue,
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      content,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
