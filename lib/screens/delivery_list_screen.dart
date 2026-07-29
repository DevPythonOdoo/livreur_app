import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/livraison_provider.dart';
import '../models/livraison.dart';
import '../widgets/state_widgets.dart';
import '../widgets/connectivity.dart';
import '../widgets/app_theme.dart';
import 'map_view_screen.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivraisonProvider>().loadLivraisons();
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    return Scaffold(
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
        title: const Text('Mes livraisons',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!connectivity.isOnline) const OfflineBanner(),
          _buildSearchBar(),
          Expanded(
            child: Consumer<LivraisonProvider>(
              builder: (_, prov, __) {
                if (prov.isLoading && prov.livraisons.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryContainer));
                }
                if (prov.error != null && prov.livraisons.isEmpty) {
                  return ErrorStateWidget(
                    message: prov.error!,
                    onRetry: () => prov.loadLivraisons(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => prov.loadLivraisons(),
                  color: AppColors.primaryContainer,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                          child: _buildFilterTabs(prov)),
                      SliverToBoxAdapter(
                          child: _buildCountInfo(prov)),
                      if (_filtered(prov).isEmpty)
                        SliverFillRemaining(
                          child: _buildEmptyState(prov),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                              Spacing.marginMobile,
                              Spacing.xs,
                              Spacing.marginMobile,
                              Spacing.lg),
                          sliver: SliverList.separated(
                            itemCount: _filtered(prov).length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _DeliveryCard(
                              livraison: _filtered(prov)[i],
                              onCall: _callClient,
                            ),
                          ),
                        ),
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

  Widget _buildEmptyState(LivraisonProvider prov) {
    final icon = _searchQuery.isNotEmpty
        ? Icons.search_off_rounded
        : Icons.local_shipping_rounded;
    final title = _searchQuery.isNotEmpty
        ? 'Aucun résultat'
        : 'Aucune livraison';
    final subtitle = _searchQuery.isNotEmpty
        ? 'Essayez un autre terme de recherche'
        : 'Les livraisons du jour apparaîtront ici';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  size: 48, color: AppColors.onSurface.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter')),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }

  List<Livraison> _filtered(LivraisonProvider prov) {
    final list = prov.livraisons;
    if (_searchQuery.isEmpty) return list;
    return list.where((l) =>
        l.clientNom.toLowerCase().contains(_searchQuery) ||
        l.adresse.toLowerCase().contains(_searchQuery) ||
        l.ville.toLowerCase().contains(_searchQuery) ||
        l.commandeNumero.toLowerCase().contains(_searchQuery)).toList();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.marginMobile, Spacing.md, Spacing.marginMobile, Spacing.xs),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Rechercher un client, une adresse...',
          hintStyle: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              fontFamily: 'Inter'),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceDim,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.primaryContainer, width: 1.5),
          ),
        ),
        style: const TextStyle(
            fontSize: 14, color: AppColors.onSurface, fontFamily: 'Inter'),
      ),
    );
  }

  Widget _buildFilterTabs(LivraisonProvider prov) {
    final filters = [
      ('Toutes', ''),
      ('En cours', 'active'),
      ('Livrées', 'livree'),
      ('Échec', 'echec'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.marginMobile, Spacing.sm, Spacing.marginMobile, Spacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final (label, value) = f;
            final sel = value == prov.filter || (value == '' && prov.filter == '');
            final chipColor = value == 'livree'
                ? AppColors.statusSuccess
                : value == 'echec'
                    ? AppColors.statusFailed
                    : value == 'active'
                        ? AppColors.primaryContainer
                        : AppColors.primaryContainer;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        fontFamily: 'Inter')),
                selected: sel,
                selectedColor: chipColor,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.onSurfaceVariant),
                backgroundColor:
                    chipColor.withValues(alpha: 0.1),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                onSelected: (_) => prov.setFilter(value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCountInfo(LivraisonProvider prov) {
    final count = _filtered(prov).length;
    final label = prov.filter.isEmpty
        ? "aujourd'hui"
        : prov.filter == 'active'
            ? 'actives'
            : prov.filter == 'livree'
                ? 'livrées'
                : 'en échec';
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.marginMobile, vertical: Spacing.xs),
      child: Text(
        '$count livraison${count > 1 ? 's' : ''} $label'
        '${_searchQuery.isNotEmpty ? ' \u00b7 "${_searchCtrl.text}"' : ''}',
        style: TextStyle(
            color: AppColors.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            fontFamily: 'Inter'),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Livraison livraison;
  final void Function(String phone) onCall;

  const _DeliveryCard({required this.livraison, required this.onCall});

  Color _color(String statut) {
    switch (statut) {
      case 'livree':
        return AppColors.statusSuccess;
      case 'echec':
      case 'annulee':
        return AppColors.statusFailed;
      case 'en_cours':
      case 'arrive_destination':
        return AppColors.primaryContainer;
      case 'prise_en_charge':
        return AppColors.primaryContainer;
      default:
        return AppColors.stateOffline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(livraison.statut);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context, '/delivery-detail',
            arguments: livraison.id,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(livraison.clientNom,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 2),
                          Text('#${livraison.commandeNumero}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurface
                                      .withValues(alpha: 0.5),
                                  fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                    StatutBadge(
                      statut: livraison.statut,
                      label: livraison.statutDisplay,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${livraison.adresse}, ${livraison.ville}',
                        style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${livraison.commandeMontantTtc.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primaryContainer,
                          fontFamily: 'Inter'),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.phone_rounded,
                            size: 18, color: AppColors.primaryContainer),
                        onPressed: () =>
                            onCall(livraison.clientTelephone),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.navigation_rounded,
                            size: 18, color: AppColors.primaryContainer),
                        onPressed: () => Navigator.pushNamed(
                          context, '/map-view',
                          arguments: MapViewArgs(
                              adresse: livraison.adresse,
                              ville: livraison.ville),
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18,
                        color: AppColors.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
