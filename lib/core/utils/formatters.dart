/// Human-readable formatting helpers.
///
/// Centralised so byte counts, dates and relative times read the same way on
/// every screen.
library;

const _kb = 1024;
const _mb = _kb * 1024;
const _gb = _mb * 1024;
const _tb = _gb * 1024;

String formatBytes(num bytes, {int decimals = 1}) {
  if (bytes.isNaN || bytes.isInfinite) return '0 B';
  final negative = bytes < 0;
  final value = bytes.abs().toDouble();
  final String text;
  if (value >= _tb) {
    text = '${(value / _tb).toStringAsFixed(decimals)} TB';
  } else if (value >= _gb) {
    text = '${(value / _gb).toStringAsFixed(decimals)} GB';
  } else if (value >= _mb) {
    text = '${(value / _mb).toStringAsFixed(decimals)} MB';
  } else if (value >= _kb) {
    text = '${(value / _kb).toStringAsFixed(decimals)} KB';
  } else {
    text = '${value.round()} B';
  }
  return negative ? '-$text' : text;
}

String formatDurationSeconds(num seconds) {
  if (seconds < 60) return '${seconds.round()}s';
  final minutes = seconds / 60;
  if (minutes < 60) return '${minutes.round()}m';
  final hours = minutes / 60;
  if (hours < 24) return '${hours.toStringAsFixed(hours < 10 ? 1 : 0)}h';
  return '${(hours / 24).toStringAsFixed(0)}d';
}

String formatMillis(num millis) {
  if (millis < 1000) return '${millis.round()} ms';
  if (millis < 60000) return '${(millis / 1000).toStringAsFixed(1)} s';
  final minutes = millis / 60000;
  return '${minutes.toStringAsFixed(minutes < 10 ? 1 : 0)} min';
}

String formatPercent(double fraction, {int decimals = 0}) =>
    '${(fraction.clamp(0, 1) * 100).toStringAsFixed(decimals)}%';

String formatDate(int? epochMillis) {
  if (epochMillis == null || epochMillis <= 0) return 'Unknown';
  final date = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  final now = DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (date.year == now.year) {
    return '${date.day} ${_monthName(date.month)}';
  }
  return '${date.day} ${_monthName(date.month)} ${date.year}';
}

String formatDateTime(int? epochMillis) {
  if (epochMillis == null || epochMillis <= 0) return 'Unknown';
  final date = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatDate(epochMillis)}, $hour:$minute';
}

String formatRelative(int? epochMillis) {
  if (epochMillis == null || epochMillis <= 0) return 'Never';
  final diff = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(epochMillis),
  );
  if (diff.isNegative) return 'Just now';
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  return formatDate(epochMillis);
}

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

/// Shortens a long path for display without hiding the filename.
String shortenPath(String path, {int maxSegments = 3}) {
  final parts = path.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length <= maxSegments) return path;
  return '…/${parts.skip(parts.length - maxSegments).join('/')}';
}

String fileExtension(String name) {
  final index = name.lastIndexOf('.');
  if (index <= 0 || index == name.length - 1) return '';
  return name.substring(index + 1).toLowerCase();
}
