import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/points_promotion.dart';
import '../../data/ruta_gen_repository.dart';

/// Refreshes separately from Home, so a failed optional promotion request
/// cannot prevent the customer from seeing their balance, QR or rewards.
class PointsPromotionBanner extends StatefulWidget {
  const PointsPromotionBanner({
    super.key,
    required this.repository,
    this.isActive = true,
    this.refreshVersion = 0,
  });

  final RutaGenRepository repository;
  final bool isActive;
  final int refreshVersion;

  @override
  State<PointsPromotionBanner> createState() => _PointsPromotionBannerState();
}

class _PointsPromotionBannerState extends State<PointsPromotionBanner>
    with WidgetsBindingObserver {
  PointsPromotion? _promotion;
  Timer? _timer;
  bool _foreground = true;
  int _requestVersion = 0;

  bool get _canRefresh => mounted && widget.isActive && _foreground;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _startRefreshing();
  }

  void _startRefreshing() {
    _timer?.cancel();
    if (!_canRefresh) return;
    unawaited(_refresh());
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refresh()),
    );
  }

  Future<void> _refresh() async {
    if (!_canRefresh) return;
    final repository = widget.repository;
    if (repository is! PointsPromotionRepository) return;
    final version = ++_requestVersion;
    // Hide the old factor until this fresh request succeeds.
    if (_promotion != null) setState(() => _promotion = null);
    try {
      final promotion =
          await (repository as PointsPromotionRepository).getPointsPromotion();
      if (_canRefresh && version == _requestVersion) {
        setState(() => _promotion = promotion);
      }
    } catch (_) {
      // Leave the banner hidden rather than advertise an unconfirmed factor.
      if (_canRefresh && version == _requestVersion) {
        setState(() => _promotion = null);
      }
    }
  }

  void _pause() {
    _timer?.cancel();
    ++_requestVersion; // Ignore responses from before pause/repository changes.
    if (_promotion != null && mounted) setState(() => _promotion = null);
  }

  @override
  void didUpdateWidget(covariant PointsPromotionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.isActive != widget.isActive) {
      _pause();
      _startRefreshing();
    } else if (oldWidget.refreshVersion != widget.refreshVersion) {
      unawaited(_refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _startRefreshing();
    } else {
      _pause();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    ++_requestVersion;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotion = _promotion;
    if (!widget.isActive || promotion == null || !promotion.shouldDisplay) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE7F3FF), Color(0xFFF0FAFF)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB6D9FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.blue, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    promotion.headline,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // A Wrap stays usable with large text and narrow phones.
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    promotion.multiplierLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  promotion.promotionName ?? 'Multiplicador vigente',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              promotion.equivalence,
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              promotion.conditions,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
