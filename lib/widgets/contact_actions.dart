import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

/// Vert officiel WhatsApp.
const Color waGreen = Color(0xFF25D366);

/// Normalise un numéro de téléphone au format international E.164 (chiffres seuls).
/// En Côte d'Ivoire, le 0 national est conservé : 0564852649 -> 2250564852649.
String normalizePhone(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('225') && digits.length >= 11) {
    return digits;
  }
  if (digits.startsWith('0')) {
    return '225$digits';
  }
  if (digits.length == 8) {
    return '225$digits';
  }
  return digits;
}

/// Lance un appel téléphonique vers [phone] (format international +225).
/// Retourne faux si aucun composeur n'a pu être lancé.
Future<bool> callPhone(String phone) async {
  final uri = Uri.parse('tel:+${normalizePhone(phone)}');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  } catch (_) {
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Ouvre WhatsApp sur une conversation avec [phone] et un message pré-rempli.
Future<void> whatsappMessage(String phone, {String text = ''}) async {
  final digits = normalizePhone(phone);
  final base = Uri.parse('https://wa.me/$digits');
  final uri = text.isEmpty
      ? base
      : base.replace(queryParameters: {'text': text});
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Lance un appel WhatsApp vers [phone].
/// Replie sur la conversation WhatsApp si l'intent d'appel n'est pas disponible.
Future<void> whatsappCall(String phone) async {
  final digits = normalizePhone(phone);
  try {
    final callUri = Uri.parse('whatsapp://call?phone=$digits');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}
  final uri = Uri.parse('https://wa.me/$digits');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Ouvre une feuille avec les 3 options de contact :
/// appel, message WhatsApp et appel WhatsApp.
void showContactSheet(
  BuildContext context, {
  required String phone,
  String? clientName,
}) {
  final defaultText = clientName == null || clientName.isEmpty
      ? 'Bonjour, je suis votre livreur.'
      : 'Bonjour $clientName, je suis votre livreur pour votre livraison.';
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Contacter le client',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.onSurface,
                  fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text(phone,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  fontFamily: 'Inter')),
          const SizedBox(height: 16),
          _ContactTile(
            icon: Icons.phone_rounded,
            iconColor: AppColors.blue,
            title: 'Appel téléphonique',
            subtitle: 'Appeler le client directement',
            onTap: () {
              final messenger = ScaffoldMessenger.of(ctx);
              Navigator.pop(ctx);
              callPhone(phone).then((ok) {
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Impossible de lancer l'appel"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
          ),
          _ContactTile(
            icon: Icons.chat_rounded,
            iconColor: waGreen,
            title: 'Message WhatsApp',
            subtitle: 'Envoyer un message via WhatsApp',
            onTap: () {
              Navigator.pop(ctx);
              whatsappMessage(phone, text: defaultText);
            },
          ),
          _ContactTile(
            icon: Icons.phone_in_talk_rounded,
            iconColor: waGreen,
            title: 'Appel WhatsApp',
            subtitle: 'Appel audio via WhatsApp',
            onTap: () {
              Navigator.pop(ctx);
              whatsappCall(phone);
            },
          ),
        ],
      ),
    ),
  );
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter')),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
