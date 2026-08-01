import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/livraison.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';

/// Écran des paramètres de l'application :
/// notifications, veilleuse d'écran et langue.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _veilleuseEnabled = false;
  bool _loading = true;

  static const String _notifKey = 'notifications_enabled';
  static const String _veilleuseKey = 'veilleuse_enabled';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notifKey) ?? true;
      _veilleuseEnabled = prefs.getBool(_veilleuseKey) ?? false;
      _loading = false;
    });
    if (_veilleuseEnabled) {
      WakelockPlus.enable();
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, enabled);
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
    if (enabled) {
      NotificationService.instance.requestPermission();
      NotificationService.instance.startPolling(context, _fetchLivraisons);
    } else {
      NotificationService.instance.stopPolling();
    }
  }

  Future<void> _toggleVeilleuse(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_veilleuseKey, enabled);
    setState(() => _veilleuseEnabled = enabled);
    if (enabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<List<Livraison>> _fetchLivraisons() async {
    final res = await ApiService().get('/livraisons/');
    if (res['status'] == 200) {
      final body = res['body'];
      final items = body is Map ? body['results'] as List : body as List;
      return items.map((j) => Livraison.fromJson(j)).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Paramètres',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _sectionTitle('Notifications'),
                _buildCard(
                  children: [
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeTrackColor: AppColors.orange,
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_active_rounded,
                            color: AppColors.orange),
                      ),
                      title: const Text('Nouvelles livraisons',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter')),
                      subtitle: Text(
                        _notificationsEnabled
                            ? 'Alertes sonores pour les nouvelles commandes'
                            : 'Les alertes de commandes sont désactivées',
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'Inter'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Écran'),
                _buildCard(
                  children: [
                    SwitchListTile(
                      value: _veilleuseEnabled,
                      onChanged: _toggleVeilleuse,
                      activeTrackColor: AppColors.orange,
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.brightness_7_rounded,
                            color: AppColors.blue),
                      ),
                      title: const Text('Veilleuse d\'écran',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter')),
                      subtitle: const Text(
                          'L\'écran reste allumé pendant la conduite',
                          style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Langue'),
                _buildCard(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.language_rounded,
                            color: AppColors.statusSuccess),
                      ),
                      title: const Text('Français',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter')),
                      subtitle: const Text(
                          'Langue de l\'application',
                          style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                      trailing: const Icon(Icons.check_circle_rounded,
                          color: AppColors.statusSuccess, size: 20),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}
