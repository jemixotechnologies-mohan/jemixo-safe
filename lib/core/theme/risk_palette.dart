import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'app_colors.dart';

/// Semantic status colour mapping. Every score/risk value in the app resolves
/// through here so the palette stays consistent and "red" never becomes a
/// decorative brand colour.
enum RiskLevel {
  safe,
  low,
  medium,
  high,
  critical;

  String localizedLabel(BuildContext context) {
    final s = Strings.of(context);
    if (!s.isHindi) return label;
    return switch (this) {
      RiskLevel.safe => s.riskSafe,
      RiskLevel.low => s.riskLow,
      RiskLevel.medium => s.riskReview,
      RiskLevel.high => s.riskHigh,
      RiskLevel.critical => s.riskCritical,
    };
  }

  String get label => switch (this) {
    RiskLevel.safe => 'Good',
    RiskLevel.low => 'Low Risk',
    RiskLevel.medium => 'Review',
    RiskLevel.high => 'High Risk',
    RiskLevel.critical => 'Attention Required',
  };

  /// Short badge label used inside dense list rows.
  String get shortLabel => switch (this) {
    RiskLevel.safe => 'Safe',
    RiskLevel.low => 'Low',
    RiskLevel.medium => 'Review',
    RiskLevel.high => 'High',
    RiskLevel.critical => 'Critical',
  };
}

class RiskPalette {
  const RiskPalette._();

  static Color color(BuildContext context, RiskLevel level) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (level) {
      RiskLevel.safe => dark ? const Color(0xFF34D399) : AppColors.safe,
      RiskLevel.low => dark ? const Color(0xFF60A5FA) : AppColors.info,
      RiskLevel.medium => AppColors.warning,
      RiskLevel.high => dark ? const Color(0xFFF87171) : AppColors.danger,
      RiskLevel.critical => AppColors.danger,
    };
  }

  static Color scoreColor(BuildContext context, int score) =>
      color(context, levelForScore(score));

  /// 90–100 Excellent · 75–89 Good · 50–74 Needs Review · below 50 Attention.
  static RiskLevel levelForScore(int score) {
    if (score >= 90) return RiskLevel.safe;
    if (score >= 75) return RiskLevel.low;
    if (score >= 50) return RiskLevel.medium;
    if (score > 0) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static String scoreBand(BuildContext context, int score) {
    final s = Strings.of(context);
    if (s.isHindi) {
      if (score >= 90) return s.excellent;
      if (score >= 75) return s.good;
      if (score >= 50) return s.needsReview;
      return s.attentionRequired;
    }
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 50) return 'Needs Review';
    return 'Attention Required';
  }
}
