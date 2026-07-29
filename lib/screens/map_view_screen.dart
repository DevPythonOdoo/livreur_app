import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_theme.dart';

class MapViewArgs {
  final String adresse;
  final String ville;
  const MapViewArgs({required this.adresse, required this.ville});
}

class MapViewScreen extends StatelessWidget {
  final String adresse;
  final String ville;
  const MapViewScreen({super.key, required this.adresse, required this.ville});

  @override
  Widget build(BuildContext context) {
    final query = Uri.encodeComponent('$adresse, $ville');
    final mapsUri = Uri.parse('https://maps.google.com/maps?daddr=$query');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xxl + Spacing.xs),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          size: 40, color: AppColors.primaryContainer),
                    ),
                    const SizedBox(height: Spacing.xl),
                    Text(adresse,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        textAlign: TextAlign.center),
                    const SizedBox(height: Spacing.sm),
                    Text(ville,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Voir l\'itinéraire',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: () => _openInBrowser(context, mapsUri),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.content_copy_rounded),
                label: const Text('Copier l\'adresse',
                    style: TextStyle(fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _copyAddress(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _copyAddress(context);
    }
  }

  void _copyAddress(BuildContext context) {
    final adr = '$adresse, $ville, Côte d\'Ivoire';
    // ignore: depend_on_referenced_packages
    Clipboard.setData(ClipboardData(text: adr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Adresse copiée'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
