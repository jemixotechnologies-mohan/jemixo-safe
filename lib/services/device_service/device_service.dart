import 'package:flutter/foundation.dart';

import '../../core/theme/risk_palette.dart';
import '../platform/native_bridge.dart';
import '../platform/native_models.dart';
import '../app_scanner/app_scanner_service.dart';

/// Battery, network and hardware health data for the Device Health screens.
class DeviceService extends ChangeNotifier {
  DeviceService({NativeBridge? bridge})
    : _bridge = bridge ?? NativeBridge.instance;

  final NativeBridge _bridge;

  BatteryInfo? _battery;
  NetworkInfo? _network;
  DeviceInfo? _device;
  MemoryInfo? _memory;
  SecuritySettings? _security;
  List<SensorInfo> _sensors = const [];
  List<BatteryUsageEntry> _batteryUsage = const [];
  bool _loading = false;
  String? _lastError;

  BatteryInfo? get battery => _battery;
  NetworkInfo? get network => _network;
  DeviceInfo? get device => _device;
  MemoryInfo? get memory => _memory;
  SecuritySettings? get security => _security;
  List<SensorInfo> get sensors => _sensors;
  List<BatteryUsageEntry> get batteryUsage => _batteryUsage;
  bool get isLoading => _loading;
  String? get lastError => _lastError;

  bool hasSensorType(int type) => _sensors.any((s) => s.type == type);

  bool get hasFlash => _device?.hasFlash ?? false;
  bool get hasProximity => hasSensorType(SensorTypes.proximity);
  bool get hasAccelerometer => hasSensorType(SensorTypes.accelerometer);
  bool get hasGyroscope => hasSensorType(SensorTypes.gyroscope);
  bool get hasCompass => hasSensorType(SensorTypes.magneticField);
  bool get hasBarometer => hasSensorType(SensorTypes.pressure);
  bool get hasLightSensor => hasSensorType(SensorTypes.light);

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _safe(_bridge.getBatteryInfo),
        _safe(_bridge.getNetworkInfo),
        _safe(_bridge.getDeviceInfo),
        _safe(_bridge.getMemoryInfo),
        _safe(_bridge.getSecuritySettings),
        _safe(_bridge.getSensors),
      ]);

      final battery = results[0] as Map<String, dynamic>?;
      final network = results[1] as Map<String, dynamic>?;
      final device = results[2] as Map<String, dynamic>?;
      final memory = results[3] as Map<String, dynamic>?;
      final security = results[4] as Map<String, dynamic>?;
      final sensors = results[5] as List<Map<String, dynamic>>?;

      if (battery != null) _battery = BatteryInfo.fromMap(battery);
      if (network != null) _network = NetworkInfo.fromMap(network);
      if (device != null) _device = DeviceInfo.fromMap(device);
      if (memory != null) _memory = MemoryInfo.fromMap(memory);
      if (security != null) _security = SecuritySettings.fromMap(security);
      if (sensors != null) {
        _sensors = sensors.map(SensorInfo.fromMap).toList(growable: false);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Runs one bridge call, remembering the first failure instead of letting it
  /// blank every other reading on the screen.
  Future<T?> _safe<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on NativeBridgeException catch (e) {
      _lastError ??= e.message;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadBatteryUsage() async {
    try {
      final raw = await _bridge.getBatteryUsage();
      _batteryUsage = raw.map(BatteryUsageEntry.fromMap).toList(growable: false);
    } on NativeBridgeException {
      _batteryUsage = const [];
    }
    notifyListeners();
  }

  /// Application names for battery-usage rows, resolved from the app list when
  /// available so the screen shows labels instead of package strings.
  Future<Map<String, String>> batteryUsageNames(
    AppScannerService scanner,
  ) async {
    final result = <String, String>{};
    for (final entry in _batteryUsage) {
      if (result.containsKey(entry.packageName)) continue;
      final match = scanner.allApps.where(
        (a) => a.packageName == entry.packageName,
      );
      if (match.isNotEmpty) {
        result[entry.packageName] = match.first.label;
      } else {
        final details = await scanner.lookup(entry.packageName);
        result[entry.packageName] = details?.label ?? entry.packageName;
      }
    }
    return result;
  }

  /// Samples a raw Android sensor for a few seconds.
  Future<SensorSample> sampleSensor(int type, {int durationMs = 4000}) async {
    try {
      return SensorSample.fromMap(
        await _bridge.sampleSensor(type, durationMs: durationMs),
      );
    } on NativeBridgeException {
      return const SensorSample(available: false, readings: 0);
    }
  }

  /// Turns the torch on or off; null when the device has no controllable flash.
  Future<bool?> setFlash(bool enabled) async {
    try {
      return await _bridge.setFlash(enabled: enabled);
    } on NativeBridgeException {
      return null;
    }
  }

  // region settings hand-offs

  Future<bool> openUsageAccessSettings() => _bridge.openUsageAccessSettings();

  Future<bool> openBatterySettings() =>
      _bridge.openBatteryOptimizationSettings();

  Future<bool> openBatteryUsageSettings() =>
      _bridge.openSystemSettings('android.intent.action.POWER_USAGE_SUMMARY');

  Future<bool> openWifiSettings() =>
      _bridge.openSystemSettings('android.settings.WIFI_SETTINGS');

  Future<bool> openDataSettings() =>
      _bridge.openSystemSettings('android.settings.DATA_ROAMING_SETTINGS');

  Future<bool> openAirplaneModeSettings() =>
      _bridge.openSystemSettings('android.settings.AIRPLANE_MODE_SETTINGS');

  Future<bool> openSecuritySettings() =>
      _bridge.openSystemSettings('android.settings.SECURITY_SETTINGS');

  Future<bool> openAccessibilitySettings() =>
      _bridge.openSystemSettings('android.settings.ACCESSIBILITY_SETTINGS');

  Future<bool> openNotificationAccessSettings() => _bridge.openSystemSettings(
    'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
  );

  Future<bool> openUnknownSourcesSettings() =>
      _bridge.openSystemSettings('android.settings.MANAGE_UNKNOWN_APP_SOURCES');

  Future<bool> openDeveloperSettings() => _bridge.openSystemSettings(
    'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
  );

  Future<bool> openManageAppsSettings() =>
      _bridge.openSystemSettings('android.settings.MANAGE_APPLICATIONS_SETTINGS');

  // endregion
}

/// Coarse connection quality derived from what ConnectivityManager reports.
/// No active probing is performed, so this never leaves the device.
class ConnectionQuality {
  const ConnectionQuality({required this.label, required this.level});

  final String label;
  final RiskLevel level;

  static ConnectionQuality from(NetworkInfo? info) {
    if (info == null) {
      return const ConnectionQuality(label: 'Unknown', level: RiskLevel.medium);
    }
    if (!info.connected) {
      return const ConnectionQuality(label: 'Offline', level: RiskLevel.high);
    }
    if (!info.validated) {
      return const ConnectionQuality(
        label: 'No internet',
        level: RiskLevel.medium,
      );
    }
    return switch (info.type) {
      'vpn' => const ConnectionQuality(label: 'VPN', level: RiskLevel.safe),
      'cellular' => const ConnectionQuality(
        label: 'Mobile data',
        level: RiskLevel.safe,
      ),
      _ => const ConnectionQuality(label: 'Connected', level: RiskLevel.safe),
    };
  }
}
