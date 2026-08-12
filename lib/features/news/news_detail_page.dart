import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({
    super.key,
    required this.repository,
    required this.initialItem,
  });

  final RutaGenRepository repository;
  final NewsItem initialItem;

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Future<NewsItem> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.getNewsDetail(widget.initialItem.id);
  }

  String _date(DateTime value) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${value.day} de ${months[value.month - 1]} de ${value.year}';
  }

  Future<void> _retry() async {
    setState(() {
      _detail = widget.repository.getNewsDetail(widget.initialItem.id);
    });
    await _detail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Novedad',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<NewsItem>(
        future: _detail,
        initialData: widget.initialItem,
        builder: (context, snapshot) {
          final item = snapshot.data;

          if (item == null &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (item == null && snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 52,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No pudimos cargar la novedad.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _retry,
            color: AppColors.blue,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 36),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 580),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      item!.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFE8F3FF),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.blue,
                            size: 58,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _date(item.displayDate),
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.displayTitle,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (item.hasDescription) ...[
                            const SizedBox(height: 18),
                            Text(
                              item.description!,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
