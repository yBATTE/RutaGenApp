import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../data/ruta_gen_repository.dart';
import '../../models/user_model.dart';
import 'legacy_draws_page.dart';

class DrawsPage extends StatefulWidget {
  const DrawsPage({super.key, required this.repository, required this.user, required this.isActive});
  final RutaGenRepository repository;
  final UserModel user;
  final bool isActive;
  @override
  State<DrawsPage> createState() => _DrawsPageState();
}

class _DrawsPageState extends State<DrawsPage> {
  late Future<List<DrawEvent>> _events;
  @override
  void initState() { super.initState(); _events = widget.repository.getDrawEvents(); }
  @override
  void didUpdateWidget(covariant DrawsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _refresh();
  }
  Future<void> _refresh() async {
    final future = widget.repository.getDrawEvents();
    setState(() => _events = future);
    try { await future; } catch (_) { /* FutureBuilder informa el error. */ }
  }
  Widget card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border)), child: child);
  String day(BuildContext context, DateTime? value) => value == null ? '—' :
    MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  String lastDay(BuildContext context, DateTime? exclusiveEnd) =>
    day(context, exclusiveEnd?.subtract(const Duration(days: 1)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F9FD),
    appBar: AppBar(title: const Text('Sorteos', style: TextStyle(fontWeight: FontWeight.w900))),
    body: RefreshIndicator(onRefresh: _refresh, child: FutureBuilder<List<DrawEvent>>(
      future: _events, builder: (context, snapshot) {
        if (!snapshot.hasData) return ListView(children: [
          const SizedBox(height: 85),
          if (snapshot.hasError) const Center(child: Text('No pudimos cargar los sorteos.'))
          else const Center(child: CircularProgressIndicator()),
          if (snapshot.hasError) Center(child: TextButton(onPressed: _refresh, child: const Text('Reintentar'))),
        ]);
        final events = snapshot.data!;
        final current = events.where((item) => item.status != 'DRAWN').toList();
        final past = events.where((item) => item.status == 'DRAWN').toList();
        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Sorteos actuales y próximos',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
          if (current.isEmpty) card(const Text('Por ahora no hay sorteos activos.')),
          ...current.map((item) => _eventCard(context, item)),
          const Padding(padding: EdgeInsets.fromLTRB(0, 18, 0, 8), child: Text('Sorteos anteriores',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
          if (past.isEmpty) card(const Text('Aún no hay resultados anteriores.')),
          ...past.map((item) => _eventCard(context, item)),
          TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
            LegacyDrawsPage(repository: widget.repository, user: widget.user, isActive: true))),
            child: const Text('Ver sorteos periódicos anteriores: bici y moto')),
        ]);
      },
    )),
  );

  Widget _eventCard(BuildContext context, DrawEvent item) => InkWell(
    borderRadius: BorderRadius.circular(18), onTap: () => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _DrawDetail(repository: widget.repository, user: widget.user, event: item))),
    child: card(Row(children: [
      if (item.imageUrls.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 14),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(item.imageUrls.first,
          width: 68, height: 68, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard)))),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(item.prizeName),
        Text('${day(context, item.startAt)} al ${lastDay(context, item.endAt)}',
          style: const TextStyle(color: AppColors.muted)),
        if (item.winnerName != null) Text('Ganador: ${item.winnerName}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ])), const Icon(Icons.chevron_right, color: AppColors.blue),
    ])),
  );
}

class _DrawDetail extends StatefulWidget {
  const _DrawDetail({required this.repository, required this.user, required this.event});
  final RutaGenRepository repository;
  final UserModel user;
  final DrawEvent event;
  @override
  State<_DrawDetail> createState() => _DrawDetailState();
}
class _DrawDetailState extends State<_DrawDetail> {
  String litersText(double value) => '${value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} L';
  late Future<MonthlyRanking> _ranking;
  @override
  void initState() { super.initState(); _ranking = widget.repository.getDrawEventRanking(widget.event.id); }
  Future<void> _refresh() async {
    final future = widget.repository.getDrawEventRanking(widget.event.id);
    setState(() => _ranking = future);
    try { await future; } catch (_) { /* FutureBuilder muestra el error. */ }
  }
  @override
  Widget build(BuildContext context) {
    final item = widget.event;
    final byLiters = item.metric == 'LITERS';
    final fmt = MaterialLocalizations.of(context);
    String day(DateTime? d) => d == null ? '—' : fmt.formatMediumDate(d.toLocal());
    return Scaffold(appBar: AppBar(title: Text(item.title)), backgroundColor: const Color(0xFFF6F9FD),
      body: RefreshIndicator(onRefresh: _refresh, child: FutureBuilder<MonthlyRanking>(future: _ranking,
        builder: (context, snapshot) => ListView(padding: const EdgeInsets.all(16), children: [
          if (item.imageUrls.isNotEmpty) SizedBox(height: 220, child: ListView.separated(scrollDirection: Axis.horizontal,
            itemCount: item.imageUrls.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) => ClipRRect(borderRadius: BorderRadius.circular(15),
              child: Image.network(item.imageUrls[index], width: 250, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, size: 70))))),
          const SizedBox(height: 14),
          Text(item.prizeName, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(item.description)),
          const SizedBox(height: 10),
          Text('Acumulación: ${day(item.startAt)} al ${day(item.endAt?.subtract(const Duration(days: 1)))}'),
          Text('Fecha del sorteo: ${day(item.drawAt)}'),
          if (item.winnerName != null) Text('Ganador: ${item.winnerName}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Container(width: double.infinity, padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Cómo funciona este sorteo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 8),
              Text(item.rules, style: const TextStyle(color: AppColors.muted, height: 1.4)),
              if (item.conditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Condiciones particulares', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(item.conditions, style: const TextStyle(color: AppColors.muted, height: 1.4)),
              ],
            ])),
          const SizedBox(height: 18),
          if (snapshot.hasError) TextButton(onPressed: _refresh, child: const Text('No se pudo cargar el ranking. Reintentar'))
          else if (!snapshot.hasData) const Center(child: CircularProgressIndicator())
          else ...[
            Text('Tu posición: ${snapshot.data!.position == null ? 'Sin posición' : '#${snapshot.data!.position}'} · ${byLiters ? litersText(snapshot.data!.liters) : '${snapshot.data!.points} pts'}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(!widget.user.identityVerified ? 'Verificá tu cuenta en una estación para participar.' :
              snapshot.data!.eligible ? 'Estás entre los ${item.qualifyingCount} participantes.' : 'Seguí sumando ${byLiters ? 'litros' : 'puntos'} para entrar entre los ${item.qualifyingCount} primeros.'),
            const SizedBox(height: 16),
            Text('Top ${item.qualifyingCount}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            if (snapshot.data!.top.isEmpty) Text('Todavía no hay participantes con ${byLiters ? 'litros' : 'puntos'}.'),
            ...snapshot.data!.top.map((entry) => Card(child: ListTile(
              leading: Text('#${entry.position}'), title: Text(entry.name),
              trailing: Text(byLiters ? litersText(entry.liters) : '${entry.points} pts'), tileColor: entry.isMe ? const Color(0xFFE8F3FF) : null))),
          ],
        ]))));
  }
}
