import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';

/// Raised when the platform side reports a failure. Carries the native error
/// code so the UI can explain what went wrong instead of showing an empty list.
class NativeBridgeException implements Exception {
  const NativeBridgeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// Something handed to Jemixo Safe from outside: the share sheet, the
/// text-selection toolbar, the Quick Settings tile or a notification.
class SharedContent {
  const SharedContent.text(this.text)
    : apkPath = null,
      apkName = null,
      packageName = null,
      kind = SharedKind.text;

  const SharedContent.apk(this.apkPath, this.apkName)
    : text = null,
      packageName = null,
      kind = SharedKind.apk;

  const SharedContent.clipboard()
    : text = null,
      apkPath = null,
      apkName = null,
      packageName = null,
      kind = SharedKind.clipboard;

  const SharedContent.app(this.packageName)
    : text = null,
      apkPath = null,
      apkName = null,
      kind = SharedKind.app;

  /// A screenshot or photo to run through OCR. Reuses [apkPath] as the path.
  const SharedContent.image(this.apkPath)
    : text = null,
      apkName = null,
      packageName = null,
      kind = SharedKind.image;

  String? get imagePath => kind == SharedKind.image ? apkPath : null;

  final SharedKind kind;
  final String? text;
  final String? apkPath;
  final String? apkName;
  final String? packageName;

  bool get isText => kind == SharedKind.text;

  static SharedContent? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    switch (map['kind']) {
      case 'text':
        final text = map['text'] as String?;
        return text == null || text.trim().isEmpty
            ? null
            : SharedContent.text(text);
      case 'apk':
        final path = map['path'] as String?;
        return path == null
            ? null
            : SharedContent.apk(path, map['name'] as String?);
      case 'clipboard':
        return const SharedContent.clipboard();
      case 'image':
        final path = map['path'] as String?;
        return path == null ? null : SharedContent.image(path);
      case 'app':
        final packageName = map['packageName'] as String?;
        return packageName == null ? null : SharedContent.app(packageName);
    }
    return null;
  }
}

enum SharedKind { text, apk, clipboard, app, image }

/// Thin, typed wrapper over the Kotlin `MethodChannel` bridge.
///
/// Every method is a thin, defensive translation of one native call. Business
/// logic (risk scoring, categorisation, scoring) lives in Dart services so it
/// can evolve without a native release.
class NativeBridge {
  NativeBridge._() {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  static final NativeBridge instance = NativeBridge._();

  static const MethodChannel _channel = MethodChannel(AppConstants.channel);

  final StreamController<SharedContent> _shared =
      StreamController<SharedContent>.broadcast();

  /// Content shared into the app while it was already running.
  Stream<SharedContent> get sharedContent => _shared.stream;

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'onShared') {
      final map = (call.arguments as Map?)?.cast<String, dynamic>();
      final content = SharedContent.fromMap(map);
      if (content != null) _shared.add(content);
    }
    return null;
  }

  /// Invokes [method]; returns null when the platform has no implementation,
  /// throws [NativeBridgeException] when it reports an error.
  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw NativeBridgeException(e.code, e.message ?? 'Unknown native error');
    } on MissingPluginException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _invokeMap(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    final result = await _invoke<Map<dynamic, dynamic>>(method, args);
    return result?.cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> _invokeList(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    final result = await _invoke<List<dynamic>>(method, args);
    if (result == null) return const [];
    return result
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  // region Apps

  Future<List<Map<String, dynamic>>> getInstalledApps({
    bool includeSystem = true,
  }) => _invokeList('getInstalledApps', {'includeSystem': includeSystem});

  Future<Map<String, dynamic>?> getAppDetails(String packageName) =>
      _invokeMap('getAppDetails', {'packageName': packageName});

  /// Whether every package is visible or only launchable ones.
  Future<Map<String, dynamic>?> getPackageVisibility() =>
      _invokeMap('getPackageVisibility');

  Future<bool> openAppSettings(String packageName) async =>
      await _invoke<bool>('openAppSettings', {'packageName': packageName}) ??
      false;

  Future<bool> openAppUninstall(String packageName) async =>
      await _invoke<bool>('openAppUninstall', {'packageName': packageName}) ??
      false;

  Future<bool> openSystemSettings(
    String action, {
    bool withPackage = false,
  }) async =>
      await _invoke<bool>('openSystemSettings', {
        'action': action,
        'withPackage': withPackage,
      }) ??
      false;

  // endregion

  // region Storage

  Future<Map<String, dynamic>?> getStorageOverview() =>
      _invokeMap('getStorageOverview');

  Future<List<Map<String, dynamic>>> getStorageCategories() =>
      _invokeList('getStorageCategories');

  Future<Map<String, dynamic>?> getStorageAccess() =>
      _invokeMap('getStorageAccess');

  Future<List<Map<String, dynamic>>> findLargeFiles({
    required int minBytes,
    int limit = 200,
  }) => _invokeList('findLargeFiles', {'minBytes': minBytes, 'limit': limit});

  Future<List<Map<String, dynamic>>> findDuplicates({
    int minBytes = 64 * 1024,
    int limitGroups = 80,
  }) => _invokeList('findDuplicates', {
    'minBytes': minBytes,
    'limitGroups': limitGroups,
  });

  Future<List<Map<String, dynamic>>> findScreenshots() =>
      _invokeList('findScreenshots');

  Future<List<Map<String, dynamic>>> findImages({int limit = 300}) =>
      _invokeList('findImages', {'limit': limit});

  Future<List<Map<String, dynamic>>> getDownloads() =>
      _invokeList('getDownloads');

  /// Small JPEG preview for an image path or content URI, or null.
  Future<Uint8List?> getThumbnail(String target, {int size = 128}) =>
      _invoke<Uint8List>('getThumbnail', {'target': target, 'size': size});

  Future<Map<String, dynamic>?> deleteFiles(List<String> targets) =>
      _invokeMap('deleteFiles', {'paths': targets});

  /// Asks Android to show its own delete confirmation for media the app is not
  /// allowed to remove silently. Returns the number of files removed.
  Future<Map<String, dynamic>?> requestMediaDelete(List<String> uris) =>
      _invokeMap('requestMediaDelete', {'uris': uris});

  // endregion

  // region Device

  Future<Map<String, dynamic>?> getDeviceInfo() => _invokeMap('getDeviceInfo');

  Future<Map<String, dynamic>?> getBatteryInfo() =>
      _invokeMap('getBatteryInfo');

  Future<List<Map<String, dynamic>>> getBatteryUsage({int hours = 24}) =>
      _invokeList('getBatteryUsage', {'hours': hours});

  Future<Map<String, dynamic>?> getNetworkInfo() =>
      _invokeMap('getNetworkInfo');

  Future<List<Map<String, dynamic>>> getSensors() => _invokeList('getSensors');

  Future<Map<String, dynamic>?> getMemoryInfo() => _invokeMap('getMemoryInfo');

  Future<Map<String, dynamic>?> getSecuritySettings() =>
      _invokeMap('getSecuritySettings');

  /// Apps with accessibility, notification access or device admin.
  Future<Map<String, dynamic>?> getSpecialAccess() =>
      _invokeMap('getSpecialAccess');

  /// Copies a content URI into the app cache and returns the file path.
  Future<String?> copyToCache(String uri) =>
      _invoke<String>('copyToCache', {'uri': uri});

  /// Listens to a raw Android sensor type for [durationMs].
  Future<Map<String, dynamic>?> sampleSensor(
    int type, {
    int durationMs = 4000,
  }) => _invokeMap('sampleSensor', {'type': type, 'durationMs': durationMs});

  Future<bool> openUsageAccessSettings() async =>
      await _invoke<bool>('openUsageAccessSettings') ?? false;

  /// Turns the camera torch on or off. Returns the resulting state, or null
  /// when the device has no controllable flash.
  Future<bool?> setFlash({required bool enabled}) =>
      _invoke<bool>('setFlash', {'enabled': enabled});

  Future<bool> openBatteryOptimizationSettings() async =>
      await _invoke<bool>('openBatteryOptimizationSettings') ?? false;

  // endregion

  // region APK

  Future<Map<String, dynamic>?> analyzeApk(String path) =>
      _invokeMap('analyzeApk', {'path': path});

  // endregion

  // region File actions

  Future<bool> shareFile(String target) async =>
      await _invoke<bool>('shareFile', {'path': target}) ?? false;

  Future<bool> openFile(String target) async =>
      await _invoke<bool>('openFile', {'path': target}) ?? false;

  Future<bool> openFileLocation(String target) async =>
      await _invoke<bool>('openFileLocation', {'path': target}) ?? false;

  Future<bool> fileExists(String target) async =>
      await _invoke<bool>('fileExists', {'path': target}) ?? false;

  // endregion

  // region Hand-offs, alerts, widget

  /// Content handed over before Dart was listening (cold start).
  Future<SharedContent?> pendingShare() async {
    try {
      return SharedContent.fromMap(await _invokeMap('getPendingShare'));
    } on NativeBridgeException {
      return null;
    }
  }

  Future<bool> setInstallWatch(bool enabled) async =>
      await _invoke<bool>('setInstallWatch', {'enabled': enabled}) ?? false;

  Future<bool> isInstallWatchEnabled() async =>
      await _invoke<bool>('isInstallWatchEnabled') ?? false;

  Future<void> updateWidget({
    required int? score,
    required String status,
    required String subtitle,
  }) async {
    try {
      await _invoke<bool>('updateWidget', {
        'score': score,
        'status': status,
        'subtitle': subtitle,
      });
    } on NativeBridgeException {
      // The widget is decorative; never fail a scan over it.
    }
  }

  // endregion
}
