import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/ruta_gen_logo.dart';
import '../../shared/widgets/section_title.dart';
import '../movements/movements_page.dart';
import '../news/news_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.user,
    required this.onNavigate,
    required this.onRefreshUser,
  });

  final RutaGenRepository repository;
  final UserModel user;
  final ValueChanged<int> onNavigate;
  final Future<void> Function() onRefreshUser;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Movement>> _movements;
  late Future<List<NewsItem>> _news;

  @override
  void initState() {
    super.initState();
    _movements = widget.repository.getMovements();
    _news = widget.repository.getNews(limit: 5);
  }

  Future<void> _refresh() async {
    final movements = widget.repository.getMovements();
    final news = widget.repository.getNews(limit: 5);

    setState(() {
      _movements = movements;
      _news = news;
    });

    await Future.wait<Object?>([
      movements,
      news,
      widget.onRefreshUser(),
    ]);
  }

  String _formatPoints(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

    final parts = text.split('.');
    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    if (parts.length == 1) {
      return integerPart;
    }

    return '$integerPart,${parts.last}';
  }

  void _openMovements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovementsPage(
          repository: widget.repository,
        ),
      ),
    );
  }

  void _openNewsDetail(NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsDetailPage(
          repository: widget.repository,
          initialItem: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.blue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 118,
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              title: const RutaGenLogo(
                compact: true,
              ),
              actions: [
                IconButton(
                  tooltip: 'Notificaciones',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Las notificaciones estarán disponibles próximamente.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                  ),
                ),
              ],
              flexibleSpace: const FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.navyDeep,
                        Color(0xFF074482),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Hola, ${widget.user.firstName}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Este es el resumen de tu cuenta',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PointsCard(
                    user: widget.user,
                    formattedPoints: _formatPoints(
                      widget.user.pointsBalance,
                    ),
                    onRewardsTap: () => widget.onNavigate(3),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.qr_code_2_rounded,
                          label: 'Mi QR',
                          onTap: () => widget.onNavigate(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Premios',
                          onTap: () => widget.onNavigate(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.history_rounded,
                          label: 'Movimientos',
                          onTap: _openMovements,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SectionTitle(
                    'Últimos movimientos',
                    action: 'Ver todas',
                    onTap: _openMovements,
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Movement>>(
                    future: _movements,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 130,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _MessageCard(
                          icon: Icons.cloud_off_rounded,
                          title: 'No pudimos cargar tus movimientos',
                          message:
                              'Deslizá hacia abajo para volver a intentar.',
                          onTap: _refresh,
                        );
                      }

                      final movements = snapshot.data ?? [];

                      if (movements.isEmpty) {
                        return const _MessageCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'Todavía no tenés movimientos',
                          message: 'Tus cargas y canjes aparecerán acá.',
                        );
                      }

                      final recentMovements = movements.take(3).toList();

                      return Column(
                        children: List.generate(
                          recentMovements.length,
                          (index) => Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index == recentMovements.length - 1 ? 0 : 10,
                            ),
                            child: _LatestMovementCard(
                              movement: recentMovements[index],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  SectionTitle('Novedades'),
                  const SizedBox(height: 10),
                  FutureBuilder<List<NewsItem>>(
                    future: _news,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 250,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _MessageCard(
                          icon: Icons.cloud_off_rounded,
                          title: 'No pudimos cargar las novedades',
                          message: 'Deslizá hacia abajo para reintentar.',
                          onTap: _refresh,
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const _MessageCard(
                          icon: Icons.campaign_outlined,
                          title: 'No hay novedades publicadas',
                          message: 'Cuando tengamos algo nuevo, aparecerá acá.',
                        );
                      }

                      return SizedBox(
                        height: 285,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final width = MediaQuery.sizeOf(context).width;
                            return SizedBox(
                              width: width >= 700 ? 360 : width - 62,
                              child: _NewsCard(
                                item: items[index],
                                onTap: () => _openNewsDetail(items[index]),
                              ),
                            );
                          },
                        ),
                      );
                    },
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

class _PointsCard extends StatelessWidget {
  const _PointsCard({
    required this.user,
    required this.formattedPoints,
    required this.onRewardsTap,
  });

  final UserModel user;
  final String formattedPoints;
  final VoidCallback onRewardsTap;

  @override
  Widget build(BuildContext context) {
    final memberCode = user.memberCode?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyDeep,
            Color(0xFF084B90),
            Color(0xFF0878C9),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -25,
            child: Container(
              width: 115,
              height: 115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PUNTOS DISPONIBLES',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$formattedPoints pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      memberCode != null && memberCode.isNotEmpty
                          ? 'Socio $memberCode'
                          : 'Usá tus puntos para canjear premios',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRewardsTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.card_giftcard_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Ver premios',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF0A66C7),
                child: Text(
                  user.initials.isEmpty ? 'RG' : user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LatestMovementCard extends StatelessWidget {
  const _LatestMovementCard({
    required this.movement,
  });

  final Movement movement;

  String _formatDecimal(double? value) {
    if (value == null) return '';

    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return text.replaceAll('.', ',');
  }

  String _details() {
    final station = movement.stationName?.trim();
    final item = movement.productName?.trim();

    if (movement.type == MovementType.redemption) {
      return [
        if (station != null && station.isNotEmpty) station,
        if (item != null && item.isNotEmpty) item,
      ].join('\n');
    }

    final loadData = <String>[
      if (item != null && item.isNotEmpty) item,
      if (movement.liters != null) '${_formatDecimal(movement.liters)} L',
    ].join(' • ');

    return [
      if (station != null && station.isNotEmpty) station,
      if (loadData.isNotEmpty) loadData,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final positive = movement.points >= 0;

    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: positive
                    ? const Color(0xFFE8F3FF)
                    : const Color(0xFFFFEEE8),
                foregroundColor: positive ? AppColors.blue : AppColors.danger,
                child: Icon(
                  movement.type == MovementType.load
                      ? Icons.local_gas_station_rounded
                      : Icons.card_giftcard_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _details(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${positive ? '+' : '-'}${movement.points.abs()}',
                style: TextStyle(
                  color: positive ? AppColors.success : AppColors.danger,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.item,
    required this.onTap,
  });

  final NewsItem item;
  final VoidCallback onTap;

  String _date(DateTime value) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  item.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFE8F3FF),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.blue,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (item.hasDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _date(item.displayDate),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Ver detalle',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 4,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
                  size: 26,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFE8F3FF),
              foregroundColor: AppColors.blue,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              IconButton(
                tooltip: 'Reintentar',
                onPressed: () {
                  onTap!();
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
