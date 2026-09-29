import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/settings_repository.dart';

/// A brand that scammers imitate, with the packages allowed to carry its name.
class BrandRule {
  const BrandRule({
    required this.keyword,
    required this.brand,
    required this.packages,
    required this.prefixes,
  });

  final String keyword;
  final String brand;
  final Set<String> packages;
  final List<String> prefixes;

  bool allows(String packageName) =>
      packages.contains(packageName) ||
      prefixes.any((p) => packageName.startsWith(p));

  factory BrandRule.fromJson(Map<String, dynamic> json) => BrandRule(
    keyword: (json['keyword'] as String).toLowerCase(),
    brand: json['brand'] as String,
    packages: _stringList(json['packages']).toSet(),
    prefixes: _stringList(json['prefixes']),
  );
}

class OfficialApp {
  const OfficialApp({
    required this.packageName,
    required this.name,
    required this.brand,
    required this.category,
    this.sha256,
  });

  final String packageName;
  final String name;
  final String brand;

  /// bank, upi, wallet, lender, government, other.
  final String category;

  /// Upper-case SHA-256 of the signing certificate when known.
  final String? sha256;

  factory OfficialApp.fromJson(Map<String, dynamic> json) => OfficialApp(
    packageName: json['package'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String? ?? json['name'] as String,
    category: json['category'] as String? ?? 'other',
    sha256: (json['sha256'] as String?)?.toUpperCase(),
  );
}

class LoanApp {
  const LoanApp({
    required this.packageName,
    required this.name,
    required this.lender,
    required this.regulator,
  });

  final String packageName;
  final String name;
  final String lender;
  final String regulator;

  factory LoanApp.fromJson(Map<String, dynamic> json) => LoanApp(
    packageName: json['package'] as String,
    name: json['name'] as String,
    lender: json['lender'] as String? ?? '',
    regulator: json['regulator'] as String? ?? '',
  );
}

class RadarItem {
  const RadarItem({
    required this.id,
    required this.title,
    required this.body,
    this.date,
  });

  final String id;
  final String title;
  final String body;
  final String? date;

  factory RadarItem.fromJson(Map<String, dynamic> json) => RadarItem(
    id: json['id'] as String? ?? json['title'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    date: json['date'] as String?,
  );
}

class Helpline {
  const Helpline({required this.name, required this.kind, this.number, this.url, this.note});

  final String name;

  /// cyber, telecom, rbi, bank, upi.
  final String kind;
  final String? number;
  final String? url;
  final String? note;

  factory Helpline.fromJson(Map<String, dynamic> json) => Helpline(
    name: json['name'] as String,
    kind: json['kind'] as String? ?? 'other',
    number: json['number'] as String?,
    url: json['url'] as String?,
    note: json['note'] as String?,
  );
}

class OfficialDomain {
  const OfficialDomain({required this.domain, required this.name});

  final String domain;
  final String name;

  bool matches(String host) => host == domain || host.endsWith('.$domain');

  factory OfficialDomain.fromJson(Map<String, dynamic> json) => OfficialDomain(
    domain: (json['domain'] as String).toLowerCase(),
    name: json['name'] as String,
  );
}

List<String> _stringList(dynamic raw) =>
    (raw as List<dynamic>? ?? const []).map((e) => e.toString()).toList();

/// Everything the analyzers need that changes faster than an app release:
/// phrases, brand rules, official/loan app lists, blocked domains, radar.
class ThreatData {
  const ThreatData({
    required this.version,
    required this.updatedAt,
    required this.phrases,
    required this.blockedDomains,
    required this.brands,
    required this.officialApps,
    required this.loanApps,
    required this.loanKeywords,
    required this.upiHandles,
    required this.radar,
    required this.helplines,
    this.officialDomains = const [],
    this.suspiciousCountryCodes = const {},
  });

  static const empty = ThreatData(
    version: 0,
    updatedAt: '',
    phrases: {},
    blockedDomains: {},
    brands: [],
    officialApps: {},
    loanApps: {},
    loanKeywords: [],
    upiHandles: {},
    radar: [],
    helplines: [],
  );

  /// The data set the analyzers read. Replaced atomically on load/refresh.
  static ThreatData current = empty;

  final int version;
  final String updatedAt;
  final Map<String, List<String>> phrases;
  final Set<String> blockedDomains;
  final List<BrandRule> brands;
  final Map<String, OfficialApp> officialApps;
  final Map<String, LoanApp> loanApps;
  final List<String> loanKeywords;
  final Set<String> upiHandles;
  final List<RadarItem> radar;
  final List<Helpline> helplines;
  final List<OfficialDomain> officialDomains;

  /// Country calling code → country name, for the caller check.
  final Map<String, String> suspiciousCountryCodes;

  /// The official organisation behind [host], when it is on the allowlist.
  OfficialDomain? officialSiteFor(String host) {
    final h = host.toLowerCase();
    for (final d in officialDomains) {
      if (d.matches(h)) return d;
    }
    return null;
  }

  List<String> phrasesFor(String category) => phrases[category] ?? const [];

  bool isBlockedDomain(String host) {
    final h = host.toLowerCase();
    return blockedDomains.any((d) => h == d || h.endsWith('.$d'));
  }

  factory ThreatData.fromJson(Map<String, dynamic> json) {
    final phrases = <String, List<String>>{};
    for (final entry in (json['phrases'] as Map<String, dynamic>? ?? const {}).entries) {
      phrases[entry.key] = _stringList(entry.value).map((p) => p.toLowerCase()).toList();
    }
    final official = <String, OfficialApp>{};
    for (final raw in json['officialApps'] as List<dynamic>? ?? const []) {
      final app = OfficialApp.fromJson(raw as Map<String, dynamic>);
      official[app.packageName] = app;
    }
    final loans = <String, LoanApp>{};
    for (final raw in json['loanApps'] as List<dynamic>? ?? const []) {
      final app = LoanApp.fromJson(raw as Map<String, dynamic>);
      loans[app.packageName] = app;
    }
    return ThreatData(
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String? ?? '',
      phrases: phrases,
      blockedDomains: _stringList(json['blockedDomains']).map((d) => d.toLowerCase()).toSet(),
      brands: (json['brands'] as List<dynamic>? ?? const [])
          .map((e) => BrandRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      officialApps: official,
      loanApps: loans,
      loanKeywords: _stringList(json['loanKeywords']).map((k) => k.toLowerCase()).toList(),
      upiHandles: _stringList(json['upiHandles']).map((h) => h.toLowerCase()).toSet(),
      radar: (json['radar'] as List<dynamic>? ?? const [])
          .map((e) => RadarItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      helplines: (json['helplines'] as List<dynamic>? ?? const [])
          .map((e) => Helpline.fromJson(e as Map<String, dynamic>))
          .toList(),
      officialDomains: (json['officialDomains'] as List<dynamic>? ?? const [])
          .map((e) => OfficialDomain.fromJson(e as Map<String, dynamic>))
          .toList(),
      suspiciousCountryCodes: {
        for (final entry
            in ((json['callRules'] as Map<String, dynamic>?)?['suspiciousCountryCodes']
                        as Map<String, dynamic>? ??
                    const {})
                .entries)
          entry.key: entry.value.toString(),
      },
    );
  }
}

/// Loads the bundled data set, prefers a newer cached copy, and refreshes it
/// from the project's own static JSON at most once a week. No third-party
/// service is involved: the URL is a file the project publishes itself.
class ThreatDataService extends ChangeNotifier {
  ThreatDataService(this._settings);

  static const _kLastCheck = 'threat_data_last_check';
  static const _cacheFile = 'threat_data.json';

  final SettingsRepository _settings;

  ThreatData _data = ThreatData.empty;
  bool _loaded = false;
  bool _updating = false;
  String? _lastError;
  DateTime? _lastChecked;
  String _source = 'bundled';

  ThreatData get data => _data;
  bool get isLoaded => _loaded;
  bool get isUpdating => _updating;
  String? get lastError => _lastError;
  DateTime? get lastChecked => _lastChecked;

  /// "bundled" or "downloaded".
  String get source => _source;

  Future<void> load() async {
    try {
      final bundled = ThreatData.fromJson(
        jsonDecode(await rootBundle.loadString('assets/data/threat_data.json'))
            as Map<String, dynamic>,
      );
      _apply(bundled, 'bundled');

      final cached = await _readCache();
      if (cached != null && cached.version > bundled.version) {
        _apply(cached, 'downloaded');
      }
      final stamp = await _settings.readInt(_kLastCheck);
      if (stamp > 0) _lastChecked = DateTime.fromMillisecondsSinceEpoch(stamp);
    } catch (error) {
      _lastError = 'Could not load threat data: $error';
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Refreshes when the last check is older than a week.
  Future<void> maybeRefresh() async {
    final last = _lastChecked;
    if (last != null && DateTime.now().difference(last).inDays < 7) return;
    await refresh();
  }

  /// Downloads the published JSON and keeps it only when it is newer.
  Future<bool> refresh() async {
    if (_updating) return false;
    final url = AppConstants.threatDataUrl;
    if (url.isEmpty) return false;
    _updating = true;
    _lastError = null;
    notifyListeners();
    var applied = false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close().timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}');
        }
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final fresh = ThreatData.fromJson(decoded);
        if (fresh.version > _data.version) {
          await _writeCache(body);
          _apply(fresh, 'downloaded');
          applied = true;
        }
      } finally {
        client.close(force: true);
      }
      _lastChecked = DateTime.now();
      await _settings.writeInt(_kLastCheck, _lastChecked!.millisecondsSinceEpoch);
    } catch (error) {
      _lastError = 'Update check failed: $error';
    } finally {
      _updating = false;
      notifyListeners();
    }
    return applied;
  }

  void _apply(ThreatData data, String source) {
    _data = data;
    _source = source;
    ThreatData.current = data;
  }

  Future<File> _cachePath() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_cacheFile');
  }

  Future<ThreatData?> _readCache() async {
    try {
      final file = await _cachePath();
      if (!await file.exists()) return null;
      return ThreatData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String body) async {
    try {
      final file = await _cachePath();
      await file.writeAsString(body, flush: true);
    } catch (_) {
      // Cache is best effort; the in-memory copy still applies.
    }
  }
}
