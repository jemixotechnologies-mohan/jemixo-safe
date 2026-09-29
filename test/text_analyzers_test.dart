import 'package:flutter_test/flutter_test.dart';
import 'package:jemixo_safe/core/theme/risk_palette.dart';
import 'package:jemixo_safe/services/risk_engine/text_analyzers.dart';

void main() {
  group('ScamTextScanner', () {
    const scanner = ScamTextScanner();

    test('a normal message is clean', () {
      final finding = scanner.analyze(
        'Hi, are we still meeting at 6 for dinner? I booked the table.',
      );
      expect(finding.isClean, isTrue);
      expect(finding.level, RiskLevel.safe);
    });

    test('phrases match whole words only', () {
      // "footprint" contains "otp"; "insurgent" contains "urgent".
      final finding = scanner.analyze(
        'The carbon footprint of the insurgent movement was studied.',
      );
      expect(finding.indicators.map((i) => i.id), isNot(contains('otp')));
      expect(finding.indicators.map((i) => i.id), isNot(contains('urgent')));
    });

    test('a classic KYC scam is rated high', () {
      final finding = scanner.analyze(
        'Dear customer, your account will be blocked within 24 hours. '
        'Update your KYC immediately: http://bit.ly/sbi-kyc-update',
      );
      expect(finding.level, RiskLevel.high);
      expect(finding.suspectedScamType, contains('KYC'));
      expect(finding.indicators.map((i) => i.id), contains('short-url'));
      expect(finding.urls, isNotEmpty);
    });

    test('OTP requests are flagged with the phrase that matched', () {
      final finding = scanner.analyze(
        'Please share the OTP you just received to confirm your identity.',
      );
      final otp = finding.indicators.firstWhere((i) => i.id == 'otp');
      expect(otp.matched, contains('otp'));
    });

    test('bare domains without a scheme are still extracted', () {
      final finding = scanner.analyze('Claim your prize at win-free-cash.xyz now');
      expect(finding.urls, contains('win-free-cash.xyz'));
      expect(finding.indicators.map((i) => i.id), contains('suspicious-url'));
    });
  });

  group('UrlSafetyAnalyzer', () {
    const analyzer = UrlSafetyAnalyzer();

    test('a well-known HTTPS site is clean', () {
      final result = analyzer.analyze('https://www.google.com/search?q=test');
      expect(result.level, RiskLevel.safe);
      expect(result.host, 'www.google.com');
      expect(result.failures, isEmpty);
    });

    test('a support subdomain of a real domain is not impersonation', () {
      final result = analyzer.analyze('https://support.google.com/accounts');
      expect(result.failures.map((f) => f.title), everyElement(isNot(contains('disposable'))));
      expect(result.level, RiskLevel.safe);
    });

    test('missing scheme is not penalised as HTTP', () {
      final result = analyzer.analyze('example.com/page');
      expect(result.hasScheme, isFalse);
      expect(result.normalized, 'https://example.com/page');
      expect(result.checks.first.passed, isTrue);
    });

    test('plain HTTP is penalised', () {
      final result = analyzer.analyze('http://example.com');
      expect(result.checks.first.passed, isFalse);
      expect(result.level, isNot(RiskLevel.safe));
    });

    test('hyphenated brand-word phishing domain is high risk', () {
      final result = analyzer.analyze(
        'http://secure-sbi-bank-login-verify.xyz/update',
      );
      expect(result.level, RiskLevel.high);
    });

    test('credentials before @ in the authority are caught', () {
      final result = analyzer.analyze('https://bank.com@evil.example/login');
      expect(result.host, 'evil.example');
      expect(result.failures.map((f) => f.title), anyElement(contains('@')));
    });

    test('an @ in the query string is not a credential trick', () {
      final result = analyzer.analyze('https://example.com/?email=a@b.com');
      expect(result.failures.map((f) => f.title), everyElement(isNot(contains('@'))));
    });

    test('raw IP addresses are flagged', () {
      final result = analyzer.analyze('http://192.168.1.10/login');
      expect(result.failures.map((f) => f.title), anyElement(contains('IP')));
    });
  });
}
