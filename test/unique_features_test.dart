import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jemixo_safe/core/l10n/strings.dart';
import 'package:jemixo_safe/core/theme/risk_palette.dart';
import 'package:jemixo_safe/services/platform/native_models.dart';
import 'package:jemixo_safe/services/risk_engine/call_number.dart';
import 'package:jemixo_safe/services/risk_engine/risk_engine.dart';
import 'package:jemixo_safe/services/risk_engine/text_analyzers.dart';
import 'package:jemixo_safe/services/threat_data/threat_data.dart';

void main() {
  setUpAll(() {
    ThreatData.current = ThreatData.fromJson(
      jsonDecode(File('assets/data/threat_data.json').readAsStringSync())
          as Map<String, dynamic>,
    );
  });

  group('official domain badge', () {
    const analyzer = UrlSafetyAnalyzer();

    test('bank domain is verified and not flagged for brand words', () {
      final r = analyzer.analyze('https://www.hdfcbank.com/personal/login');
      expect(r.isOfficial, isTrue);
      expect(r.officialName, 'HDFC Bank');
      expect(r.level, RiskLevel.safe);
      expect(r.verdict, contains('Official site'));
    });

    test('look-alike domain is not verified', () {
      final r = analyzer.analyze('https://hdfcbank-kyc-update.xyz');
      expect(r.isOfficial, isFalse);
      expect(r.level, RiskLevel.high);
    });

    test('government challan domain is verified', () {
      expect(analyzer.analyze('https://echallan.parivahan.gov.in/index').isOfficial, isTrue);
    });
  });

  group('CallNumberAnalyzer', () {
    const analyzer = CallNumberAnalyzer();

    test('1600 series is a verified service call', () {
      expect(analyzer.analyze('1600 123456').kind, CallerKind.verifiedService);
    });

    test('140 series is a telemarketer', () {
      expect(analyzer.analyze('1401234567').kind, CallerKind.telemarketer);
    });

    test('foreign number is high risk with country name', () {
      final v = analyzer.analyze('+92 300 1234567');
      expect(v.kind, CallerKind.international);
      expect(v.level, RiskLevel.high);
      expect(v.country, 'Pakistan');
    });

    test('Indian mobile with +91 is a personal number', () {
      expect(analyzer.analyze('+91 98765 43210').kind, CallerKind.indianMobile);
      expect(analyzer.analyze('09876543210').kind, CallerKind.indianMobile);
    });

    test('toll-free is recognised', () {
      expect(analyzer.analyze('1800 1234').kind, CallerKind.tollFree);
    });
  });

  group('special access and hidden apps', () {
    AppInfo app({
      required bool launcher,
      List<String> permissions = const [],
      String packageName = 'com.example.thing',
    }) => AppInfo(
      packageName: packageName,
      label: 'Thing',
      hasLauncherIcon: launcher,
      permissions: permissions,
      installerPackage: 'com.android.vending',
      signatures: const [AppSignature(sha256: 'X')],
    );

    test('hidden app with mic + SMS is high risk', () {
      final r = const RiskEngine().assess(
        app(
          launcher: false,
          permissions: const [
            'android.permission.RECORD_AUDIO',
            'android.permission.READ_SMS',
          ],
        ),
      );
      expect(r.indicators.map((i) => i.id), contains('hidden-spy'));
      expect(r.level, RiskLevel.high);
    });

    test('hidden plugin without spying permissions is informational', () {
      final r = const RiskEngine().assess(app(launcher: false));
      final hidden = r.indicators.firstWhere((i) => i.id == 'hidden-app');
      expect(hidden.severity, 1);
      expect(r.needsReview, isFalse);
    });

    test('enabled accessibility service is decisive', () {
      final engine = RiskEngine(
        device: const DeviceContext(accessibilityPackages: {'com.example.thing'}),
      );
      final r = engine.assess(app(launcher: true));
      expect(r.indicators.map((i) => i.id), contains('accessibility-on'));
      expect(r.level, RiskLevel.high);
    });
  });

  group('Strings', () {
    test('Hindi strings are non-empty and differ from English', () {
      final en = Strings.forCode('en');
      final hi = Strings.forCode('hi');
      expect(hi.isHindi, isTrue);
      expect(hi.panicHangUp, isNot(en.panicHangUp));
      expect(hi.panicScriptLines.length, en.panicScriptLines.length);
    });
  });
}
