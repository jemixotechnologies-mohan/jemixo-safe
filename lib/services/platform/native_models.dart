/// Raw shapes returned by the Kotlin bridge.
///
/// These models only translate what Android reports. They intentionally carry
/// nullable fields: the platform withholds a lot of metadata (app size, min SDK,
/// install source) and silently omitting a value is better than inventing one.
library;

int? _int(dynamic v) => v == null ? null : (v as num).toInt();

int _intOr(dynamic v, int fallback) => _int(v) ?? fallback;

double? _double(dynamic v) => v == null ? null : (v as num).toDouble();

bool _bool(dynamic v) => v == true;

String? _string(dynamic v) {
  if (v == null) return null;
  final text = v.toString();
  return text.isEmpty ? null : text;
}

class AppSignature {
  const AppSignature({this.sha256, this.md5});

  final String? sha256;
  final String? md5;

  factory AppSignature.fromMap(Map<String, dynamic> map) => AppSignature(
    sha256: _string(map['sha256']),
    md5: _string(map['md5']),
  );

  String get shortFingerprint {
    final source = sha256 ?? md5;
    if (source == null || source.length < 16) return 'Unavailable';
    return source.substring(0, 16);
  }
}

/// Installer packages that mean "the user installed this from a store".
const kKnownStoreInstallers = <String>{
  'com.android.vending',
  'com.amazon.venezia',
  'com.sec.android.app.samsungapps',
  'com.huawei.appmarket',
  'com.xiaomi.mipicks',
  'com.xiaomi.market',
  'com.oppo.market',
  'com.heytap.market',
  'com.vivo.appstore',
  'com.bbk.appstore',
  'com.oneplus.store',
  'com.google.android.packageinstaller.store',
};

class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.label,
    this.versionName,
    this.versionCode,
    this.minSdk,
    this.targetSdk,
    this.sizeBytes,
    this.isSystemApp = false,
    this.isEnabled = true,
    this.installTime,
    this.lastUpdateTime,
    this.installerPackage,
    this.debuggable = false,
    this.hasCode = false,
    this.hasLauncherIcon = true,
    this.permissions = const [],
    this.signatures = const [],
  });

  final String packageName;
  final String label;
  final String? versionName;
  final int? versionCode;
  final int? minSdk;
  final int? targetSdk;
  final int? sizeBytes;
  final bool isSystemApp;
  final bool isEnabled;
  final int? installTime;
  final int? lastUpdateTime;
  final String? installerPackage;
  final bool debuggable;
  final bool hasCode;

  /// False for apps with no launcher activity: they cannot be opened from the
  /// home screen and only appear in Settings → Apps.
  final bool hasLauncherIcon;
  final List<String> permissions;
  final List<AppSignature> signatures;

  factory AppInfo.fromMap(Map<String, dynamic> map) => AppInfo(
    packageName: _string(map['packageName']) ?? 'unknown',
    label: _string(map['label']) ?? _string(map['packageName']) ?? 'Unknown',
    versionName: _string(map['versionName']),
    versionCode: _int(map['versionCode']),
    minSdk: _int(map['minSdk']),
    targetSdk: _int(map['targetSdk']),
    sizeBytes: _int(map['sizeBytes']),
    isSystemApp: _bool(map['isSystemApp']),
    isEnabled: map['isEnabled'] == null ? true : _bool(map['isEnabled']),
    installTime: _int(map['installTime']),
    lastUpdateTime: _int(map['lastUpdateTime']),
    installerPackage: _string(map['installerPackage']),
    debuggable: _bool(map['debuggable']),
    hasCode: _bool(map['hasCode']),
    hasLauncherIcon: map['hasLauncherIcon'] == null ? true : _bool(map['hasLauncherIcon']),
    permissions: _permissionList(map['requestedPermissions']),
    signatures: _signatureList(map['signatures']),
  );

  String get versionLabel {
    final name = versionName;
    if (name != null && name.isNotEmpty) {
      final code = versionCode;
      return code == null ? name : '$name ($code)';
    }
    final code = versionCode;
    return code == null ? 'Unknown' : 'Build $code';
  }

  /// Human label for where the app came from, when the platform discloses it.
  String? get installSourceLabel {
    final source = installerPackage;
    if (source == null || source.isEmpty) return null;
    return switch (source) {
      'com.android.vending' => 'Google Play',
      'com.amazon.venezia' => 'Amazon Appstore',
      'com.sec.android.app.samsungapps' => 'Galaxy Store',
      'com.huawei.appmarket' => 'AppGallery',
      'com.xiaomi.mipicks' || 'com.xiaomi.market' => 'GetApps',
      'com.oppo.market' || 'com.heytap.market' => 'OPPO App Market',
      'com.vivo.appstore' || 'com.bbk.appstore' => 'vivo App Store',
      'com.google.android.packageinstaller' ||
      'com.android.packageinstaller' => 'Manual install (APK)',
      'com.android.shell' => 'ADB / developer tools',
      _ => source,
    };
  }

  /// True when no recognised store installed the app. The system package
  /// installer counts as sideloaded: it is what runs when a user opens an
  /// APK file directly.
  bool get isSideloaded {
    final source = installerPackage;
    if (source == null || source.isEmpty) return true;
    return !kKnownStoreInstallers.contains(source);
  }
}

List<String> _permissionList(dynamic raw) =>
    (raw as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => _string(e['name']) ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

List<AppSignature> _signatureList(dynamic raw) =>
    (raw as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => AppSignature.fromMap(e.cast<String, dynamic>()))
        .toList(growable: false);

class StorageOverview {
  const StorageOverview({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
  });

  final int totalBytes;
  final int freeBytes;
  final int usedBytes;

  double get usedFraction => totalBytes == 0 ? 0 : usedBytes / totalBytes;

  factory StorageOverview.fromMap(Map<String, dynamic> map) {
    final total = _intOr(map['totalBytes'], 0);
    final free = _intOr(map['freeBytes'], 0);
    return StorageOverview(
      totalBytes: total,
      freeBytes: free,
      usedBytes: _intOr(map['usedBytes'], total - free),
    );
  }
}

class StorageCategory {
  const StorageCategory({required this.category, required this.bytes});

  final String category;
  final int bytes;

  factory StorageCategory.fromMap(Map<String, dynamic> map) => StorageCategory(
    category: _string(map['category']) ?? 'Other',
    bytes: _intOr(map['bytes'], 0),
  );
}

/// What the user has allowed the app to read.
enum StorageAccess {
  /// Nothing granted yet.
  none,

  /// Photos, videos, audio and downloads through MediaStore. This is the only
  /// level the app ever asks for; there is no all-files access.
  media;

  bool get canReadMedia => this == StorageAccess.media;
}

class StorageFile {
  const StorageFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    this.uri,
    this.modified,
    this.mimeType,
    this.width,
    this.height,
  });

  /// Absolute file-system path, or empty when the platform withheld it.
  final String path;

  /// MediaStore content URI, when the entry came from the media index.
  final String? uri;
  final String name;
  final int sizeBytes;
  final int? modified;
  final String? mimeType;
  final int? width;
  final int? height;

  bool get isImage => (mimeType ?? '').startsWith('image/');
  bool get isVideo => (mimeType ?? '').startsWith('video/');
  bool get isApk =>
      name.toLowerCase().endsWith('.apk') ||
      mimeType == 'application/vnd.android.package-archive';

  bool get hasPath => path.startsWith('/');

  /// Stable identity for selection sets and caches.
  String get id => hasPath ? path : (uri ?? name);

  /// What to hand the platform when opening, sharing or deleting. Content
  /// URIs win because Android accepts them regardless of storage mode.
  String get target => uri ?? path;

  /// Best handle for reading bytes: the path when we can walk files, else the URI.
  String get readTarget => hasPath ? path : (uri ?? '');

  factory StorageFile.fromMap(Map<String, dynamic> map) => StorageFile(
    path: _string(map['path']) ?? '',
    uri: _string(map['uri']),
    name: _string(map['name']) ?? 'File',
    sizeBytes: _intOr(map['sizeBytes'], 0),
    modified: _int(map['modified']),
    mimeType: _string(map['mimeType']),
    width: _int(map['width']),
    height: _int(map['height']),
  );
}

class DuplicateGroup {
  const DuplicateGroup({
    required this.files,
    required this.sizeBytes,
    required this.wastedBytes,
  });

  final List<StorageFile> files;
  final int sizeBytes;
  final int wastedBytes;

  factory DuplicateGroup.fromMap(Map<String, dynamic> map) => DuplicateGroup(
    files: (map['files'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => StorageFile.fromMap(e.cast<String, dynamic>()))
        .toList(growable: false),
    sizeBytes: _intOr(map['sizeBytes'], 0),
    wastedBytes: _intOr(map['wastedBytes'], 0),
  );
}

/// Outcome of a delete request.
class DeleteResult {
  const DeleteResult({
    this.deleted = 0,
    this.failed = 0,
    this.errors = const [],
    this.needsConsent = const [],
    this.cancelled = false,
  });

  final int deleted;
  final int failed;
  final List<String> errors;

  /// Content URIs Android will only remove after its own confirmation dialog.
  final List<String> needsConsent;
  final bool cancelled;

  factory DeleteResult.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DeleteResult();
    return DeleteResult(
      deleted: _intOr(map['deleted'], 0),
      failed: _intOr(map['failed'], 0),
      errors: (map['errors'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      needsConsent: (map['needsConsent'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      cancelled: _bool(map['cancelled']),
    );
  }

  DeleteResult merge(DeleteResult other) => DeleteResult(
    deleted: deleted + other.deleted,
    failed: failed + other.failed,
    errors: [...errors, ...other.errors],
    needsConsent: other.needsConsent,
    cancelled: other.cancelled,
  );
}

class BatteryInfo {
  const BatteryInfo({
    this.percent,
    this.isCharging = false,
    this.statusCode,
    this.isPowerSaveMode = false,
    this.temperatureCelsius,
    this.voltageMillivolts,
    this.technology,
    this.healthCode,
    this.chargeCounterMah,
  });

  final int? percent;
  final bool isCharging;
  final int? statusCode;
  final bool isPowerSaveMode;
  final double? temperatureCelsius;
  final int? voltageMillivolts;
  final String? technology;
  final int? healthCode;
  final int? chargeCounterMah;

  /// Design capacity is a hidden platform constant, so we deliberately do not
  /// compute a battery-health percentage. Only raw readings are exposed.
  bool get hasCapacityInfo => chargeCounterMah != null && chargeCounterMah! > 0;

  String get statusLabel {
    if (statusCode == null) return 'Unknown';
    return switch (statusCode) {
      2 => 'Charging',
      3 => 'Discharging',
      4 => 'Not charging',
      5 => 'Full',
      _ => 'Unknown',
    };
  }

  String get healthLabel {
    if (healthCode == null) return 'Unknown';
    return switch (healthCode) {
      2 => 'Good',
      3 => 'Overheating',
      4 => 'Dead',
      5 => 'Over voltage',
      6 => 'Unspecified failure',
      7 => 'Cold',
      _ => 'Unknown',
    };
  }

  factory BatteryInfo.fromMap(Map<String, dynamic> map) => BatteryInfo(
    percent: _int(map['percent']),
    isCharging: _bool(map['isCharging']),
    statusCode: _int(map['statusCode']),
    isPowerSaveMode: _bool(map['isPowerSaveMode']),
    temperatureCelsius: _double(map['temperatureCelsius']),
    voltageMillivolts: _int(map['voltageMillivolts']),
    technology: _string(map['technology']),
    healthCode: _int(map['healthCode']),
    chargeCounterMah: _int(map['chargeCounterMah']),
  );
}

class NetworkInfo {
  const NetworkInfo({
    this.available = false,
    this.connected = false,
    this.validated = false,
    this.type,
    this.wifiName,
    this.metered = false,
    this.downstreamKbps,
    this.upstreamKbps,
    this.carrierName,
  });

  final bool available;
  final bool connected;
  final bool validated;
  final String? type;
  final String? wifiName;
  final bool metered;
  final int? downstreamKbps;
  final int? upstreamKbps;
  final String? carrierName;

  String get typeLabel => switch (type) {
    'wifi' => 'Wi-Fi',
    'cellular' => 'Mobile data',
    'ethernet' => 'Ethernet',
    'vpn' => 'VPN',
    'other' => 'Other',
    _ => 'Not connected',
  };

  factory NetworkInfo.fromMap(Map<String, dynamic> map) => NetworkInfo(
    available: _bool(map['available']),
    connected: _bool(map['connected']),
    validated: _bool(map['validated']),
    type: _string(map['type']),
    wifiName: _string(map['wifiName']),
    metered: _bool(map['metered']),
    downstreamKbps: _int(map['downstreamKbps']),
    upstreamKbps: _int(map['upstreamKbps']),
    carrierName: _string(map['carrierName']),
  );
}

class DeviceInfo {
  const DeviceInfo({
    this.manufacturer,
    this.brand,
    this.model,
    this.device,
    this.androidRelease,
    this.sdkInt,
    this.securityPatch,
    this.buildId,
    this.abi,
    this.locale,
    this.timezone,
    this.isEmulator = false,
    this.hasFlash = false,
  });

  final String? manufacturer;
  final String? brand;
  final String? model;
  final String? device;
  final String? androidRelease;
  final int? sdkInt;
  final String? securityPatch;
  final String? buildId;
  final String? abi;
  final String? locale;
  final String? timezone;
  final bool isEmulator;
  final bool hasFlash;

  String get displayName {
    final parts = [
      manufacturer,
      model,
    ].where((e) => e != null && e.isNotEmpty).toSet().toList();
    return parts.isEmpty ? 'Android device' : parts.join(' ');
  }

  factory DeviceInfo.fromMap(Map<String, dynamic> map) => DeviceInfo(
    manufacturer: _string(map['manufacturer']),
    brand: _string(map['brand']),
    model: _string(map['model']),
    device: _string(map['device']),
    androidRelease: _string(map['androidRelease']),
    sdkInt: _int(map['sdkInt']),
    securityPatch: _string(map['securityPatch']),
    buildId: _string(map['buildId']),
    abi: _string(map['abi']),
    locale: _string(map['locale']),
    timezone: _string(map['timezone']),
    isEmulator: _bool(map['isEmulator']),
    hasFlash: _bool(map['hasFlash']),
  );
}

class MemoryInfo {
  const MemoryInfo({
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.lowMemory,
    required this.totalDataBytes,
    required this.freeDataBytes,
  });

  final int totalRamBytes;
  final int availableRamBytes;
  final bool lowMemory;
  final int totalDataBytes;
  final int freeDataBytes;

  double get usedFraction => totalRamBytes == 0
      ? 0
      : (totalRamBytes - availableRamBytes) / totalRamBytes;

  factory MemoryInfo.fromMap(Map<String, dynamic> map) => MemoryInfo(
    totalRamBytes: _intOr(map['totalRamBytes'], 0),
    availableRamBytes: _intOr(map['availableRamBytes'], 0),
    lowMemory: _bool(map['lowMemory']),
    totalDataBytes: _intOr(map['totalDataBytes'], 0),
    freeDataBytes: _intOr(map['freeDataBytes'], 0),
  );
}

class SecuritySettings {
  const SecuritySettings({
    this.deviceSecure = false,
    this.accessibilityServicesEnabled = false,
    this.overlayPermissionGranted = false,
    this.activeDeviceAdmins = 0,
    this.usageAccessGranted = false,
    this.unknownSourcesAllowed = false,
    this.developerOptionsEnabled = false,
    this.adbEnabled = false,
  });

  final bool deviceSecure;
  final bool accessibilityServicesEnabled;
  final bool overlayPermissionGranted;
  final int activeDeviceAdmins;
  final bool usageAccessGranted;
  final bool unknownSourcesAllowed;
  final bool developerOptionsEnabled;
  final bool adbEnabled;

  factory SecuritySettings.fromMap(Map<String, dynamic> map) =>
      SecuritySettings(
        deviceSecure: _bool(map['deviceSecure']),
        accessibilityServicesEnabled: _bool(
          map['accessibilityServicesEnabled'],
        ),
        overlayPermissionGranted: _bool(map['overlayPermissionGranted']),
        activeDeviceAdmins: _intOr(map['activeDeviceAdmins'], 0),
        usageAccessGranted: _bool(map['usageAccessGranted']),
        unknownSourcesAllowed: _bool(map['unknownSourcesAllowed']),
        developerOptionsEnabled: _bool(map['developerOptionsEnabled']),
        adbEnabled: _bool(map['adbEnabled']),
      );
}

/// One app holding a special capability (accessibility, notification access,
/// device admin).
class SpecialAccessEntry {
  const SpecialAccessEntry({
    required this.packageName,
    required this.component,
    required this.label,
    required this.isSystemApp,
  });

  final String packageName;
  final String component;
  final String label;
  final bool isSystemApp;

  factory SpecialAccessEntry.fromMap(Map<String, dynamic> map) =>
      SpecialAccessEntry(
        packageName: _string(map['packageName']) ?? '',
        component: _string(map['component']) ?? '',
        label: _string(map['label']) ?? _string(map['packageName']) ?? '',
        isSystemApp: _bool(map['isSystemApp']),
      );
}

class SpecialAccess {
  const SpecialAccess({
    this.accessibility = const [],
    this.notificationListeners = const [],
    this.deviceAdmins = const [],
  });

  final List<SpecialAccessEntry> accessibility;
  final List<SpecialAccessEntry> notificationListeners;
  final List<SpecialAccessEntry> deviceAdmins;

  Set<String> get accessibilityPackages =>
      accessibility.map((e) => e.packageName).toSet();
  Set<String> get listenerPackages =>
      notificationListeners.map((e) => e.packageName).toSet();
  Set<String> get adminPackages =>
      deviceAdmins.map((e) => e.packageName).toSet();

  int get userAppCount => {
    ...accessibility.where((e) => !e.isSystemApp).map((e) => e.packageName),
    ...notificationListeners.where((e) => !e.isSystemApp).map((e) => e.packageName),
    ...deviceAdmins.where((e) => !e.isSystemApp).map((e) => e.packageName),
  }.length;

  static List<SpecialAccessEntry> _list(dynamic raw) =>
      (raw as List<dynamic>? ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => SpecialAccessEntry.fromMap(e.cast<String, dynamic>()))
          .toList(growable: false);

  factory SpecialAccess.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SpecialAccess();
    return SpecialAccess(
      accessibility: _list(map['accessibility']),
      notificationListeners: _list(map['notificationListeners']),
      deviceAdmins: _list(map['deviceAdmins']),
    );
  }
}

class SensorInfo {
  const SensorInfo({
    required this.name,
    required this.type,
    this.vendor,
    this.powerMah,
  });

  final String name;
  final int type;
  final String? vendor;
  final double? powerMah;

  factory SensorInfo.fromMap(Map<String, dynamic> map) => SensorInfo(
    name: _string(map['name']) ?? 'Sensor',
    type: _intOr(map['type'], -1),
    vendor: _string(map['vendor']),
    powerMah: _double(map['powerMah']),
  );
}

/// Android `Sensor.TYPE_*` constants used by the hardware tests.
class SensorTypes {
  const SensorTypes._();

  static const accelerometer = 1;
  static const magneticField = 2;
  static const gyroscope = 4;
  static const light = 5;
  static const pressure = 6;
  static const proximity = 8;
}

/// Result of a native sensor sampling window.
class SensorSample {
  const SensorSample({
    required this.available,
    required this.readings,
    this.last = const [],
    this.min,
    this.max,
    this.maxRange,
  });

  final bool available;
  final int readings;
  final List<double> last;
  final double? min;
  final double? max;
  final double? maxRange;

  factory SensorSample.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SensorSample(available: false, readings: 0);
    return SensorSample(
      available: _bool(map['available']),
      readings: _intOr(map['readings'], 0),
      last: (map['last'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(growable: false),
      min: _double(map['min']),
      max: _double(map['max']),
      maxRange: _double(map['maxRange']),
    );
  }
}

class BatteryUsageEntry {
  const BatteryUsageEntry({
    required this.packageName,
    required this.foregroundMillis,
    this.lastTimeUsed,
  });

  final String packageName;
  final int foregroundMillis;
  final int? lastTimeUsed;

  factory BatteryUsageEntry.fromMap(Map<String, dynamic> map) =>
      BatteryUsageEntry(
        packageName: _string(map['packageName']) ?? 'unknown',
        foregroundMillis: _intOr(map['foregroundMillis'], 0),
        lastTimeUsed: _int(map['lastTimeUsed']),
      );
}

class ApkAnalysis {
  const ApkAnalysis({
    required this.valid,
    required this.fileName,
    required this.sizeBytes,
    this.path,
    this.modified,
    this.packageName,
    this.label,
    this.versionName,
    this.versionCode,
    this.installedVersionCode,
    this.minSdk,
    this.targetSdk,
    this.debuggable = false,
    this.usesCleartextTraffic,
    this.hasNativeCode,
    this.entryCount,
    this.permissions = const [],
    this.signatures = const [],
    this.message,
  });

  final bool valid;
  final String fileName;
  final int sizeBytes;
  final String? path;
  final int? modified;
  final String? packageName;
  final String? label;
  final String? versionName;
  final int? versionCode;

  /// Version already installed on this device, if the package exists.
  final int? installedVersionCode;
  final int? minSdk;
  final int? targetSdk;
  final bool debuggable;
  final bool? usesCleartextTraffic;
  final bool? hasNativeCode;
  final int? entryCount;
  final List<String> permissions;
  final List<AppSignature> signatures;
  final String? message;

  String get displayName =>
      (label != null && label!.isNotEmpty) ? label! : fileName;

  bool get isInstalled => installedVersionCode != null;

  factory ApkAnalysis.fromMap(Map<String, dynamic> map) => ApkAnalysis(
    valid: _bool(map['valid']),
    fileName: _string(map['fileName']) ?? 'unknown.apk',
    sizeBytes: _intOr(map['sizeBytes'], 0),
    path: _string(map['path']),
    modified: _int(map['modified']),
    packageName: _string(map['packageName']),
    label: _string(map['label']),
    versionName: _string(map['versionName']),
    versionCode: _int(map['versionCode']),
    installedVersionCode: _int(map['installedVersionCode']),
    minSdk: _int(map['minSdk']),
    targetSdk: _int(map['targetSdk']),
    debuggable: _bool(map['debuggable']),
    usesCleartextTraffic: map['usesCleartextTraffic'] as bool?,
    hasNativeCode: map['hasNativeCode'] as bool?,
    entryCount: _int(map['entryCount']),
    permissions: _permissionList(map['requestedPermissions']),
    signatures: _signatureList(map['signatures']),
    message: _string(map['message']),
  );
}
