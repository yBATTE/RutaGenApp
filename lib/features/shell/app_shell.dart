import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/ruta_gen_repository.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';
import '../account/account_page.dart';
import '../draws/draws_page.dart';
import '../gifts/gift_rewards_page.dart';
import '../home/home_page.dart';
import '../movements/movements_page.dart';
import '../notifications/notifications_page.dart';
import '../qr/my_qr_page.dart';
import '../rewards/rewards_page.dart';
import '../stations/stations_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.user,
    required this.onLogout,
    required this.onAccountDeleted,
  });

  final RutaGenRepository repository;
  final UserModel user;
  final VoidCallback onLogout;
  final VoidCallback onAccountDeleted;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  int _unreadNotifications = 0;
  bool _loadingNotifications = false;
  bool _notificationsRefreshPending = false;
  Timer? _notificationsTimer;
  StreamSubscription<PushMessage>? _pushSubscription;

  late UserModel _currentUser;
  bool _refreshingUser = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    WidgetsBinding.instance.addObserver(this);
    _refreshNotifications();
    _notificationsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshNotifications(),
    );
    _pushSubscription =
        PushNotificationService.instance.foregroundMessages.listen((_) {
      Future.delayed(const Duration(seconds: 2), _refreshNotifications);
    });

    PushNotificationService.instance.actionNotifier
        .addListener(_handlePushAction);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePushAction();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationsTimer?.cancel();
    _pushSubscription?.cancel();
    PushNotificationService.instance.actionNotifier
        .removeListener(_handlePushAction);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotifications();
      _refreshCurrentUser();
    }
  }

  void _handleSessionExpired() {
    if (!AuthService.instance.accountDeletionInProgress) widget.onLogout();
  }

  Future<void> _refreshNotifications() async {
    if (AuthService.instance.accountDeletionInProgress) return;
    if (_loadingNotifications) {
      _notificationsRefreshPending = true;
      return;
    }
    _loadingNotifications = true;
    try {
      final response = await ApiClient.instance.get(
        '/notifications/me',
        queryParameters: {'limit': '100'},
      );
      final data = response['data'];
      final payload =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final items = payload['items'];
      final count = items is List
          ? items.where((item) => item is Map && item['read'] != true).length
          : 0;
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {
      // Mantener el último contador si falla la conexión.
    } finally {
      _loadingNotifications = false;
      if (_notificationsRefreshPending && mounted) {
        _notificationsRefreshPending = false;
        _refreshNotifications();
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.id != widget.user.id) {
      setState(() {
        _currentUser = widget.user;
        _unreadNotifications = 0;
      });
      _refreshNotifications();
    }
  }

  /*
   * Actualiza inmediatamente los datos del usuario
   * después de editar el perfil.
   */
  void _handleUserUpdated(UserModel updatedUser) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = updatedUser;
    });
  }

  /*
   * Consulta nuevamente el usuario en el backend.
   */
  Future<void> _refreshCurrentUser() async {
    if (AuthService.instance.accountDeletionInProgress) return;
    if (_refreshingUser) {
      return;
    }

    _refreshingUser = true;

    try {
      final updatedUser = await AuthService.instance.getCurrentUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = updatedUser;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (AuthService.instance.accountDeletionInProgress) return;
      if (error.isUnauthorized || error.isForbidden) {
        _handleSessionExpired();
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo actualizar la información de la cuenta.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      _refreshingUser = false;
    }
  }

  void _goTo(int index) {
    if (index == 2 && !_currentUser.identityVerified) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Primero tenés que verificar tu cuenta presentando el DNI en una estación Ruta GEN.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (_index != index) {
      setState(() {
        _index = index;
      });
    }

    /*
     * Actualizamos el usuario al entrar en:
     * 0: Inicio
     * 3: Premios
     * 4: Sorteos
     * 5: Cuenta
     */
    if (index == 0 || index == 3 || index == 4 || index == 5) {
      _refreshCurrentUser();
    }
  }

  void _openMovements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovementsPage(
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          onUnreadChanged: _refreshNotifications,
        ),
      ),
    );
    _refreshNotifications();
  }

  void _openGiftRewards() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GiftRewardsPage(
          repository: widget.repository,
        ),
      ),
    );
  }

  void _handlePushAction() {
    if (AuthService.instance.accountDeletionInProgress) return;
    if (!mounted) return;

    final action = PushNotificationService.instance.consumePendingAction();
    if (action == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (action) {
        case 'HOME':
          _goTo(0);
          break;
        case 'REWARDS':
          _goTo(3);
          break;
        case 'GIFT_REWARDS':
        case 'GIFTS':
          _openGiftRewards();
          break;
        case 'STATIONS':
          _goTo(1);
          break;
        case 'MOVEMENTS':
          _openMovements();
          break;
        case 'QR':
          _goTo(2);
          break;
        case 'NOTIFICATIONS':
        default:
          _openNotifications();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        isActive: _index == 0,
        repository: widget.repository,
        user: _currentUser,
        onNavigate: _goTo,
        onRefreshUser: _refreshCurrentUser,
        onOpenNotifications: _openNotifications,
        unreadNotifications: _unreadNotifications,
        onOpenGiftRewards: _openGiftRewards,
      ),
      StationsPage(
        repository: widget.repository,
      ),
      MyQrPage(
        repository: widget.repository,
        isActive: _index == 2,
        onSessionExpired: _handleSessionExpired,
      ),
      RewardsPage(
        repository: widget.repository,
        isActive: _index == 3,
        onRefreshUser: _refreshCurrentUser,
        onShowQr: () => _goTo(2),
        identityVerified: _currentUser.identityVerified,
        onOpenGiftRewards: _openGiftRewards,
      ),
      AccountPage(
        user: _currentUser,
        onUserUpdated: _handleUserUpdated,
        onLogout: widget.onLogout,
        onAccountDeleted: widget.onAccountDeleted,
      ),
    ];

    // Keep the existing account page last and add the draw tab before it.
    pages.insert(
        4,
        DrawsPage(
          repository: widget.repository,
          user: _currentUser,
          isActive: _index == 4,
        ));

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blue.withValues(
          alpha: 0.12,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.local_gas_station_outlined,
            ),
            selectedIcon: Icon(
              Icons.local_gas_station_rounded,
            ),
            label: 'Estaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_rounded),
            selectedIcon: Icon(Icons.qr_code_2_rounded),
            label: 'Mi QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(
              Icons.card_giftcard_rounded,
            ),
            label: 'Premios',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Sorteos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cuenta',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.small(
              onPressed: _openMovements,
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              child: const Icon(
                Icons.history_rounded,
              ),
            )
          : null,
    );
  }
}
