import '../../core/theme/risk_palette.dart';

enum SenderKind {
  /// TRAI DLT header such as AX-SBIINB or VM-HDFCBK-S.
  registeredHeader,

  /// A 10-digit Indian mobile number.
  mobileNumber,

  /// A foreign number.
  international,

  /// 3 to 6 digit short code.
  shortCode,

  /// Anything else (email, alphanumeric that is not a DLT header).
  unknown,
}

/// What an SMS sender ID tells you about who sent the message.
///
/// India's DLT system gives every registered business a fixed header. Banks,
/// utilities, courier companies and government bodies always send from one.
/// A "bank" message from a personal number is therefore a scam by definition.
class SenderVerdict {
  const SenderVerdict({
    required this.kind,
    required this.level,
    required this.title,
    required this.detail,
    this.entityCode,
    this.suffixMeaning,
  });

  final SenderKind kind;
  final RiskLevel level;
  final String title;
  final String detail;

  /// The 6-character entity part of a DLT header, e.g. SBIINB.
  final String? entityCode;
  final String? suffixMeaning;
}

class SenderIdAnalyzer {
  const SenderIdAnalyzer();

  static final _dltHeader = RegExp(r'^([A-Z]{2})-([A-Z0-9]{6})(?:-([SPTG]))?$');
  static final _indianMobile = RegExp(r'^(?:\+?91[\s-]?|0)?([6-9]\d{9})$');
  static final _international = RegExp(r'^\+(?!91)\d{7,15}$');
  static final _shortCode = RegExp(r'^\d{3,6}$');

  SenderVerdict analyze(String input) {
    final raw = input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) {
      return const SenderVerdict(
        kind: SenderKind.unknown,
        level: RiskLevel.safe,
        title: 'No sender given',
        detail: 'Paste the name or number shown at the top of the message.',
      );
    }

    final header = _dltHeader.firstMatch(raw);
    if (header != null) {
      final suffix = header.group(3);
      final meaning = switch (suffix) {
        'S' => 'service message (OTP, alerts)',
        'T' => 'transactional message',
        'P' => 'promotional message',
        'G' => 'government message',
        _ => null,
      };
      return SenderVerdict(
        kind: SenderKind.registeredHeader,
        level: RiskLevel.low,
        title: 'Registered sender ID',
        detail:
            'This is a TRAI DLT header. The sender is a registered business or '
            'organisation, which makes impersonation harder but not impossible: '
            'scammers do register look-alike headers. Match "${header.group(2)}" '
            'with the header your bank normally uses.',
        entityCode: header.group(2),
        suffixMeaning: meaning,
      );
    }

    if (_indianMobile.hasMatch(raw)) {
      return const SenderVerdict(
        kind: SenderKind.mobileNumber,
        level: RiskLevel.high,
        title: 'Sent from a personal mobile number',
        detail:
            'Banks, telecom companies, couriers and government departments never '
            'send official SMS from a 10-digit number. Treat any account, KYC, '
            'bill or parcel message from this sender as a scam.',
      );
    }

    if (_international.hasMatch(raw)) {
      return const SenderVerdict(
        kind: SenderKind.international,
        level: RiskLevel.high,
        title: 'Sent from a foreign number',
        detail:
            'Indian organisations do not message customers from international '
            'numbers. Job offers and prize messages from +1, +44, +62 or similar '
            'numbers are a common scam pattern.',
      );
    }

    if (_shortCode.hasMatch(raw)) {
      return const SenderVerdict(
        kind: SenderKind.shortCode,
        level: RiskLevel.medium,
        title: 'Short code sender',
        detail:
            'Short codes are used by some operators and services, but they are '
            'also easy to spoof. Judge the message by its content.',
      );
    }

    return const SenderVerdict(
      kind: SenderKind.unknown,
      level: RiskLevel.medium,
      title: 'Not a registered header format',
      detail:
          'Registered Indian senders look like "AX-SBIINB" or "VM-HDFCBK-S". '
          'This sender does not follow that format, so it cannot be verified.',
    );
  }
}
