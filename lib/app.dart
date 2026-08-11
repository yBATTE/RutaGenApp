import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/ruta_gen_repository.dart';
import 'features/auth/login_page.dart';
import 'features/shell/app_shell.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'shared/widgets/ruta_gen_logo.dart';

class RutaGenApp extends StatefulWidget {
  const RutaGenApp({
    super.key,
    required this.repository,
  });

  final RutaGenRepository repository;

  @override
  State<RutaGenApp> createState() => _RutaGenAppState();
}

class _RutaGenAppState extends State<RutaGenApp> {
  UserModel? _currentUser;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await AuthService.instance.restoreSession();

      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _checkingSession = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _currentUser = null;
        _checkingSession = false;
      });
    }
  }

  Future<void> _handleAuthenticated() async {
    setState(() {
      _checkingSession = true;
    });

    try {
      final user = await AuthService.instance.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _checkingSession = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _currentUser = null;
        _checkingSession = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron obtener los datos de la cuenta.',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();

    if (!mounted) return;

    setState(() {
      _currentUser = null;
      _checkingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruta Gen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_checkingSession) {
      return const _SessionLoadingPage();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _currentUser != null
          ? AppShell(
              key: const ValueKey('app'),
              repository: widget.repository,
              user: _currentUser!,
              onLogout: _logout,
            )
          : LoginPage(
              key: const ValueKey('login'),
              onAuthenticated: _handleAuthenticated,
            ),
    );
  }
}

class _SessionLoadingPage extends StatelessWidget {
  const _SessionLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navyDeep,
              AppColors.navy,
              Color(0xFF00356C),
            ],
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RutaGenLogo(),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: AppColors.cyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}