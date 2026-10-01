import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({
    super.key,
    required this.acceptedTermsAt,
  });

  final DateTime? acceptedTermsAt;

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
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
            title: 'Vencimiento de puntos',
            content:
                'Los puntos acumulados durante el año calendario tendrán vigencia hasta el 31 de diciembre de ese mismo año a las 23:59 horas. Una vez alcanzado dicho vencimiento, los puntos no utilizados caducarán y dejarán de estar disponibles para canje. Los puntos vencidos no podrán recuperarse, transferirse ni utilizarse posteriormente.',
          ),

          const _TermSection(
            number: '5',
            title: 'Correcciones y controles',
            content:
                'Grupo GEN podrá revisar operaciones cuando existan errores, duplicaciones, inconsistencias, cargas manuales o indicios de uso indebido. Si se comprueba una acreditación incorrecta, el saldo podrá ser corregido dejando registro de la modificación.',
          ),

          const _TermSection(
            number: '6',
            title: 'Uso de los puntos',
            content:
                'Los puntos no representan dinero, no generan intereses y no pueden cambiarse por efectivo. Son personales e intransferibles y no pueden venderse, cederse ni transferirse a otra cuenta o persona.',
          ),

          const _TermSection(
            number: '7',
            title: 'Canje de premios',
            content:
                'Los canjes están sujetos a la cantidad de puntos disponible, al stock del premio y a las condiciones informadas en la aplicación. La visualización de un premio no garantiza su disponibilidad hasta que el canje sea confirmado.',
          ),

          const _TermSection(
            number: '8',
            title: 'Código QR',
            content:
                'El código QR es personal y debe utilizarse únicamente para identificar la cuenta del cliente. No debe compartirse mediante capturas de pantalla, mensajes u otros medios. Ruta Gen podrá renovar o invalidar códigos cuando sea necesario por razones de seguridad.',
          ),

          const _TermSection(
            number: '9',
            title: 'Seguridad y biometría',
            content:
                'La huella o Face ID se procesa localmente mediante los mecanismos de seguridad del dispositivo. Ruta Gen no recibe ni almacena imágenes de huellas o rostros. La biometría solamente se utiliza para autorizar el acceso a las credenciales protegidas en el dispositivo.',
          ),

          const _TermSection(
            number: '10',
            title: 'Datos personales',
            content:
                'Los datos proporcionados podrán utilizarse para administrar la cuenta, acreditar puntos, registrar canjes, prevenir operaciones irregulares, brindar soporte y comunicar información relacionada con Ruta Gen. El usuario podrá solicitar la actualización, corrección o supresión de sus datos mediante los canales oficiales, sujeto a las obligaciones legales de conservación aplicables.',
          ),

          const _TermSection(
            number: '11',
            title: 'Disponibilidad',
            content:
                'Ruta Gen puede presentar interrupciones temporales por mantenimiento, conectividad, actualizaciones o causas externas. Cuando una operación no pueda completarse normalmente, podrán utilizarse mecanismos de contingencia sujetos a revisión.',
          ),

          const _TermSection(
            number: '12',
            title: 'Suspensión de cuentas',
            content:
                'Una cuenta podrá ser bloqueada o deshabilitada ante uso fraudulento, manipulación de operaciones, incumplimiento de estos términos o riesgos para la seguridad del programa. El usuario podrá comunicarse con Grupo GEN para solicitar información sobre su situación.',
          ),

          const _TermSection(
            number: '13',
            title: 'Cambios en el programa',
            content:
                'Grupo GEN podrá actualizar las reglas del programa, los beneficios, las equivalencias de puntos y estos términos. Los cambios importantes serán informados mediante la aplicación o por los canales disponibles antes de entrar en vigencia cuando corresponda.',
          ),

          const _TermSection(
            number: '14',
            title: 'Derechos del consumidor',
            content:
                'Estos términos no limitan los derechos reconocidos por la normativa argentina aplicable en materia de defensa del consumidor, protección de datos personales y demás derechos que correspondan al usuario.',
          ),

          const SizedBox(height: 18),

          const Center(
            child: Text(
              'Ruta Gen · Términos versión 0.2\n'
              'Última actualización: 21/09/2026',
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
        color: accepted
            ? const Color(0xFFEAF8F1)
            : const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accepted
              ? const Color(0xFF16865A).withValues(
                  alpha: 0.25,
                )
              : const Color(0xFFD98A00).withValues(
                  alpha: 0.25,
                ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            accepted
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: accepted
                ? const Color(0xFF16865A)
                : const Color(0xFFD98A00),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              accepted
                  ? 'Aceptaste los términos el $formattedDate.'
                  : 'No encontramos registrada la fecha de aceptación.',
              style: TextStyle(
                color: accepted
                    ? const Color(0xFF126C49)
                    : const Color(0xFF8A5A00),
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