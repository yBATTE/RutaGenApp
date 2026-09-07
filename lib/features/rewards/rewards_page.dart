import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import 'reward_detail_page.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({
    super.key,
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
    if (!oldWidget.isActive && widget.isActive) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
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
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: FutureBuilder<Customer>(
        future: _customer,
        builder: (context, customerSnapshot) {
          if (customerSnapshot.connectionState ==
                  ConnectionState.waiting &&
              !customerSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (customerSnapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  4,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ice,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Tus puntos',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _points(points),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                child: Card(
                  child: InkWell(
                    onTap: widget.onOpenGiftRewards,
                    borderRadius: BorderRadius.circular(18),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFEAF4FF),
                            foregroundColor: AppColors.blue,
                            child: Icon(Icons.auto_awesome_rounded),
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
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sorteos, sorpresas y beneficios por visitar estaciones.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
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
                ),
              ),
              if (!widget.identityVerified)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFFFD58A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: Color(0xFF8A5700)),
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
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: SegmentedButton<int>(
                  selected: {_filter},
                  onSelectionChanged: (value) {
                    setState(() {
                      _filter = value.first;
                    });
                  },
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Todos'),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Me alcanza'),
                    ),
                    ButtonSegment<int>(
                      value: 2,
                      label: Text('Disponibles'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Reward>>(
                  future: _rewards,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 150),
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No se pudieron cargar los premios.\nDeslizá hacia abajo para intentar nuevamente.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final rewards =
                        (snapshot.data ?? const <Reward>[])
                            .where((reward) {
                      if (_filter == 1) {
                        return reward.points <= points &&
                            reward.stock > 0;
                      }

                      if (_filter == 2) {
                        return reward.stock > 0;
                      }

                      return true;
                    }).toList();

                    if (rewards.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 150),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _filter == 1
                                    ? 'Todavía no hay premios que puedas canjear con tus puntos.'
                                    : _filter == 2
                                        ? 'No hay premios con stock disponible.'
                                        : 'Todavía no hay premios disponibles.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          10,
                          18,
                          30,
                        ),
                        itemCount: rewards.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final reward = rewards[index];

                          return Card(
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(20),
                              onTap: () {
                                _openRewardDetail(
                                  reward: reward,
                                  availablePoints: points,
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 78,
                                      height: 78,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: AppColors.ice,
                                        borderRadius:
                                            BorderRadius.circular(
                                          16,
                                        ),
                                      ),
                                      child: reward.imageUrl !=
                                                  null &&
                                              reward
                                                  .imageUrl!
                                                  .isNotEmpty
                                          ? Image.network(
                                              reward.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      Icon(
                                                reward.icon,
                                                size: 42,
                                                color:
                                                    AppColors.navy,
                                              ),
                                            )
                                          : Icon(
                                              reward.icon,
                                              size: 42,
                                              color:
                                                  AppColors.navy,
                                            ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            reward.name,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (reward
                                              .subtitle.isNotEmpty)
                                            Text(
                                              reward.subtitle,
                                              maxLines: 2,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    AppColors.muted,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_points(reward.points)} puntos',
                                            style:
                                                const TextStyle(
                                              color:
                                                  AppColors.blue,
                                              fontSize: 17,
                                              fontWeight:
                                                  FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            reward.stock > 0
                                                ? 'Stock disponible'
                                                : 'Sin stock',
                                            style: TextStyle(
                                              color:
                                                  reward.stock > 0
                                                      ? AppColors
                                                          .success
                                                      : AppColors
                                                          .danger,
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}