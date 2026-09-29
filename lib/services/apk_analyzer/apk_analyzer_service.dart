import 'package:flutter/foundation.dart';

import '../../core/permissions/permission_catalog.dart';
import '../../core/theme/risk_palette.dart';
import '../platform/native_bridge.dart';
import '../platform/native_models.dart';
import '../risk_engine/risk_engine.dart';

/// APK inspection for a user-selected file.
///
/// Android only lets an app read an arbitrary APK through the document picker
/// or a share intent, so this service works on paths the user explicitly
/// handed over. Nothing here installs or executes the package.
class ApkAnalyzerService extends ChangeNotifier {
  ApkAnalyzerService({NativeBridge? bridge, PrivacyEngine? privacyEngine})
    : _bridge = bridge ?? NativeBridge.instance,
      _privacyEngine = privacyEngine ?? const PrivacyEngine();

  final NativeBridge _bridge;
  final PrivacyEngine _privacyEngine;

  ApkAnalysis? _lastResult;
  String? _lastError;
  bool _analyzing = false;

  ApkAnalysis? get lastResult => _lastResult;
  String? get lastError => _lastError;
  bool get isAnalyzing => _analyzing;

  Future<ApkAnalysis?> analyze(String target) async {
    if (_analyzing) return null;
    _analyzing = true;
    _lastResult = null;
    _lastError = null;
    notifyListeners();

    try {
      final map = await _bridge.analyzeApk(target);
      if (map == null) {
        _lastError = 'Android returned no data for this file.';
        return null;
      }
      final result = ApkAnalysis.fromMap(map);
      _lastResult = result;
      return result;
    } on NativeBridgeException catch (e) {
      _lastError = switch (e.code) {
        'APK_NOT_FOUND' => 'That file no longer exists.',
        _ => e.message,
      };
      return null;
    } finally {
      _analyzing = false;
      notifyListeners();
    }
  }

  void clear() {
    _lastResult = null;
    _lastError = null;
    notifyListeners();
  }

  int privacyScore(ApkAnalysis analysis) =>
      _privacyEngine.scoreFor(_synthetic(analysis));

  RiskLevel privacyLevel(ApkAnalysis analysis) =>
      _privacyEngine.levelFor(privacyScore(analysis));

  List<String> privacyReasons(ApkAnalysis analysis) =>
      _privacyEngine.reasons(_synthetic(analysis));

  List<String> sensitivePermissions(ApkAnalysis analysis) => analysis
      .permissions
      .where((p) => resolvePermission(p) != null)
      .toList(growable: false);

  List<String> elevatedPermissions(ApkAnalysis analysis) =>
      analysis.permissions.where(isElevatedPermission).toList(growable: false);

  /// Collects advisory notes about a package's manifest.
  List<ApkAnalysisNote> review(ApkAnalysis analysis) {
    final notes = <ApkAnalysisNote>[];

    if (!analysis.valid) {
      notes.add(
        const ApkAnalysisNote(
          severity: 2,
          title: 'Not a readable Android package',
          message:
              'Android could not parse this file, so no metadata is available. '
              'A truncated or corrupted download is the most likely cause.',
        ),
      );
      return notes;
    }

    for (final permission in elevatedPermissions(analysis)) {
      notes.add(
        ApkAnalysisNote(
          severity: 2,
          title: 'Asks for ${elevatedPermissionTitle(permission)}',
          message:
              'This is a powerful capability. Only expected in accessibility, '
              'VPN, launcher or security apps.',
        ),
      );
    }

    if (analysis.debuggable) {
      notes.add(
        const ApkAnalysisNote(
          severity: 2,
          title: 'Built in debug mode',
          message:
              'Release apps from stores are never debuggable. Debug builds can '
              'expose extra logging and are easy to tamper with.',
        ),
      );
    }

    if (analysis.usesCleartextTraffic == true) {
      notes.add(
        const ApkAnalysisNote(
          severity: 1,
          title: 'May allow unencrypted connections',
          message:
              'The manifest mentions cleartext traffic. Sensitive data sent '
              'over plain HTTP can be intercepted.',
        ),
      );
    }

    if (analysis.signatures.isEmpty) {
      notes.add(
        const ApkAnalysisNote(
          severity: 1,
          title: 'No signature information',
          message:
              'Publisher identity could not be read from this file, so the app '
              'cannot be attributed to a known developer.',
        ),
      );
    } else {
      notes.add(
        ApkAnalysisNote(
          severity: 0,
          title: 'Signed',
          message:
              'Signed with certificate ${analysis.signatures.first.shortFingerprint}.',
        ),
      );
    }

    final installed = analysis.installedVersionCode;
    final own = analysis.versionCode;
    if (installed != null && own != null) {
      if (own > installed) {
        notes.add(
          ApkAnalysisNote(
            severity: 0,
            title: 'Update for an installed app',
            message:
                'Version $own is newer than the installed build ($installed). '
                'Android will only apply it if the signing certificate matches.',
          ),
        );
      } else if (own < installed) {
        notes.add(
          ApkAnalysisNote(
            severity: 1,
            title: 'Older than the installed version',
            message:
                'This package is version $own but $installed is installed. '
                'Downgrades are refused by Android and are a common repackaging sign.',
          ),
        );
      } else {
        notes.add(
          const ApkAnalysisNote(
            severity: 0,
            title: 'Already installed',
            message: 'The same version of this package is on the device.',
          ),
        );
      }
    }

    final target = analysis.targetSdk;
    if (target != null) {
      if (target >= 31) {
        notes.add(
          ApkAnalysisNote(
            severity: 0,
            title: 'Targets a recent Android version',
            message:
                'Built for API $target, so it follows current permission and '
                'privacy rules.',
          ),
        );
      } else if (target < 26) {
        notes.add(
          ApkAnalysisNote(
            severity: 1,
            title: 'Targets an old Android version',
            message:
                'Built for API $target. Old targets skip newer privacy '
                'protections and may not install on recent devices.',
          ),
        );
      }
    }

    if (analysis.hasNativeCode == false) {
      notes.add(
        const ApkAnalysisNote(
          severity: 0,
          title: 'No native libraries',
          message:
              'This package contains no native code. Normal for web-based or '
              'simple utility apps.',
        ),
      );
    }

    final sensitive = sensitivePermissions(analysis).length;
    if (sensitive >= 6) {
      notes.add(
        ApkAnalysisNote(
          severity: 1,
          title: '$sensitive sensitive permissions',
          message:
              'Review the permission list below and question anything the app '
              'would not need for what it does.',
        ),
      );
    }

    notes.sort((a, b) => b.severity.compareTo(a.severity));
    return notes;
  }

  AppInfo _synthetic(ApkAnalysis analysis) => AppInfo(
    packageName: analysis.packageName ?? 'unknown',
    label: analysis.displayName,
    sizeBytes: analysis.sizeBytes,
    permissions: analysis.permissions,
    targetSdk: analysis.targetSdk,
  );
}

class ApkAnalysisNote {
  const ApkAnalysisNote({
    required this.severity,
    required this.title,
    required this.message,
  });

  /// 0 informational, 1 worth a look, 2 notable.
  final int severity;
  final String title;
  final String message;

  RiskLevel get level => switch (severity) {
    >= 2 => RiskLevel.high,
    1 => RiskLevel.medium,
    _ => RiskLevel.safe,
  };
}
