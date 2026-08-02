import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Affiche les étoiles de priorité d'une livraison.
/// 0 étoile = normale, 5 = urgence maximale.
class PriorityStars extends StatelessWidget {
  final int priorite;
  final double size;
  final bool showLabel;

  const PriorityStars({
    super.key,
    required this.priorite,
    this.size = 14,
    this.showLabel = false,
  });

  /// Orange pour 1-3 étoiles, rouge pour 4-5 (urgence).
  Color get _color =>
      priorite >= 4 ? AppColors.statusFailed : AppColors.orange;

  String get _label {
    switch (priorite) {
      case 1: return 'Priorité basse';
      case 2: return 'Priorité moyenne';
      case 3: return 'Priorité élevée';
      case 4: return 'Très prioritaire';
      case 5: return 'URGENCE MAXIMALE';
      default: return 'Normale';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (priorite <= 0) {
      return const SizedBox.shrink();
    }
    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < priorite;
        return Padding(
          padding: const EdgeInsets.only(right: 1),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled ? _color : AppColors.outlineVariant,
          ),
        );
      }),
    );
    if (!showLabel) return stars;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        stars,
        const SizedBox(height: 4),
        Text(
          _label,
          style: TextStyle(
            fontSize: size + 2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: _color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

/// Bandeau de priorité plein pour les écrans de détail.
class PriorityBanner extends StatelessWidget {
  final int priorite;
  final double fraisPriorite;

  const PriorityBanner({
    super.key,
    required this.priorite,
    this.fraisPriorite = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (priorite <= 0) return const SizedBox.shrink();
    final urgent = priorite >= 4;
    final color = urgent ? AppColors.statusFailed : AppColors.orange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            urgent
                ? Icons.priority_high_rounded
                : Icons.stars_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVRAISON PRIORITAIRE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'À traiter avant les autres livraisons',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          PriorityStars(priorite: priorite, size: 15),
        ],
      ),
    );
  }
}
