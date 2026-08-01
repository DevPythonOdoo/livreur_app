import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/livraison_provider.dart';
import '../models/livraison.dart';
import '../widgets/app_theme.dart';
import '../widgets/connectivity.dart';
import '../widgets/main_drawer.dart';
import 'delivery_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDeliveries;
  final ValueChanged<int>? onSelectTab;
  final VoidCallback? onHistory;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLateOrders;
  final VoidCallback? onSettings;
  final VoidCallback? onHelp;
  final VoidCallback? onAbout;
  final VoidCallback? onLogout;
  final String livreurName;
  final Map<String, dynamic>? profile;

  const DashboardScreen({
    super.key,
    this.onNavigateToDeliveries,
    this.onSelectTab,
    this.onHistory,
    this.onChangePassword,
    this.onLateOrders,
    this.onSettings,
    this.onHelp,
    this.onAbout,
    this.onLogout,
    this.livreurName = '',
    this.profile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLocked = true;
  final List<int> _kpiOrder = [0, 1, 2, 3];

  final List<_KpiDef> _kpiDefs = const [
    _KpiDef(Icons.local_shipping_rounded, 'En cours', AppColors.orange),
    _KpiDef(Icons.check_circle_rounded, 'Livrées', AppColors.statusSuccess),
    _KpiDef(Icons.cancel_rounded, 'Échecs', AppColors.statusFailed),
    _KpiDef(Icons.trending_up_rounded, 'Taux', AppColors.blue),
  ];

  String _kpiValue(DeliveryStats stats, int idx) {
    if (idx == 0) return '${stats.enCours}';
    if (idx == 1) return '${stats.livrees}';
    if (idx == 2) return '${stats.echecs}';
    final total = stats.aujourdHui;
    return total > 0
        ? '${(stats.livrees / total * 100).toStringAsFixed(0)}%'
        : '—';
  }

  void _openRetardView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DeliveryListScreen(initialFilter: 'retard'),
      ),
    );
  }

  Widget _buildDrawer() {
    final profile = widget.profile;
    final prenom = profile?['prenom'] as String? ?? '';
    final nom = profile?['nom'] as String? ?? '';
    final fullName = '$prenom $nom'.trim();
    final photoUrl = profile?['photo_profil'] as String?;
    final telephone = profile?['telephone'] as String? ?? '';
    final vehicule = profile?['vehicule'] as String? ?? '';
    final plaque = profile?['plaque_immatriculation'] as String? ?? '';
    final dispo = profile?['statut'] == 'disponible';

    return MainDrawer(
      fullName: fullName.isNotEmpty ? fullName : widget.livreurName,
      photoUrl: photoUrl,
      telephone: telephone,
      vehicule: vehicule,
      plaque: plaque,
      dispo: dispo,
      currentIndex: 0,
      onSelectTab: (i) => widget.onSelectTab?.call(i),
      onHistory: () => widget.onHistory?.call(),
      onChangePassword: () => widget.onChangePassword?.call(),
      onLateOrders: widget.onLateOrders ?? _openRetardView,
      onSettings: () => widget.onSettings?.call(),
      onHelp: () => widget.onHelp?.call(),
      onAbout: () => widget.onAbout?.call(),
      onLogout: () => widget.onLogout?.call(),
    );
  }

  void _onKpiReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _kpiOrder.removeAt(oldIndex);
      _kpiOrder.insert(newIndex, item);
    });
  }

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
      drawer: _buildDrawer(),
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
                      const SizedBox(height: 16),
                      if (prov.stats != null) _buildKpiSection(prov.stats!),
                      const SizedBox(height: 20),
                      if (prov.stats != null && prov.stats!.enRetard > 0) ...[
                        _buildRetardAlertCard(prov.stats!),
                        const SizedBox(height: 20),
                      ],
                      if (prov.livraisons.where((l) => l.enRetard).isNotEmpty) ...[
                        _buildSectionHeader(
                          'Commandes en retard',
                          trailing: TextButton(
                            onPressed: _openRetardView,
                            child: const Text('Voir tout',
                                style: TextStyle(
                                    color: AppColors.statusFailed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...prov.livraisons
                            .where((l) => l.enRetard)
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
                        const SizedBox(height: 20),
                      ],
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(23),
              topRight: Radius.circular(23),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.orange, Color(0xFFFF8C5A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              "AUJOURD'HUI",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 24,
                        child: GestureDetector(
                          onTap: () => setState(() => _isLocked = !_isLocked),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLocked
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                if (!_isLocked) ...[
                                  const SizedBox(width: 3),
                                  const Text(
                                    'Réorg.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('En ligne',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AnimatedNumber(
                            value: total,
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Inter',
                              letterSpacing: -0.03,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'livraisons aujourd\'hui',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$taux%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Inter',
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'succès',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 4,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.3),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$livrees livrées',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${total - livrees} restantes',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetardAlertCard(DeliveryStats stats) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.statusFailed, Color(0xFFE5484D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusFailed.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openRetardView,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          _AnimatedNumber(
                            value: stats.enRetard,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Inter',
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'commande${stats.enRetard > 1 ? 's' : ''} en retard',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Touchez pour voir les commandes en retard',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(DeliveryStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Aperçu des livraisons',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: AppColors.blue,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 24,
              child: GestureDetector(
                onTap: () => setState(() => _isLocked = !_isLocked),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isLocked
                        ? AppColors.blueLight
                        : AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLocked
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        size: 11,
                        color: _isLocked ? AppColors.blue : AppColors.orange,
                      ),
                      if (!_isLocked) ...[
                        const SizedBox(width: 3),
                        const Text(
                          'Réorg.',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildKpiMiniGrid(stats),
      ],
    );
  }

  Widget _buildKpiMiniGrid(DeliveryStats stats) {
    return _isLocked
        ? _buildLockedKpiRow(stats)
        : _buildReorderableKpiRow(stats);
  }

  Widget _buildLockedKpiRow(DeliveryStats stats) {
    return Row(
      children: [
        for (int pos = 0; pos < _kpiOrder.length; pos++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: pos < _kpiOrder.length - 1 ? 8 : 0),
              child: _kpiCard(_kpiOrder[pos], stats),
            ),
          ),
      ],
    );
  }

  Widget _buildReorderableKpiRow(DeliveryStats stats) {
    return SizedBox(
      height: 92,
      child: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          onReorder: _onKpiReorder,
          itemCount: _kpiOrder.length,
          proxyDecorator: (child, idx, anim) => AnimatedBuilder(
            animation: anim,
            builder: (_, c) => Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black26,
              child: c,
            ),
            child: child,
          ),
          itemBuilder: (context, pos) {
            final i = _kpiOrder[pos];
            final isLast = pos == _kpiOrder.length - 1;
            return SizedBox(
              key: ValueKey(i),
              width: (MediaQuery.of(context).size.width -
                      (isLast ? 12 : 20)) /
                  4,
              height: 92,
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 4 : 8),
                child: _kpiCard(i, stats),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _kpiCard(int index, DeliveryStats stats) {
    final def = _kpiDefs[index];
    final value = _kpiValue(stats, index);
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 19,
      color: def.color,
      fontFamily: 'Inter',
      letterSpacing: -0.01,
      height: 1.1,
    );
    final Widget valueWidget = value == '—'
        ? Text(value, style: valueStyle)
        : value.endsWith('%')
            ? _AnimatedNumber(
                value: int.tryParse(value.substring(0, value.length - 1)) ?? 0,
                suffix: '%',
                style: valueStyle,
              )
            : _AnimatedNumber(
                value: int.tryParse(value) ?? 0,
                style: valueStyle,
              );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: def.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(def.icon, color: def.color, size: 17),
          ),
          const SizedBox(height: 5),
          valueWidget,
          Text(
            def.label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!_isLocked)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.drag_handle_rounded,
                size: 10,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
        ],
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

class _KpiDef {
  final IconData icon;
  final String label;
  final Color color;
  const _KpiDef(this.icon, this.label, this.color);
}

/// Compteur animé : fait défiler le chiffre de la valeur précédente
/// vers la nouvelle à chaque mise à jour.
class _AnimatedNumber extends StatelessWidget {
  final int value;
  final String? suffix;
  final TextStyle style;

  const _AnimatedNumber({
    required this.value,
    required this.style,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        '${v.round()}${suffix ?? ''}',
        style: style,
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
    final isLate = livraison.enRetard;
    final isUrgent = livraison.statut == 'en_cours' && !isLate;
    final badgeColor = isLate
        ? AppColors.statusFailed
        : isUrgent
            ? AppColors.orange
            : AppColors.surfaceDim;
    final badgeText = isLate
        ? 'EN RETARD'
        : isUrgent
            ? 'URGENT'
            : 'Standard';
    final badgeTextColor = isLate || isUrgent
        ? badgeColor
        : AppColors.onSurfaceVariant;
    final borderColor = isLate
        ? AppColors.statusFailed.withValues(alpha: 0.4)
        : isUrgent
            ? AppColors.orange.withValues(alpha: 0.4)
            : AppColors.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
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
                if (isLate && livraison.dateLivraisonSouhaitee != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: AppColors.statusFailed),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Livraison souhaitée le ${DateFormat('d MMM HH:mm', 'fr').format(livraison.dateLivraisonSouhaitee!.toLocal())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.statusFailed,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
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
