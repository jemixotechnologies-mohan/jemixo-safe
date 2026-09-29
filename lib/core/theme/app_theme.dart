import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Inter-based type scale matching the design system spec.
class AppTypography {
  const AppTypography._();

  static const _family = 'Inter';

  static const brand = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const pageTitle = TextStyle(
    fontFamily: _family,
    fontSize: 23,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const cardTitle = TextStyle(
    fontFamily: _family,
    fontSize: 15.5,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const bodyStrong = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const small = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  static const smallStrong = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  static const metric = TextStyle(
    fontFamily: _family,
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );

  /// Package names, hashes and URLs: a real monospace face so look-alike
  /// characters (l / I / 1) stay distinguishable.
  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Roboto Mono', 'Droid Sans Mono', _family],
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme = const ColorScheme.light(
      primary: AppColors.midnightGreen,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE7EFEC),
      onPrimaryContainer: AppColors.midnightGreen,
      secondary: AppColors.royalBlue,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: AppColors.midnightGreen,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return _base(scheme, Brightness.light).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.pageTitle,
        systemOverlayStyle: AppSystemOverlay.light,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.royalBlue.withValues(alpha: 0.12),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.royalBlue
                : AppColors.slate,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.small.copyWith(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.royalBlue
                : AppColors.slate,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      primary: AppColors.royalBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF122C24),
      onPrimaryContainer: AppColors.darkText,
      secondary: AppColors.gold,
      onSecondary: AppColors.midnightGreen,
      tertiary: AppColors.gold,
      onTertiary: AppColors.midnightGreen,
      error: Color(0xFFF87171),
      onError: Color(0xFF3B0A0A),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
    );

    return _base(scheme, Brightness.dark).copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.pageTitle,
        systemOverlayStyle: AppSystemOverlay.dark,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.royalBlue.withValues(alpha: 0.22),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF7BA3F7)
                : AppColors.darkTextSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.small.copyWith(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF7BA3F7)
                : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: AppTypography._family,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displaySmall: AppTypography.metric,
        headlineMedium: AppTypography.brand,
        titleLarge: AppTypography.pageTitle,
        titleMedium: AppTypography.sectionTitle,
        titleSmall: AppTypography.cardTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.small,
        labelLarge: AppTypography.smallStrong,
        labelMedium: AppTypography.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.royalBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderStrong,
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: AppTypography._family,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(
            fontFamily: AppTypography._family,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.royalBlue,
          textStyle: const TextStyle(
            fontFamily: AppTypography._family,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? AppColors.surface
            : const Color(0xFF0A231C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.standard,
          vertical: 14,
        ),
        hintStyle: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: scheme.outline),
        labelStyle: AppTypography.smallStrong.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.midnightGreen,
        contentTextStyle: AppTypography.smallStrong.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (brightness == Brightness.light
                    ? Colors.white
                    : AppColors.darkTextSecondary),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.royalBlue
              : (brightness == Brightness.light
                    ? AppColors.borderStrong
                    : AppColors.darkBorder),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: AppTypography.cardTitle.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: AppTypography.small.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.royalBlue,
        linearTrackColor: AppColors.linearTrack,
        circularTrackColor: AppColors.linearTrack,
      ),
    );
  }
}
