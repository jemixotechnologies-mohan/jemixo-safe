import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../platform/native_models.dart';
import 'storage_service.dart';

/// Groups visually similar photos so near-duplicate shots (bursts, forwarded
/// images, re-saved screenshots) can be reviewed together.
///
/// Similarity is a 64-bit difference hash computed on a 9x8 greyscale
/// reduction of a small native thumbnail. It is a heuristic for "these look
/// alike", not a duplicate detector — exact duplicates are found by hashing
/// file contents instead.
class SimilarPhotoFinder extends ChangeNotifier {
  SimilarPhotoFinder(this._storage, {int concurrency = 4})
    : _concurrency = concurrency.clamp(1, 8);

  final StorageService _storage;
  final int _concurrency;

  bool _running = false;
  int _processed = 0;
  int _total = 0;

  bool get isRunning => _running;
  int get processed => _processed;
  int get total => _total;
  double get progress => _total == 0 ? 0 : _processed / _total;

  /// Returns groups ordered by total reclaimable bytes. Only groups with more
  /// than one photo are returned.
  Future<List<SimilarPhotoGroup>> find(
    List<StorageFile> photos, {
    int maxPhotos = 300,
    int threshold = 8,
  }) async {
    if (_running) return const [];
    _running = true;
    _processed = 0;

    final candidates = photos.where((f) => f.isImage).take(maxPhotos).toList();
    _total = candidates.length;
    notifyListeners();

    final hashes = <String, int>{};
    try {
      for (var index = 0; index < candidates.length; index += _concurrency) {
        final slice = candidates.skip(index).take(_concurrency).toList();
        final results = await Future.wait(slice.map(_hashOf));
        for (var offset = 0; offset < slice.length; offset++) {
          final hash = results[offset];
          if (hash != null) hashes[slice[offset].id] = hash;
        }
        _processed = math.min(index + _concurrency, candidates.length);
        notifyListeners();
      }
    } finally {
      _running = false;
      notifyListeners();
    }

    return _cluster(candidates, hashes, threshold);
  }

  Future<int?> _hashOf(StorageFile file) async {
    try {
      final bytes = await _storage.thumbnail(file, size: 64);
      if (bytes == null) return null;
      // Decoding a 64 px JPEG is cheap, but keep it off the UI isolate anyway
      // so scrolling stays smooth while hundreds are processed.
      return await compute(_hashBytes, bytes);
    } catch (_) {
      return null;
    }
  }

  static int? _hashBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return differenceHash(decoded);
  }

  /// 64-bit dHash: compares each pixel with the one to its right on a 9x8
  /// greyscale reduction.
  @visibleForTesting
  static int differenceHash(img.Image source) {
    final small = img.copyResize(
      source,
      width: 9,
      height: 8,
      interpolation: img.Interpolation.average,
    );

    var hash = 0;
    var bit = 0;
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final left = small.getPixel(x, y).luminance;
        final right = small.getPixel(x + 1, y).luminance;
        if (left > right) hash |= 1 << bit;
        bit++;
      }
    }
    return hash;
  }

  @visibleForTesting
  static int hamming(int a, int b) {
    var difference = a ^ b;
    var count = 0;
    while (difference != 0) {
      count += difference & 1;
      difference >>>= 1;
    }
    return count;
  }

  List<SimilarPhotoGroup> _cluster(
    List<StorageFile> photos,
    Map<String, int> hashes,
    int threshold,
  ) {
    final entries = photos.where((f) => hashes.containsKey(f.id)).toList();
    final assigned = <String>{};
    final groups = <SimilarPhotoGroup>[];

    for (final seed in entries) {
      if (assigned.contains(seed.id)) continue;
      final seedHash = hashes[seed.id]!;
      final members = <StorageFile>[seed];
      assigned.add(seed.id);

      for (final other in entries) {
        if (assigned.contains(other.id)) continue;
        if (hamming(seedHash, hashes[other.id]!) <= threshold) {
          members.add(other);
          assigned.add(other.id);
        }
      }

      if (members.length < 2) continue;

      final sorted = [...members]
        ..sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
      final keep = sorted.last;
      final duplicates = sorted.take(sorted.length - 1).toList();
      groups.add(
        SimilarPhotoGroup(
          keeper: keep,
          duplicates: duplicates,
          totalBytes: sorted.fold(0, (sum, f) => sum + f.sizeBytes),
          reclaimableBytes: duplicates.fold(0, (sum, f) => sum + f.sizeBytes),
        ),
      );
    }

    groups.sort((a, b) => b.reclaimableBytes.compareTo(a.reclaimableBytes));
    return groups;
  }
}

class SimilarPhotoGroup {
  const SimilarPhotoGroup({
    required this.keeper,
    required this.duplicates,
    required this.totalBytes,
    required this.reclaimableBytes,
  });

  final StorageFile keeper;
  final List<StorageFile> duplicates;
  final int totalBytes;
  final int reclaimableBytes;

  int get count => duplicates.length + 1;

  /// Drops files that no longer exist, keeping the group only if it still
  /// has something to compare.
  SimilarPhotoGroup? without(Set<String> ids) {
    if (ids.contains(keeper.id)) return null;
    final remaining = duplicates.where((f) => !ids.contains(f.id)).toList();
    if (remaining.isEmpty) return null;
    return SimilarPhotoGroup(
      keeper: keeper,
      duplicates: remaining,
      totalBytes: keeper.sizeBytes + remaining.fold(0, (s, f) => s + f.sizeBytes),
      reclaimableBytes: remaining.fold(0, (s, f) => s + f.sizeBytes),
    );
  }
}
