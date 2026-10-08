import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';

class RewardDetailPage extends StatefulWidget {
  const RewardDetailPage({
    super.key,
    required this.repository,
    required this.reward,
    required this.availablePoints,
    required this.onShowQr,
  });

  // Se conserva para mantener la misma firma general de la pantalla.
  // El canje ya no se ejecuta desde la app del cliente.
  final RutaGenRepository repository;
  final Reward reward;
  final int availablePoints;
  final VoidCallback onShowQr;

  @override
  State<RewardDetailPage> createState() => _RewardDetailPageState();
}

class _RewardDetailPageState extends State<RewardDetailPage> {
  int _selectedPhoto = 0;

  String _points(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
  }

  void _openQr(BuildContext context) {
    Navigator.of(context).pop();
    widget.onShowQr();
  }

  @override
  Widget build(BuildContext context) {
    final canRedeem = widget.availablePoints >= widget.reward.points &&
        widget.reward.hasStock;
    final reward = widget.reward;
    final availablePoints = widget.availablePoints;
    final gallery = reward.gallery;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle del premio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Container(
            height: 300,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF4F7FA), Color(0xFFE2ECF7)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: gallery.isNotEmpty
                ? PageView.builder(
                    itemCount: gallery.length,
                    onPageChanged: (index) =>
                        setState(() => _selectedPhoto = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.white,
                          insetPadding: const EdgeInsets.all(12),
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image.network(gallery[index],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.network(gallery[index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(reward.icon,
                                size: 130, color: AppColors.navy)),
                      ),
                    ),
                  )
                : Icon(
                    reward.icon,
                    size: 130,
                    color: AppColors.navy,
                  ),
          ),
          if (gallery.length > 1) ...[
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  gallery.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _selectedPhoto == index ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _selectedPhoto == index
                          ? AppColors.blue
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 22),
          Text(
            reward.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          if (reward.subtitle.isNotEmpty)
            Text(
              reward.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_points(reward.points)} puntos',
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (reward.stockTrackingEnabled) Center(
            child: Text(
              reward.hasStock ? '✓ Stock disponible' : 'Sin stock disponible',
              style: TextStyle(
                color: reward.hasStock ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFFF0F7FF),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.star_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tenés',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        Text(
                          '${_points(availablePoints)} puntos',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: canRedeem ? () => _openQr(context) : null,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Mostrar mi QR para canjear'),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.muted,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'El Vendedor de Playa verificará el premio y confirmará la entrega.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
