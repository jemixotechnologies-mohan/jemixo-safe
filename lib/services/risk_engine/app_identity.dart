import '../platform/native_models.dart';
import '../threat_data/threat_data.dart';
import 'risk_engine.dart';

/// Finds apps that borrow a trusted brand's name without being the official
/// package, and loan apps that are not on the regulated-lender list.
///
/// Both checks are offline and data-driven: the brand rules and app lists
/// come from [ThreatData], so a new fake can be covered by publishing a JSON
/// update rather than an app release.
class AppIdentityChecker {
  const AppIdentityChecker(this.data);

  final ThreatData data;

  static final Map<String, RegExp> _patterns = {};

  /// Word-boundary match so "axis" does not fire on "Praxis". Patterns are
  /// cached: the scanner evaluates hundreds of apps against dozens of brands.
  static bool _labelMentions(String label, String keyword) {
    final pattern = _patterns.putIfAbsent(
      keyword,
      () => RegExp(
        '(?<![a-z0-9])${RegExp.escape(keyword)}(?![a-z0-9])',
        caseSensitive: false,
      ),
    );
    return pattern.hasMatch(label);
  }

  /// The brand this app pretends to be, or null when the name is fine.
  BrandRule? impersonatedBrand(AppInfo app) {
    if (app.isSystemApp) return null;
    final label = app.label.toLowerCase();
    final packageName = app.packageName.toLowerCase();
    for (final rule in data.brands) {
      if (!_labelMentions(label, rule.keyword)) continue;
      if (rule.allows(app.packageName) || rule.allows(packageName)) continue;
      // The package itself may be a different official product of the brand
      // (e.g. a bank's credit-card app); those are in the official list.
      final official = data.officialApps[app.packageName];
      if (official != null && official.brand.toLowerCase() == rule.brand.toLowerCase()) {
        continue;
      }
      return rule;
    }
    return null;
  }

  /// True when the package name is official but the signing certificate
  /// differs from the published one (only when a certificate is published).
  bool hasSignatureMismatch(AppInfo app) {
    final official = data.officialApps[app.packageName];
    final expected = official?.sha256;
    if (expected == null || expected.isEmpty) return false;
    if (app.signatures.isEmpty) return false;
    return !app.signatures.any(
      (s) => (s.sha256 ?? '').toUpperCase() == expected,
    );
  }

  bool looksLikeLoanApp(AppInfo app) {
    if (app.isSystemApp) return false;
    final label = app.label.toLowerCase();
    final packageName = app.packageName.toLowerCase();
    return data.loanKeywords.any(
      (k) => _labelMentions(label, k) || packageName.contains(k.replaceAll(' ', '')),
    );
  }

  bool isListedLender(AppInfo app) =>
      data.loanApps.containsKey(app.packageName) ||
      (data.officialApps[app.packageName]?.category == 'bank') ||
      (data.officialApps[app.packageName]?.category == 'lender');

  /// Loan-looking apps that are not on the regulated list.
  bool isUnlistedLoanApp(AppInfo app) =>
      looksLikeLoanApp(app) && !isListedLender(app);

  List<RiskIndicator> indicatorsFor(AppInfo app) {
    final indicators = <RiskIndicator>[];

    final brand = impersonatedBrand(app);
    if (brand != null) {
      indicators.add(
        RiskIndicator(
          id: 'impersonation',
          title: 'Uses the ${brand.brand} name but is not the official app',
          description:
              '"${app.label}" mentions ${brand.brand}, yet its package '
              '(${app.packageName}) is not one ${brand.brand} publishes. Fake '
              'banking and payment apps are the most common way money is stolen '
              'from a phone. Do not sign in to it.',
          severity: 3,
        ),
      );
    }

    if (hasSignatureMismatch(app)) {
      indicators.add(
        RiskIndicator(
          id: 'signature-mismatch',
          title: 'Official package name, different publisher signature',
          description:
              'The package name matches ${data.officialApps[app.packageName]?.name}, '
              'but the signing certificate is not the published one. This is what '
              'a repackaged (modified) app looks like.',
          severity: 3,
        ),
      );
    }

    if (isUnlistedLoanApp(app)) {
      indicators.add(
        RiskIndicator(
          id: 'unlisted-loan',
          title: 'Loan app not on the regulated-lender list',
          description:
              '"${app.label}" looks like a lending app but is not in Jemixo '
              'Safe\'s list of apps run by RBI-regulated lenders. Unregulated '
              'loan apps are known for harassment using your contacts and photos. '
              'Check the lender name on RBI\'s Sachet portal before borrowing.',
          severity: app.isSideloaded ? 3 : 2,
        ),
      );
    }

    return indicators;
  }
}
