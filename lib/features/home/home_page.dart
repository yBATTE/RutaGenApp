import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/identity_verification_banner.dart';
import '../../shared/widgets/points_promotion_banner.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_quick_actions.dart';
import '../../shared/widgets/visit_progress_card.dart';
import '../movements/movements_page.dart';
import '../news/news_detail_page.dart';
import '../news/news_list_page.dart';
import '../news/news_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.refreshVersion = 0,
    required this.repository,
    required this.user,
    required this.onNavigate,
    required this.onRefreshUser,
    required this.onOpenNotifications,
    required this.unreadNotifications,
    required this.onOpenGiftRewards,
    required this.onCompleteDni,
    this.isActive = true,
  });

  final bool isActive;
  final int refreshVersion;
  final RutaGenRepository repository;
  final UserModel user;
  final ValueChanged<int> onNavigate;
  final Future<void> Function() onRefreshUser;
  final VoidCallback onOpenNotifications;
  final int unreadNotifications;
  final VoidCallback onOpenGiftRewards;
  final VoidCallback onCompleteDni;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Movement>> _movements;
  late Future<List<NewsItem>> _news;
  late Future<VisitProgress> _visitProgress;
  int _promotionRefreshVersion = 0;

  // Sliver children subscribe when they enter the viewport. Attach an error
  // listener immediately so a fast failure offscreen is still handled; the
  // original future retains its result/error for its FutureBuilder.
  Future<T> _observe<T>(Future<T> future) {
    future.ignore();
    return future;
  }

  @override
  void initState() {
    super.initState();
    _movements = _observe(widget.repository.getMovements());
    _news = _observe(widget.repository.getNews(limit: 5));
    _visitProgress = _observe(widget.repository.getVisitProgress());
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion ||
        (!oldWidget.isActive && widget.isActive) ||
        oldWidget.user.pointsBalance != widget.user.pointsBalance ||
        oldWidget.user.identityVerified != widget.user.identityVerified) {
      _movements = _observe(widget.repository.getMovements());
      _news = _observe(widget.repository.getNews(limit: 5));
      _visitProgress = _observe(widget.repository.getVisitProgress());
    }
  }

  Future<void> _refresh() async {
    for (final path in [
      '/auth/me',
      '/loads/me',
      '/rewards',
      '/users/me/point-adjustments',
      '/news',
      '/points/promotion',
      '/draws',
    ]) {
      ApiClient.instance.invalidateCache(path);
    }
    final movements = _observe(widget.repository.getMovements());

    final news = _observe(widget.repository.getNews(limit: 5));

    final visitProgress = _observe(widget.repository.getVisitProgress());

    setState(() {
      _promotionRefreshVersion++;
      _movements = movements;
      _news = news;
      _visitProgress = visitProgress;
    });

    try {
      await Future.wait<Object?>([
        movements,
        news,
        visitProgress,
        widget.onRefreshUser(),
      ]);
    } catch (_) {
      // Each section keeps its retry/error UI; finish the refresh gesture.
    }
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
    final horizontalPadding =
        math.max(18.0, (MediaQuery.sizeOf(context).width - 720) / 2);
    return Scaffold(
      backgroundColor: const Color(0xFF032A46),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.darkBackgroundOverlay,
        child: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: AppColors.ice,
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.blue,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: HomeHero(
                      firstName: widget.user.firstName,
                      formattedPoints: _formatPoints(widget.user.pointsBalance),
                      unreadNotifications: widget.unreadNotifications,
                      onOpenNotifications: widget.onOpenNotifications,
                      onRewardsTap: () => widget.onNavigate(3),
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      6,
                      horizontalPadding,
                      28,
                    ),
                    sliver: SliverList.list(
                      children: [
                        if (widget.user.dni.trim().isEmpty ||
                            !widget.user.identityVerified) ...[
                          IdentityVerificationBanner(
                            needsDni: widget.user.dni.trim().isEmpty,
                            onCompleteDni: widget.onCompleteDni,
                            onViewStations: () => widget.onNavigate(1),
                          ),
                          const SizedBox(height: 16),
                        ],
                        HomeSectionTitle(
                          'Novedades',
                          action: 'Ver todas ›',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  NewsListPage(repository: widget.repository),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<NewsItem>>(
                          future: _news,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 148,
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
                                message:
                                    'Cuando tengamos algo nuevo, aparecerá acá.',
                              );
                            }

                            return NewsCarousel(
                              items: items,
                              onOpen: _openNewsDetail,
                            );
                          },
                        ),
                        PointsPromotionBanner(
                          repository: widget.repository,
                          isActive: widget.isActive,
                          refreshVersion: _promotionRefreshVersion,
                        ),
                        const SizedBox(height: 18),
                        HomeQuickActions(
                          onQr: () => widget.onNavigate(2),
                          onRewards: () => widget.onNavigate(3),
                          onMovements: _openMovements,
                        ),
                        const SizedBox(height: 22),
                        if (widget.user.identityVerified)
                          FutureBuilder<VisitProgress>(
                            future: _visitProgress,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 24),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _MessageCard(
                                    icon: Icons.cloud_off_rounded,
                                    title: 'No pudimos cargar tu ruta del mes',
                                    message:
                                        'Deslizá hacia abajo para reintentar.',
                                    onTap: _refresh,
                                  ),
                                );
                              }
                              final progress = snapshot.data;
                              if (progress == null || !progress.enabled) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: VisitProgressCard(
                                  progress: progress,
                                  onOpenGifts: widget.onOpenGiftRewards,
                                  onHistory: _openMovements,
                                ),
                              );
                            },
                          ),
                        _GiftShortcut(
                          onTap: widget.onOpenGiftRewards,
                        ),
                        const SizedBox(height: 26),
                        HomeSectionTitle(
                          'Últimos movimientos',
                          action: 'Ver todas',
                          onTap: _openMovements,
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<Movement>>(
                          future: _movements,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                                    bottom: index == recentMovements.length - 1
                                        ? 0
                                        : 10,
                                  ),
                                  child: _LatestMovementCard(
                                    movement: recentMovements[index],
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}

class _GiftShortcut extends StatelessWidget {
  const _GiftShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEAF4FF),
                foregroundColor: AppColors.blue,
                child: Icon(Icons.auto_awesome_rounded),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis premios regalados',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Sorpresas, sorteos y beneficios por visitar estaciones.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
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
    if (movement.type == MovementType.adjustment || movement.isGift) {
      final date = movement.argentinaDate;
      final timestamp = '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} · '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
      return '${movement.subtitle}\n$timestamp';
    }

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
    final isGift = movement.isGift;
    final positive = movement.points > 0;

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
                backgroundColor: isGift
                    ? const Color(0xFFEFF4FF)
                    : positive
                        ? const Color(0xFFE8F3FF)
                        : const Color(0xFFFFEEE8),
                foregroundColor: isGift
                    ? const Color(0xFF6558D3)
                    : positive
                        ? AppColors.blue
                        : AppColors.danger,
                child: Icon(
                  movement.isGiftRedeemed
                      ? Icons.check_circle_rounded
                      : movement.type == MovementType.adjustment
                          ? Icons.tune_rounded
                          : movement.type == MovementType.load
                              ? Icons.local_gas_station_rounded
                              : movement.type == MovementType.visitBonus
                                  ? Icons.route_rounded
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _details(),
                      maxLines: movement.isGift ? null : 2,
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
                isGift
                    ? 'Gratis'
                    : '${positive ? '+' : '-'}${movement.points.abs()}',
                style: TextStyle(
                  color: isGift
                      ? const Color(0xFF6558D3)
                      : positive
                          ? AppColors.success
                          : AppColors.danger,
                  fontSize: isGift ? 14 : 21,
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
