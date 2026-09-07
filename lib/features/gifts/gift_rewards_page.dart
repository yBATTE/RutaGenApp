import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';

class GiftRewardsPage extends StatefulWidget {
  const GiftRewardsPage({
    super.key,
    required this.repository,
  });

  final RutaGenRepository repository;

  @override
  State<GiftRewardsPage> createState() => _GiftRewardsPageState();
}

class _GiftRewardsPageState extends State<GiftRewardsPage> {
  late Future<List<GiftReward>> _future;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getGiftRewards();
  }

  Future<void> _refresh() async {
    final next = widget.repository.getGiftRewards();
    setState(() {
      _future = next;
    });
    await next;
  }

  List<GiftReward> _filtered(List<GiftReward> items) {
    switch (_filter) {
      case 1:
        return items.where((item) => item.isAvailable).toList();
      case 2:
        return items.where((item) => !item.isAvailable).toList();
      default:
        return items;
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Sin vencimiento';
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _openGift(GiftReward gift) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GiftDetailSheet(
        gift: gift,
        dateFormatter: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mis premios',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navyDeep, Color(0xFF0A6BB5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.auto_awesome_rounded),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premios que Ruta GEN te regaló',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Mostrá el QR en Tienda para retirarlos. Cada QR puede usarse una sola vez.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: SegmentedButton<int>(
              selected: {_filter},
              onSelectionChanged: (value) {
                setState(() {
                  _filter = value.first;
                });
              },
              segments: const [
                ButtonSegment(value: 0, label: Text('Todos')),
                ButtonSegment(value: 1, label: Text('Disponibles')),
                ButtonSegment(value: 2, label: Text('Historial')),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<GiftReward>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 90),
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 52,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No pudimos cargar tus premios regalados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: FilledButton(
                            onPressed: _refresh,
                            child: const Text('Volver a intentar'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final items = _filtered(snapshot.data ?? const <GiftReward>[]);
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 90),
                        const Icon(
                          Icons.card_giftcard_rounded,
                          size: 56,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 1
                              ? 'No tenés premios pendientes para retirar.'
                              : _filter == 2
                                  ? 'Todavía no hay premios en tu historial.'
                                  : 'Cuando Ruta GEN te regale un premio, va a aparecer acá.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.blue,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final gift = items[index];
                      return _GiftCard(
                        gift: gift,
                        dateFormatter: _date,
                        onTap: () => _openGift(gift),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    required this.gift,
    required this.dateFormatter,
    required this.onTap,
  });

  final GiftReward gift;
  final String Function(DateTime?) dateFormatter;
  final VoidCallback onTap;

  Color get _statusColor {
    if (gift.isAvailable) return AppColors.success;
    if (gift.isRedeemed) return AppColors.blue;
    return AppColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFEAF4FF),
                  child: gift.rewardImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: gift.rewardImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.card_giftcard_rounded,
                            color: AppColors.blue,
                          ),
                        )
                      : const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.blue,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.rewardName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gift.sourceLabel,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            gift.statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (gift.isAvailable) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vence ${dateFormatter(gift.expiresAt)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftDetailSheet extends StatelessWidget {
  const _GiftDetailSheet({
    required this.gift,
    required this.dateFormatter,
  });

  final GiftReward gift;
  final String Function(DateTime?) dateFormatter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.blue,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                gift.rewardName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                gift.sourceLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (gift.rewardDescription.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  gift.rewardDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 22),
              if (gift.canShowQr) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE1E7EE)),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: gift.qrToken!,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.navy,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.navyDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mostrá este QR en Tienda. Se invalida automáticamente después del canje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        gift.isRedeemed
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: gift.isRedeemed
                            ? AppColors.success
                            : AppColors.muted,
                        size: 34,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gift.statusLabel,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _InfoRow(label: 'Código', value: gift.giftCode),
              _InfoRow(label: 'Emitido', value: dateFormatter(gift.issuedAt)),
              if (gift.expiresAt != null)
                _InfoRow(label: 'Vence', value: dateFormatter(gift.expiresAt)),
              if (gift.redeemedAt != null)
                _InfoRow(
                  label: 'Canjeado',
                  value: dateFormatter(gift.redeemedAt),
                ),
              if (gift.redeemedStationName != null)
                _InfoRow(
                  label: 'Estación',
                  value: gift.redeemedStationName!,
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
