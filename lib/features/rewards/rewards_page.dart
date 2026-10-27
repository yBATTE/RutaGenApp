import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import 'reward_detail_page.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({
    super.key,
    this.refreshVersion = 0,
    required this.repository,
    required this.onShowQr,
    required this.isActive,
    required this.onRefreshUser,
    required this.identityVerified,
    required this.onOpenGiftRewards,
  });

  final RutaGenRepository repository;
  final VoidCallback onShowQr;
  final bool isActive;
  final int refreshVersion;
  final Future<void> Function() onRefreshUser;
  final bool identityVerified;
  final VoidCallback onOpenGiftRewards;

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int _filter = 0;

  late Future<List<Reward>> _rewards;
  late Future<Customer> _customer;

  @override
  void initState() {
    super.initState();

    _rewards = widget.repository.getRewards();
    _customer = widget.repository.getCustomer();
  }

  @override
  void didUpdateWidget(covariant RewardsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    /*
     * IndexedStack mantiene viva la página.
     * Cuando la pestaña Premios pasa de inactiva a activa,
     * volvemos a consultar premios, stock y puntos.
     */
    if ((!oldWidget.isActive && widget.isActive) ||
        oldWidget.refreshVersion != widget.refreshVersion) {
      _refresh(forceRefresh: false);
    }
  }

  Future<void> _refresh({bool forceRefresh = true}) async {
    if (forceRefresh) {
      ApiClient.instance.invalidateCache('/rewards');
      ApiClient.instance.invalidateCache('/auth/me');
    }
    final rewardsFuture = widget.repository.getRewards();
    final customerFuture = widget.repository.getCustomer();

    if (mounted) {
      setState(() {
        _rewards = rewardsFuture;
        _customer = customerFuture;
      });
    }

    await Future.wait<Object?>([
      rewardsFuture,
      customerFuture,
      widget.onRefreshUser(),
    ]);
  }

  Future<void> _openRewardDetail({
    required Reward reward,
    required int availablePoints,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RewardDetailPage(
          repository: widget.repository,
          reward: reward,
          availablePoints: availablePoints,
          onShowQr: widget.onShowQr,
        ),
      ),
    );

    /*
     * Al regresar del detalle puede haberse realizado un canje.
     * Actualizamos puntos, premios y stock inmediatamente.
     */
    if (mounted) {
      await _refresh();
    }
  }

  String _points(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premios',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<Customer>(
        future: _customer,
        builder: (context, customerSnapshot) {
          if (customerSnapshot.connectionState == ConnectionState.waiting &&
              !customerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (customerSnapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No se pudieron cargar tus puntos.\nDeslizá hacia abajo para intentar nuevamente.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          final points = customerSnapshot.data?.points ?? 0;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PointsBalanceCard(points: _points(points)),
                        const SizedBox(height: 14),
                        _GiftRewardsLink(onTap: widget.onOpenGiftRewards),
                        if (!widget.identityVerified) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFFFD58A),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF8A5700),
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Podés ver los premios, pero para canjearlos primero tenés que verificar tu identidad en una estación Ruta GEN.',
                                    style: TextStyle(
                                      color: Color(0xFF755A2B),
                                      fontSize: 12.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            selected: {_filter},
                            showSelectedIcon: false,
                            onSelectionChanged: (value) {
                              setState(() => _filter = value.first);
                            },
                            style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              side: const WidgetStatePropertyAll(
                                BorderSide(color: AppColors.border),
                              ),
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? AppColors.blue
                                    : Colors.white,
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? Colors.white
                                    : AppColors.ink,
                              ),
                            ),
                            segments: const [
                              ButtonSegment(value: 0, label: Text('Todos')),
                              ButtonSegment(
                                value: 1,
                                label: Text('Me alcanza'),
                              ),
                              ButtonSegment(
                                value: 2,
                                label: Text('Disponibles'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<Reward>>(
                  future: _rewards,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return const _RewardsNotice(
                        message: 'No se pudieron cargar los premios.\nDeslizá hacia abajo para intentar nuevamente.',
                      );
                    }
                    final rewards = (snapshot.data ?? const <Reward>[]).where((
                      reward,
                    ) {
                      if (_filter == 1) {
                        return reward.points <= points && reward.hasStock;
                      }
                      if (_filter == 2) return reward.hasStock;
                      return true;
                    }).toList();
                    if (rewards.isEmpty) {
                      return _RewardsNotice(
                        message: _filter == 1
                            ? 'Todavía no hay premios que puedas canjear con tus puntos.'
                            : _filter == 2
                            ? 'No hay premios con stock disponible.'
                            : 'Todavía no hay premios disponibles.',
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          // Dos por fila; la altura crece con el tamaño de letra.
                          final cardWidth =
                              (constraints.crossAxisExtent - 12) / 2;
                          final imageHeight = (cardWidth - 20)
                              .clamp(88.0, 200.0)
                              .toDouble();
                          final scaler = MediaQuery.textScalerOf(context);
                          final titleHeight = scaler.scale(15) * 1.25 * 2;
                          final subtitleHeight = scaler.scale(11.5) * 1.3;
                          final pointsHeight = scaler.scale(17) * 1.2 * 2;
                          final stockHeight = scaler.scale(11.5) * 1.25;
                          final cardHeight =
                              imageHeight +
                              titleHeight +
                              subtitleHeight +
                              pointsHeight +
                              stockHeight +
                              54;
                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: cardHeight,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final reward = rewards[index];
                              return _RewardGridCard(
                                key: ValueKey(reward.id),
                                reward: reward,
                                pointsText: _points(reward.points),
                                imageHeight: imageHeight.toDouble(),
                                titleHeight: titleHeight,
                                subtitleHeight: subtitleHeight,
                                pointsHeight: pointsHeight,
                                stockHeight: stockHeight,
                                onTap: () => _openRewardDetail(
                                  reward: reward,
                                  availablePoints: points,
                                ),
                              );
                            }, childCount: rewards.length),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PointsBalanceCard extends StatelessWidget {
  const _PointsBalanceCard({required this.points});
  final String points;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: AppColors.navy,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _PointsRoadPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Semantics(
                    label: 'Ruta GEN',
                    image: true,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16375D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x334B8ED6)),
                        ),
                        padding: const EdgeInsets.all(7),
                        child: const CustomPaint(painter: _RgMonogramPainter()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tus puntos',
                          style: TextStyle(
                            color: Color(0xFFCBDCF2),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: points,
                                style: const TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const TextSpan(
                                text: ' puntos',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.15,
                          ),
                          softWrap: true,
                        ),
                      ],
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

// Monograma original: R blanca y G amarilla, trazadas como vectores nativos.
class _RgMonogramPainter extends CustomPainter {
  const _RgMonogramPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.width / 56;
    canvas.translate(0, (size.height - 40 * scale) / 2);
    canvas.scale(scale);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;
    final r = Path()
      ..moveTo(5, 33)
      ..lineTo(5, 7)
      ..lineTo(16, 7)
      ..cubicTo(28, 7, 28, 21, 16, 21)
      ..lineTo(5, 21)
      ..moveTo(16, 21)
      ..lineTo(25, 33);
    canvas.drawPath(r, pen);
    pen.color = const Color(0xFFFFD43B);
    final g = Path()
      ..moveTo(51, 11)
      ..cubicTo(47, 5, 36, 5, 32, 12)
      ..cubicTo(28, 19, 30, 29, 37, 33)
      ..cubicTo(42, 36, 49, 33, 52, 30)
      ..lineTo(52, 22)
      ..lineTo(43, 22);
    canvas.drawPath(g, pen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RgMonogramPainter oldDelegate) => false;
}

class _PointsRoadPainter extends CustomPainter {
  const _PointsRoadPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0x26FFD43B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final first = Path()
      ..moveTo(size.width * 0.78, size.height + 8)
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.35,
        size.width + 18,
        size.height * 0.12,
      );
    final second = Path()
      ..moveTo(size.width * 0.88, size.height + 8)
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.4,
        size.width + 22,
        size.height * 0.26,
      );
    canvas.drawPath(first, pen);
    canvas.drawPath(second, pen);
  }

  @override
  bool shouldRepaint(covariant _PointsRoadPainter oldDelegate) => false;
}

class _GiftRewardsLink extends StatelessWidget {
  const _GiftRewardsLink({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8DF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.blue,
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis premios regalados',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Ver mis regalos',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsNotice extends StatelessWidget {
  const _RewardsNotice({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _RewardGridCard extends StatelessWidget {
  const _RewardGridCard({
    super.key,
    required this.reward,
    required this.pointsText,
    required this.imageHeight,
    required this.titleHeight,
    required this.subtitleHeight,
    required this.pointsHeight,
    required this.stockHeight,
    required this.onTap,
  });
  final Reward reward;
  final String pointsText;
  final double imageHeight;
  final double titleHeight;
  final double subtitleHeight;
  final double pointsHeight;
  final double stockHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = reward.gallery.isEmpty ? null : reward.gallery.first;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: imageHeight,
                decoration: BoxDecoration(
                  color: AppColors.ice,
                  borderRadius: BorderRadius.circular(13),
                ),
                clipBehavior: Clip.antiAlias,
                child: image == null
                    ? Icon(reward.icon, size: 44, color: AppColors.navy)
                    : CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            Icon(reward.icon, size: 44, color: AppColors.navy),
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: titleHeight,
                child: Text(
                  reward.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: subtitleHeight,
                child: Text(
                  reward.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: pointsHeight,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: pointsText,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(
                        text: ' puntos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.blue, height: 1.2),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: stockHeight,
                child: reward.stockTrackingEnabled
                    ? Text(
                        reward.hasStock ? 'Stock disponible' : 'Sin stock',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: reward.hasStock
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
