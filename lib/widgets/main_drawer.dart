import 'package:flutter/material.dart';
import 'app_logo.dart';
import 'app_theme.dart';
import '../services/api_service.dart';

/// Drawer de navigation partagé entre le tableau de bord et le shell principal.
/// Propose la navigation par onglets ainsi que des menus supplémentaires
/// (historique, retards, paramètres, aide, à propos).
class MainDrawer extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final String telephone;
  final String vehicule;
  final String plaque;
  final bool dispo;
  final int currentIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onHistory;
  final VoidCallback onChangePassword;
  final VoidCallback onLateOrders;
  final VoidCallback onSettings;
  final VoidCallback onHelp;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  const MainDrawer({
    super.key,
    required this.fullName,
    required this.telephone,
    required this.currentIndex,
    required this.onSelectTab,
    required this.onHistory,
    required this.onChangePassword,
    required this.onLateOrders,
    required this.onSettings,
    required this.onHelp,
    required this.onAbout,
    required this.onLogout,
    this.photoUrl,
    this.vehicule = '',
    this.plaque = '',
    this.dispo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      backgroundColor: AppColors.surfaceDim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _menuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    label: 'Tableau de bord',
                    selected: currentIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(0);
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.local_shipping_rounded,
                    label: 'Mes livraisons',
                    selected: currentIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(1);
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.calendar_month_rounded,
                    label: 'Planning',
                    selected: currentIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(2);
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.map_rounded,
                    label: 'Carte',
                    selected: currentIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(3);
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.person_rounded,
                    label: 'Mon profil',
                    selected: currentIndex == 4,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab(4);
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'AUTRES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  _menuItem(
                    context,
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      onHistory();
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.alarm_rounded,
                    label: 'Mes commandes en retard',
                    selected: false,
                    color: AppColors.statusFailed,
                    onTap: () {
                      Navigator.pop(context);
                      onLateOrders();
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.settings_rounded,
                    label: 'Paramètres',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      onSettings();
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    label: 'Aide & support',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      onHelp();
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'À propos',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      onAbout();
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.orange,
            child: Column(
              children: [
                _menuItem(
                  context,
                  icon: Icons.lock_outline_rounded,
                  label: 'Changer le mot de passe',
                  selected: false,
                  color: Colors.white,
                  light: true,
                  onTap: () {
                    Navigator.pop(context);
                    onChangePassword();
                  },
                ),
                _menuItem(
                  context,
                  icon: Icons.logout_rounded,
                  label: 'Déconnexion',
                  selected: false,
                  color: Colors.white,
                  light: true,
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogoCompact(size: 20),
                      const SizedBox(width: 6),
                      const Text('KingDely Route',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.orange,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GradientCircleAvatar(
            radius: 32,
            imageUrl:
                photoUrl != null ? ApiService().mediaUrl(photoUrl) : null,
            initials: fullName.isNotEmpty
                ? fullName
                    .split(' ')
                    .where((p) => p.isNotEmpty)
                    .take(2)
                    .map((p) => p[0].toUpperCase())
                    .join()
                : 'L',
            showOnlineDot: dispo,
          ),
          const SizedBox(height: 12),
          Text(
            fullName.isNotEmpty ? fullName : 'Livreur',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 17,
                fontFamily: 'Inter'),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_outlined,
                  size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  telephone.isNotEmpty ? telephone : 'Non renseigné',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, fontFamily: 'Inter'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (vehicule.isNotEmpty || plaque.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '$vehicule ${plaque.isNotEmpty ? '\u00b7 $plaque' : ''}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
    bool light = false,
  }) {
    final clr = color ??
        (selected
            ? AppColors.primaryContainer
            : AppColors.onSurfaceVariant);
    final baseIcon =
        selected ? clr : (light ? Colors.white : AppColors.onSurfaceVariant);
    final baseText =
        selected ? clr : (light ? Colors.white : AppColors.onSurface);
    return ListTile(
      leading: Icon(icon, color: baseIcon, size: 22),
      title: Text(
        label,
        style: TextStyle(
            color: baseText,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
            fontFamily: 'Inter'),
      ),
      trailing: selected
          ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }
}
