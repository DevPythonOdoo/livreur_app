import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFFF0EB);
  static const Color orangeDark = Color(0xFFE05520);

  static const Color blue = Color(0xFF051424);
  static const Color blueLight = Color(0xFFF0F4F8);
  static const Color blueDark = Color(0xFF030B1A);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF0F2F5);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFF8F9FA);
  static const Color surfaceContainerLow = Color(0xFFF0F2F5);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFF8F9FA);
  static const Color surfaceContainerHighest = Color(0xFFE8ECF0);

  static const Color onSurface = Color(0xFF051424);
  static const Color onSurfaceVariant = Color(0xFF64748B);

  static const Color primary = Color(0xFFFF6B35);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFF6B35);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF051424);
  static const Color secondaryContainer = Color(0xFFF0F4F8);

  static const Color surfaceGlass = Color(0xFFF8F9FA);

  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFFF6B35);
  static const Color statusFailed = Color(0xFFEF4444);
  static const Color stateOnline = Color(0xFF22C55E);
  static const Color stateOffline = Color(0xFF94A3B8);

  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEF2F2);

  static const Map<String, Color> statutColors = {
    'preparation': Color(0xFF94A3B8),
    'prise_en_charge': Color(0xFFFF6B35),
    'en_cours': Color(0xFFFF6B35),
    'arrive_destination': Color(0xFF10B981),
    'livree': Color(0xFF10B981),
    'echec': Color(0xFFEF4444),
    'annulee': Color(0xFF94A3B8),
  };

  static Color forStatut(String statut) =>
      statutColors[statut] ?? const Color(0xFF94A3B8);
}

class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double gutter = 16;
  static const double marginMobile = 20;
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          surface: AppColors.surface,
          primary: AppColors.orange,
          onPrimary: Colors.white,
          primaryContainer: AppColors.orangeLight,
          onPrimaryContainer: Color(0xFFCC4400),
          secondary: AppColors.blue,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.blueLight,
          onSecondaryContainer: AppColors.blue,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          surfaceContainerLowest: AppColors.surfaceContainerLowest,
          surfaceContainerLow: AppColors.surfaceContainerLow,
          surfaceContainer: AppColors.surfaceContainer,
          surfaceContainerHigh: AppColors.surfaceContainerHigh,
          surfaceContainerHighest: AppColors.surfaceContainerHighest,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDim,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.orange, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg, vertical: 14),
          labelStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              fontFamily: 'Inter'),
          hintStyle: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              fontFamily: 'Inter'),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter'),
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: AppColors.orange),
            foregroundColor: AppColors.orange,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.outlineVariant,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
          backgroundColor: AppColors.surfaceDim,
          selectedColor: AppColors.orange,
          side: BorderSide.none,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.blue,
            fontFamily: 'Inter',
            letterSpacing: -0.02,
            height: 1.25,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
            fontFamily: 'Inter',
            height: 1.33,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
            fontFamily: 'Inter',
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
            fontFamily: 'Inter',
          ),
          titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
            fontFamily: 'Inter',
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurface,
            fontFamily: 'Inter',
            height: 1.55,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurface,
            fontFamily: 'Inter',
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
            fontFamily: 'Inter',
            height: 1.33,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.orangeLight,
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          surfaceTintColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.orange);
            }
            return const IconThemeData(color: AppColors.onSurfaceVariant);
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}

class StatutBadge extends StatelessWidget {
  final String statut;
  final String label;
  final double fontSize;

  const StatutBadge({
    super.key,
    required this.statut,
    required this.label,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forStatut(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: padding ?? const EdgeInsets.all(Spacing.lg),
      child: child,
    );
  }
}

class GradientCircleAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final String initials;
  final bool showOnlineDot;

  const GradientCircleAvatar({
    super.key,
    this.radius = 40,
    this.imageUrl,
    this.initials = '?',
    this.showOnlineDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2 + 4,
      height: radius * 2 + 4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.surface,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: radius * 0.7,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    )
                  : null,
            ),
          ),
          if (showOnlineDot)
            const Positioned(
              bottom: 2,
              right: 2,
              child: SizedBox(
                width: 14,
                height: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.stateOnline,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const SectionHeader({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: AppColors.blue)),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
