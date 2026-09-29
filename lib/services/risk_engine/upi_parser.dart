import '../../core/theme/risk_palette.dart';
import '../threat_data/threat_data.dart';

/// A decoded UPI deep link or QR payload.
///
/// The single most common QR scam is a "receive money" story attached to a
/// pay-me request, so the parser's job is to say plainly who gets paid.
class UpiPayment {
  const UpiPayment({
    required this.raw,
    required this.action,
    required this.payeeAddress,
    this.payeeName,
    this.amount,
    this.note,
    this.merchantCode,
    this.transactionRef,
    this.currency,
  });

  final String raw;

  /// pay, collect, mandate or another verb from the scheme path.
  final String action;
  final String payeeAddress;
  final String? payeeName;
  final double? amount;
  final String? note;
  final String? merchantCode;
  final String? transactionRef;
  final String? currency;

  bool get isCollect => action == 'collect';
  bool get isMandate => action == 'mandate';
  bool get hasAmount => amount != null && amount! > 0;
  bool get isMerchant => merchantCode != null && merchantCode!.isNotEmpty && merchantCode != '0000';

  /// The part after "@".
  String get handle => payeeAddress.contains('@')
      ? payeeAddress.split('@').last.toLowerCase()
      : '';

  bool get isPhoneNumberVpa =>
      RegExp(r'^\d{10}@').hasMatch(payeeAddress) ||
      RegExp(r'^\+?91\d{10}@').hasMatch(payeeAddress);

  bool get knownHandle => ThreatData.current.upiHandles.contains(handle);

  /// Money leaves the phone in every case except an explicit collect request,
  /// which asks the *scanner's* app to pull money from the *payer* - and that
  /// is still the user paying.
  String get direction => 'You would pay';

  static const _schemes = {'upi', 'paytmmp', 'phonepe', 'gpay', 'tez', 'bhim'};

  static bool looksLikeUpi(String value) {
    final lower = value.trim().toLowerCase();
    return _schemes.any((s) => lower.startsWith('$s://'));
  }

  static UpiPayment? parse(String value) {
    final raw = value.trim();
    if (!looksLikeUpi(raw)) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    final params = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      params[entry.key.toLowerCase()] = entry.value.trim();
    }
    final pa = params['pa'];
    if (pa == null || pa.isEmpty) return null;

    // upi://pay, upi://collect, phonepe://pay, gpay://upi/pay ...
    final segments = [uri.host, ...uri.pathSegments]
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .toList();
    final action = segments.contains('collect')
        ? 'collect'
        : segments.contains('mandate')
        ? 'mandate'
        : 'pay';

    return UpiPayment(
      raw: raw,
      action: action,
      payeeAddress: pa,
      payeeName: params['pn']?.isEmpty == false ? params['pn'] : null,
      amount: double.tryParse(params['am'] ?? ''),
      note: params['tn']?.isEmpty == false ? params['tn'] : null,
      merchantCode: params['mc'],
      transactionRef: params['tr'] ?? params['tid'],
      currency: params['cu'],
    );
  }

  /// Plain-language observations for the result screen.
  List<UpiObservation> observations() {
    final notes = <UpiObservation>[];

    notes.add(
      UpiObservation(
        level: RiskLevel.low,
        title: hasAmount
            ? 'This QR makes you PAY ₹${_formatAmount(amount!)}'
            : 'This QR makes you pay; the amount is entered by you',
        detail:
            'Scanning a QR never gives you money. If someone said you would '
            'receive a refund, prize or deposit by scanning, that is the scam.',
      ),
    );

    if (isCollect) {
      notes.add(
        const UpiObservation(
          level: RiskLevel.high,
          title: 'Collect request',
          detail:
              'Approving a collect request sends money out of your account. '
              'Only approve requests you started yourself.',
        ),
      );
    }

    if (isMandate) {
      notes.add(
        const UpiObservation(
          level: RiskLevel.high,
          title: 'Recurring mandate (AutoPay)',
          detail:
              'This sets up automatic future debits, not a single payment. '
              'Check the amount, frequency and end date very carefully.',
        ),
      );
    }

    if (payeeName == null) {
      notes.add(
        const UpiObservation(
          level: RiskLevel.medium,
          title: 'No payee name in the code',
          detail:
              'Genuine merchant QRs carry the business name. Your UPI app will '
              'show the verified name before you pay: read it.',
        ),
      );
    }

    if (handle.isEmpty) {
      notes.add(
        const UpiObservation(
          level: RiskLevel.high,
          title: 'Malformed UPI address',
          detail: 'The payee address has no @bank part. Do not proceed.',
        ),
      );
    } else if (!knownHandle) {
      notes.add(
        UpiObservation(
          level: RiskLevel.medium,
          title: 'Unfamiliar UPI handle "@$handle"',
          detail:
              'Jemixo Safe does not recognise this bank handle. It may be new or '
              'rare; confirm the payee name in your UPI app before paying.',
        ),
      );
    }

    if (isPhoneNumberVpa) {
      notes.add(
        const UpiObservation(
          level: RiskLevel.low,
          title: 'Paying a personal phone-number address',
          detail:
              'This goes to an individual, not a registered business. Fine for '
              'friends; unusual for a shop or a "customer care" refund.',
        ),
      );
    }

    if (hasAmount && !isMerchant && amount! >= 5000) {
      notes.add(
        UpiObservation(
          level: RiskLevel.medium,
          title: 'Large fixed amount to a non-merchant',
          detail:
              '₹${_formatAmount(amount!)} pre-filled to an address without a '
              'merchant code. Verified shops usually have one.',
        ),
      );
    }

    return notes;
  }

  RiskLevel get level {
    final levels = observations().map((o) => o.level);
    if (levels.contains(RiskLevel.high)) return RiskLevel.high;
    if (levels.where((l) => l == RiskLevel.medium).length >= 2) {
      return RiskLevel.high;
    }
    if (levels.contains(RiskLevel.medium)) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class UpiObservation {
  const UpiObservation({
    required this.level,
    required this.title,
    required this.detail,
  });

  final RiskLevel level;
  final String title;
  final String detail;
}
