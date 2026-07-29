import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.orange,
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.3),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.06),
              ),
            ],
          ),
          child: const Icon(
            Icons.delivery_dining_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          const Text(
            'KingDely Route',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.blue,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Livreur Professionnel',
            style: TextStyle(
              fontSize: size * 0.22,
              color: AppColors.blue.withValues(alpha: 0.6),
              letterSpacing: 1.2,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }
}

class AppLogoCompact extends StatelessWidget {
  final double size;
  const AppLogoCompact({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange,
      ),
      child: const Icon(
        Icons.delivery_dining_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
