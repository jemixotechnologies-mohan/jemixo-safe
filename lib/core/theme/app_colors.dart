import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Jemixo Safe design tokens.
///
/// Palette intent: a calm security assistant, not an alarming antivirus.
/// Midnight Green carries the brand, Royal Blue drives action, Gold is a
/// restrained accent. Red/amber are reserved for genuine status signalling.
class AppColors {
  const AppColors._();

  // Brand
  static const midnightGreen = Color(0xFF0B3328);
  static const royalBlue = Color(0xFF2C63EB);
  static const gold = Color(0xFFDAAF37);
  static const slate = Color(0xFF64748B);

  // Neutrals
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);

  // Status
  static const safe = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);

  // Dark surfaces — deliberately not pure black.
  static const darkBackground = Color(0xFF071C16);
  static const darkSurface = Color(0xFF0D2921);
  static const darkBorder = Color(0xFF1B3A30);
  static const darkText = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);

  static const lightScheme = <Color>[midnightGreen, royalBlue, gold, slate];

  static const linearTrack = Color(0xFFE2E8F0);
  static const darkTrack = Color(0xFF1B3A30);
}

class AppRadii {
  const AppRadii._();
  static const card = 16.0;
  static const button = 14.0;
  static const input = 12.0;
  static const pill = 999.0;
}

class AppSpacing {
  const AppSpacing._();
  static const standard = 16.0;
  static const screen = 20.0;
  static const section = 12.0;
  static const tight = 8.0;
}

class AppDurations {
  const AppDurations._();
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
}

class AppCurves {
  const AppCurves._();
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
}

/// Shared elevation. Intentionally very soft — depth comes from the hairline
/// border, not from heavy shadows.
class AppShadows {
  const AppShadows._();

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const cta = <BoxShadow>[
    BoxShadow(color: Color(0x332C63EB), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

class AppSystemOverlay {
  const AppSystemOverlay._();

  static const light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const dark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
