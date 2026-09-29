import '../platform/native_models.dart';

/// Which WhatsApp folder a file came from.
enum WhatsAppKind {
  images('Photos'),
  videos('Videos'),
  gifs('GIFs'),
  voiceNotes('Voice notes'),
  audio('Audio'),
  documents('Documents'),
  stickers('Stickers'),
  statuses('Viewed statuses'),
  other('Other');

  const WhatsAppKind(this.label);

  final String label;
}

/// A file from a WhatsApp / WhatsApp Business media folder, with where it
/// came from and whether the user sent it or received it.
class WhatsAppMedia {
  const WhatsAppMedia({
    required this.file,
    required this.kind,
    required this.sent,
    required this.business,
  });

  final StorageFile file;
  final WhatsAppKind kind;

  /// True when the file sits under the "Sent" sub-folder.
  final bool sent;
  final bool business;

  bool get received => !sent;

  /// Whether [path] is inside a WhatsApp media folder.
  static bool isWhatsAppPath(String path) {
    final p = path.toLowerCase();
    return p.contains('/whatsapp/media/') ||
        p.contains('/whatsapp business/media/');
  }

  static WhatsAppKind kindOf(String path, String? mime) {
    final p = path.toLowerCase();
    if (p.contains('/.statuses/')) return WhatsAppKind.statuses;
    if (p.contains('/whatsapp images/')) return WhatsAppKind.images;
    if (p.contains('/whatsapp video/')) return WhatsAppKind.videos;
    if (p.contains('/whatsapp animated gifs/')) return WhatsAppKind.gifs;
    if (p.contains('/whatsapp voice notes/')) return WhatsAppKind.voiceNotes;
    if (p.contains('/whatsapp audio/')) return WhatsAppKind.audio;
    if (p.contains('/whatsapp documents/')) return WhatsAppKind.documents;
    if (p.contains('/whatsapp stickers/')) return WhatsAppKind.stickers;
    final m = mime ?? '';
    if (m.startsWith('image/')) return WhatsAppKind.images;
    if (m.startsWith('video/')) return WhatsAppKind.videos;
    if (m.startsWith('audio/')) return WhatsAppKind.audio;
    return WhatsAppKind.other;
  }

  /// Null when the file is not under a WhatsApp media folder or has no path.
  static WhatsAppMedia? from(StorageFile file) {
    final path = file.path;
    if (!file.hasPath || !isWhatsAppPath(path)) return null;
    final lower = path.toLowerCase();
    final kind = kindOf(path, file.mimeType);
    // Profile photos and thumbnails WhatsApp regenerates are not worth listing.
    if (lower.contains('/whatsapp profile photos/') ||
        lower.contains('/.thumbs/') ||
        lower.contains('/.trash/')) {
      return null;
    }
    return WhatsAppMedia(
      file: file,
      kind: kind,
      sent: lower.contains('/sent/'),
      business: lower.contains('/whatsapp business/'),
    );
  }
}

/// Filters offered on the cleaner screen.
enum WhatsAppFilter {
  all('All'),
  old('Older than 90 days'),
  large('Over 20 MB'),
  received('Received'),
  sent('Sent'),
  duplicates('Duplicates');

  const WhatsAppFilter(this.label);

  final String label;
}

/// Pure helpers so the screen stays thin and the rules are testable.
class WhatsAppCleaner {
  const WhatsAppCleaner._();

  static const oldAfter = Duration(days: 90);
  static const largeBytes = 20 * 1024 * 1024;

  static bool matches(
    WhatsAppMedia media,
    WhatsAppFilter filter, {
    Set<String> duplicateIds = const {},
    DateTime? now,
  }) {
    switch (filter) {
      case WhatsAppFilter.all:
        return true;
      case WhatsAppFilter.old:
        final modified = media.file.modified;
        if (modified == null) return false;
        final cutoff = (now ?? DateTime.now()).subtract(oldAfter);
        return DateTime.fromMillisecondsSinceEpoch(modified).isBefore(cutoff);
      case WhatsAppFilter.large:
        return media.file.sizeBytes >= largeBytes;
      case WhatsAppFilter.received:
        return media.received;
      case WhatsAppFilter.sent:
        return media.sent;
      case WhatsAppFilter.duplicates:
        return duplicateIds.contains(media.file.id);
    }
  }

  /// Total bytes per kind, biggest first.
  static List<MapEntry<WhatsAppKind, int>> bytesByKind(
    Iterable<WhatsAppMedia> items,
  ) {
    final totals = <WhatsAppKind, int>{};
    for (final item in items) {
      totals.update(
        item.kind,
        (v) => v + item.file.sizeBytes,
        ifAbsent: () => item.file.sizeBytes,
      );
    }
    return totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// WhatsApp copies that are safe to remove because the same bytes exist
  /// elsewhere. When a non-WhatsApp copy exists (gallery, Downloads) every
  /// WhatsApp copy is redundant; otherwise one WhatsApp copy is kept.
  static Set<String> duplicateIdsFrom(List<DuplicateGroup> groups) {
    final ids = <String>{};
    for (final group in groups) {
      final whatsapp = group.files
          .where((f) => WhatsAppMedia.isWhatsAppPath(f.path))
          .toList();
      if (whatsapp.isEmpty) continue;
      final hasOutsideCopy = whatsapp.length < group.files.length;
      final removable = hasOutsideCopy ? whatsapp : whatsapp.skip(1);
      ids.addAll(removable.map((f) => f.id));
    }
    return ids;
  }
}
