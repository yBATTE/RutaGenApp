import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import '../../models/user_model.dart';
import '../account/terms_page.dart';

class LegacyDrawsPage extends StatefulWidget {
  const LegacyDrawsPage(
      {super.key,
      required this.repository,
      required this.user,
      required this.isActive});
  final RutaGenRepository repository;
  final UserModel user;
  final bool isActive;

  @override
  State<LegacyDrawsPage> createState() => _LegacyDrawsPageState();
}

class _LegacyDrawsPageState extends State<LegacyDrawsPage> {
  late Future<MonthlyRanking> _ranking;
  String _selectedType = 'BIKE';

  @override
  void initState() {
    super.initState();
    _ranking = widget.repository.getMonthlyRanking(type: _selectedType);
  }

  @override
  void didUpdateWidget(covariant LegacyDrawsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _refresh();
  }

  Future<void> _refresh() async {
    final future = widget.repository.getMonthlyRanking(type: _selectedType);
    setState(() => _ranking = future);
    try {
      await future;
    } catch (_) {/* FutureBuilder muestra el error. */}
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border)),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      appBar: AppBar(
          title: const Text('Sorteos',
              style: TextStyle(fontWeight: FontWeight.w900))),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Expanded(child: _tab('BIKE', '🚲  Bicicleta', 'Cada mes')),
              const SizedBox(width: 10),
              Expanded(child: _tab('MOTORCYCLE', '🏍  Moto', 'Cada 6 meses')),
            ])),
        const Padding(
            padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Text(
                'Las cargas válidas suman en los dos sorteos si sus períodos coinciden.',
                style: TextStyle(color: AppColors.muted))),
        Expanded(
            child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<MonthlyRanking>(
            future: _ranking,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return ListView(children: [
                  const SizedBox(height: 100),
                  const Center(child: Text('No pudimos cargar el ranking.')),
                  Center(
                      child: TextButton(
                          onPressed: _refresh,
                          child: const Text('Reintentar'))),
                ]);
              }
              final ranking = snapshot.data!;
              final eligible = ranking.eligible;
              final name = widget.user.fullName;
              if (!ranking.configured || ranking.status == 'PAUSED') {
                return ListView(padding: const EdgeInsets.all(24), children: [
                  const SizedBox(height: 65),
                  const Center(
                      child: Icon(Icons.emoji_events_outlined,
                          size: 56, color: AppColors.blue)),
                  const SizedBox(height: 16),
                  Center(
                      child: Text(
                          ranking.configured
                              ? 'Este sorteo no está activo por ahora.'
                              : 'Próximamente: sorteo de ${_selectedType == 'BIKE' ? 'bicicleta' : 'moto'}.',
                          textAlign: TextAlign.center)),
                ]);
              }
              final dateFormat = MaterialLocalizations.of(context);
              String day(DateTime? value) => value == null
                  ? '—'
                  : dateFormat.formatMediumDate(value.toLocal());
              final isUpcoming = ranking.status == 'UPCOMING';
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                children: [
                  Text(
                      'Top 20 · ${ranking.prizeName.isEmpty ? (_selectedType == 'BIKE' ? 'Bicicleta' : 'Moto') : ranking.prizeName}',
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Text(
                      '${isUpcoming ? 'Comienza' : 'Período'}: ${day(ranking.cycleStart)} al ${day(ranking.cycleEnd)}',
                      style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 10),
                  const Text(
                      'La elección es al azar entre los 20 participantes con más puntos por cargas válidas de este período.'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.navy, Color(0xFF086CC1)]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TU INFORMACIÓN',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                          if (widget.user.memberCode != null)
                            Text('Socio ${widget.user.memberCode}',
                                style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 20),
                          Row(children: [
                            Expanded(
                                child: _stat('Tus puntos del período',
                                    '${ranking.points}')),
                            Expanded(
                                child: _stat(
                                    'Tu posición actual',
                                    ranking.position == null
                                        ? '—'
                                        : '#${ranking.position}')),
                          ]),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14)),
                            child: Text(
                              !widget.user.identityVerified
                                  ? 'Verificá tu cuenta en una estación para participar.'
                                  : eligible
                                      ? '¡Estás entre los 20 participantes de este sorteo!'
                                      : 'Actualmente estás fuera del Top 20. Seguí sumando puntos para entrar.',
                              style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                  ),
                  _card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.emoji_events_rounded,
                              color: AppColors.blue),
                          SizedBox(width: 10),
                          Text('Ranking de participantes',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800))
                        ]),
                        Text(
                            'Top 20 · ${day(ranking.cycleStart)} al ${day(ranking.cycleEnd)}',
                            style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 14),
                        if (ranking.top.isEmpty)
                          const Text(
                              'Todavía no hay cargas válidas en este período.'),
                        ...ranking.top.map((entry) => Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 9),
                              decoration: BoxDecoration(
                                color: entry.isMe
                                    ? const Color(0xFFE8F3FF)
                                    : Colors.transparent,
                                border: const Border(
                                    bottom:
                                        BorderSide(color: AppColors.border)),
                              ),
                              child: Row(children: [
                                SizedBox(
                                    width: 36,
                                    child: Text('${entry.position}',
                                        style: TextStyle(
                                            color: entry.position <= 3
                                                ? AppColors.blue
                                                : AppColors.muted,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    child: Text(entry.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: entry.isMe
                                                ? FontWeight.w800
                                                : FontWeight.w500))),
                                Text('${entry.points} pts',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ]),
                            )),
                      ])),
                  if (!eligible)
                    _card(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tu posición',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 10),
                          Text(
                              '${ranking.position == null ? 'Sin posición' : '#${ranking.position}'}  $name  ·  ${ranking.points} pts'),
                          const SizedBox(height: 8),
                          Text(
                              widget.user.identityVerified
                                  ? 'Seguí sumando puntos por cargas para entrar al Top 20.'
                                  : 'Verificá tu cuenta para poder participar.',
                              style: const TextStyle(color: AppColors.muted)),
                        ])),
                  _card(ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined,
                        color: AppColors.blue),
                    title: const Text('Cómo funciona el sorteo'),
                    subtitle:
                        const Text('Puntos, ranking y selección al azar.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                              title: const Text('Cómo funciona'),
                              content: const Text(
                                  'Participan las cuentas verificadas con más puntos acreditados por cargas válidas en el período de cada sorteo. Si ambos sorteos están activos, la misma carga suma para los dos. Los canjes no descuentan puntos del ranking. En caso de empate se ordena por fecha de la última carga y luego por identificador. La selección del ganador entre los 20 participantes es al azar. Consultá las bases oficiales antes de participar.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cerrar')),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => TermsPage(
                                                  acceptedTermsAt: widget
                                                      .user.acceptedTermsAt)));
                                    },
                                    child: const Text('Términos de Ruta Gen')),
                              ],
                            )),
                  )),
                ],
              );
            },
          ),
        )),
      ]),
    );
  }

  Widget _stat(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900)),
      ]);

  Widget _tab(String type, String title, String subtitle) {
    final selected = _selectedType == type;
    return InkWell(
      onTap: () {
        if (!selected) {
          _selectedType = type;
          _refresh();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
              color: selected ? AppColors.navy : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Text(title,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w800)),
            Text(subtitle,
                style: TextStyle(
                    color: selected ? Colors.white70 : AppColors.muted))
          ])),
    );
  }
}
