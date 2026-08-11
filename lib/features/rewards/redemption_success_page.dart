import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';

class RedemptionSuccessPage extends StatelessWidget {
  const RedemptionSuccessPage({super.key, required this.reward, required this.remainingPoints, required this.code});

  final Reward reward;
  final int remainingPoints;
  final String code;

  String _points(int value) => value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
          children: [
            const CircleAvatar(radius: 58, backgroundColor: Color(0xFFE6F2FF), child: CircleAvatar(radius: 43, backgroundColor: AppColors.blue, foregroundColor: Colors.white, child: Icon(Icons.check_rounded, size: 55))),
            const SizedBox(height: 28),
            const Text('¡Canje realizado!', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text('Usaste ${_points(reward.points)} puntos', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [const Text('Te quedan', style: TextStyle(color: AppColors.muted)), Text(_points(remainingPoints), style: const TextStyle(color: AppColors.blue, fontSize: 42, fontWeight: FontWeight.w900)), const Text('puntos')]))),
            const SizedBox(height: 14),
            Card(color: const Color(0xFFF0F7FF), child: ListTile(leading: const CircleAvatar(backgroundColor: AppColors.blue, foregroundColor: Colors.white, child: Icon(Icons.receipt_long_rounded)), title: const Text('Código de canje'), subtitle: Text(code, style: const TextStyle(color: AppColors.blue, fontSize: 19, fontWeight: FontWeight.w900)))),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Volver al inicio')),
          ],
        ),
      ),
    );
  }
}
