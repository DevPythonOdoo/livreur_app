import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_theme.dart';

/// Écran « À propos » : informations de l'application et de la société.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Map<String, dynamic>? _societe;

  static const String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSociete();
  }

  Future<void> _loadSociete() async {
    final res = await ApiService().get('/societe/');
    if (res['status'] == 200 && mounted) {
      setState(() {
        _societe = res['body'] as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nom = _societe?['nom'] as String? ?? '';
    final adresse = _societe?['adresse'] as String? ?? '';
    final codePostal = _societe?['code_postal'] as String? ?? '';
    final ville = _societe?['ville'] as String? ?? '';
    final telephone = _societe?['telephone'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('À propos',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          const AppLogo(size: 64),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.business_rounded,
                  label: 'Société',
                  value: nom.isNotEmpty ? nom : 'KingDely',
                ),
                if (adresse.isNotEmpty || ville.isNotEmpty) ...[
                  const Divider(height: 24),
                  _infoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Adresse',
                    value: [adresse, codePostal, ville]
                        .where((p) => p.isNotEmpty)
                        .join(', '),
                  ),
                ],
                if (telephone.isNotEmpty) ...[
                  const Divider(height: 24),
                  _infoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: telephone,
                    onTap: () => _call(telephone),
                  ),
                ],
                const Divider(height: 24),
                _infoRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Version',
                  value: 'KingDely Route v$_version',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Application de gestion des livraisons pour les livreurs '
            'professionnels KingDely.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter'),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2026 KingDely · Tous droits réservés',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.8),
                          fontFamily: 'Inter')),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.phone_rounded,
                  size: 16, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}
