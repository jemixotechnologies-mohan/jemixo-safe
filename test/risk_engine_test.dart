import 'package:flutter_test/flutter_test.dart';
import 'package:jemixo_safe/core/theme/risk_palette.dart';
import 'package:jemixo_safe/services/platform/native_models.dart';
import 'package:jemixo_safe/services/risk_engine/risk_engine.dart';

AppInfo app({
  String packageName = 'com.example.app',
  List<String> permissions = const [],
  String? installer = 'com.android.vending',
  bool debuggable = false,
  bool system = false,
  List<AppSignature> signatures = const [AppSignature(sha256: 'abc')],
}) => AppInfo(
  packageName: packageName,
  label: 'Example',
  permissions: permissions,
  installerPackage: installer,
  debuggable: debuggable,
  isSystemApp: system,
  signatures: signatures,
);

void main() {
  const engine = RiskEngine();

  group('RiskEngine', () {
    test('a plain store app with no sensitive permissions is clean', () {
      final result = engine.assess(
        app(permissions: const ['android.permission.INTERNET']),
      );
      expect(result.indicators, isEmpty);
      expect(result.score, 0);
      expect(result.level, RiskLevel.safe);
      expect(result.needsReview, isFalse);
    });

    test('contacts indicator only fires when the app asks for contacts', () {
      final without = engine.evaluate(
        app(permissions: const ['android.permission.CAMERA']),
      );
      final with_ = engine.evaluate(
        app(permissions: const ['android.permission.READ_CONTACTS']),
      );
      expect(without.map((i) => i.id), isNot(contains('contacts')));
      expect(with_.map((i) => i.id), contains('contacts'));
    });

    test('SMS plus contacts is flagged as a critical pairing', () {
      final result = engine.assess(
        app(
          permissions: const [
            'android.permission.READ_SMS',
            'android.permission.READ_CONTACTS',
          ],
        ),
      );
      expect(result.indicators.map((i) => i.id), contains('sms+contacts'));
      expect(result.level, RiskLevel.high);
    });

    test('background location uses the real Android constant', () {
      final result = engine.evaluate(
        app(
          permissions: const ['android.permission.ACCESS_BACKGROUND_LOCATION'],
        ),
      );
      expect(result.map((i) => i.id), contains('background-location'));
    });

    test('sideloaded apps are flagged, store apps are not', () {
      expect(
        engine.evaluate(app(installer: null)).map((i) => i.id),
        contains('sideloaded'),
      );
      expect(
        engine
            .evaluate(app(installer: 'com.google.android.packageinstaller'))
            .map((i) => i.id),
        contains('sideloaded'),
      );
      expect(
        engine.evaluate(app(installer: 'com.android.vending')).map((i) => i.id),
        isNot(contains('sideloaded')),
      );
    });

    test('debuggable flag respects the setting', () {
      expect(
        const RiskEngine(flagDebuggable: true)
            .evaluate(app(debuggable: true))
            .map((i) => i.id),
        contains('debuggable'),
      );
      expect(
        const RiskEngine(flagDebuggable: false)
            .evaluate(app(debuggable: true))
            .map((i) => i.id),
        isNot(contains('debuggable')),
      );
    });

    test('informational-only signals do not put an app on the review list', () {
      final result = engine.assess(app(signatures: const []));
      expect(result.indicators.map((i) => i.id), contains('no-signature'));
      expect(result.needsReview, isFalse);
    });

    test('trusted packages keep only critical indicators', () {
      final result = engine.evaluate(
        app(
          packageName: 'com.whatsapp',
          permissions: const [
            'android.permission.READ_CONTACTS',
            'android.permission.READ_SMS',
          ],
          installer: null,
        ),
      );
      expect(result.every((i) => i.isCritical), isTrue);
      expect(result.map((i) => i.id), isNot(contains('sideloaded')));
    });

    test('score compresses with diminishing returns', () {
      final one = engine.scoreFor(const [
        RiskIndicator(id: 'a', title: '', description: '', severity: 3),
      ]);
      final many = engine.scoreFor(
        List.generate(
          10,
          (i) => RiskIndicator(id: '$i', title: '', description: '', severity: 1),
        ),
      );
      expect(one, greaterThan(0));
      expect(one, lessThan(100));
      expect(many, lessThan(60));
    });
  });

  group('PrivacyEngine', () {
    const privacy = PrivacyEngine();

    test('no sensitive permissions scores zero', () {
      expect(privacy.scoreFor(app()), 0);
      expect(privacy.levelFor(0), RiskLevel.safe);
    });

    test('location, contacts and SMS push the score high', () {
      final score = privacy.scoreFor(
        app(
          permissions: const [
            'android.permission.ACCESS_FINE_LOCATION',
            'android.permission.ACCESS_BACKGROUND_LOCATION',
            'android.permission.READ_CONTACTS',
            'android.permission.READ_SMS',
            'android.permission.RECORD_AUDIO',
            'android.permission.CAMERA',
          ],
        ),
      );
      expect(privacy.levelFor(score), isIn([RiskLevel.medium, RiskLevel.high]));
    });
  });
}
