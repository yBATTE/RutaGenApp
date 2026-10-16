import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'terms_content.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({
    super.key,
    required this.acceptedTermsAt,
    this.showAcceptance = true,
  });

  final DateTime? acceptedTermsAt;
  final bool showAcceptance;

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
          if (rutaGenTermsIsDraft) const _DraftNotice(),
          if (showAcceptance) _AcceptanceCard(
            acceptedTermsAt: acceptedTermsAt,
            formattedDate: acceptedTermsAt == null
                ? null
                : _formatDate(
                    acceptedTermsAt!,
                  ),
          ),
          const SizedBox(height: 22),
          for (final section in rutaGenTermsSections)
            _TermSection(number: section.number, title: section.title, content: section.content),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Ruta GEN · Términos versión $rutaGenTermsVersion\n'
              'Preparado el $rutaGenTermsUpdatedAt',
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

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 14),
    child: Card(
      color: Color(0xFFFFF5E6),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('BORRADOR PARA REVISIÓN. Datos del organizador completados. Falta validar las bases de cada sorteo, su forma de participación gratuita y los pendientes operativos antes de publicar esta versión.',
          style: TextStyle(color: Color(0xFF8A5A00), height: 1.4)),
      ),
    ),
  );
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
            accepted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: accepted ? const Color(0xFF16865A) : const Color(0xFFD98A00),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              accepted
                  ? 'Registro de aceptación de tu cuenta: $formattedDate. Esta fecha no confirma por sí sola la aceptación de una versión posterior.'
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
