import 'package:flutter_test/flutter_test.dart';
import 'package:jemixo_safe/services/platform/native_models.dart';
import 'package:jemixo_safe/services/storage_analyzer/whatsapp_media.dart';

StorageFile file(
  String path, {
  int size = 1024,
  String mime = 'image/jpeg',
  int? modified,
}) => StorageFile(
  path: path,
  uri: 'content://media/external/file/${path.hashCode}',
  name: path.split('/').last,
  sizeBytes: size,
  mimeType: mime,
  modified: modified,
);

const base = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media';

void main() {
  group('WhatsAppMedia.from', () {
    test('classifies folders and sent/received', () {
      final image = WhatsAppMedia.from(file('$base/WhatsApp Images/a.jpg'))!;
      expect(image.kind, WhatsAppKind.images);
      expect(image.received, isTrue);

      final sent = WhatsAppMedia.from(
        file('$base/WhatsApp Video/Sent/b.mp4', mime: 'video/mp4'),
      )!;
      expect(sent.kind, WhatsAppKind.videos);
      expect(sent.sent, isTrue);

      final voice = WhatsAppMedia.from(
        file('$base/WhatsApp Voice Notes/202601/c.opus', mime: 'audio/ogg'),
      )!;
      expect(voice.kind, WhatsAppKind.voiceNotes);

      final gif = WhatsAppMedia.from(
        file('$base/WhatsApp Animated Gifs/d.mp4', mime: 'video/mp4'),
      )!;
      expect(gif.kind, WhatsAppKind.gifs);
    });

    test('detects WhatsApp Business and legacy locations', () {
      final business = WhatsAppMedia.from(
        file(
          '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/WhatsApp Business Images/e.jpg',
        ),
      )!;
      expect(business.business, isTrue);
      expect(business.kind, WhatsAppKind.images);

      final legacy = WhatsAppMedia.from(
        file('/storage/emulated/0/WhatsApp/Media/WhatsApp Images/f.jpg'),
      );
      expect(legacy, isNotNull);
    });

    test('ignores files outside WhatsApp, profile photos and thumbnails', () {
      expect(WhatsAppMedia.from(file('/storage/emulated/0/DCIM/x.jpg')), isNull);
      expect(
        WhatsAppMedia.from(file('$base/WhatsApp Profile Photos/p.jpg')),
        isNull,
      );
      expect(WhatsAppMedia.from(file('$base/.Thumbs/t.jpg')), isNull);
      expect(
        WhatsAppMedia.from(
          const StorageFile(path: '', name: 'n', sizeBytes: 1, mimeType: 'image/jpeg'),
        ),
        isNull,
      );
    });
  });

  group('WhatsAppCleaner', () {
    final now = DateTime(2026, 9, 30);
    WhatsAppMedia media(String sub, {int size = 1024, DateTime? modified, String mime = 'image/jpeg'}) =>
        WhatsAppMedia.from(
          file('$base/$sub', size: size, mime: mime, modified: modified?.millisecondsSinceEpoch),
        )!;

    test('old and large filters', () {
      final old = media('WhatsApp Images/a.jpg', modified: DateTime(2026, 5, 1));
      final fresh = media('WhatsApp Images/b.jpg', modified: DateTime(2026, 9, 20));
      final big = media('WhatsApp Video/c.mp4', size: 50 * 1024 * 1024, mime: 'video/mp4');
      expect(WhatsAppCleaner.matches(old, WhatsAppFilter.old, now: now), isTrue);
      expect(WhatsAppCleaner.matches(fresh, WhatsAppFilter.old, now: now), isFalse);
      expect(WhatsAppCleaner.matches(big, WhatsAppFilter.large), isTrue);
      expect(WhatsAppCleaner.matches(old, WhatsAppFilter.large), isFalse);
    });

    test('sent and received filters', () {
      final sent = media('WhatsApp Images/Sent/a.jpg');
      final got = media('WhatsApp Images/b.jpg');
      expect(WhatsAppCleaner.matches(sent, WhatsAppFilter.sent), isTrue);
      expect(WhatsAppCleaner.matches(got, WhatsAppFilter.sent), isFalse);
      expect(WhatsAppCleaner.matches(got, WhatsAppFilter.received), isTrue);
    });

    test('bytesByKind orders biggest first', () {
      final items = [
        media('WhatsApp Images/a.jpg', size: 100),
        media('WhatsApp Video/b.mp4', size: 900, mime: 'video/mp4'),
        media('WhatsApp Images/c.jpg', size: 200),
      ];
      final result = WhatsAppCleaner.bytesByKind(items);
      expect(result.first.key, WhatsAppKind.videos);
      expect(result.last.value, 300);
    });

    test('duplicates: gallery copy makes every WhatsApp copy removable', () {
      final w1 = file('$base/WhatsApp Images/a.jpg');
      final w2 = file('$base/WhatsApp Images/a(1).jpg');
      final gallery = file('/storage/emulated/0/DCIM/a.jpg');
      final onlyWhatsApp = [
        file('$base/WhatsApp Images/x.jpg'),
        file('$base/WhatsApp Images/y.jpg'),
      ];
      final ids = WhatsAppCleaner.duplicateIdsFrom([
        DuplicateGroup(files: [gallery, w1, w2], sizeBytes: 1024, wastedBytes: 2048),
        DuplicateGroup(files: onlyWhatsApp, sizeBytes: 1024, wastedBytes: 1024),
        DuplicateGroup(
          files: [file('/storage/emulated/0/DCIM/p.jpg'), file('/storage/emulated/0/Pictures/p.jpg')],
          sizeBytes: 1,
          wastedBytes: 1,
        ),
      ]);
      expect(ids, containsAll([w1.id, w2.id, onlyWhatsApp[1].id]));
      expect(ids, isNot(contains(onlyWhatsApp[0].id)));
      expect(ids.length, 3);
    });
  });
}
