import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../core/utils/formatters.dart';
import '../../core/theme/risk_palette.dart';
import '../platform/native_bridge.dart';
import '../platform/native_models.dart';
import 'whatsapp_media.dart';

/// Storage inventory, large files, duplicates, screenshots and downloads.
///
/// Everything comes from Android's media index, so the only permission ever
/// requested is the media one. Destructive operations always go through the
/// native bridge with an explicit confirmation step in the UI; nothing here
/// deletes on its own.
class StorageService extends ChangeNotifier {
  StorageService({NativeBridge? bridge})
    : _bridge = bridge ?? NativeBridge.instance;

  final NativeBridge _bridge;

  StorageOverview? _overview;
  List<StorageCategory> _categories = const [];
  List<StorageFile> _largeFiles = const [];
  List<DuplicateGroup> _duplicates = const [];
  List<StorageFile> _screenshots = const [];
  List<StorageFile> _downloads = const [];
  List<StorageFile> _images = const [];
  List<WhatsAppMedia> _whatsapp = const [];
  StorageAccess _access = StorageAccess.none;
  int _sdkInt = 0;
  String? _lastError;

  bool _loadingOverview = false;
  bool _loadingLargeFiles = false;
  bool _loadingDuplicates = false;
  bool _loadingScreenshots = false;
  bool _loadingDownloads = false;
  bool _loadingImages = false;
  bool _loadingWhatsApp = false;
  bool _whatsappLoaded = false;

  bool _largeFilesLoaded = false;
  int _largeFilesMinBytes = 0;
  bool _duplicatesLoaded = false;
  bool _screenshotsLoaded = false;
  bool _downloadsLoaded = false;

  final Map<String, Future<Uint8List?>> _thumbnails = {};
  static const _thumbnailCacheLimit = 600;

  StorageOverview? get overview => _overview;
  List<StorageCategory> get categories => _categories;
  List<StorageFile> get largeFiles => _largeFiles;
  List<DuplicateGroup> get duplicates => _duplicates;
  List<StorageFile> get screenshots => _screenshots;
  List<StorageFile> get downloads => _downloads;
  List<StorageFile> get images => _images;
  List<WhatsAppMedia> get whatsapp => _whatsapp;
  String? get lastError => _lastError;

  StorageAccess get access => _access;
  bool get canReadMedia => _access.canReadMedia;
  int get sdkInt => _sdkInt;

  bool get isLoadingOverview => _loadingOverview;
  bool get isLoadingLargeFiles => _loadingLargeFiles;
  bool get isLoadingDuplicates => _loadingDuplicates;
  bool get isLoadingScreenshots => _loadingScreenshots;
  bool get isLoadingDownloads => _loadingDownloads;
  bool get isLoadingImages => _loadingImages;
  bool get isLoadingWhatsApp => _loadingWhatsApp;
  bool get whatsappLoaded => _whatsappLoaded;

  int get whatsappTotalBytes =>
      _whatsapp.fold(0, (sum, m) => sum + m.file.sizeBytes);

  bool get largeFilesLoaded => _largeFilesLoaded;
  bool get duplicatesLoaded => _duplicatesLoaded;
  bool get screenshotsLoaded => _screenshotsLoaded;
  bool get downloadsLoaded => _downloadsLoaded;

  int get duplicateWastedBytes =>
      _duplicates.fold(0, (sum, group) => sum + group.wastedBytes);

  int get largeFileTotalBytes =>
      _largeFiles.fold(0, (sum, file) => sum + file.sizeBytes);

  int get screenshotTotalBytes =>
      _screenshots.fold(0, (sum, file) => sum + file.sizeBytes);

  /// Human-readable reclaimable size for the Clean tab subtitle.
  String get duplicateWastedBytesLabel => formatBytes(duplicateWastedBytes);

  // region access

  Future<void> checkStorageAccess() async {
    try {
      final map = await _bridge.getStorageAccess();
      final media = map?['media'] == true;
      _sdkInt = (map?['sdkInt'] as num?)?.toInt() ?? _sdkInt;
      final next = media ? StorageAccess.media : StorageAccess.none;
      if (next != _access) {
        _access = next;
        _largeFilesLoaded = false;
        _duplicatesLoaded = false;
        _screenshotsLoaded = false;
        _downloadsLoaded = false;
        _whatsappLoaded = false;
      }
    } catch (_) {
      // Keep the previous state; the UI will offer the permission again.
    }
    notifyListeners();
  }

  /// Runtime prompt for photos / videos (Android 13+) or the legacy storage
  /// permission. Returns true when media can be read afterwards.
  Future<bool> requestMediaAccess() async {
    try {
      if (_sdkInt >= 33) {
        await [ph.Permission.photos, ph.Permission.videos].request();
      } else {
        await ph.Permission.storage.request();
      }
    } catch (_) {
      // permission_handler unavailable; fall through to the native check.
    }
    await checkStorageAccess();
    return canReadMedia;
  }

  /// Whether the user has permanently denied the media prompt, in which case
  /// only the system settings screen can change it.
  Future<bool> mediaPermanentlyDenied() async {
    try {
      final permission = _sdkInt >= 33
          ? ph.Permission.photos
          : ph.Permission.storage;
      return await permission.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Opens this app's own settings page, for permanently denied permissions.
  Future<void> openOwnAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (_) {
      // Best effort.
    }
  }

  // endregion

  // region loading

  Future<void> refreshOverview() async {
    _loadingOverview = true;
    _lastError = null;
    notifyListeners();
    try {
      final map = await _bridge.getStorageOverview();
      _overview = map == null ? null : StorageOverview.fromMap(map);
      final categories = await _bridge.getStorageCategories();
      _categories =
          categories.map(StorageCategory.fromMap).toList(growable: false)
            ..sort((a, b) => b.bytes.compareTo(a.bytes));
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
    } finally {
      _loadingOverview = false;
      notifyListeners();
    }
  }

  Future<void> loadLargeFiles({
    int minBytes = 100 * 1024 * 1024,
    bool force = false,
  }) async {
    if (_loadingLargeFiles) return;
    if (_largeFilesLoaded && !force && _largeFilesMinBytes == minBytes) return;
    _largeFilesMinBytes = minBytes;
    _loadingLargeFiles = true;
    _lastError = null;
    notifyListeners();
    try {
      final raw = await _bridge.findLargeFiles(minBytes: minBytes);
      _largeFiles = raw.map(StorageFile.fromMap).toList(growable: false);
      _largeFilesLoaded = true;
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
    } finally {
      _loadingLargeFiles = false;
      notifyListeners();
    }
  }

  Future<void> loadDuplicates({bool force = false}) async {
    if (_loadingDuplicates) return;
    if (_duplicatesLoaded && !force) return;
    _loadingDuplicates = true;
    _lastError = null;
    notifyListeners();
    try {
      final raw = await _bridge.findDuplicates();
      _duplicates = raw.map(DuplicateGroup.fromMap).toList(growable: false)
        ..sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
      _duplicatesLoaded = true;
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
    } finally {
      _loadingDuplicates = false;
      notifyListeners();
    }
  }

  Future<void> loadScreenshots({bool force = false}) async {
    if (_loadingScreenshots) return;
    if (_screenshotsLoaded && !force) return;
    _loadingScreenshots = true;
    _lastError = null;
    notifyListeners();
    try {
      final raw = await _bridge.findScreenshots();
      _screenshots = raw.map(StorageFile.fromMap).toList(growable: false);
      _screenshotsLoaded = true;
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
    } finally {
      _loadingScreenshots = false;
      notifyListeners();
    }
  }

  Future<void> loadDownloads({bool force = false}) async {
    if (_loadingDownloads) return;
    if (_downloadsLoaded && !force) return;
    _loadingDownloads = true;
    _lastError = null;
    notifyListeners();
    try {
      final raw = await _bridge.getDownloads();
      _downloads = raw.map(StorageFile.fromMap).toList(growable: false);
      _downloadsLoaded = true;
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
    } finally {
      _loadingDownloads = false;
      notifyListeners();
    }
  }

  Future<void> loadWhatsApp({bool force = false}) async {
    if (_loadingWhatsApp) return;
    if (_whatsappLoaded && !force) return;
    _loadingWhatsApp = true;
    _lastError = null;
    notifyListeners();
    try {
      final raw = await _bridge.findWhatsApp();
      _whatsapp = raw
          .map(StorageFile.fromMap)
          .map(WhatsAppMedia.from)
          .whereType<WhatsAppMedia>()
          .toList(growable: false);
      _whatsappLoaded = true;
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
    } finally {
      _loadingWhatsApp = false;
      notifyListeners();
    }
  }

  /// Recent photos from the media library, for the similar-photo finder.
  Future<List<StorageFile>> loadImages({int limit = 300}) async {
    if (_loadingImages) return _images;
    _loadingImages = true;
    notifyListeners();
    try {
      final raw = await _bridge.findImages(limit: limit);
      _images = raw.map(StorageFile.fromMap).toList(growable: false);
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
    } finally {
      _loadingImages = false;
      notifyListeners();
    }
    return _images;
  }

  // endregion

  // region file actions

  Future<bool> share(StorageFile file) async {
    try {
      return await _bridge.shareFile(file.target);
    } on NativeBridgeException {
      return false;
    }
  }

  Future<bool> open(StorageFile file) async {
    try {
      return await _bridge.openFile(file.target);
    } on NativeBridgeException {
      return false;
    }
  }

  Future<bool> openLocation(StorageFile file) async {
    try {
      return await _bridge.openFileLocation(
        file.hasPath ? file.path : file.target,
      );
    } on NativeBridgeException {
      return false;
    }
  }

  /// Deletes [files]. Callers must confirm with the user first. When Android
  /// insists on its own confirmation (scoped storage), that dialog is shown
  /// and the outcome folded into the result.
  Future<DeleteResult> deleteFiles(List<StorageFile> files) async {
    if (files.isEmpty) return const DeleteResult();
    DeleteResult result;
    try {
      result = DeleteResult.fromMap(
        await _bridge.deleteFiles(files.map((f) => f.target).toList()),
      );
      if (result.needsConsent.isNotEmpty) {
        final consent = DeleteResult.fromMap(
          await _bridge.requestMediaDelete(result.needsConsent),
        );
        result = result.merge(consent);
      }
    } on NativeBridgeException catch (e) {
      _lastError = e.message;
      result = DeleteResult(failed: files.length);
    }

    final consentGranted = result.needsConsent.isEmpty || result.deleted > 0;
    final removed = <String>{
      for (final file in files)
        if (!result.errors.contains(file.target) &&
            (consentGranted || !result.needsConsent.contains(file.target)))
          file.id,
    };
    if (removed.isNotEmpty) _forget(removed);
    return result;
  }

  void _forget(Set<String> ids) {
    _largeFiles = _largeFiles.where((f) => !ids.contains(f.id)).toList();
    _screenshots = _screenshots.where((f) => !ids.contains(f.id)).toList();
    _downloads = _downloads.where((f) => !ids.contains(f.id)).toList();
    _images = _images.where((f) => !ids.contains(f.id)).toList();
    _whatsapp = _whatsapp.where((m) => !ids.contains(m.file.id)).toList();
    _duplicates = _duplicates
        .map(
          (group) => DuplicateGroup(
            files: group.files.where((f) => !ids.contains(f.id)).toList(),
            sizeBytes: group.sizeBytes,
            wastedBytes: 0,
          ),
        )
        .where((group) => group.files.length > 1)
        .map(
          (group) => DuplicateGroup(
            files: group.files,
            sizeBytes: group.sizeBytes,
            wastedBytes: (group.files.length - 1) * group.sizeBytes,
          ),
        )
        .toList();
    for (final id in ids) {
      _thumbnails.remove(id);
    }
    notifyListeners();
  }

  /// Small preview, cached per file. Returns null for non-images.
  Future<Uint8List?> thumbnail(StorageFile file, {int size = 128}) {
    if (!file.isImage && !file.isVideo) return Future.value(null);
    final cached = _thumbnails[file.id];
    if (cached != null) return cached;
    if (_thumbnails.length >= _thumbnailCacheLimit) {
      _thumbnails.remove(_thumbnails.keys.first);
    }
    final future = _bridge
        .getThumbnail(file.target, size: size)
        .catchError((_) => null);
    _thumbnails[file.id] = future;
    return future;
  }

  // endregion

  // region heuristics

  /// Heuristic hint for a downloaded file. 0 means nothing notable.
  int riskFor(StorageFile file) {
    final name = file.name.toLowerCase();
    if (file.isApk) return 60;
    if (name.endsWith('.exe') || name.endsWith('.msi')) return 90;
    if (file.mimeType?.contains('application/x-msdownload') == true) return 90;
    return 0;
  }

  /// Groups downloads into actionable buckets.
  Map<String, List<StorageFile>> downloadsByType() {
    final groups = <String, List<StorageFile>>{};
    for (final file in _downloads) {
      groups.putIfAbsent(downloadKind(file), () => []).add(file);
    }
    final sorted = groups.keys.toList()
      ..sort(
        (a, b) => groups[b]!
            .fold<int>(0, (s, f) => s + f.sizeBytes)
            .compareTo(groups[a]!.fold<int>(0, (s, f) => s + f.sizeBytes)),
      );
    return {for (final key in sorted) key: groups[key]!};
  }

  String downloadKind(StorageFile file) {
    final mime = file.mimeType ?? '';
    final name = file.name.toLowerCase();
    if (file.isApk) return 'APK';
    if (name.endsWith('.pdf')) return 'PDF';
    if (RegExp(r'\.(zip|rar|7z|tar|gz)$').hasMatch(name)) return 'Archive';
    if (mime.startsWith('image/')) return 'Images';
    if (mime.startsWith('video/')) return 'Videos';
    if (mime.startsWith('audio/')) return 'Audio';
    if (mime.startsWith('text/')) return 'Text';
    return 'Other';
  }

  /// Storage pressure: below 15% free is worth a gentle nudge.
  RiskLevel storagePressure() {
    final overview = _overview;
    if (overview == null || overview.totalBytes == 0) return RiskLevel.safe;
    final free = overview.freeBytes / overview.totalBytes;
    if (free < 0.05) return RiskLevel.high;
    if (free < 0.15) return RiskLevel.medium;
    return RiskLevel.safe;
  }

  // endregion
}
