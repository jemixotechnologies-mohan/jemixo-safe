import 'package:flutter/foundation.dart';

import '../data/database/app_database.dart';
import '../data/repositories/scan_repository.dart';

/// Backs the History screen. Records are local only and the user can delete
/// any scan or wipe the list at any time.
class HistoryController extends ChangeNotifier {
  HistoryController(this._repository);

  final ScanRepository _repository;

  List<ScanRecord> _records = const [];
  bool _loading = false;
  String? _lastError;

  List<ScanRecord> get records => _records;
  bool get isLoading => _loading;
  bool get isEmpty => _records.isEmpty;
  String? get lastError => _lastError;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      _records = await _repository.history();
    } catch (error) {
      _lastError = 'Could not read history: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<AppSnapshot>> snapshots(int scanId) =>
      _repository.snapshots(scanId);

  Future<List<FindingRecord>> findings(int scanId) =>
      _repository.findings(scanId);

  Future<void> delete(int scanId) async {
    await _repository.deleteScan(scanId);
    _records = _records.where((r) => r.id != scanId).toList(growable: false);
    notifyListeners();
  }

  Future<void> clear() async {
    await _repository.clearHistory();
    _records = const [];
    notifyListeners();
  }
}
