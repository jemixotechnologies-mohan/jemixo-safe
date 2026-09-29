import 'package:flutter/material.dart';

import '../data/repositories/settings_repository.dart';

/// User preferences persisted in the local database. Nothing here is uploaded.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  static const kThemeKey = 'theme_mode';
  static const kOnboardingKey = 'onboarding_complete';
  static const kHapticsKey = 'haptics';
  static const kSaveScansKey = 'save_scan_history';
  static const kLargeFileThresholdKey = 'large_file_threshold_mb';
  static const kShowDebuggableKey = 'show_debuggable_apps';
  static const kSimpleModeKey = 'simple_mode';
  static const kInstallAlertsKey = 'install_alerts';
  static const kLanguageKey = 'language';

  ThemeMode _themeMode = ThemeMode.system;
  bool _onboardingComplete = false;
  bool _haptics = true;
  bool _saveHistory = true;
  bool _showDebuggable = true;
  bool _simpleMode = false;
  bool _installAlerts = false;
  String _language = 'en';
  int _largeFileThresholdMb = 100;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get onboardingComplete => _onboardingComplete;
  bool get haptics => _haptics;
  bool get saveHistory => _saveHistory;
  bool get showDebuggable => _showDebuggable;

  /// Large text and three big buttons instead of the full app.
  bool get simpleMode => _simpleMode;

  /// "New app installed" notifications (WorkManager check every 30 minutes).
  bool get installAlerts => _installAlerts;

  /// 'en' or 'hi'; applies to simple mode and the emergency screens.
  String get language => _language;
  int get largeFileThresholdMb => _largeFileThresholdMb;
  bool get isLoaded => _loaded;
  int get largeFileThresholdBytes => _largeFileThresholdMb * 1024 * 1024;

  Future<void> load() async {
    final storedTheme = await _repository.read(kThemeKey);
    _themeMode = switch (storedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _onboardingComplete = await _repository.readBool(kOnboardingKey);
    _haptics = await _repository.readBool(kHapticsKey, fallback: true);
    _saveHistory = await _repository.readBool(kSaveScansKey, fallback: true);
    _showDebuggable = await _repository.readBool(
      kShowDebuggableKey,
      fallback: true,
    );
    _simpleMode = await _repository.readBool(kSimpleModeKey);
    _installAlerts = await _repository.readBool(kInstallAlertsKey);
    _language = await _repository.read(kLanguageKey) ?? 'en';
    _largeFileThresholdMb = await _repository.readInt(
      kLargeFileThresholdKey,
      fallback: 100,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repository.write(kThemeKey, mode.name);
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();
    await _repository.writeBool(kOnboardingKey, true);
  }

  Future<void> setHaptics(bool value) async {
    _haptics = value;
    notifyListeners();
    await _repository.writeBool(kHapticsKey, value);
  }

  Future<void> setSaveHistory(bool value) async {
    _saveHistory = value;
    notifyListeners();
    await _repository.writeBool(kSaveScansKey, value);
  }

  Future<void> setShowDebuggable(bool value) async {
    _showDebuggable = value;
    notifyListeners();
    await _repository.writeBool(kShowDebuggableKey, value);
  }

  Future<void> setSimpleMode(bool value) async {
    _simpleMode = value;
    notifyListeners();
    await _repository.writeBool(kSimpleModeKey, value);
  }

  Future<void> setLanguage(String code) async {
    _language = code;
    notifyListeners();
    await _repository.write(kLanguageKey, code);
  }

  Future<void> setInstallAlerts(bool value) async {
    _installAlerts = value;
    notifyListeners();
    await _repository.writeBool(kInstallAlertsKey, value);
  }

  Future<void> setLargeFileThreshold(int megabytes) async {
    _largeFileThresholdMb = megabytes;
    notifyListeners();
    await _repository.writeInt(kLargeFileThresholdKey, megabytes);
  }
}
