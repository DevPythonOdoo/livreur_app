import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/livraison_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/livraison.dart';
import '../widgets/app_theme.dart';
import '../widgets/main_drawer.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _profile;
  final _notifService = NotificationService.instance;
  late final LivraisonProvider _livraisonProvider;
  late final AuthProvider _authProvider;
  bool _authChecked = false;
  bool _manualLogout = false;

  @override
  void initState() {
    super.initState();
    _livraisonProvider = Provider.of<LivraisonProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _authProvider.addListener(_onAuthChanged);
      _authChecked = true;
      _notifService.requestPermission();
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      if (!mounted) return;
      if (notificationsEnabled) {
        _notifService.startPolling(context, () async {
          final res = await ApiService().get('/livraisons/');
          if (res['status'] == 200) {
            final body = res['body'];
            final items = body is Map ? body['results'] as List : body as List;
            return items.map((j) => Livraison.fromJson(j)).toList();
          }
          return [];
        });
      }
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
          onSelectTab: (i) => setState(() => _currentIndex = i),
          onHistory: () => Navigator.pushNamed(context, '/history'),
          onChangePassword: () =>
              Navigator.pushNamed(context, '/change-password'),
          onLateOrders: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DeliveryListScreen(initialFilter: 'retard'),
            ),
          ),
          onSettings: () => Navigator.pushNamed(context, '/settings'),
          onHelp: () => Navigator.pushNamed(context, '/help'),
          onAbout: () => Navigator.pushNamed(context, '/about'),
          onLogout: _confirmLogout,
          livreurName: _fullName,
          profile: _profile,
        ),
        DeliveryListScreen(onOpenDrawer: _openDrawer),
        AgendaScreen(onOpenDrawer: _openDrawer),
        MapScreen(onOpenDrawer: _openDrawer),
        ProfileScreen(onLogout: _cleanLogout, onOpenDrawer: _openDrawer),
      ];

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

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
    final result = await Navigator.pushNamed(context, '/disconnect',
        arguments: {
          'photo': _profile?['photo_profil'],
          'prenom': _profile?['prenom'],
          'nom': _profile?['nom'],
        });
    return result == true;
  }

  Future<void> _handleLogout() async {
    final confirm = await _confirmLogout();
    if (confirm) {
      _cleanLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _fullName;
    final photoUrl = _profile?['photo_profil'] as String?;
    final telephone = _profile?['telephone'] as String? ?? '';
    final vehicule = _profile?['vehicule'] as String? ?? '';
    final plaque = _profile?['plaque_immatriculation'] as String? ?? '';
    final dispo = _profile?['statut'] == 'disponible';

    return Scaffold(
      key: _scaffoldKey,
      body: _pages[_currentIndex],
      drawer: MainDrawer(
        fullName: fullName,
        photoUrl: photoUrl,
        telephone: telephone,
        vehicule: vehicule,
        plaque: plaque,
        dispo: dispo,
        currentIndex: _currentIndex,
        onSelectTab: (i) => setState(() => _currentIndex = i),
        onHistory: () => Navigator.pushNamed(context, '/history'),
        onChangePassword: () =>
            Navigator.pushNamed(context, '/change-password'),
        onLateOrders: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DeliveryListScreen(initialFilter: 'retard'),
          ),
        ),
        onSettings: () => Navigator.pushNamed(context, '/settings'),
        onHelp: () => Navigator.pushNamed(context, '/help'),
        onAbout: () => Navigator.pushNamed(context, '/about'),
        onLogout: _handleLogout,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDim,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _buildNavItem(0, Icons.dashboard_outlined,
                    Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.local_shipping_outlined,
                    Icons.local_shipping_rounded, 'Livraisons'),
                _buildNavItem(2, Icons.calendar_month_outlined,
                    Icons.calendar_month_rounded, 'Planning'),
                _buildNavItem(3, Icons.map_outlined, Icons.map_rounded,
                    'Carte'),
                _buildNavItem(4, Icons.person_outline, Icons.person_rounded,
                    'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final selected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => switchToTab(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected ? activeIcon : icon,
                      key: ValueKey(selected),
                      size: 23,
                      color: selected
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                ClipRect(
                  child: AnimatedAlign(
                    alignment: Alignment.center,
                    heightFactor: selected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
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
