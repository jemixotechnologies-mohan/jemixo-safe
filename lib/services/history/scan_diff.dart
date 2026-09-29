import '../../data/database/app_database.dart';
import '../../data/repositories/scan_repository.dart';

/// One app whose permissions grew between two scans.
class PermissionChange {
  const PermissionChange({
    required this.packageName,
    required this.appName,
    required this.added,
    required this.removed,
  });

  final String packageName;
  final String appName;
  final List<String> added;
  final List<String> removed;
}

/// What changed between the last two safety checks.
class ScanDiff {
  const ScanDiff({
    required this.previous,
    required this.latest,
    required this.installed,
    required this.removed,
    required this.changed,
  });

  final ScanRecord previous;
  final ScanRecord latest;
  final List<AppSnapshot> installed;
  final List<AppSnapshot> removed;
  final List<PermissionChange> changed;

  bool get isEmpty => installed.isEmpty && removed.isEmpty && changed.isEmpty;
  int get scoreDelta => latest.score - previous.score;
}

/// Compares the two most recent stored scans of a type.
class ScanDiffService {
  const ScanDiffService(this._repository);

  final ScanRepository _repository;

  Future<ScanDiff?> latest({String scanType = 'security'}) async {
    final scans = await _repository.lastTwo(scanType);
    if (scans.length < 2) return null;
    final latest = scans[0];
    final previous = scans[1];
    final now = await _repository.snapshots(latest.id);
    final before = await _repository.snapshots(previous.id);
    if (now.isEmpty || before.isEmpty) return null;

    final beforeByPackage = {for (final s in before) s.packageName: s};
    final nowByPackage = {for (final s in now) s.packageName: s};

    final installed = now
        .where((s) => !s.systemApp && !beforeByPackage.containsKey(s.packageName))
        .toList();
    final removed = before
        .where((s) => !s.systemApp && !nowByPackage.containsKey(s.packageName))
        .toList();

    final changed = <PermissionChange>[];
    for (final current in now) {
      final old = beforeByPackage[current.packageName];
      if (old == null) continue;
      final oldSet = _split(old.permissions);
      final newSet = _split(current.permissions);
      final added = newSet.difference(oldSet).toList()..sort();
      final gone = oldSet.difference(newSet).toList()..sort();
      if (added.isEmpty && gone.isEmpty) continue;
      changed.add(
        PermissionChange(
          packageName: current.packageName,
          appName: current.appName,
          added: added,
          removed: gone,
        ),
      );
    }
    changed.sort((a, b) => b.added.length.compareTo(a.added.length));

    return ScanDiff(
      previous: previous,
      latest: latest,
      installed: installed,
      removed: removed,
      changed: changed,
    );
  }

  static Set<String> _split(String raw) =>
      raw.split('\n').where((p) => p.trim().isNotEmpty).toSet();
}
