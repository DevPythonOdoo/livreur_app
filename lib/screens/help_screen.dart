import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

/// Écran d'aide et de support : contact de la société et questions fréquentes.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? _telephone;
  String? _societeNom;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSociete();
  }

  Future<void> _loadSociete() async {
    final res = await ApiService().get('/societe/');
    if (res['status'] == 200 && mounted) {
      final body = res['body'] as Map<String, dynamic>?;
      setState(() {
        _telephone = body?['telephone'] as String?;
        _societeNom = body?['nom'] as String?;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _callSupport() async {
    final phone = _telephone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
        title: const Text('Aide & support',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orange, Color(0xFFFF8C5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Besoin d\'aide ?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter')),
                const SizedBox(height: 4),
                Text(
                  _societeNom != null && _societeNom!.isNotEmpty
                      ? 'Contactez le support de $_societeNom pour toute question sur vos livraisons.'
                      : 'Contactez le support pour toute question sur vos livraisons.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      height: 1.4),
                ),
                if (!_loading && _telephone != null && _telephone!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _callSupport,
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: Text('Appeler le support · $_telephone',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              fontFamily: 'Inter')),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Questions fréquentes'),
          _faq(
            icon: Icons.play_circle_outline_rounded,
            question: 'Comment démarrer une livraison ?',
            answer:
                'Ouvrez l\'onglet « Mes livraisons », sélectionnez la commande '
                'puis appuyez sur « Démarrer » pour marquer votre départ. '
                'Une fois arrivé, confirmez la livraison avec le client.',
          ),
          _faq(
            icon: Icons.person_search_rounded,
            question: 'Le client n\'est pas joignable ?',
            answer:
                'Appelez le client via l\'icône téléphone de la commande. '
                'Attendez quelques minutes et réessayez avant de signaler '
                'un échec de livraison.',
          ),
          _faq(
            icon: Icons.cancel_outlined,
            question: 'Comment signaler un échec de livraison ?',
            answer:
                'Depuis le détail de la commande, appuyez sur « Échec de '
                'livraison », choisissez le motif puis confirmez. '
                'La commande sera marquée en échec.',
          ),
          _faq(
            icon: Icons.lock_reset_rounded,
            question: 'Comment changer mon mot de passe ?',
            answer:
                'Ouvrez le menu (☰), puis « Changer le mot de passe ». '
                'Saisissez votre ancien mot de passe et choisissez un nouveau.',
          ),
          _faq(
            icon: Icons.offline_bolt_rounded,
            question: 'Que faire si l\'application ne se connecte pas ?',
            answer:
                'Vérifiez votre connexion internet, puis tirez la liste vers '
                'le bas pour actualiser. Si le problème persiste, contactez le support.',
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

  Widget _faq({
    required IconData icon,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.orange),
          ),
          title: Text(question,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Inter')),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(answer,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}
