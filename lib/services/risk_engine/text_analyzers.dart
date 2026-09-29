import '../../core/theme/risk_palette.dart';
import '../threat_data/threat_data.dart';

/// One detected scam characteristic.
class ScamIndicator {
  const ScamIndicator({
    required this.id,
    required this.title,
    required this.why,
    required this.weight,
    this.matched = const [],
  });

  final String id;
  final String title;
  final String why;

  /// Relative contribution to the overall risk level.
  final int weight;

  /// The phrases that triggered this indicator, shown so the user can judge.
  final List<String> matched;
}

class ScamFinding {
  const ScamFinding({
    required this.indicators,
    required this.level,
    required this.urls,
    required this.score,
    this.suspectedScamType,
  });

  final List<ScamIndicator> indicators;
  final RiskLevel level;
  final List<String> urls;

  /// 0–100 indicator score.
  final int score;

  /// e.g. "Fake KYC message", "Investment scam".
  final String? suspectedScamType;

  bool get isClean => indicators.isEmpty;

  String get headline => switch (level) {
    RiskLevel.high || RiskLevel.critical => 'High risk indicators found',
    RiskLevel.medium => 'Review recommended',
    RiskLevel.low => 'Low risk indicators',
    _ => 'No scam patterns detected',
  };
}

/// Domains that shorten URLs, which hide the real destination.
const kUrlShorteners = <String>{
  'bit.ly',
  'tinyurl.com',
  'ow.ly',
  't.co',
  'goo.gl',
  'is.gd',
  'buff.ly',
  'shorturl.at',
  'rb.gy',
  'cutt.ly',
  'rebrand.ly',
  'short.link',
  'tiny.cc',
  'v.gd',
  'soo.gd',
  'clck.ru',
  'urlz.fr',
  't.ly',
  'tinyurl.in',
  'shorte.st',
};

bool _isShortenerHost(String host) =>
    kUrlShorteners.any((s) => host == s || host.endsWith('.$s'));

/// Whole-phrase matcher: "otp" must not fire on "footprint".
class _PhraseMatcher {
  static final Map<String, RegExp> _cache = {};

  static RegExp _pattern(String phrase) => _cache.putIfAbsent(
    phrase,
    () => RegExp(
      '(?<![a-z0-9])${RegExp.escape(phrase)}(?![a-z0-9])',
      caseSensitive: false,
    ),
  );

  static List<String> matches(String text, List<String> phrases) => [
    for (final phrase in phrases)
      if (_pattern(phrase).hasMatch(text)) phrase,
  ];
}

/// Local, rule-based scam-text analysis.
///
/// Deliberately transparent: every hit names the pattern that matched so the
/// user can judge it themselves. Results are labelled as risk indicators, never
/// as a verdict that a message is definitely a scam.
class ScamTextScanner {
  const ScamTextScanner();

  static const _urgentPhrases = [
    'immediately',
    'right now',
    'within 24 hours',
    'within 24 hrs',
    'within 2 hours',
    'asap',
    'urgent',
    'urgently',
    'act now',
    'expires today',
    'last warning',
    'final notice',
    'final reminder',
    'last chance',
    'avoid suspension',
    'today only',
  ];

  static const _threatPhrases = [
    'will be blocked',
    'will be suspended',
    'will be banned',
    'will be deactivated',
    'will be disconnected',
    'legal action',
    'police complaint',
    'case has been registered',
    'fir has been registered',
    'arrest warrant',
    'you are fined',
    'tax penalty',
    'permanent closure',
    'electricity will be cut',
    'power will be cut',
  ];

  static const _otpPhrases = [
    'otp',
    'one time password',
    'one-time password',
    'verification code',
    'confirmation code',
    'security code',
    'pin number',
    'atm pin',
    'upi pin',
    'mpin',
    'cvv',
    'card number',
    'expiry date',
    'net banking password',
    'login password',
    'account password',
    'confirm your identity',
    'verify your account',
    'share the code',
    'enter the code',
    'screen share',
    'anydesk',
    'teamviewer',
    'quick support',
  ];

  static const _paymentPhrases = [
    'pay now',
    'payment required',
    'complete the payment',
    'pay rs',
    'pay ₹',
    'processing fee',
    'registration fee',
    'clearance fee',
    'customs fee',
    'redelivery fee',
    'release payment',
    'transfer the amount',
    'send money',
    'gift card',
    'google play card',
    'scratch card',
    'crypto',
    'bitcoin',
    'usdt',
    'wire transfer',
    'refund will be credited',
    'claim refund',
    'cashback',
    'scan this qr',
    'scan the qr',
  ];

  static const _kycPhrases = [
    'kyc',
    'know your customer',
    'update your kyc',
    'kyc verification',
    'kyc pending',
    'kyc expired',
    'aadhaar',
    'aadhar',
    'pan card',
    'pan verification',
    'account reactivation',
    're-activate your account',
    'reactivation',
    'unblock your account',
    'sim will be blocked',
    'sim card',
  ];

  static const _rewardPhrases = [
    'you have won',
    'you won',
    'congratulations',
    'claim your prize',
    'claim your reward',
    'free gift',
    'lucky winner',
    'cash prize',
    'you are selected',
    'you have been selected',
    'lucky draw',
    'free recharge',
    'free gift voucher',
    'lottery',
    'jackpot',
  ];

  static const _accountBlockPhrases = [
    'account will be blocked',
    'account blocked',
    'account suspended',
    'account has been suspended',
    'suspend your account',
    'blocked permanently',
    'deactivate your account',
    'unblock',
    'verify to keep your account active',
    'account will be closed',
    'account locked',
  ];

  static const _jobPhrases = [
    'work from home',
    'earn daily',
    'daily income',
    'daily earning',
    'part time job',
    'part-time job',
    'investment opportunity',
    'double your money',
    'guaranteed returns',
    'guaranteed profit',
    'trading signals',
    'crypto investment',
    'forex trading',
    'become a distributor',
    'mlm',
    'like and earn',
    'rate products',
    'task based',
    'earn per task',
  ];

  static const _sensitiveRequests = [
    'do not share with anyone',
    'do not share this with anyone',
    'keep this confidential',
    'do not tell',
    'do not forward',
    'do not inform',
    'hurry',
    'do not delay',
    'stay on the line',
    'do not hang up',
    'do not disconnect',
    'do not call the bank',
  ];

  static const _impersonationPhrases = [
    'customs department',
    'cbi',
    'cyber crime',
    'cyber cell',
    'narcotics',
    'courier',
    'parcel',
    'fedex',
    'dhl',
    'blue dart',
    'india post',
    'income tax',
    'rbi',
    'trai',
    'telecom department',
    'electricity board',
    'electricity bill',
    'traffic challan',
    'e-challan',
    'bank manager',
    'customer care',
  ];

  /// Built-in English phrases plus the Hindi / Hinglish and updated phrases
  /// from the threat-data set.
  static List<String> _phrases(String category, List<String> builtIn) {
    final extra = ThreatData.current.phrasesFor(category);
    if (extra.isEmpty) return builtIn;
    return [...builtIn, ...extra];
  }

  ScamFinding analyze(String input) {
    final text = input.toLowerCase();
    final indicators = <ScamIndicator>[];

    void addIf(
      String id,
      String title,
      String why,
      int weight,
      List<String> matched,
    ) {
      if (matched.isNotEmpty) {
        indicators.add(
          ScamIndicator(
            id: id,
            title: title,
            why: why,
            weight: weight,
            matched: matched,
          ),
        );
      }
    }

    final urls = _extractUrls(input);

    addIf(
      'urgent',
      'Urgent or pressure language',
      'Tells you to act immediately, which is a common way to stop you thinking.',
      3,
      _PhraseMatcher.matches(text, _phrases('urgent', _urgentPhrases)),
    );

    addIf(
      'threat',
      'Threatening language',
      'Mentions blocking, bans, fines or legal action to create panic.',
      4,
      _PhraseMatcher.matches(text, _phrases('threat', _threatPhrases)),
    );

    addIf(
      'otp',
      'Asks for an OTP, PIN or remote access',
      'No genuine organisation will ask you to share an OTP, PIN, CVV or install '
          'a screen-sharing app.',
      5,
      _PhraseMatcher.matches(text, _phrases('otp', _otpPhrases)),
    );

    addIf(
      'payment',
      'Asks for payment',
      'Requests a fee, transfer, QR scan or gift card before releasing something.',
      4,
      _PhraseMatcher.matches(text, _phrases('payment', _paymentPhrases)),
    );

    addIf(
      'kyc',
      'Fake KYC or account reactivation',
      'Banks and telecom providers use in-app or in-person KYC. Messages that '
          'push you to a link or app for KYC are fakes.',
      4,
      _PhraseMatcher.matches(text, _phrases('kyc', _kycPhrases)),
    );

    addIf(
      'reward',
      'Unexpected prize or reward',
      'Prize claims that arrive by message with a link are almost always bait.',
      3,
      _PhraseMatcher.matches(text, _phrases('reward', _rewardPhrases)),
    );

    addIf(
      'block',
      'Account-blocking claim',
      'Claims your account will close unless you act immediately.',
      4,
      _PhraseMatcher.matches(text, _phrases('block', _accountBlockPhrases)),
    );

    addIf(
      'job',
      'Job or investment pattern',
      'Guaranteed income, work-from-home or doubling-your-money offers are a '
          'common scam template.',
      3,
      _PhraseMatcher.matches(text, _phrases('job', _jobPhrases)),
    );

    addIf(
      'secrecy',
      'Asks for secrecy',
      'Instructs you not to tell family or the bank, which is a fraud trait.',
      4,
      _PhraseMatcher.matches(text, _phrases('secrecy', _sensitiveRequests)),
    );

    addIf(
      'impersonation',
      'Claims to be an authority or courier',
      'Scams often pose as police, customs, tax, telecom or courier companies. '
          'Verify through the official number, never the one in the message.',
      2,
      _PhraseMatcher.matches(text, _phrases('impersonation', _impersonationPhrases)),
    );

    final blocked = urls
        .where((u) => ThreatData.current.isBlockedDomain(_hostOf(u)))
        .toList();
    addIf(
      'blocked-domain',
      'Link to a known scam domain',
      'This address is on the Jemixo Safe scam-domain list. Do not open it.',
      6,
      blocked,
    );

    final shorteners = urls.where((u) => _isShortenerHost(_hostOf(u))).toList();
    addIf(
      'short-url',
      'Contains a shortened link',
      'A shortened link hides the real destination until you open it.',
      3,
      shorteners,
    );

    final suspicious = urls
        .where(
          (u) =>
              !_isShortenerHost(_hostOf(u)) &&
              ThreatData.current.officialSiteFor(_hostOf(u)) == null &&
              _hasSuspiciousHost(u),
        )
        .toList();
    addIf(
      'suspicious-url',
      'Unusual web address',
      'The link uses an IP address, an odd domain ending or a long chain of '
          'subdomains that may imitate a real service.',
      4,
      suspicious,
    );

    // A message that is mostly a link with little text is often a drive-by scam.
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    final linkHeavy =
        urls.isNotEmpty && compact.length < urls.first.length * 3;
    addIf(
      'link-only',
      'Message is mostly a link',
      'Very little text around a link, with no context about the sender.',
      2,
      linkHeavy ? [urls.first] : const [],
    );

    final score = _scoreFor(indicators);
    return ScamFinding(
      indicators: indicators,
      level: _levelFor(score),
      urls: urls,
      score: score,
      suspectedScamType: _classify(indicators),
    );
  }

  List<String> _extractUrls(String input) {
    final matches = RegExp(
      r'(?:https?://|www\.)[^\s<>"“”]+|(?<![\w@.])[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|in|net|org|xyz|top|click|link|info|co|io|app|site|online|shop|store|live|me|ly|gl|ru|cc|tk|ml|ga|cf|gq)(?:/[^\s<>"“”]*)?',
      caseSensitive: false,
    ).allMatches(input);
    return matches
        .map((m) => m.group(0)!.replaceAll(RegExp(r'[.,;:!?)\]]+$'), ''))
        .where((u) => u.contains('.'))
        .toSet()
        .toList(growable: false);
  }

  bool _hasSuspiciousHost(String url) {
    final host = _hostOf(url);
    if (host.isEmpty) return false;
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) return true;
    final tld = host.split('.').last;
    if (UrlSafetyAnalyzer.suspiciousTlds.contains(tld)) return true;
    // A long, hyphen-heavy host with many labels is a common throwaway shape.
    if (host.split('.').length > 4) return true;
    if (host.split('-').length > 3) return true;
    return false;
  }

  String _hostOf(String url) {
    var value = url.trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    value = value.split('/').first.split('?').first.split('#').first;
    if (value.contains('@')) value = value.split('@').last;
    return value.split(':').first;
  }

  int _scoreFor(List<ScamIndicator> indicators) {
    if (indicators.isEmpty) return 0;
    var weight = 0;
    for (final indicator in indicators) {
      weight += indicator.weight;
    }
    return ((weight / (weight + 12)) * 100).round().clamp(0, 100);
  }

  /// Two strong signals (e.g. "account will be blocked" + "update your KYC")
  /// are enough for medium; a shortened link or urgency on top makes it high.
  RiskLevel _levelFor(int score) {
    if (score >= 60) return RiskLevel.high;
    if (score >= 30) return RiskLevel.medium;
    if (score > 0) return RiskLevel.low;
    return RiskLevel.safe;
  }

  String? _classify(List<ScamIndicator> indicators) {
    final ids = indicators.map((i) => i.id).toSet();
    if (ids.contains('otp') && ids.contains('impersonation')) {
      return 'Impersonation / digital-arrest style scam';
    }
    if (ids.contains('kyc')) return 'Fake KYC or bank message';
    if (ids.contains('job')) return 'Job or investment scam';
    if (ids.contains('reward')) return 'Prize or reward scam';
    if (ids.contains('impersonation') && ids.contains('payment')) {
      return 'Fake courier or fee scam';
    }
    if (ids.contains('payment')) return 'Payment request scam';
    if (ids.contains('otp')) return 'Credential theft attempt';
    if (ids.contains('threat') || ids.contains('block')) {
      return 'Account-blocking scam';
    }
    return null;
  }
}

/// Static, offline URL safety checks.
class UrlSafetyAnalyzer {
  const UrlSafetyAnalyzer();

  static const suspiciousTlds = {
    'xyz',
    'top',
    'click',
    'link',
    'work',
    'country',
    'gq',
    'tk',
    'ml',
    'cf',
    'ga',
    'zip',
    'mov',
    'icu',
    'buzz',
    'rest',
    'monster',
    'cfd',
    'sbs',
  };

  static const _impersonatingWords = [
    'bank',
    'kyc',
    'verify',
    'login',
    'signin',
    'secure',
    'account',
    'update',
    'confirm',
    'payment',
    'support',
    'helpdesk',
    'refund',
    'reward',
    'prize',
    'wallet',
    'upi',
    'paytm',
    'phonepe',
    'gpay',
    'sbi',
    'hdfc',
    'icici',
    'axis',
  ];

  UrlAnalysis analyze(String input) {
    final raw = input.trim().replaceAll(RegExp(r'[.,;:!?)\]]+$'), '');
    final checks = <UrlCheck>[];
    var score = 0;

    final lower = raw.toLowerCase();
    final hasScheme = lower.startsWith('http://') || lower.startsWith('https://');
    final isHttps = lower.startsWith('https://');
    final withoutScheme = raw.replaceFirst(
      RegExp(r'^https?://', caseSensitive: false),
      '',
    );
    final authority = withoutScheme.split('/').first.split('?').first.split('#').first;
    final host = _host(withoutScheme);
    final normalized = hasScheme ? raw : 'https://$raw';

    checks.add(
      UrlCheck(
        title: !hasScheme
            ? 'No scheme given'
            : isHttps
            ? 'Encrypted connection (HTTPS)'
            : 'Not encrypted (HTTP)',
        detail: !hasScheme
            ? 'The link does not say HTTP or HTTPS. Jemixo Safe assumes HTTPS when opening it.'
            : isHttps
            ? 'Data sent to this address is encrypted in transit.'
            : 'Anything you type on this page can be read in transit.',
        passed: !hasScheme || isHttps,
        weight: hasScheme && !isHttps ? 12 : 0,
      ),
    );

    final isIpAddress = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
    final labels = host.split('.').where((l) => l.isNotEmpty).toList();
    final tld = labels.length > 1 ? labels.last : '';

    final official = ThreatData.current.officialSiteFor(host);
    if (official != null && !isIpAddress) {
      checks.add(
        UrlCheck(
          title: 'Official domain of ${official.name}',
          detail:
              '"${official.domain}" is on the Jemixo Safe list of verified '
              'official sites. Look-alikes use a different ending or extra words.',
          passed: true,
          weight: 0,
        ),
      );
    }

    final blocked = ThreatData.current.isBlockedDomain(host);
    if (blocked) {
      checks.add(
        const UrlCheck(
          title: 'Known scam domain',
          detail:
              'This address is on the Jemixo Safe scam-domain list, which is '
              'updated from reported phishing sites. Do not open it.',
          passed: false,
          weight: 60,
        ),
      );
    }

    checks.add(
      UrlCheck(
        title: isIpAddress ? 'Uses a raw IP address' : 'Uses a named domain',
        detail: isIpAddress
            ? 'Legitimate services almost always use a domain name, not a number.'
            : 'The address is a normal domain name.',
        passed: !isIpAddress,
        weight: isIpAddress ? 18 : 0,
      ),
    );

    final isShortener = _isShortenerHost(host);
    checks.add(
      UrlCheck(
        title: isShortener ? 'Shortened link' : 'Full link shown',
        detail: isShortener
            ? 'The real destination is hidden until you open the link.'
            : 'You can see the full destination before opening it.',
        passed: !isShortener,
        weight: isShortener ? 16 : 0,
      ),
    );

    final suspiciousTld = suspiciousTlds.contains(tld);
    checks.add(
      UrlCheck(
        title: suspiciousTld
            ? 'Domain ending often used by throwaway sites'
            : 'Common domain ending',
        detail: suspiciousTld
            ? '.${tld.toUpperCase()} is inexpensive and heavily associated with short-lived scam sites.'
            : tld.isEmpty
            ? 'No domain ending could be read from this address.'
            : '.${tld.toUpperCase()} is a widely used domain ending.',
        passed: !suspiciousTld,
        weight: suspiciousTld ? 16 : 0,
      ),
    );

    final hasAt = authority.contains('@');
    checks.add(
      UrlCheck(
        title: hasAt
            ? 'Contains "@" before the domain'
            : 'No embedded credentials',
        detail: hasAt
            ? 'Text before "@" is ignored by browsers, so "bank.com@evil.xyz" really goes to evil.xyz.'
            : 'The link does not try to hide its destination.',
        passed: !hasAt,
        weight: hasAt ? 22 : 0,
      ),
    );

    final punycode = host.contains('xn--');
    checks.add(
      UrlCheck(
        title: punycode ? 'Punycode domain' : 'Standard character encoding',
        detail: punycode
            ? 'Punycode domains can display almost any text and are used to imitate real sites.'
            : 'The domain uses normal characters.',
        passed: !punycode,
        weight: punycode ? 20 : 0,
      ),
    );

    final deepSubdomain = labels.length > 4;
    checks.add(
      UrlCheck(
        title: deepSubdomain
            ? 'Unusually long subdomain chain'
            : 'Simple domain structure',
        detail: deepSubdomain
            ? 'Only the last two parts ("${labels.length >= 2 ? '${labels[labels.length - 2]}.${labels.last}' : host}") identify the real owner. Everything before them can say anything.'
            : 'The domain structure is straightforward.',
        passed: !deepSubdomain,
        weight: deepSubdomain ? 12 : 0,
      ),
    );

    final hyphenHeavy = host.split('-').length > 2;
    final registrable = labels.length >= 2
        ? '${labels[labels.length - 2]}.${labels.last}'
        : host;
    final brandWords = official != null
        ? const <String>[]
        : _impersonatingWords.where((word) => host.contains(word)).toList();
    // Brand words are only alarming when the domain also looks disposable:
    // "support.google.com" is fine, "google-support-verify.xyz" is not.
    final brandInSubdomainOnly =
        brandWords.isNotEmpty &&
        !brandWords.any((w) => registrable.contains(w));
    final impersonating =
        brandWords.isNotEmpty &&
        (hyphenHeavy || suspiciousTld || deepSubdomain || isIpAddress || brandInSubdomainOnly && labels.length > 3);
    checks.add(
      UrlCheck(
        title: brandWords.isEmpty
            ? 'No brand words in the domain'
            : impersonating
            ? 'Domain mentions "${brandWords.first}" but looks disposable'
            : 'Domain mentions "${brandWords.first}"',
        detail: brandWords.isEmpty
            ? 'The domain does not reference a bank, wallet or account keyword.'
            : impersonating
            ? 'Real services put the brand in their registered domain, not in a hyphenated or throwaway one.'
            : 'Check that "$registrable" is the organisation\'s real domain before signing in.',
        passed: !impersonating,
        weight: impersonating ? 22 : 0,
      ),
    );

    checks.add(
      UrlCheck(
        title: hyphenHeavy ? 'Many hyphens in the domain' : 'Clean domain characters',
        detail: hyphenHeavy
            ? 'Hyphenated names like "secure-bank-login" are typical of phishing domains; real brands rarely need them.'
            : 'The domain uses only letters, numbers, dots and a hyphen at most.',
        passed: !hyphenHeavy,
        weight: hyphenHeavy ? 10 : 0,
      ),
    );

    final asciiHost = host.replaceAll(RegExp(r'xn--[a-z0-9]+'), '');
    final unusualChars = asciiHost.contains(RegExp(r'[^a-z0-9.\-]'));
    checks.add(
      UrlCheck(
        title: unusualChars
            ? 'Unusual characters in the domain'
            : 'Standard domain characters',
        detail: unusualChars
            ? 'Unusual characters can be used to confuse you when reading the address.'
            : 'No look-alike characters were found.',
        passed: !unusualChars,
        weight: unusualChars ? 12 : 0,
      ),
    );

    for (final check in checks) {
      score += check.weight;
    }

    return UrlAnalysis(
      original: input,
      normalized: normalized,
      host: host,
      isHttps: isHttps,
      hasScheme: hasScheme,
      checks: checks,
      level: _levelFor(score),
      score: score.clamp(0, 100),
      officialName: official?.name,
    );
  }

  String _host(String withoutScheme) {
    var value = withoutScheme
        .split('/')
        .first
        .split('?')
        .first
        .split('#')
        .first;
    if (value.contains('@')) value = value.split('@').last;
    value = value.split(':').first;
    return value.toLowerCase();
  }

  RiskLevel _levelFor(int score) {
    if (score >= 45) return RiskLevel.high;
    if (score >= 22) return RiskLevel.medium;
    if (score > 0) return RiskLevel.low;
    return RiskLevel.safe;
  }
}

class UrlCheck {
  const UrlCheck({
    required this.title,
    required this.detail,
    required this.passed,
    required this.weight,
  });

  final String title;
  final String detail;
  final bool passed;
  final int weight;
}

class UrlAnalysis {
  const UrlAnalysis({
    required this.original,
    required this.normalized,
    required this.host,
    required this.isHttps,
    required this.hasScheme,
    required this.checks,
    required this.level,
    required this.score,
    this.officialName,
  });

  /// Set when the host is on the verified official-domain list.
  final String? officialName;

  bool get isOfficial => officialName != null;

  final String original;

  /// The address as it will be opened (scheme added when missing).
  final String normalized;
  final String host;
  final bool isHttps;
  final bool hasScheme;
  final List<UrlCheck> checks;
  final RiskLevel level;
  final int score;

  List<UrlCheck> get failures =>
      checks.where((c) => !c.passed).toList(growable: false);

  /// A live reputation lookup would need a third-party service; V1 stays local.
  String get verdict {
    if (isOfficial && level == RiskLevel.safe) return 'Official site: $officialName';
    return switch (level) {
      RiskLevel.high || RiskLevel.critical => 'Do not open this link',
      RiskLevel.medium => 'Review before opening',
      RiskLevel.low => 'Minor concerns found',
      _ => 'No obvious problems found locally',
    };
  }
}
