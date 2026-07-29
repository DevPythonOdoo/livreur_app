import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/livraison_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/livraison.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_theme.dart';
import 'dashboard_screen.dart';
import 'delivery_list_screen.dart';
import 'agenda_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  final _notifService = NotificationService();
  late final LivraisonProvider _livraisonProvider;
  late final AuthProvider _authProvider;
  bool _authChecked = false;
  bool _manualLogout = false;

  @override
  void initState() {
    super.initState();
    _livraisonProvider = Provider.of<LivraisonProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider.addListener(_onAuthChanged);
      _authChecked = true;
      _notifService.requestPermission();
      _notifService.startPolling(context, () async {
        final res = await ApiService().get('/livraisons/');
        if (res['status'] == 200) {
          final body = res['body'];
          final items = body is Map ? body['results'] as List : body as List;
          return items.map((j) => Livraison.fromJson(j)).toList();
        }
        return [];
      });
      _livraisonProvider.startAutoRefresh();
      _loadProfile();
    });
  }

  void _onAuthChanged() {
    if (!_authChecked || !mounted || _manualLogout) return;
    if (!_authProvider.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  void dispose() {
    if (_authChecked) {
      _authProvider.removeListener(_onAuthChanged);
    }
    _notifService.stopPolling();
    _livraisonProvider.stopAutoRefresh();
    super.dispose();
  }

  void _cleanLogout() {
    if (_manualLogout) return;
    _manualLogout = true;
    _livraisonProvider.stopAutoRefresh();
    _notifService.stopPolling();
    _authProvider.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  List<Widget> get _pages => [
        DashboardScreen(
          onNavigateToDeliveries: () => setState(() => _currentIndex = 1),
          livreurName: _fullName,
          profile: _profile,
        ),
        const DeliveryListScreen(),
        const AgendaScreen(),
        const MapScreen(),
        ProfileScreen(onLogout: _cleanLogout),
      ];

  String get _fullName {
    final prenom = _profile?['prenom'] as String? ?? '';
    final nom = _profile?['nom'] as String? ?? '';
    return '$prenom $nom'.trim();
  }

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _loadProfile() async {
    final res = await ApiService().get('/livreurs/me/');
    if (res['status'] == 200 && mounted) {
      setState(() => _profile = res['body']);
    }
  }

  Future<bool> _confirmLogout() async {
    final result = await Navigator.pushNamed(context, '/disconnect');
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final prenom = _profile?['prenom'] as String? ?? '';
    final nom = _profile?['nom'] as String? ?? '';
    final fullName = '$prenom $nom'.trim();
    final photoUrl = _profile?['photo_profil'] as String?;
    final telephone = _profile?['telephone'] as String? ?? '';
    final vehicule = _profile?['vehicule'] as String? ?? '';
    final plaque = _profile?['plaque_immatriculation'] as String? ?? '';
    final dispo = _profile?['statut'] == 'disponible';

    return Scaffold(
      body: _pages[_currentIndex],
      drawer: Drawer(
        width: 300,
        backgroundColor: AppColors.surfaceDim,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientCircleAvatar(
                    radius: 30,
                    imageUrl:
                        photoUrl != null ? ApiService().mediaUrl(photoUrl) : null,
                    initials: '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                    showOnlineDot: dispo,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName.isNotEmpty ? fullName : 'Livreur',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                        fontSize: 17,
                        fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 12,
                          color: AppColors.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          telephone.isNotEmpty ? telephone : 'Non renseigné',
                          style: TextStyle(
                              color: AppColors.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontFamily: 'Inter'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (vehicule.isNotEmpty || plaque.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car_rounded,
                              size: 14,
                              color:
                                  AppColors.onSurface.withValues(alpha: 0.7)),
                          const SizedBox(width: 6),
                          Text(
                            '$vehicule ${plaque.isNotEmpty ? '\u00b7 $plaque' : ''}',
                            style: TextStyle(
                                color: AppColors.onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: 12,
                                fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            _menuItem(
              icon: Icons.dashboard_rounded,
              label: 'Tableau de bord',
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            _menuItem(
              icon: Icons.local_shipping_rounded,
              label: 'Mes livraisons',
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            _menuItem(
              icon: Icons.calendar_month_rounded,
              label: 'Planning',
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            _menuItem(
              icon: Icons.map_rounded,
              label: 'Carte',
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            _menuItem(
              icon: Icons.person_rounded,
              label: 'Mon profil',
              selected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            _menuItem(
              icon: Icons.history_rounded,
              label: 'Historique',
              selected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/history');
              },
            ),
            const Spacer(),
            _menuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Changer le mot de passe',
              selected: false,
              color: AppColors.onSurfaceVariant,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/change-password');
              },
            ),
            _menuItem(
              icon: Icons.logout_rounded,
              label: 'Déconnexion',
              selected: false,
              color: AppColors.statusFailed,
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _confirmLogout();
                if (confirm) {
                  _cleanLogout();
                }
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogoCompact(size: 20),
                  const SizedBox(width: 6),
                  const Text('KingDely Route',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDim,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => switchToTab(i),
            backgroundColor: Colors.transparent,
            indicatorColor:
                AppColors.primaryContainer.withValues(alpha: 0.15),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined,
                    color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.dashboard_rounded,
                    color: AppColors.primaryContainer),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined,
                    color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.local_shipping_rounded,
                    color: AppColors.primaryContainer),
                label: 'Livraisons',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined,
                    color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.calendar_month_rounded,
                    color: AppColors.primaryContainer),
                label: 'Planning',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined,
                    color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.map_rounded,
                    color: AppColors.primaryContainer),
                label: 'Carte',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline,
                    color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.person_rounded,
                    color: AppColors.primaryContainer),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final clr =
        color ?? (selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant);
    return ListTile(
      leading: Icon(icon,
          color: selected ? clr : AppColors.onSurfaceVariant, size: 22),
      title: Text(
        label,
        style: TextStyle(
            color: selected ? clr : AppColors.onSurface,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }
}
