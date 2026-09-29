/// Core product constants and user-facing disclaimers.
///
/// Jemixo Safe never claims to detect malware or prove its absence. Scores are
/// risk indicators derived from locally observable metadata, and every screen
/// that shows a score must carry a disclaimer. Keeping them here makes it
/// obvious when one is missing.
class AppConstants {
  const AppConstants._();

  static const appName = 'Jemixo Safe';
  static const tagline = 'Know Your Phone. Protect Your Privacy.';
  static const version = '1.1.0';

  static const channel = 'com.jemixo.safe/native';

  /// Published privacy policy. Host the file in `docs/privacy-policy.html`
  /// with GitHub Pages (or any static host) and put its address here before
  /// submitting to Play.
  static const privacyPolicyUrl = 'https://jemixo.github.io/safe/privacy-policy.html';

  /// The project's own static JSON with updated phrases, brand rules, app
  /// lists and scam radar. Leave empty to disable update checks. Same schema
  /// as `assets/data/threat_data.json`.
  static const threatDataUrl =
      'https://raw.githubusercontent.com/jemixo/safe-data/main/threat_data.json';

  static const cyberHelpline = '1930';
  static const cyberPortal = 'https://cybercrime.gov.in';

  static const disclaimerScore =
      'This score is a Jemixo Safe risk indicator based on information this app '
      'can read on your device. It is not a guarantee that your phone is free of '
      'harmful apps.';

  static const disclaimerRisk =
      'Risk levels are indicators, not proof of harmful behaviour. Review any '
      'flagged app before taking action.';

  static const privacyPromise =
      'Analysis runs entirely on this device. No account, no upload, no cloud.';
}
