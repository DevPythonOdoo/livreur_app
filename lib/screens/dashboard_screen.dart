import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/livraison_provider.dart';
import '../models/livraison.dart';
import '../widgets/app_theme.dart';
import '../widgets/connectivity.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDeliveries;
  final String livreurName;
  final Map<String, dynamic>? profile;

  const DashboardScreen({
    super.key,
    this.onNavigateToDeliveries,
    this.livreurName = '',
    this.profile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<LivraisonProvider>();
      p.loadLivraisons();
      p.loadStats();
    });
  }

  Future<void> _refresh() async {
    final p = context.read<LivraisonProvider>();
    await p.loadLivraisons();
    await p.loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE d MMMM', 'fr').format(DateTime.now());
    final connectivity = context.watch<ConnectivityProvider>();
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 16
            ? 'Bon après-midi'
            : 'Bonsoir';
    final dispo = widget.profile?['statut'] == 'disponible';

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dispo
                        ? AppColors.stateOnline
                        : AppColors.stateOffline,
                    boxShadow: dispo
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.stateOnline.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$greeting, ${widget.livreurName.isNotEmpty ? widget.livreurName.split(' ').first : ''}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.white),
                ),
              ],
            ),
            Text(
              today[0].toUpperCase() + today.substring(1),
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Inter'),
            ),
          ],
        ),
        actions: [
          Consumer<LivraisonProvider>(
            builder: (_, prov, __) {
              final count = prov.livraisons.where((l) => l.isActive).length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: widget.onNavigateToDeliveries,
                  ),
                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.orange, width: 1.5),
                          ),
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 20, minHeight: 20),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!connectivity.isOnline) const OfflineBanner(),
          Expanded(
            child: Consumer<LivraisonProvider>(
              builder: (_, prov, __) {
                if (prov.isLoading && prov.stats == null) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.orange));
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.orange,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.marginMobile, 0, Spacing.marginMobile, 90),
                    children: [
                      const SizedBox(height: 8),
                      if (prov.stats != null) _buildHeroCard(prov.stats!),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Livraisons en cours',
                        trailing: widget.onNavigateToDeliveries != null
                            ? TextButton(
                                onPressed: widget.onNavigateToDeliveries,
                                child: const Text('Voir tout',
                                    style: TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (prov.livraisons.where((l) => l.isActive).isEmpty)
                        _buildEmptyState()
                      else
                        ...prov.livraisons
                            .where((l) => l.isActive)
                            .take(5)
                            .map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PriorityCard(
                                    livraison: l,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/delivery-detail',
                                      arguments: l.id,
                                    ),
                                  ),
                                )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: AppColors.blue)),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _buildHeroCard(DeliveryStats stats) {
    final total = stats.aujourdHui;
    final livrees = stats.livrees;
    final taux =
        total > 0 ? (livrees / total * 100).toStringAsFixed(0) : '—';
    final progress = total > 0 ? livrees / total : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orangeLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today_rounded,
                              size: 14, color: AppColors.orange),
                          SizedBox(width: 5),
                          Text(
                            "AUJOURD'HUI",
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.stateOnline,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('Disponible',
                              style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 11,
                                  fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                    fontFamily: 'Inter',
                    letterSpacing: -0.03,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'livraison(s)',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 6,
                    width: double.infinity,
                    color: AppColors.outlineVariant,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.statusSuccess),
                    const SizedBox(width: 4),
                    Text(
                      '$livrees livrées ($taux%)',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${total - livrees} restante(s)',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: _buildKpiMiniGrid(stats),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMiniGrid(DeliveryStats stats) {
    final total = stats.aujourdHui;
    final taux =
        total > 0 ? (stats.livrees / total * 100).toStringAsFixed(0) : '—';

    return Row(
      children: [
        _miniKpi(Icons.local_shipping_rounded, 'En cours', '${stats.enCours}',
            AppColors.orange),
        const SizedBox(width: 8),
        _miniKpi(Icons.check_circle_rounded, 'Livrées', '${stats.livrees}',
            AppColors.statusSuccess),
        const SizedBox(width: 8),
        _miniKpi(Icons.cancel_rounded, 'Échecs', '${stats.echecs}',
            AppColors.statusFailed),
        const SizedBox(width: 8),
        _miniKpi(Icons.trending_up_rounded, 'Taux', '$taux%', AppColors.blue),
      ],
    );
  }

  Widget _miniKpi(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
                fontFamily: 'Inter',
                letterSpacing: -0.01,
                height: 1.2,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.statusSuccess.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 48, color: AppColors.statusSuccess),
          ),
          const SizedBox(height: 16),
          const Text('Tout est calme !',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                  fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text(
            'Aucune livraison active pour le moment.\nLes nouvelles missions apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final Livraison livraison;
  final VoidCallback onTap;

  const _PriorityCard({required this.livraison, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUrgent = livraison.statut == 'en_cours';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.orange.withValues(alpha: 0.4)
              : AppColors.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? AppColors.orangeLight
                            : AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isUrgent ? 'URGENT' : 'Standard',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isUrgent
                              ? AppColors.orange
                              : AppColors.onSurfaceVariant,
                          fontFamily: 'Inter',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${livraison.commandeNumero}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.blue.withValues(alpha: 0.5),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  livraison.clientNom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.blue,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${livraison.adresse}, ${livraison.ville}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.blue.withValues(alpha: 0.6),
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'DÉMARRER LA NAVIGATION',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Inter'),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.orange),
                      foregroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
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
