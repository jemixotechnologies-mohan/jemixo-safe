import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Every stored scan result. Risk scores are indicators produced by on-device
/// heuristics, never verdicts, so the schema keeps the reason text alongside
/// the number.
@DataClassName('ScanRecord')
class ScanRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get scanType => text()();
  IntColumn get score => integer()();
  TextColumn get riskLevel => text()();
  IntColumn get createdAt => integer()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get appsScanned => integer().withDefault(const Constant(0))();
  IntColumn get findingsCount => integer().withDefault(const Constant(0))();
  IntColumn get findingsHigh => integer().withDefault(const Constant(0))();
  IntColumn get findingsMedium => integer().withDefault(const Constant(0))();
  IntColumn get findingsLow => integer().withDefault(const Constant(0))();
  TextColumn get summary => text().withDefault(const Constant(''))();
}

/// Per-app snapshot produced by the app scanner, kept so the report page and
/// history can be reopened without rescanning.
@DataClassName('AppSnapshot')
class AppSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scanId => integer()();
  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  TextColumn get riskLevel => text()();
  IntColumn get riskScore => integer()();
  IntColumn get permissionsSensitive =>
      integer().withDefault(const Constant(0))();
  IntColumn get elevatedPermissions =>
      integer().withDefault(const Constant(0))();
  BoolColumn get sideloaded => boolean().withDefault(const Constant(false))();
  BoolColumn get systemApp => boolean().withDefault(const Constant(false))();
  TextColumn get reasons => text().withDefault(const Constant(''))();

  /// Newline-joined sensitive + elevated permission names at scan time, so
  /// two scans can be diffed ("this app now asks for contacts").
  TextColumn get permissions => text().withDefault(const Constant(''))();
}

/// Findings attached to a scan, used by History and Reports.
@DataClassName('FindingRecord')
class FindingRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scanId => integer()();
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get detail => text().withDefault(const Constant(''))();
  TextColumn get severity => text()();
  TextColumn get subject => text().withDefault(const Constant(''))();
}

/// User decisions: apps and permissions they want the app to stop nagging about.
@DataClassName('IgnoreRecord')
class IgnoreRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get target => text()();
  IntColumn get createdAt => integer()();
}

@DataClassName('SettingRecord')
class SettingRecords extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    ScanRecords,
    AppSnapshots,
    FindingRecords,
    IgnoreRecords,
    SettingRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'jemixo_safe'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(appSnapshots, appSnapshots.permissions);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// The two most recent scans of [type], newest first.
  Future<List<ScanRecord>> lastTwoScans(String type) {
    return (select(scanRecords)
          ..where((t) => t.scanType.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(2))
        .get();
  }

  Future<List<ScanRecord>> recentScans({int limit = 30}) {
    return (select(scanRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<int> lastScanOfType(String type) async {
    final row =
        await (select(scanRecords)
              ..where((t) => t.scanType.equals(type))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.createdAt ?? 0;
  }

  Future<List<AppSnapshot>> snapshotsFor(int scanId) {
    return (select(appSnapshots)..where((t) => t.scanId.equals(scanId))).get();
  }

  Future<List<FindingRecord>> findingsFor(int scanId) {
    return (select(
      findingRecords,
    )..where((t) => t.scanId.equals(scanId))).get();
  }

  Future<void> deleteScan(int scanId) async {
    await transaction(() async {
      await (delete(appSnapshots)..where((t) => t.scanId.equals(scanId))).go();
      await (delete(
        findingRecords,
      )..where((t) => t.scanId.equals(scanId))).go();
      await (delete(scanRecords)..where((t) => t.id.equals(scanId))).go();
    });
  }

  Future<void> clearHistory() async {
    await transaction(() async {
      await delete(appSnapshots).go();
      await delete(findingRecords).go();
      await delete(scanRecords).go();
    });
  }

  Future<void> clearIgnoreList() async => delete(ignoreRecords).go();

  Future<void> clearEverything() async {
    await clearHistory();
    await clearIgnoreList();
    await delete(settingRecords).go();
  }
}
