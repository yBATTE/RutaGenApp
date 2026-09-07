import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/push_notification_service.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.action,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String action;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWithRead() {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      action: action,
      createdAt: createdAt,
      read: true,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Ruta Gen').toString(),
      body: (json['body'] ?? '').toString(),
      action: (json['action'] ?? 'NOTIFICATIONS').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString())
              ?.toLocal() ??
          DateTime.now(),
      read: json['read'] == true,
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiClient _apiClient = ApiClient.instance;
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() async {
    final response = await _apiClient.get(
      '/notifications/me',
      queryParameters: {
        'limit': '100',
      },
    );

    final data = response['data'];
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final items = payload['items'];

    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _open(AppNotification item) async {
    if (!item.read) {
      try {
        await _apiClient.patch(
          '/notifications/${item.id}/read',
        );
      } catch (_) {
        // El aviso puede abrirse aunque falle la confirmación de lectura.
      }
    }

    if (!mounted) return;

    if (item.action == 'NOTIFICATIONS') {
      await _refresh();
      return;
    }

    Navigator.of(context).pop();
    PushNotificationService.instance.openAction(item.action);
  }

  String _date(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();

    if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      return 'Hoy · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.blue,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pudimos cargar las notificaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Volver a intentar'),
                  ),
                ],
              );
            }

            final items = snapshot.data ?? const <AppNotification>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 90),
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: AppColors.muted,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Todavía no tenés notificaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: item.read ? 0 : 1,
                  color: item.read ? Colors.white : const Color(0xFFEAF6FF),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: item.read
                                  ? const Color(0xFFEEF2F6)
                                  : AppColors.blue,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              color: item.read ? AppColors.muted : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (!item.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item.body,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  _date(item.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
