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
  final _controller = PageController(viewportFraction: .80);
  int _current = 0;

  @override
  void didUpdateWidget(covariant NewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: LayoutBuilder(builder: (context, constraints) {
          if (widget.items.length == 1) {
            return NewsPreviewCard(item: widget.items.first,
              onTap: () => widget.onOpen(widget.items.first));
          }
          final side = constraints.maxWidth * .80 - 10;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: side + NewsPreviewCard.titleHeight(context),
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  itemCount: widget.items.length,
                  onPageChanged: (index) => setState(() => _current = index),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: NewsPreviewCard(item: widget.items[index],
                      onTap: () => widget.onOpen(widget.items[index])),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.items.length, (index) => Semantics(
                    label: 'Novedad ${index + 1} de ${widget.items.length}',
                    selected: index == _current,
                    child: Container(
                      width: index == _current ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: index == _current ? AppColors.blue : AppColors.blue.withValues(alpha: .18),
                      ),
                    ),
                  )),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class NewsPreviewCard extends StatelessWidget {
  const NewsPreviewCard({super.key, required this.item, required this.onTap});
  final NewsItem item;
  final VoidCallback onTap;

  static double titleHeight(BuildContext context) =>
      28 + MediaQuery.textScalerOf(context).scale(16) * 1.25 * 2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir ${item.displayTitle}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                key: ValueKey('news-square-${item.id}'),
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.contain,
                  memCacheWidth: 900,
                  maxWidthDiskCache: 1200,
                  fadeInDuration: const Duration(milliseconds: 180),
                  placeholder: (_, __) => const ColoredBox(
                    color: Color(0xFFE8F3FF),
                    child: Center(child: SizedBox.square(dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFE8F3FF),
                    child: Center(child: Icon(Icons.campaign_outlined,
                      color: AppColors.blue, size: 38)),
                  ),
                ),
              ),
              SizedBox(
                height: titleHeight(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Expanded(child: Text(item.displayTitle, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.ink, fontSize: 16,
                        height: 1.25, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.blue, size: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
