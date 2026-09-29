import '../database/app_database.dart';

/// Simple key/value preferences stored in the local database. Nothing here is
/// uploaded.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> read(String key) async {
    final row = await (_db.select(
      _db.settingRecords,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<bool> readBool(String key, {bool fallback = false}) async {
    final value = await read(key);
    if (value == null) return fallback;
    return value == '1' || value == 'true';
  }

  Future<int> readInt(String key, {int fallback = 0}) async {
    final value = await read(key);
    return int.tryParse(value ?? '') ?? fallback;
  }

  Future<void> write(String key, String value) async {
    await _db
        .into(_db.settingRecords)
        .insertOnConflictUpdate(
          SettingRecordsCompanion.insert(key: key, value: value),
        );
  }

  Future<void> writeBool(String key, bool value) =>
      write(key, value ? '1' : '0');

  Future<void> writeInt(String key, int value) => write(key, '$value');

  /// Removes history and every stored preference.
  Future<void> wipe() => _db.clearEverything();
}
