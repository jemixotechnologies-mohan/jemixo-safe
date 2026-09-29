import 'package:flutter/foundation.dart';

import '../core/permissions/permission_catalog.dart';
import '../core/theme/risk_palette.dart';
import '../data/repositories/scan_repository.dart';
import '../services/app_scanner/app_scanner_service.dart';
import '../services/platform/native_bridge.dart';

/// Drives the Security screen scan: runs the app scanner, derives a
/// device-level indicator, and (when enabled) writes a history record.
class SecurityController extends ChangeNotifier {
  SecurityController(this._scanner, this._repository, this._shouldSaveHistory);

  static const scanType = 'security';

  final AppScannerService _scanner;
  final ScanRepository _repository;
  final bool Function() _shouldSaveHistory;

  DateTime? _lastScanAt;
  int _lastDurationMs = 0;
  int? _lastScore;
  int _lastScanId = -1;
  bool _running = false;
  int _progress = 0;
  String? _lastError;

  DateTime? get lastScanAt => _lastScanAt;
  int get lastDurationMs => _lastDurationMs;
  int? get lastScore => _lastScore;
  int get lastScanId => _lastScanId;
  bool get isRunning => _running;
  int get progress => _progress;
  String? get lastError => _lastError;

  /// Overall indicator, 0–100. Derived from how many apps carry elevated
  /// indicators, never presented as a malware verdict.
  int? get score {
    if (_scanner.allApps.isEmpty) return null;
    return computeScore(_scanner);
  }

  RiskLevel get level =>
      score == null ? RiskLevel.medium : RiskPalette.levelForScore(score!);

  Future<void> runScan() async {
    if (_running) return;
    _running = true;
    _progress = 8;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      await _scanner.scan();
      _progress = 70;
      notifyListeners();
      _lastScore = _scanner.allApps.isEmpty ? null : computeScore(_scanner);
      _lastError = _scanner.lastError;
    } catch (error) {
      _lastError = 'Scan failed: $error';
    } finally {
      stopwatch.stop();
      _lastDurationMs = stopwatch.elapsedMilliseconds;
      _lastScanAt = DateTime.now();
      _progress = 100;
      _running = false;
      notifyListeners();
    }

    if (_lastScore != null && _shouldSaveHistory()) {
      try {
        await _persist();
      } catch (_) {
        // History is a convenience; a write failure must not surface as a
        // failed scan.
      }
    }
    _publishWidget();
  }

  /// Mirrors the result onto the home-screen widget.
  void _publishWidget() {
    final score = _lastScore;
    final review = _scanner.needsReview.length;
    final fakes = _scanner.impersonatingApps.length;
    NativeBridge.instance.updateWidget(
      score: score,
      status: score == null
          ? 'Tap to run a safety check'
          : fakes > 0
          ? '$fakes look-alike bank app${fakes == 1 ? '' : 's'} found'
          : review == 0
          ? 'Nothing needs attention'
          : '$review app${review == 1 ? '' : 's'} worth a look',
      subtitle: score == null
          ? ''
          : 'Checked ${_relative(_lastScanAt)} · ${_scanner.userApps.length} apps',
    );
  }

  static String _relative(DateTime? at) {
    if (at == null) return 'just now';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }

  Future<void> _persist() async {
    final findings = buildFindings(_scanner);
    final id = await _repository.saveScan(
      scanType: scanType,
      score: _lastScore ?? 0,
      level: level,
      durationMs: _lastDurationMs,
      appsScanned: _scanner.allApps.length,
      summary: _summary(),
      findings: findings,
      snapshots: [
        for (final assessment in _scanner.assessments)
          if (!assessment.app.isSystemApp || assessment.needsReview)
            AppSnapshotDraft(
              packageName: assessment.app.packageName,
              appName: assessment.app.label,
              level: assessment.level,
              score: assessment.score,
              sensitivePermissions: assessment.app.permissions
                  .where((p) => resolvePermission(p) != null)
                  .length,
              elevatedPermissions: assessment.app.permissions
                  .where(isElevatedPermission)
                  .length,
              sideloaded: assessment.app.isSideloaded,
              systemApp: assessment.app.isSystemApp,
              reasons: assessment.indicators.map((i) => i.title).toList(),
              permissionNames: assessment.app.permissions
                  .where((p) => resolvePermission(p) != null || isElevatedPermission(p))
                  .toList(),
            ),
      ],
    );
    _lastScanId = id;
    notifyListeners();
  }

  String _summary() {
    final buffer = StringBuffer();
    buffer.write('${_scanner.userApps.length} user apps reviewed. ');
    buffer.write('${_scanner.highRisk.length} high, ');
    buffer.write('${_scanner.mediumRisk.length} to review, ');
    buffer.write('${_scanner.lowRisk.length} low. ');
    if (_scanner.debuggableAppCount > 0) {
      buffer.write('${_scanner.debuggableAppCount} debuggable build(s). ');
    }
    if (_scanner.sideloadedAppCount > 0) {
      buffer.write(
        '${_scanner.sideloadedAppCount} installed outside a known store.',
      );
    }
    return buffer.toString().trim();
  }
}

/// Shared scoring so the dashboard and the Security screen always agree.
int computeScore(AppScannerService scanner) {
  final userApps = scanner.userApps;
  if (userApps.isEmpty) return 100;

  final total = userApps.fold<int>(
    0,
    (sum, app) => sum + (scanner.assessmentFor(app.packageName)?.score ?? 0),
  );
  final average = total / userApps.length;

  var score = 100 - average;
  if (scanner.debuggableAppCount > 0) score -= 4;
  if (scanner.sideloadedAppCount > 2) score -= 3;
  if (scanner.elevatedAccessCount > 12) score -= 4;
  return score.round().clamp(0, 100);
}

/// Human-readable findings used for the checklist and the history record.
List<FindingDraft> buildFindings(AppScannerService scanner) {
  final findings = <FindingDraft>[];

  for (final assessment in scanner.needsReview) {
    for (final indicator in assessment.indicators) {
      findings.add(
        FindingDraft(
          category: 'App permission',
          title: '${assessment.app.label} — ${indicator.title}',
          detail: indicator.description,
          severity: indicator.severity,
          subject: assessment.app.packageName,
        ),
      );
    }
  }
  return findings;
}
