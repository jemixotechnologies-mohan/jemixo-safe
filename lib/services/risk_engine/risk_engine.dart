import '../../core/permissions/permission_catalog.dart';
import '../../core/theme/risk_palette.dart';
import '../platform/native_models.dart';
import '../threat_data/threat_data.dart';
import 'app_identity.dart';

/// A single observable fact that raises or lowers an app's risk indicator.
///
/// [severity] drives both the per-indicator weight and the UI colour, so a
/// single critical indicator is visible without inflating the total count.
class RiskIndicator {
  const RiskIndicator({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
  });

  final String id;
  final String title;
  final String description;

  /// 1 informational, 2 worth a look, 3 serious.
  final int severity;

  bool get isCritical => severity >= 3;
}

/// Result of evaluating one app.
class AppRiskAssessment {
  const AppRiskAssessment({
    required this.app,
    required this.indicators,
    required this.score,
    required this.level,
  });

  final AppInfo app;
  final List<RiskIndicator> indicators;

  /// 0 (clean) to 100 (max concern). This is a density indicator, not a verdict.
  final int score;
  final RiskLevel level;

  /// Only indicators that are worth the user's attention count. Purely
  /// informational signals (unusual package name, missing metadata) do not
  /// put an app on the review list by themselves.
  bool get needsReview => indicators.any((i) => i.severity >= 2);

  RiskIndicator? get topIndicator {
    if (indicators.isEmpty) return null;
    final sorted = [...indicators]
      ..sort((a, b) => b.severity.compareTo(a.severity));
    return sorted.first;
  }

  List<String> get sensitivePermissions => app.permissions
      .where((p) => resolvePermission(p) != null)
      .toList(growable: false);

  List<PermissionCategory> get sensitiveCategories =>
      sensitivePermissions.map(categoryFor).toSet().toList(growable: false);
}

const _kSmsPermissions = <String>{
  'android.permission.READ_SMS',
  'android.permission.RECEIVE_SMS',
  'android.permission.SEND_SMS',
  'android.permission.RECEIVE_MMS',
  'android.permission.RECEIVE_WAP_PUSH',
};

const _kContactPermissions = <String>{
  'android.permission.READ_CONTACTS',
  'android.permission.WRITE_CONTACTS',
};

/// Rule-based local risk engine.
///
/// Every rule describes an *observable* property (permission mix, install
/// source, debuggable flag) and is phrased as an indicator. Nothing here
/// classifies an app as malware — the UI must not overstate the result.
/// Device-wide facts that change how an app is judged.
class DeviceContext {
  const DeviceContext({
    this.accessibilityPackages = const {},
    this.notificationListenerPackages = const {},
    this.deviceAdminPackages = const {},
  });

  final Set<String> accessibilityPackages;
  final Set<String> notificationListenerPackages;
  final Set<String> deviceAdminPackages;
}

class RiskEngine {
  const RiskEngine({
    this.flagDebuggable = true,
    this.dataOverride,
    this.device = const DeviceContext(),
  });

  /// Mirrors the "Flag debuggable builds" setting.
  final bool flagDebuggable;

  final DeviceContext device;

  /// Threat data to use instead of [ThreatData.current] (tests).
  final ThreatData? dataOverride;

  ThreatData get data => dataOverride ?? ThreatData.current;

  /// Number of curated sensitive permissions before the count alone becomes
  /// noteworthy. Requesting many is legitimate for some apps (a camera app
  /// wants camera + audio + storage), so this is a low-weight signal.
  static const _highSensitiveCount = 8;

  /// Well-known packages that legitimately need broad access. Ignoring these
  /// keeps the dashboard useful instead of permanently amber.
  static const _trustedPackages = <String>{
    'com.android.chrome',
    'com.google.android.youtube',
    'com.google.android.apps.maps',
    'com.google.android.apps.messaging',
    'com.google.android.dialer',
    'com.google.android.contacts',
    'com.google.android.gm',
    'com.whatsapp',
    'com.whatsapp.w4b',
    'org.telegram.messenger',
    'com.android.vending',
    'com.google.android.gms',
    'com.google.android.googlequicksearchbox',
    'com.truecaller',
    'com.microsoft.teams',
    'com.skype.raider',
  };

  List<RiskIndicator> evaluate(AppInfo app) {
    final indicators = <RiskIndicator>[];

    // --- Identity: fake brand apps and unregulated lenders -----------------
    indicators.addAll(AppIdentityChecker(data).indicatorsFor(app));

    final sensitive = app.permissions
        .where((permission) => resolvePermission(permission) != null)
        .toList(growable: false);
    final permissionSet = app.permissions.toSet();

    // --- Special access actually granted (not just requested) --------------
    if (!app.isSystemApp && device.accessibilityPackages.contains(app.packageName)) {
      indicators.add(
        const RiskIndicator(
          id: 'accessibility-on',
          title: 'Accessibility service is switched ON',
          description:
              'This app can read everything on screen and tap on your behalf, '
              'including banking apps. Only screen readers and assistive tools '
              'should have this. Turn it off in Settings if you did not enable it knowingly.',
          severity: 3,
        ),
      );
    }
    if (!app.isSystemApp && device.notificationListenerPackages.contains(app.packageName)) {
      indicators.add(
        const RiskIndicator(
          id: 'notification-access-on',
          title: 'Notification access is switched ON',
          description:
              'This app reads every notification, including OTP messages. '
              'Expected for smartwatch companions; unexpected for anything else.',
          severity: 3,
        ),
      );
    }
    if (!app.isSystemApp && device.deviceAdminPackages.contains(app.packageName)) {
      indicators.add(
        const RiskIndicator(
          id: 'device-admin-on',
          title: 'Device administrator is active',
          description:
              'A device admin can lock the phone, wipe it and resist uninstalling. '
              'Company MDM apps use this; a loan or utility app should not.',
          severity: 3,
        ),
      );
    }

    // --- Hidden app ---------------------------------------------------------
    if (!app.isSystemApp && !app.hasLauncherIcon && app.isEnabled) {
      final spies = permissionSet.any(
        (p) =>
            _kSmsPermissions.contains(p) ||
            p == 'android.permission.RECORD_AUDIO' ||
            p == 'android.permission.ACCESS_FINE_LOCATION' ||
            p == 'android.permission.CAMERA' ||
            p == 'android.permission.READ_CALL_LOG' ||
            p == 'android.permission.BIND_ACCESSIBILITY_SERVICE',
      );
      indicators.add(
        RiskIndicator(
          id: spies ? 'hidden-spy' : 'hidden-app',
          title: spies
              ? 'Hidden app with spying-type permissions'
              : 'App with no home-screen icon',
          description: spies
              ? 'It has no icon, so you cannot open it, yet it asks for SMS, '
                    'microphone, camera, location or call log. This is the shape '
                    'of stalkerware. Review it in Settings → Apps and uninstall if unknown.'
              : 'It cannot be opened from the launcher. Plugins and keyboards '
                    'are like this; anything else is worth a look in Settings → Apps.',
          severity: spies ? 3 : 1,
        ),
      );
    }

    // --- Elevated / special access -------------------------------------
    for (final permission in app.permissions) {
      if (isElevatedPermission(permission)) {
        final title = elevatedPermissionTitle(permission);
        indicators.add(
          RiskIndicator(
            id: 'elevated:${permission.split('.').last}',
            title: 'Requests elevated access ($title)',
            description:
                'This grants powerful control over the device and is only expected '
                'in accessibility tools, launchers, VPNs or security apps.',
            severity: 3,
          ),
        );
      }
    }

    // --- SMS ------------------------------------------------------------
    final hasSms = permissionSet.any(_kSmsPermissions.contains);
    if (hasSms) {
      indicators.add(
        const RiskIndicator(
          id: 'sms',
          title: 'Requests SMS access',
          description:
              'Can read, receive or send text messages. Normal for messaging apps; '
              'unusual for games, wallpapers or utility apps.',
          severity: 3,
        ),
      );
    }

    // --- Contacts -------------------------------------------------------
    final hasContacts = permissionSet.any(_kContactPermissions.contains);
    if (hasContacts) {
      indicators.add(
        const RiskIndicator(
          id: 'contacts',
          title: 'Requests contacts access',
          description: 'Can read the contacts saved on this device.',
          severity: 2,
        ),
      );
    }

    // --- Location in the background -------------------------------------
    if (permissionSet.contains(
      'android.permission.ACCESS_BACKGROUND_LOCATION',
    )) {
      indicators.add(
        const RiskIndicator(
          id: 'background-location',
          title: 'Tracks location in the background',
          description:
              'Keeps collecting location while closed. Expected for maps, delivery '
              'and fitness apps; review it for anything else.',
          severity: 3,
        ),
      );
    }

    // --- SMS + contacts pairing ----------------------------------------
    if (hasSms && hasContacts) {
      indicators.add(
        const RiskIndicator(
          id: 'sms+contacts',
          title: 'Combines SMS and contacts access',
          description:
              'Together these two permissions can read messages from the people in '
              'your contacts. This pairing is unusual outside messaging apps.',
          severity: 3,
        ),
      );
    }

    // --- Broad sensitive count -----------------------------------------
    if (sensitive.length >= _highSensitiveCount) {
      indicators.add(
        RiskIndicator(
          id: 'excessive-permissions',
          title: 'Requests ${sensitive.length} sensitive permissions',
          description:
              'A wide permission list is sometimes legitimate, but it increases how '
              'much of your private data the app could reach.',
          severity: sensitive.length >= 12 ? 2 : 1,
        ),
      );
    }

    // --- Package naming characteristics ---------------------------------
    if (!app.isSystemApp) indicators.addAll(_packageNameSignals(app));

    // --- Debuggable -----------------------------------------------------
    if (flagDebuggable && app.debuggable && !app.isSystemApp) {
      indicators.add(
        const RiskIndicator(
          id: 'debuggable',
          title: 'Marked as debuggable',
          description:
              'The app was built in debug mode. Store releases are never built this '
              'way, so a debuggable store app is unusual.',
          severity: 2,
        ),
      );
    }

    // --- Missing metadata ----------------------------------------------
    if (app.signatures.isEmpty && !app.isSystemApp) {
      indicators.add(
        const RiskIndicator(
          id: 'no-signature',
          title: 'Signature details unavailable',
          description:
              'Android did not expose signing information for this app, so its '
              'publisher could not be verified locally.',
          severity: 1,
        ),
      );
    }

    // --- Install source ------------------------------------------------
    if (app.isSideloaded && !app.isSystemApp) {
      indicators.add(
        RiskIndicator(
          id: 'sideloaded',
          title: 'Installed outside a known app store',
          description:
              'Android reports ${app.installSourceLabel ?? 'no store'} as the '
              'installer for ${app.label}. Apps from outside a store receive no '
              'store review, so take extra care.',
          severity: 2,
        ),
      );
    }

    // Well-known packages keep only genuinely serious signals.
    if (_trustedPackages.contains(app.packageName)) {
      return indicators.where((i) => i.isCritical).toList(growable: false);
    }

    return indicators;
  }

  /// Conservative check for package-name shapes that are worth a look.
  /// Deliberately narrow: broad "looks random" heuristics produce noise.
  List<RiskIndicator> _packageNameSignals(AppInfo app) {
    final signals = <RiskIndicator>[];
    final name = app.packageName.toLowerCase();

    final segments = name.split('.');
    if (segments.length < 2) {
      signals.add(
        RiskIndicator(
          id: 'package-shape',
          title: 'Unusual package name',
          description:
              '${app.packageName} does not follow the usual reverse-domain format. '
              'Most legitimate apps use a company domain.',
          severity: 1,
        ),
      );
    }

    if (RegExp(r'[0-9]{5,}').hasMatch(name) && segments.length <= 3) {
      signals.add(
        const RiskIndicator(
          id: 'package-numeric',
          title: 'Package name contains long number sequences',
          description:
              'Long random number sequences in a package name can occur in generated '
              'or throwaway packages. Many legitimate apps do this too.',
          severity: 1,
        ),
      );
    }

    return signals;
  }

  /// Aggregate indicator density into a 0–100 score with diminishing returns,
  /// so ten minor signals do not outweigh one serious one.
  int scoreFor(List<RiskIndicator> indicators) {
    if (indicators.isEmpty) return 0;
    var raw = 0;
    for (final indicator in indicators) {
      raw += switch (indicator.severity) {
        >= 3 => 26,
        2 => 14,
        _ => 6,
      };
    }
    // Compress: 100 requires many separate indicators, not one.
    final compressed = (raw / (raw + 70)) * 100;
    return compressed.round().clamp(0, 100);
  }

  static const _decisiveIds = {
    'impersonation',
    'signature-mismatch',
    'accessibility-on',
    'notification-access-on',
    'hidden-spy',
  };

  RiskLevel levelFor(int score, List<RiskIndicator> indicators) {
    // A fake bank app is high risk on its own, whatever else it asks for.
    if (indicators.any((i) => _decisiveIds.contains(i.id))) {
      return RiskLevel.high;
    }
    if (indicators.any((i) => i.isCritical) && score >= 45) {
      return RiskLevel.high;
    }
    if (score >= 60) return RiskLevel.high;
    if (score >= 35) return RiskLevel.medium;
    if (score > 0) return RiskLevel.low;
    return RiskLevel.safe;
  }

  AppRiskAssessment assess(AppInfo app) {
    final indicators = evaluate(app);
    final score = scoreFor(indicators);
    return AppRiskAssessment(
      app: app,
      indicators: indicators,
      score: score,
      level: levelFor(score, indicators),
    );
  }
}

/// Dedicated privacy-risk evaluator.
///
/// Separate from the security risk engine on purpose: an app can be perfectly
/// safe and still be highly invasive of privacy (a flashlight app asking for
/// contacts). The Privacy tab needs that distinction.
class PrivacyEngine {
  const PrivacyEngine();

  int scoreFor(AppInfo app) {
    var weighted = 0;
    for (final permission in app.permissions) {
      final definition = resolvePermission(permission);
      if (definition == null) continue;
      weighted += definition.category.sensitivityWeight;
    }

    // Total-files access on a non-system app is a large exposure.
    if (app.permissions.contains(
          'android.permission.MANAGE_EXTERNAL_STORAGE',
        ) &&
        !app.isSystemApp) {
      weighted += 4;
    }
    if (app.permissions.contains(
      'android.permission.ACCESS_BACKGROUND_LOCATION',
    )) {
      weighted += 3;
    }

    // 0 -> 100 with diminishing returns. One location permission (3) lands
    // at 20, contacts + location + microphone (8) at 40, and an app that
    // reaches SMS, contacts and background location clears 60.
    return ((weighted / (weighted + 12)) * 100).round().clamp(0, 100);
  }

  RiskLevel levelFor(int score) {
    if (score >= 70) return RiskLevel.high;
    if (score >= 45) return RiskLevel.medium;
    if (score > 0) return RiskLevel.low;
    return RiskLevel.safe;
  }

  List<String> reasons(AppInfo app) {
    final reasons = <String>[];
    final byCategory = <PermissionCategory, List<String>>{};

    for (final permission in app.permissions) {
      final definition = resolvePermission(permission);
      if (definition == null) continue;
      byCategory
          .putIfAbsent(definition.category, () => [])
          .add(definition.title);
    }

    if (byCategory.isEmpty) {
      reasons.add('No sensitive permissions detected');
      return reasons;
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final entry in sorted.take(6)) {
      reasons.add('Access to ${entry.key.label.toLowerCase()}');
    }

    final total = app.permissions
        .where((p) => resolvePermission(p) != null)
        .length;
    if (total >= 6) {
      reasons.add('$total sensitive permissions in total');
    }

    return reasons;
  }
}
