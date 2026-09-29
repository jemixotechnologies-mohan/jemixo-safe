import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jemixo_safe/core/theme/risk_palette.dart';
import 'package:jemixo_safe/services/platform/native_models.dart';
import 'package:jemixo_safe/services/risk_engine/app_identity.dart';
import 'package:jemixo_safe/services/risk_engine/risk_engine.dart';
import 'package:jemixo_safe/services/risk_engine/sender_id.dart';
import 'package:jemixo_safe/services/risk_engine/text_analyzers.dart';
import 'package:jemixo_safe/services/risk_engine/upi_parser.dart';
import 'package:jemixo_safe/services/threat_data/threat_data.dart';

ThreatData loadBundled() {
  final file = File('assets/data/threat_data.json');
  return ThreatData.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );
}

AppInfo app({
  required String packageName,
  required String label,
  String? installer = 'com.android.vending',
  List<String> permissions = const [],
}) => AppInfo(
  packageName: packageName,
  label: label,
  installerPackage: installer,
  permissions: permissions,
  signatures: const [AppSignature(sha256: 'ABC')],
);

void main() {
  late ThreatData data;

  setUpAll(() {
    data = loadBundled();
    ThreatData.current = data;
  });

  group('bundled threat data', () {
    test('parses with the expected sections', () {
      expect(data.version, greaterThan(0));
      expect(data.brands, isNotEmpty);
      expect(data.officialApps, isNotEmpty);
      expect(data.loanApps, isNotEmpty);
      expect(data.upiHandles, contains('ybl'));
      expect(data.radar, isNotEmpty);
      expect(data.helplines.any((h) => h.number == '1930'), isTrue);
      expect(data.phrasesFor('kyc'), contains('केवाईसी'));
    });
  });

  group('AppIdentityChecker', () {
    test('official bank package is not impersonation', () {
      final checker = AppIdentityChecker(data);
      final yono = app(packageName: 'com.sbi.lotusintouch', label: 'YONO SBI');
      expect(checker.impersonatedBrand(yono), isNull);
    });

    test('brand name on an unknown package is flagged', () {
      final checker = AppIdentityChecker(data);
      final fake = app(
        packageName: 'com.update.sbi.rewards',
        label: 'SBI Rewards Points',
        installer: null,
      );
      expect(checker.impersonatedBrand(fake)?.brand, 'State Bank of India');
      final indicators = const RiskEngine().assess(fake);
      expect(indicators.indicators.map((i) => i.id), contains('impersonation'));
      expect(indicators.level, RiskLevel.high);
    });

    test('word boundaries avoid false positives', () {
      final checker = AppIdentityChecker(data);
      final praxis = app(packageName: 'com.example.praxis', label: 'Praxis Notes');
      expect(checker.impersonatedBrand(praxis), isNull);
    });

    test('loan-looking app outside the list is flagged, listed one is not', () {
      final checker = AppIdentityChecker(data);
      final shady = app(
        packageName: 'com.quick.cash.loan',
        label: 'Quick Cash Loan',
        installer: null,
      );
      final navi = app(packageName: 'com.naviapp', label: 'Navi');
      expect(checker.isUnlistedLoanApp(shady), isTrue);
      expect(checker.isUnlistedLoanApp(navi), isFalse);
      final assessment = const RiskEngine().assess(shady);
      expect(assessment.indicators.map((i) => i.id), contains('unlisted-loan'));
    });
  });

  group('Hindi phrases', () {
    test('Hinglish KYC message is caught', () {
      final finding = const ScamTextScanner().analyze(
        'Aapka account band ho jayega. Turant KYC update karo is link par.',
      );
      expect(finding.indicators.map((i) => i.id), containsAll(['kyc', 'threat', 'urgent']));
      expect(finding.level, isNot(RiskLevel.safe));
    });

    test('Devanagari OTP request is caught', () {
      final finding = const ScamTextScanner().analyze('कृपया ओटीपी बताएं, आपका इनाम जीता है');
      expect(finding.indicators.map((i) => i.id), containsAll(['otp', 'reward']));
    });
  });

  group('UpiPayment', () {
    test('parses a pay intent with amount', () {
      final p = UpiPayment.parse('upi://pay?pa=shop@ybl&pn=Tea%20Shop&am=45.00&cu=INR&mc=5812');
      expect(p, isNotNull);
      expect(p!.payeeAddress, 'shop@ybl');
      expect(p.payeeName, 'Tea Shop');
      expect(p.amount, 45.0);
      expect(p.handle, 'ybl');
      expect(p.knownHandle, isTrue);
      expect(p.isMerchant, isTrue);
      expect(p.level, RiskLevel.low);
    });

    test('collect request with unknown handle is high risk', () {
      final p = UpiPayment.parse('upi://collect?pa=refund@weirdbank&am=9999');
      expect(p!.isCollect, isTrue);
      expect(p.level, RiskLevel.high);
    });

    test('non-UPI text is ignored', () {
      expect(UpiPayment.parse('https://example.com'), isNull);
      expect(UpiPayment.looksLikeUpi('WIFI:S:home;;'), isFalse);
    });
  });

  group('SenderIdAnalyzer', () {
    const analyzer = SenderIdAnalyzer();

    test('DLT header is recognised with suffix meaning', () {
      final v = analyzer.analyze('vm-hdfcbk-s');
      expect(v.kind, SenderKind.registeredHeader);
      expect(v.entityCode, 'HDFCBK');
      expect(v.suffixMeaning, contains('service'));
      expect(v.level, RiskLevel.low);
    });

    test('personal mobile number is high risk', () {
      expect(analyzer.analyze('+91 98765 43210').kind, SenderKind.mobileNumber);
      expect(analyzer.analyze('9876543210').level, RiskLevel.high);
    });

    test('foreign number is high risk', () {
      expect(analyzer.analyze('+6281234567890').kind, SenderKind.international);
    });

    test('short code is medium', () {
      expect(analyzer.analyze('57575').kind, SenderKind.shortCode);
    });
  });
}
