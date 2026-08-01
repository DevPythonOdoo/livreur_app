import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/livraison_provider.dart';
import '../models/livraison.dart';
import '../widgets/state_widgets.dart';
import '../widgets/connectivity.dart';
import '../widgets/app_theme.dart';

class AgendaScreen extends StatefulWidget {
  final void Function(int index)? onNavigateToDetail;
  final VoidCallback? onOpenDrawer;
  const AgendaScreen({super.key, this.onNavigateToDetail, this.onOpenDrawer});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _selectedDate;
  late DateTime _today;
  late List<DateTime> _visibleDates;
  late ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _selectedDate = _today;
    _visibleDates = _buildDateRange(_today);
    _dateScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
      _loadPlanning();
    });
  }

  void _scrollToToday() {
    if (!_dateScrollController.hasClients) return;
    const itemWidth = 64.0;
    final todayIndex = 14;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = todayIndex * itemWidth - (screenWidth / 2 - 29);
    _dateScrollController.animateTo(
      offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  List<DateTime> _buildDateRange(DateTime center) {
    final dates = <DateTime>[];
    for (int i = -14; i <= 14; i++) {
      dates.add(DateTime(center.year, center.month, center.day + i));
    }
    return dates;
  }

  void _loadPlanning() {
    final start = _visibleDates.first;
    final end = _visibleDates.last;
    context.read<LivraisonProvider>().loadPlanning(start, end);
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    context.read<LivraisonProvider>().selectAgendaDate(date);
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _goToToday() {
    _selectDate(_today);
    setState(() {
      _visibleDates = _buildDateRange(_today);
    });
    _loadPlanning();
  }

  String _dayName(DateTime d) {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return names[d.weekday - 1];
  }

  bool _isToday(DateTime d) =>
      d.year == _today.year && d.month == _today.month && d.day == _today.day;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    final provider = context.watch<LivraisonProvider>();
    final deliveries = provider.getDeliveriesForDate(_selectedDate);

    // Grouper par statut
    final Map<String, List<Livraison>> grouped = {};
    for (final d in deliveries) {
      grouped.putIfAbsent(d.statut, () => []).add(d);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {
              final onOpen = widget.onOpenDrawer;
              if (onOpen != null) {
                onOpen();
              } else {
                Scaffold.of(ctx).openDrawer();
              }
            },
          ),
        ),
        title: const Text('Agenda',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded, size: 22),
            tooltip: "Aujourd'hui",
            onPressed: _goToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!connectivity.isOnline) const OfflineBanner(),
          _buildDateStrip(provider),
          Expanded(child: _buildDeliveriesList(grouped, provider)),
        ],
      ),
    );
  }

  Widget _buildDateStrip(LivraisonProvider provider) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView.builder(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: _visibleDates.length,
              itemBuilder: (_, i) {
                final d = _visibleDates[i];
                final isSelected = _isSameDay(d, _selectedDate);
                final isToady = _isToday(d);
                final count = provider.getCountForDate(d);

                return GestureDetector(
                  onTap: () => _selectDate(d),
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToady
                              ? AppColors.primaryContainer.withValues(alpha: 0.08)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayName(d),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.onSurface,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : count > 0
                                    ? AppColors.primaryContainer
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            count > 0 ? '$count' : '',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildDeliveriesList(
    Map<String, List<Livraison>> grouped,
    LivraisonProvider provider,
  ) {
    if (provider.isPlanningLoading && grouped.isEmpty) {
      return const LoadingWidget(message: 'Chargement de l\'agenda...');
    }

    if (provider.planningError != null && grouped.isEmpty) {
      return ErrorStateWidget(
        message: provider.planningError!,
        onRetry: _loadPlanning,
      );
    }

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: Spacing.md),
            Text(
              'Aucune livraison',
              style: TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            Text(
              _isToday(_selectedDate)
                  ? 'Aucune livraison prévue aujourd\'hui'
                  : 'Aucune livraison pour cette date',
              style: TextStyle(
                  fontSize: 13, color: AppColors.outlineVariant),
            ),
          ],
        ),
      );
    }

    // Ordre des sections de statut
    const statusOrder = ['preparation', 'en_cours', 'arrive_destination', 'livree', 'echec'];
    const statusLabels = {
      'preparation': 'À livrer',
      'en_cours': 'En route',
      'arrive_destination': 'Arrivé',
      'livree': 'Livrée',
      'echec': 'Échec',
    };

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadPlanning(_visibleDates.first, _visibleDates.last);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            Spacing.marginMobile, Spacing.md, Spacing.marginMobile, Spacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Text(
              _formatDateHeader(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ),
          for (final status in statusOrder) ...[
            if (grouped.containsKey(status)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabels[status] ?? status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${grouped[status]!.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final liv in grouped[status]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PlanningCard(livraison: liv),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Color _statusColor(String statut) {
    switch (statut) {
      case 'preparation':
        return AppColors.onSurfaceVariant;
      case 'en_cours':
      case 'arrive_destination':
        return AppColors.primaryContainer;
      case 'livree':
        return AppColors.statusSuccess;
      case 'echec':
      case 'annulee':
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _formatDateHeader(DateTime d) {
    if (_isSameDay(d, _today)) return "Aujourd'hui";
    final yesterday = DateTime(_today.year, _today.month, _today.day - 1);
    if (_isSameDay(d, yesterday)) return 'Hier';
    final tomorrow = DateTime(_today.year, _today.month, _today.day + 1);
    if (_isSameDay(d, tomorrow)) return 'Demain';
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _PlanningCard extends StatelessWidget {
  final Livraison livraison;
  const _PlanningCard({required this.livraison});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context, '/delivery-detail',
          arguments: livraison.id,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: _statutColor(livraison.statut),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(livraison.clientNom,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.onSurface)),
                          ),
                          StatutBadge(
                            statut: livraison.statut,
                            label: livraison.statutDisplay,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${livraison.adresse}, ${livraison.ville}',
                              style: const TextStyle(
                                  color: AppColors.onSurfaceVariant, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.receipt_outlined,
                              size: 13, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            livraison.commandeNumero,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Text(
                            '${livraison.commandeMontantTtc.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'livree':
        return AppColors.statusSuccess;
      case 'echec':
      case 'annulee':
        return AppColors.error;
      case 'en_cours':
      case 'arrive_destination':
        return AppColors.primaryContainer;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}
