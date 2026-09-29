import 'package:drift/drift.dart';

import '../../core/theme/risk_palette.dart';
import '../database/app_database.dart';

/// Persists scan results, findings and app snapshots so History and Reports
/// work without rescanning the device.
class ScanRepository {
  ScanRepository(this._db);

  final AppDatabase _db;

  Future<int> saveScan({
    required String scanType,
    required int score,
    required RiskLevel level,
    required int durationMs,
    required int appsScanned,
    required String summary,
    required List<FindingDraft> findings,
    List<AppSnapshotDraft> snapshots = const [],
  }) async {
    return _db.transaction(() async {
      final scanId = await _db
          .into(_db.scanRecords)
          .insert(
            ScanRecordsCompanion.insert(
              scanType: scanType,
              score: score,
              riskLevel: level.name,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              durationMs: Value(durationMs),
              appsScanned: Value(appsScanned),
              findingsCount: Value(findings.length),
              findingsHigh: Value(
                findings.where((f) => f.severity >= 3).length,
              ),
              findingsMedium: Value(
                findings.where((f) => f.severity == 2).length,
              ),
              findingsLow: Value(findings.where((f) => f.severity <= 1).length),
              summary: Value(summary),
            ),
          );

      if (snapshots.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.appSnapshots, [
            for (final snapshot in snapshots)
              AppSnapshotsCompanion.insert(
                scanId: scanId,
                packageName: snapshot.packageName,
                appName: snapshot.appName,
                riskLevel: snapshot.level.name,
                riskScore: snapshot.score,
                permissionsSensitive: Value(snapshot.sensitivePermissions),
                elevatedPermissions: Value(snapshot.elevatedPermissions),
                sideloaded: Value(snapshot.sideloaded),
                systemApp: Value(snapshot.systemApp),
                reasons: Value(snapshot.reasons.join('\n')),
                permissions: Value(snapshot.permissionNames.join('\n')),
              ),
          ]);
        });
      }

      if (findings.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.findingRecords, [
            for (final finding in findings)
              FindingRecordsCompanion.insert(
                scanId: scanId,
                category: finding.category,
                title: finding.title,
                detail: Value(finding.detail),
                severity: finding.severity >= 3
                    ? 'high'
                    : finding.severity == 2
                    ? 'medium'
                    : 'low',
                subject: Value(finding.subject),
              ),
          ]);
        });
      }

      return scanId;
    });
  }

  Future<List<ScanRecord>> history({int limit = 50}) =>
      _db.recentScans(limit: limit);

  Future<List<AppSnapshot>> snapshots(int scanId) => _db.snapshotsFor(scanId);

  Future<List<FindingRecord>> findings(int scanId) => _db.findingsFor(scanId);

  Future<ScanRecord?> scan(int id) => (_db.select(
    _db.scanRecords,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> deleteScan(int id) => _db.deleteScan(id);

  Future<void> clearHistory() => _db.clearHistory();

  /// Newest two scans of [type], for the "what changed" comparison.
  Future<List<ScanRecord>> lastTwo(String type) => _db.lastTwoScans(type);
}

class FindingDraft {
  const FindingDraft({
    required this.category,
    required this.title,
    required this.detail,
    required this.severity,
    this.subject = '',
  });

  final String category;
  final String title;
  final String detail;
  final int severity;
  final String subject;
}

class AppSnapshotDraft {
  const AppSnapshotDraft({
    required this.packageName,
    required this.appName,
    required this.level,
    required this.score,
    required this.sensitivePermissions,
    required this.elevatedPermissions,
    required this.sideloaded,
    required this.systemApp,
    required this.reasons,
    this.permissionNames = const [],
  });

  final String packageName;
  final String appName;
  final RiskLevel level;
  final int score;
  final int sensitivePermissions;
  final int elevatedPermissions;
  final bool sideloaded;
  final bool systemApp;
  final List<String> reasons;

  /// Sensitive + elevated permission names, for diffing scans.
  final List<String> permissionNames;
}
