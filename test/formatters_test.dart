import 'package:flutter_test/flutter_test.dart';
import 'package:jemixo_safe/core/utils/formatters.dart';

void main() {
  group('formatBytes', () {
    test('picks the right unit', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(3.5 * 1024 * 1024 * 1024), '3.5 GB');
    });

    test('handles negatives and non-finite values', () {
      expect(formatBytes(-2048), '-2.0 KB');
      expect(formatBytes(double.nan), '0 B');
    });
  });

  group('formatRelative', () {
    test('describes recent timestamps', () {
      final now = DateTime.now();
      expect(formatRelative(now.millisecondsSinceEpoch), 'Just now');
      expect(
        formatRelative(
          now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        ),
        '5 min ago',
      );
      expect(
        formatRelative(
          now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        ),
        '1 hour ago',
      );
      expect(formatRelative(null), 'Never');
    });
  });

  group('shortenPath', () {
    test('keeps the trailing segments', () {
      expect(
        shortenPath('/storage/emulated/0/Download/file.apk', maxSegments: 2),
        '…/Download/file.apk',
      );
      expect(shortenPath('/a/b', maxSegments: 3), '/a/b');
    });
  });
}
