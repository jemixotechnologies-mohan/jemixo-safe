import '../../core/theme/risk_palette.dart';
import '../threat_data/threat_data.dart';

enum CallerKind {
  /// 1600-series: TRAI's allocated range for verified service / transactional calls.
  verifiedService,

  /// 140-series: registered telemarketers (promotional).
  telemarketer,

  /// Indian mobile number.
  indianMobile,

  /// Indian landline (STD code).
  indianLandline,

  /// Foreign number.
  international,

  /// Toll-free 1800 / 1860.
  tollFree,

  /// Short code or unrecognised.
  unknown,
}

class CallerVerdict {
  const CallerVerdict({
    required this.kind,
    required this.level,
    required this.title,
    required this.detail,
    this.country,
  });

  final CallerKind kind;
  final RiskLevel level;
  final String title;
  final String detail;
  final String? country;
}

/// Offline caller-number pattern check based on TRAI numbering rules.
///
/// No lookup service is involved; the point is to catch the patterns behind
/// most Indian phone scams: "bank" or "police" calling from a personal mobile
/// or a foreign number, and to explain what 140 / 1600 prefixes mean.
class CallNumberAnalyzer {
  const CallNumberAnalyzer();

  CallerVerdict analyze(String input) {
    var raw = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (raw.startsWith('00')) raw = '+${raw.substring(2)}';
    if (raw.isEmpty) {
      return const CallerVerdict(
        kind: CallerKind.unknown,
        level: RiskLevel.safe,
        title: 'No number given',
        detail: 'Type the number exactly as it appeared on the call screen.',
      );
    }

    // Strip the Indian country code so the national rules can apply.
    var national = raw;
    var explicitIndia = false;
    if (raw.startsWith('+91')) {
      national = raw.substring(3);
      explicitIndia = true;
    } else if (raw.startsWith('91') && raw.length == 12) {
      national = raw.substring(2);
      explicitIndia = true;
    } else if (raw.startsWith('0') && raw.length == 11) {
      national = raw.substring(1);
    }

    if (raw.startsWith('+') && !explicitIndia) {
      final digits = raw.substring(1);
      final codes = ThreatData.current.suspiciousCountryCodes;
      String? country;
      for (final length in [3, 2, 1]) {
        if (digits.length >= length && codes.containsKey(digits.substring(0, length))) {
          country = codes[digits.substring(0, length)];
          break;
        }
      }
      return CallerVerdict(
        kind: CallerKind.international,
        level: RiskLevel.high,
        country: country,
        title: country == null
            ? 'Foreign number'
            : 'Foreign number ($country)',
        detail:
            'No Indian bank, courier, police station or government office calls '
            'customers from an international number. WhatsApp calls from these '
            'codes claiming a job, parcel or "digital arrest" are a known scam '
            'pattern. Do not call back.',
      );
    }

    if (RegExp(r'^1600\d{6}$').hasMatch(national)) {
      return const CallerVerdict(
        kind: CallerKind.verifiedService,
        level: RiskLevel.low,
        title: '1600-series: verified service call',
        detail:
            'TRAI reserves 1600xxxxxx for banks, insurers and government bodies '
            'making service or transactional calls. Genuine, but still never '
            'share an OTP on a call.',
      );
    }

    if (RegExp(r'^140\d{7}$').hasMatch(national)) {
      return const CallerVerdict(
        kind: CallerKind.telemarketer,
        level: RiskLevel.medium,
        title: '140-series: registered telemarketer',
        detail:
            'This range is for promotional calls only. A "bank officer" or '
            '"police" calling from a 140 number is lying about who they are.',
      );
    }

    if (RegExp(r'^1800\d{4,7}$').hasMatch(national) ||
        RegExp(r'^1860\d{7}$').hasMatch(national)) {
      return const CallerVerdict(
        kind: CallerKind.tollFree,
        level: RiskLevel.low,
        title: 'Toll-free number',
        detail:
            'Toll-free lines cannot normally place outgoing calls. If this number '
            '"called you", the caller ID was spoofed. Call it back yourself from '
            'the official website instead.',
      );
    }

    if (RegExp(r'^[6-9]\d{9}$').hasMatch(national)) {
      return const CallerVerdict(
        kind: CallerKind.indianMobile,
        level: RiskLevel.medium,
        title: 'Personal mobile number',
        detail:
            'Fine for friends and small businesses. But banks, couriers, TRAI, '
            'the police and customs never contact you from a personal 10-digit '
            'number. If the caller claims to be any of those, hang up and dial '
            'the official number.',
      );
    }

    if (RegExp(r'^[1-5]\d{7,10}$').hasMatch(national)) {
      return const CallerVerdict(
        kind: CallerKind.indianLandline,
        level: RiskLevel.low,
        title: 'Indian landline',
        detail:
            'A landline with an STD code. Offices do use these, but caller ID can '
            'be spoofed. Confirm through the number on the official website.',
      );
    }

    return const CallerVerdict(
      kind: CallerKind.unknown,
      level: RiskLevel.medium,
      title: 'Unrecognised number format',
      detail:
          'This does not match Indian mobile, landline, toll-free, 140 or 1600 '
          'patterns. Treat unexpected calls from it with care.',
    );
  }
}
