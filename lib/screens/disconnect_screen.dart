import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class DisconnectScreen extends StatefulWidget {
  const DisconnectScreen({super.key});

  @override
  State<DisconnectScreen> createState() => _DisconnectScreenState();
}

class _DisconnectScreenState extends State<DisconnectScreen> {
  final _isLoading = false;

  Map<String, dynamic>? get _args =>
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  String get _fullName {
    final a = _args;
    final full = a?['fullName'] as String? ?? '';
    if (full.isNotEmpty) return full;
    final prenom = a?['prenom'] as String? ?? '';
    final nom = a?['nom'] as String? ?? '';
    return '$prenom $nom'.trim();
  }

  String get _initials {
    final name = _fullName;
    if (name.isEmpty) return 'L';
    return name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  String? get _photoPath => _args?['photo'] as String?;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientCircleAvatar(
                    radius: 48,
                    imageUrl: _photoPath != null
                        ? ApiService().mediaUrl(_photoPath!)
                        : null,
                    initials: _initials,
                    showOnlineDot: true,
                  ),
                  if (_fullName.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Déconnexion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prêt à terminer votre service ?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Warning card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.statusFailed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.statusFailed.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statusFailed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.warning_amber_rounded,
                              color: AppColors.statusFailed, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Êtes-vous sûr de vouloir vous déconnecter ?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Vous ne recevrez plus de notifications de nouvelles livraisons prioritaires.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onSurface
                                      .withValues(alpha: 0.6),
                                  fontFamily: 'Inter',
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context, true);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statusFailed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.logout_rounded),
                      label: const Text(
                        'SE DÉCONNECTER',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.onSurface.withValues(alpha: 0.3),
                        ),
                        foregroundColor: AppColors.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'RESTER CONNECTÉ',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Session sécurisée KingDely Velocity',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurface.withValues(alpha: 0.3),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
