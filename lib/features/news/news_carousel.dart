import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key, required this.items, required this.onOpen});

  final List<NewsItem> items;
  final ValueChanged<NewsItem> onOpen;

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final _controller = PageController(viewportFraction: .72);
  int _current = 0;

  @override
  void didUpdateWidget(covariant NewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refresh can remove articles or change their order. Reset both the
    // visible page and its indicator rather than retaining an invalid index.
    if (oldWidget.items.map((item) => item.id).join('|') !=
        widget.items.map((item) => item.id).join('|')) {
      _current = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extraHeight = MediaQuery.textScalerOf(context).scale(16) - 16;
    if (widget.items.isEmpty) return const SizedBox.shrink();
    if (widget.items.length == 1) {
      return SizedBox(
        height: 148 + extraHeight * 3,
        child: NewsPreviewCard(
          item: widget.items.first,
          onTap: () => widget.onOpen(widget.items.first),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 148 + extraHeight * 3,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: NewsPreviewCard(
                item: widget.items[index],
                onTap: () => widget.onOpen(widget.items[index]),
              ),
            ),
          ),
        ),
        if (widget.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (index) {
                return Semantics(
                  label: 'Novedad ${index + 1} de ${widget.items.length}',
                  selected: index == _current,
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _current
                          ? AppColors.blue
                          : AppColors.blue.withValues(alpha: .18),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class NewsPreviewCard extends StatelessWidget {
  const NewsPreviewCard({super.key, required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir ${item.displayTitle}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.thumbnailUrl,
              fit: BoxFit.cover,
              memCacheWidth: 900,
              maxWidthDiskCache: 1200,
              fadeInDuration: const Duration(milliseconds: 180),
              placeholder: (_, __) => const ColoredBox(
                color: Color(0xFFE8F3FF),
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: Color(0xFF084B90),
                child: Center(
                  child: Icon(Icons.campaign_outlined,
                      color: Colors.white54, size: 38),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [.25, 1],
                  colors: [Colors.transparent, Color(0xEB001B38)],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NOVEDAD',
                  style: TextStyle(color: Colors.white, fontSize: 9,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      item.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          height: 1.15, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.blue,
                    child: Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
