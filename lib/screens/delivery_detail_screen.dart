import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/livraison_provider.dart';
import '../widgets/connectivity.dart';
import '../widgets/app_theme.dart';
import '../widgets/priority_widgets.dart';
import '../widgets/contact_actions.dart';
import 'map_view_screen.dart';
import '../services/receipt_service.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final int livraisonId;
  const DeliveryDetailScreen({super.key, required this.livraisonId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivraisonProvider>().loadDetail(widget.livraisonId);
    });
  }

  Color _c(String statut) {
    switch (statut) {
      case 'livree': return AppColors.statusSuccess;
      case 'echec':
      case 'annulee': return AppColors.error;
      case 'en_cours': return AppColors.primaryContainer;
      case 'arrive_destination': return AppColors.statusSuccess;
      case 'preparation': return AppColors.onSurfaceVariant;
      default: return AppColors.onSurfaceVariant;
    }
  }

  IconData _icon(String statut) {
    switch (statut) {
      case 'livree': return Icons.check_circle_rounded;
      case 'echec': return Icons.cancel_rounded;
      case 'annulee': return Icons.block_rounded;
      case 'en_cours': return Icons.local_shipping_rounded;
      case 'arrive_destination': return Icons.location_on_rounded;
      case 'preparation': return Icons.inventory_2_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  void _openMaps(String adresse, String ville) {
    Navigator.of(context).pushNamed('/navigation',
        arguments: MapViewArgs(adresse: adresse, ville: ville));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectivity = context.watch<ConnectivityProvider>();

    if (!connectivity.isOnline) {
      return NoConnectionScreen(
        onRetry: () => context.read<LivraisonProvider>()
            .loadDetail(widget.livraisonId),
      );
    }

    return Scaffold(
      body: Consumer<LivraisonProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading && prov.selectedLivraison == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final liv = prov.selectedLivraison;
          if (liv == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: Spacing.md),
                    Text(prov.error ?? 'Livraison introuvable',
                        style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }

          final couleur = _c(liv.statut);
          final canDepart = liv.statut == 'preparation' ||
              liv.statut == 'prise_en_charge';
          final canArrive = liv.statut == 'en_cours';
          final canDeliver = liv.statut == 'arrive_destination';
          final canFail = liv.statut == 'arrive_destination' ||
              liv.statut == 'en_cours';
          final hasActions = canDepart || canArrive || canDeliver || canFail;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => prov.loadDetail(widget.livraisonId),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 180,
                        pinned: true,
                        stretch: true,
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.pop(context),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            color: AppColors.orange,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(_icon(liv.statut),
                                      size: 28, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                Text('#${liv.commandeNumero}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    liv.statutDisplay.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Spacing.xl),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(Spacing.marginMobile, Spacing.xl, Spacing.marginMobile, hasActions ? 100 : Spacing.xl),
                          child: Column(
                            children: [
                              if (liv.estPrioritaire) ...[
                                PriorityBanner(
                                  priorite: liv.priorite,
                                  fraisPriorite: liv.fraisPriorite,
                                ),
                                const SizedBox(height: Spacing.md),
                              ],
                              _buildClientCard(theme, liv),
                              const SizedBox(height: Spacing.md),
                              _buildCommandeCard(theme, liv, couleur),
                              const SizedBox(height: Spacing.md),
                              if (liv.dateDepart != null || liv.dateArrivee != null)
                                _buildTrajetCard(theme, liv),
                              if (liv.evenements.isNotEmpty) ...[
                                const SizedBox(height: Spacing.md),
                                _buildTimeline(theme, liv),
                              ],
                              if (liv.statut == 'livree') ...[
                                const SizedBox(height: Spacing.md),
                                _buildTicketButton(theme, liv),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasActions)
                _buildBottomActionBar(context, theme, liv,
                    canDepart, canArrive, canDeliver, canFail, couleur),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, ThemeData theme, dynamic liv,
      bool canDepart, bool canArrive, bool canDeliver, bool canFail, Color couleur) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canFail)
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context, '/report-failure',
                  arguments: liv.id,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: AppColors.error,
                ),
                icon: const Icon(Icons.cancel_rounded, size: 20),
                label: Text(
                    canDeliver ? 'Échec' : 'Abandonner',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          if (canFail) const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: _buildPrimaryAction(
                liv, canDepart, canArrive, canDeliver, couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(dynamic liv,
      bool canDepart, bool canArrive, bool canDeliver, Color couleur) {
    if (canDepart) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _action('depart',
                  adresse: liv.adresse, ville: liv.ville),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_circle_rounded, size: 20),
              label: const Text('Démarrer la course',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _openMaps(liv.adresse, liv.ville),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.orange),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.navigation_rounded, color: AppColors.orange, size: 22),
            ),
          ),
        ],
      );
    }
    if (canArrive) {
      return FilledButton.icon(
        onPressed: () => _action('arrivee'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
              icon: const Icon(Icons.flag_rounded, size: 20),
              label: const Text('Terminer la course',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );
    }
    if (canDeliver) {
      return FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context, '/confirm-delivery',
                  arguments: {
                    'id': liv.id,
                    'clientName': liv.clientNom,
                  },
                ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.statusSuccess,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: const Text('Confirmer la livraison',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildClientCard(ThemeData theme, dynamic liv) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(theme, Icons.person_rounded, 'Client',
                AppColors.primaryContainer),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                  child: Text(
                    liv.clientNom.isNotEmpty
                        ? liv.clientNom[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(liv.clientNom,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => showContactSheet(
                          context,
                          phone: liv.clientTelephone,
                          clientName: liv.clientNom,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_rounded,
                                size: 14, color: AppColors.primaryContainer),
                            const SizedBox(width: 4),
                            Text(liv.clientTelephone,
                                style: const TextStyle(
                                    color: AppColors.primaryContainer,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md + 2),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 18, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Adresse de livraison',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('${liv.adresse}, ${liv.ville}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, height: 1.3, color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.navigation_rounded,
                          color: AppColors.primaryContainer, size: 20),
                      onPressed: () => _openMaps(liv.adresse, liv.ville),
                      tooltip: 'Itinéraire',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandeCard(ThemeData theme, dynamic liv, Color couleur) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(theme, Icons.receipt_rounded, 'Détails commande',
                AppColors.secondary),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.tag_rounded, 'Numéro', liv.commandeNumero),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${liv.commandeArticlesCount} article${liv.commandeArticlesCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppColors.primaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: Spacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total TTC',
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                Text(
                  '${liv.commandeMontantTtc.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: couleur),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Frais livraison',
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                Text(
                  '${liv.fraisLivraison.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface),
                ),
              ],
            ),
            if (liv.fraisPriorite > 0) ...[
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          size: 15, color: AppColors.orange),
                      const SizedBox(width: 6),
                      const Text('Frais de priorité',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 14)),
                    ],
                  ),
                  Text(
                    '+ ${liv.fraisPriorite.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.orange),
                  ),
                ],
              ),
            ],
            if (liv.commandeModePaiement.isNotEmpty) ...[
              const Divider(height: Spacing.xxl),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(liv.paiementIcon,
                        size: 20, color: AppColors.statusSuccess),
                  ),
                  const SizedBox(width: Spacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mode de paiement',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.onSurfaceVariant)),
                      Text(liv.paiementDisplay,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface)),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrajetCard(ThemeData theme, dynamic liv) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(theme, Icons.route_rounded, 'Trajet',
                AppColors.statusSuccess),
            const SizedBox(height: Spacing.lg),
            if (liv.dateDepart != null) ...[
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.statusSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _trajetRow('Départ', liv.dateDepart!),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: Spacing.xs),
                child: Container(
                  width: 2,
                  height: 24,
                  color: AppColors.outlineVariant,
                ),
              ),
            ],
            if (liv.dateArrivee != null) ...[
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _trajetRow('Arrivée', liv.dateArrivee!),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trajetRow(String label, String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
        Text(
          dt != null
              ? DateFormat('HH:mm').format(dt)
              : dateStr,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface),
        ),
      ],
    );
  }

  Widget _buildTimeline(ThemeData theme, dynamic liv) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(theme, Icons.timeline_rounded, 'Chronologie',
                AppColors.primaryContainer),
            const SizedBox(height: Spacing.lg),
            ...liv.evenements.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final dt = DateTime.tryParse(e.date);
              final isLast = i == liv.evenements.length - 1;
              return _timelineItem(
                label: e.typeLabel,
                date: dt != null
                    ? DateFormat('EEEE d MMMM', 'fr').format(dt)
                    : e.date,
                time: dt != null ? DateFormat('HH:mm').format(dt) : '',
                color: AppColors.primaryContainer,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader(
      ThemeData theme, IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface)),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineItem({
    required String label,
    required String date,
    required String time,
    required Color color,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5, color: AppColors.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 11, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(date,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(width: Spacing.sm),
                      Icon(Icons.access_time,
                          size: 11, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(time,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 12)),
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

  Future<void> _action(String action, {String adresse = '', String ville = ''}) async {
    final prov = context.read<LivraisonProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await prov.updateStatus(widget.livraisonId, action);
    if (ok && mounted) {
      await prov.loadDetail(widget.livraisonId);
      await prov.loadLivraisons();
      messenger.showSnackBar(_successSnack(
          action == 'prise_en_charge'
              ? 'Prise en charge enregistrée'
              : action == 'depart'
                  ? 'Départ enregistré'
                  : 'Arrivée enregistrée'));
      if (action == 'depart' && adresse.isNotEmpty) {
        Navigator.of(context).pushNamed('/navigation',
            arguments: MapViewArgs(adresse: adresse, ville: ville));
      }
    } else if (mounted) {
      messenger.showSnackBar(_errorSnack('Erreur lors de la mise à jour'));
    }
  }

  Widget _buildTicketButton(ThemeData theme, dynamic liv) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primaryContainer, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Ticket de livraison',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: const Text('Partager le ticket (PDF)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _sendTicket(liv, 'pdf'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_android_rounded, size: 20),
                label: const Text('Contacter sur WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () => _sendTicket(liv, 'whatsapp'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTicket(dynamic liv, String mode) async {
    final phone = liv.clientTelephone as String;
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _errorSnack('Aucun numéro de téléphone client'),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Génération du ticket...'),
          ]),
          backgroundColor: AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final receipt = ReceiptService();
    try {
      if (mode == 'whatsapp') {
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        final uri = Uri.parse('https://wa.me/$cleanPhone');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        await receipt.generateTicket(
          commandeNumero: liv.commandeNumero,
          clientNom: liv.clientNom,
          adresse: liv.adresse,
          ville: liv.ville,
          montantTtc: (liv.commandeMontantTtc as num).toDouble(),
          paiement: liv.paiementDisplay,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _errorSnack('Erreur : impossible de générer le ticket'),
        );
      }
    }
  }

  SnackBar _successSnack(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(message,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      backgroundColor: AppColors.statusSuccess,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  SnackBar _errorSnack(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(message,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
