import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/ruta_gen_repository.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../account/account_page.dart';
import '../home/home_page.dart';
import '../movements/movements_page.dart';
import '../qr/my_qr_page.dart';
import '../rewards/rewards_page.dart';
import '../stations/stations_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.user,
    required this.onLogout,
  });

  final RutaGenRepository repository;
  final UserModel user;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  late UserModel _currentUser;
  bool _refreshingUser = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.id != widget.user.id) {
      setState(() {
        _currentUser = widget.user;
      });
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
    if (_refreshingUser) {
      return;
    }

    _refreshingUser = true;

    try {
      final updatedUser =
          await AuthService.instance.getCurrentUser();

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

      if (error.isUnauthorized || error.isForbidden) {
        widget.onLogout();
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
    if (_index != index) {
      setState(() {
        _index = index;
      });
    }

    /*
     * Actualizamos el usuario al entrar en:
     * 0: Inicio
     * 3: Premios
     * 4: Cuenta
     */
    if (index == 0 || index == 3 || index == 4) {
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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        repository: widget.repository,
        user: _currentUser,
        onNavigate: _goTo,
        onRefreshUser: _refreshCurrentUser,
      ),
      StationsPage(
        repository: widget.repository,
      ),
      MyQrPage(
        repository: widget.repository,
        isActive: _index == 2,
        onSessionExpired: widget.onLogout,
      ),
      RewardsPage(
        repository: widget.repository,
        isActive: _index == 3,
        onRefreshUser: _refreshCurrentUser,
        onShowQr: () => _goTo(2),
      ),
      AccountPage(
        user: _currentUser,
        onUserUpdated: _handleUserUpdated,
        onLogout: widget.onLogout,
      ),
    ];

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