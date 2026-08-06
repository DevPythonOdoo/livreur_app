import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/livraison_provider.dart';
import '../models/livraison.dart';
import '../widgets/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivraisonProvider>().loadLivraisons();
    });
  }

  List<Livraison> _filtered(LivraisonProvider prov, String filter) {
    final all = prov.livraisons;
    final now = DateTime.now();
    switch (filter) {
      case 'today':
        return all.where((l) {
          final d = DateTime.tryParse(l.dateCreation);
          return d != null && _isSameDay(d, now);
        }).toList();
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return all.where((l) {
          final d = DateTime.tryParse(l.dateCreation);
          return d != null && _isSameDay(d, yesterday);
        }).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return all.where((l) {
          final d = DateTime.tryParse(l.dateCreation);
          return d != null && d.isAfter(weekAgo);
        }).toList();
      case 'month':
        return all.where((l) {
          final d = DateTime.tryParse(l.dateCreation);
          return d != null && d.month == now.month && d.year == now.year;
        }).toList();
      default:
        return all;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        title: const Text('Historique',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<LivraisonProvider>(
        builder: (_, prov, __) {
          final filtered = _filtered(prov, _selectedFilter);
          final completed = filtered.where((l) => l.statut == 'livree').length;
          final revenue = filtered.fold<double>(
              0, (sum, l) => sum + (l.commandeMontantTtc));

          return RefreshIndicator(
            onRefresh: () => prov.loadLivraisons(),
            color: AppColors.primaryContainer,
            child: CustomScrollView(
              slivers: [
                // KPI summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.marginMobile, 16, Spacing.marginMobile, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.statusSuccess, size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  '$completed',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.statusSuccess,
                                      fontFamily: 'Inter'),
                                ),
                                Text(
                                  'Complétée${completed > 1 ? 's' : ''}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurface
                                          .withValues(alpha: 0.6),
                                      fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.monetization_on_rounded,
                                    color: AppColors.primaryContainer, size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  revenue.toStringAsFixed(0),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryContainer,
                                      fontFamily: 'Inter'),
                                ),
                                Text(
                                  'Revenu FCFA',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurface
                                          .withValues(alpha: 0.6),
                                      fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Date filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.marginMobile, 0,
                        Spacing.marginMobile, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                              label: 'Tout',
                              value: 'all',
                              selected: _selectedFilter == 'all',
                              onTap: () => setState(() => _selectedFilter = 'all')),
                          _FilterChip(
                              label: "Aujourd'hui",
                              value: 'today',
                              selected: _selectedFilter == 'today',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'today')),
                          _FilterChip(
                              label: 'Hier',
                              value: 'yesterday',
                              selected: _selectedFilter == 'yesterday',
                              onTap: () => setState(
                                  () => _selectedFilter = 'yesterday')),
                          _FilterChip(
                              label: 'Cette semaine',
                              value: 'week',
                              selected: _selectedFilter == 'week',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'week')),
                          _FilterChip(
                              label: 'Ce mois',
                              value: 'month',
                              selected: _selectedFilter == 'month',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'month')),
                        ],
                      ),
                    ),
                  ),
                ),
                // List
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 48,
                              color: AppColors.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text('Aucun historique',
                              style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.marginMobile, 0, Spacing.marginMobile, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => _HistoryCard(
                          livraison: filtered[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Inter')),
        selected: selected,
        selectedColor: AppColors.primaryContainer,
        labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.onSurfaceVariant),
        backgroundColor: AppColors.surfaceContainerHigh,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Livraison livraison;

  const _HistoryCard({required this.livraison});

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final isSuccess = livraison.statut == 'livree';
    final dt = DateTime.tryParse(livraison.dateCreation);
    final dateStr =
        dt != null ? _dateFmt.format(dt) : livraison.dateCreation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context, '/delivery-detail',
            arguments: livraison.id,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isSuccess
                            ? AppColors.statusSuccess
                            : AppColors.statusFailed)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: isSuccess
                        ? AppColors.statusSuccess
                        : AppColors.statusFailed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(livraison.clientNom,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter')),
                      const SizedBox(height: 2),
                      Text(
                        '#${livraison.commandeNumero} \u00b7 $dateStr',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                            fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${livraison.commandeMontantTtc.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSuccess
                        ? AppColors.statusSuccess
                        : AppColors.onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
