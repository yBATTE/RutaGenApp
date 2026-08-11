import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final UserModel user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mi cuenta',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          _PointsSummary(user: user),
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Información personal'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _InformationTile(
                  icon: Icons.badge_outlined,
                  title: 'DNI',
                  value: user.dni,
                ),
                const Divider(height: 1),
                _InformationTile(
                  icon: Icons.email_outlined,
                  title: 'Correo electrónico',
                  value: user.email,
                  verified: user.emailVerified,
                ),
                if (user.phone != null &&
                    user.phone!.trim().isNotEmpty) ...[
                  const Divider(height: 1),
                  _InformationTile(
                    icon: Icons.phone_outlined,
                    title: 'Teléfono',
                    value: user.phone!,
                    verified: user.phoneVerified,
                  ),
                ],
                if (user.stationName != null &&
                    user.stationName!.trim().isNotEmpty) ...[
                  const Divider(height: 1),
                  _InformationTile(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Estación',
                    value: user.stationName!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Configuración'),
          const SizedBox(height: 10),
          _AccountOption(
            icon: Icons.person_outline_rounded,
            title: 'Mis datos',
            subtitle: 'Información personal de tu cuenta',
            onTap: () {
              _showComingSoon(
                context,
                'La edición de datos estará disponible próximamente.',
              );
            },
          ),
          _AccountOption(
            icon: Icons.lock_outline_rounded,
            title: 'Seguridad y biometría',
            subtitle: 'Contraseña, huella y Face ID',
            onTap: () {
              _showComingSoon(
                context,
                'La configuración de seguridad estará disponible próximamente.',
              );
            },
          ),
          _AccountOption(
            icon: Icons.star_border_rounded,
            title: 'Estación favorita',
            subtitle: user.stationName ?? 'Seleccioná tu estación habitual',
            onTap: () {
              _showComingSoon(
                context,
                'Próximamente vas a poder elegir tu estación favorita.',
              );
            },
          ),
          _AccountOption(
            icon: Icons.notifications_none_rounded,
            title: 'Notificaciones',
            subtitle: 'Administrá tus avisos',
            onTap: () {
              _showComingSoon(
                context,
                'La configuración de notificaciones estará disponible próximamente.',
              );
            },
          ),
          _AccountOption(
            icon: Icons.description_outlined,
            title: 'Términos y condiciones',
            onTap: () {
              _showComingSoon(
                context,
                'Los términos y condiciones se conectarán próximamente.',
              );
            },
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.blue,
              side: const BorderSide(
                color: AppColors.blue,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Ruta Gen · Versión 0.1.0',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Querés cerrar tu sesión en este dispositivo?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onLogout();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final memberCode = user.memberCode?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.navyDeep,
              AppColors.navy,
            ],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navy,
              child: Text(
                user.initials.isEmpty ? 'RG' : user.initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    memberCode != null && memberCode.isNotEmpty
                        ? 'Socio $memberCode'
                        : 'DNI ${user.dni}',
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Cuenta activa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsSummary extends StatelessWidget {
  const _PointsSummary({
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text(
                'PUNTOS DISPONIBLES',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatPoints(user.pointsBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'puntos',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PointsItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'Acumulados',
                value: user.lifetimePointsEarned,
                color: const Color(0xFF16865A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PointsItem(
                icon: Icons.redeem_rounded,
                label: 'Canjeados',
                value: user.lifetimePointsRedeemed,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PointsItem extends StatelessWidget {
  const _PointsItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatPoints(value),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationTile extends StatelessWidget {
  const _InformationTile({
    required this.icon,
    required this.title,
    required this.value,
    this.verified = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Icon(
        icon,
        color: AppColors.navy,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: verified
          ? const Tooltip(
              message: 'Verificado',
              child: Icon(
                Icons.verified_rounded,
                color: Color(0xFF16865A),
                size: 20,
              ),
            )
          : null,
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Icon(
            icon,
            color: AppColors.navy,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _formatPoints(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}