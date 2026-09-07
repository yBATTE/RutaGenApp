import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import '../../services/api_client.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({
    super.key,
    required this.repository,
  });

  final RutaGenRepository repository;

  @override
  State<MovementsPage> createState() =>
      _MovementsPageState();
}

class _MovementsPageState
    extends State<MovementsPage> {
  static const int _pageSize = 20;

  final List<Movement> _movements = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final movements =
          await widget.repository.getMovements(
        page: 1,
        limit: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _movements
          ..clear()
          ..addAll(movements);

        _hasMore =
            movements.length == _pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _loadingMore = true;
      _error = null;
    });

    final nextPage = _currentPage + 1;

    try {
      final movements =
          await widget.repository.getMovements(
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _movements.addAll(movements);
        _currentPage = nextPage;
        _hasMore =
            movements.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingMore = false;
        _error = _errorMessage(error);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
        ),
      );
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudieron cargar los movimientos.';
  }

  String _points(int value) {
    return value.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  String _day(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final value = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today.difference(value).inDays;

    if (difference == 0) {
      return 'Hoy';
    }

    if (difference == 1) {
      return 'Ayer';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _hour(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Movimientos',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _movements.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        color: AppColors.blue,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: _loadFirstPage,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Reintentar',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_movements.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        color: AppColors.blue,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.receipt_long_outlined,
              size: 58,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Todavía no tenés movimientos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tus cargas y canjes aparecerán acá.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppColors.blue,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(18, 12, 18, 30),
        itemCount:
            _movements.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _movements.length) {
            return Padding(
              padding:
                  const EdgeInsets.only(top: 4),
              child: Center(
                child: FilledButton.tonalIcon(
                  onPressed:
                      _loadingMore ? null : _loadMore,
                  icon: _loadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.expand_more_rounded,
                        ),
                  label: Text(
                    _loadingMore
                        ? 'Cargando...'
                        : 'Cargar más',
                  ),
                ),
              ),
            );
          }

          final movement = _movements[index];
          final isGift = movement.isGift;
          final positive = movement.points > 0;

          final showDay = index == 0 ||
              _day(_movements[index - 1].date) !=
                  _day(movement.date);

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (showDay)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    bottom: 7,
                  ),
                  child: Text(
                    _day(movement.date),
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: isGift
                            ? const Color(0xFFEFF4FF)
                            : positive
                                ? const Color(0xFFEAF4FF)
                                : const Color(0xFFFFEEE8),
                        foregroundColor: isGift
                            ? const Color(0xFF6558D3)
                            : positive
                                ? AppColors.blue
                                : AppColors.danger,
                        child: Icon(
                          movement.type == MovementType.load
                              ? Icons.local_gas_station_rounded
                              : movement.type == MovementType.visitBonus
                                  ? Icons.route_rounded
                                  : Icons.card_giftcard_rounded,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              movement.title,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              movement.subtitle,
                              style: const TextStyle(
                                color:
                                    AppColors.muted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _hour(movement.date),
                              style: TextStyle(
                                color:
                                    Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isGift
                            ? '0 pts'
                            : '${positive ? '+' : '-'}${_points(movement.points)}',
                        style: TextStyle(
                          color: isGift
                              ? const Color(0xFF6558D3)
                              : positive
                                  ? AppColors.success
                                  : AppColors.danger,
                          fontSize: isGift ? 14 : 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
