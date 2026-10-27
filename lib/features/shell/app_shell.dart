import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/gen_bottom_navigation.dart';
import '../../data/ruta_gen_repository.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';
import '../account/account_page.dart';
import '../account/complete_dni_page.dart';
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
  int _dataVersion = 0;
  final Set<int> _visitedTabs = {0};
  int _unreadNotifications = 0;
  bool _loadingNotifications = false;
  bool _notificationsRefreshPending = false;
  Timer? _notificationsTimer;
  StreamSubscription<PushMessage>? _pushSubscription;

  late UserModel _currentUser;
  bool _refreshingUser = false;
  bool _userRefreshPending = false;
  bool _foreground = true;

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
        PushNotificationService.instance.foregroundMessages.listen((message) {
      ApiClient.instance.invalidateForNotification(message.action);
      if (mounted) setState(() => _dataVersion++);
      _refreshCurrentUser();
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
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      // Conservar entradas válidas; los TTL renuevan lo que haya vencido.
      if (mounted) setState(() => _dataVersion++);
      _refreshNotifications();
      _refreshCurrentUser();
    }
  }

  void _handleSessionExpired() {
    if (!AuthService.instance.accountDeletionInProgress) widget.onLogout();
  }

  Future<void> _refreshNotifications() async {
    if (!mounted ||
        !_foreground ||
        AuthService.instance.accountDeletionInProgress) {
      return;
    }
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
      _userRefreshPending = true;
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
        _userRefreshPending = false;
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
      if (_userRefreshPending && mounted &&
          !AuthService.instance.accountDeletionInProgress) {
        _userRefreshPending = false;
        unawaited(_refreshCurrentUser());
      }
    }
  }

  Future<void> _openCompleteDni() async {
    final updated = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(builder: (_) => const CompleteDniPage()),
    );
    if (!mounted || updated == null) return;
    _handleUserUpdated(updated);
  }

  void _goTo(int index) {
    if (index == 2 && !_currentUser.identityVerified) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _currentUser.dni.trim().isEmpty
                  ? 'Completá tu DNI en Mi cuenta antes de verificar tu identidad en la estación.'
                  : 'Primero tenés que verificar tu cuenta presentando el DNI en una estación Ruta GEN.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (_index != index) {
      setState(() {
        _index = index;
        _visitedTabs.add(index);
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

  void _openGiftRewards({String? giftId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GiftRewardsPage(
          repository: widget.repository,
          initialGiftId: giftId,
        ),
      ),
    );
  }

  void _handlePushAction() {
    if (AuthService.instance.accountDeletionInProgress) return;
    if (!mounted) return;

    final action = PushNotificationService.instance.consumePendingAction();
    if (action == null) return;
    ApiClient.instance.invalidateForNotification(action.action);
    setState(() => _dataVersion++);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (action.action) {
        case 'HOME':
          _goTo(0);
          break;
        case 'REWARDS':
          _goTo(3);
          break;
        case 'GIFT_REWARDS':
        case 'GIFTS':
          _openGiftRewards(giftId: action.giftId);
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
        refreshVersion: _dataVersion,
        isActive: _index == 0,
        repository: widget.repository,
        user: _currentUser,
        onNavigate: _goTo,
        onRefreshUser: _refreshCurrentUser,
        onOpenNotifications: _openNotifications,
        unreadNotifications: _unreadNotifications,
        onOpenGiftRewards: _openGiftRewards,
        onCompleteDni: _openCompleteDni,
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
        refreshVersion: _dataVersion,
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
          refreshVersion: _dataVersion,
          repository: widget.repository,
          user: _currentUser,
          isActive: _index == 4,
        ));

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < pages.length; i++)
            _visitedTabs.contains(i) ? pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: GenBottomNavigation(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
      ),
    );
  }
}
