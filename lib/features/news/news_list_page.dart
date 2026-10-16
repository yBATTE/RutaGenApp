import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import 'news_carousel.dart';
import 'news_detail_page.dart';

class NewsListPage extends StatefulWidget {
  const NewsListPage({super.key, required this.repository});

  final RutaGenRepository repository;

  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  static const _limit = 10;
  List<NewsItem> _items = [];
  int _nextPage = 1;
  int _request = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _hasError = false;
  bool _failedRefresh = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading && !refresh) return;
    final request = ++_request;
    final page = refresh ? 1 : _nextPage;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final items = await widget.repository.getNews(page: page, limit: _limit);
      if (!mounted || request != _request) return;
      setState(() {
        final combined = [...(refresh ? <NewsItem>[] : _items), ...items];
        _items = {for (final item in combined) item.id: item}.values.toList();
        _nextPage = page + 1;
        _hasMore = items.length == _limit;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _hasError = true;
          _failedRefresh = refresh;
        });
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Novedades')),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            for (final item in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: NewsPreviewCard(
                  item: item,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NewsDetailPage(
                      repository: widget.repository, initialItem: item)),
                  ),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_hasError) ...[
              const Text('No pudimos cargar las novedades.',
                  textAlign: TextAlign.center),
              TextButton(
                onPressed: () => _load(refresh: _failedRefresh),
                child: const Text('Reintentar'),
              ),
            ] else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay novedades publicadas.',
                    textAlign: TextAlign.center),
              )
            else if (_hasMore)
              TextButton(
                onPressed: () => _load(),
                child: const Text('Cargar más'),
              ),
          ],
        ),
      ),
    );
  }
}
