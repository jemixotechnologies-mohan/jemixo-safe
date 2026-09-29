import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';

/// Haptic cues gated by the "Haptic feedback" setting.
class AppHaptics {
  const AppHaptics._();

  static bool _enabled(BuildContext context) {
    try {
      return context.read<SettingsController>().haptics;
    } catch (_) {
      return false;
    }
  }

  /// Light tick for selection changes.
  static void tap(BuildContext context) {
    if (_enabled(context)) HapticFeedback.selectionClick();
  }

  /// Confirms that a scan or cleanup finished.
  static void success(BuildContext context) {
    if (_enabled(context)) HapticFeedback.mediumImpact();
  }

  /// Draws attention to a warning or failure.
  static void warning(BuildContext context) {
    if (_enabled(context)) HapticFeedback.heavyImpact();
  }
}
