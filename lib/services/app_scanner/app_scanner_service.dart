import 'package:flutter/foundation.dart';

import '../../core/permissions/permission_catalog.dart';
import '../../core/theme/risk_palette.dart';
import '../platform/native_bridge.dart';
import '../platform/native_models.dart';
import '../risk_engine/app_identity.dart';
import '../risk_engine/risk_engine.dart';
import '../threat_data/threat_data.dart';

/// Permission-centric view of the installed app inventory.
class PermissionUsage {
  const PermissionUsage({required this.category, required this.apps});

  final PermissionCategory category;
  final List<AppInfo> apps;

  int get count => apps.length;

  bool get isSensitive => category.sensitivityWeight > 0;
}

class AppScannerService extends ChangeNotifier {
  AppScannerService({
    NativeBridge? bridge,
    PrivacyEngine? privacyEngine,
    bool Function()? flagDebuggable,
  }) : _bridge = bridge ?? NativeBridge.instance,
       _privacyEngine = privacyEngine ?? const PrivacyEngine(),
       _flagDebuggable = flagDebuggable ?? (() => true);

  final NativeBridge _bridge;
  final PrivacyEngine _privacyEngine;
  final bool Function() _flagDebuggable;

  List<AppInfo> _allApps = const [];
  List<AppRiskAssessment> _assessments = const [];
  Map<String, AppRiskAssessment> _byPackage = const {};
  Map<String, int> _privacyScores = const {};
  bool _scanning = false;
  String? _lastError;
  bool _visibilityLimited = false;
  SpecialAccess _specialAccess = const SpecialAccess();

  /// Apps holding accessibility, notification access or device admin.
  SpecialAccess get specialAccess => _specialAccess;

  DeviceContext get _deviceContext => DeviceContext(
    accessibilityPackages: _specialAccess.accessibilityPackages,
    notificationListenerPackages: _specialAccess.listenerPackages,
    deviceAdminPackages: _specialAccess.adminPackages,
  );


  bool get isScanning => _scanning;
  String? get lastError => _lastError;
  bool get hasScanned => _allApps.isNotEmpty;

  /// True when Android only exposes launchable apps (no QUERY_ALL_PACKAGES).
  bool get visibilityLimited => _visibilityLimited;

  AppIdentityChecker get _identity => AppIdentityChecker(ThreatData.current);

  // Derived lists are computed once per scan / reassess, not per widget build.
  List<AppInfo> _impersonating = const [];
  List<AppInfo> _unlistedLoans = const [];
  List<AppInfo> _listedFinance = const [];
  List<AppInfo> _hidden = const [];
  List<AppRiskAssessment> _needsReview = const [];
  Map<String, String> _impersonatedBrand = const {};

  /// Installed apps that borrow a bank / payment brand name.
  List<AppInfo> get impersonatingApps => _impersonating;

  /// Loan-looking apps that are not on the regulated-lender list.
  List<AppInfo> get unlistedLoanApps => _unlistedLoans;

  /// Installed apps that are on the regulated-lender or official list.
  List<AppInfo> get listedFinanceApps => _listedFinance;

  /// Non-system apps with no launcher icon that ask for spying-type access.
  List<AppInfo> get hiddenApps => _hidden;

  /// Which brand an app imitates, if any.
  String? impersonatedBrandFor(AppInfo app) => _impersonatedBrand[app.packageName];

  void _deriveLists() {
    final identity = _identity;
    final official = ThreatData.current.officialApps;
    final impersonating = <AppInfo>[];
    final loans = <AppInfo>[];
    final listed = <AppInfo>[];
    final brands = <String, String>{};
    for (final app in _allApps) {
      final brand = identity.impersonatedBrand(app);
      if (brand != null) brands[app.packageName] = brand.brand;
      if (brand != null || identity.hasSignatureMismatch(app)) impersonating.add(app);
      if (identity.isUnlistedLoanApp(app)) loans.add(app);
      if (!app.isSystemApp &&
          (identity.isListedLender(app) || official.containsKey(app.packageName))) {
        listed.add(app);
      }
    }
    _impersonating = impersonating;
    _unlistedLoans = loans;
    _listedFinance = listed;
    _impersonatedBrand = brands;
    _hidden = _assessments
        .where((a) => a.indicators.any((i) => i.id == 'hidden-spy'))
        .map((a) => a.app)
        .toList(growable: false);
    _needsReview = _assessments.where((a) => a.needsReview).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  List<AppInfo> get allApps => _allApps;
  List<AppRiskAssessment> get assessments => _assessments;
  List<AppInfo> get userApps =>
      _allApps.where((a) => !a.isSystemApp).toList(growable: false);
  List<AppInfo> get systemApps =>
      _allApps.where((a) => a.isSystemApp).toList(growable: false);

  List<AppRiskAssessment> get needsReview => _needsReview;

  List<AppRiskAssessment> get highRisk => _assessments
      .where((a) => a.level == RiskLevel.high)
      .toList(growable: false);

  List<AppRiskAssessment> get mediumRisk => _assessments
      .where((a) => a.level == RiskLevel.medium)
      .toList(growable: false);

  List<AppRiskAssessment> get lowRisk => _assessments
      .where((a) => a.level == RiskLevel.low)
      .toList(growable: false);

  List<PermissionUsage> get permissionUsage {
    final buckets = <PermissionCategory, List<AppInfo>>{};
    for (final app in _allApps) {
      if (app.isSystemApp) continue;
      for (final permission in app.permissions) {
        final definition = resolvePermission(permission);
        if (definition == null) continue;
        buckets.putIfAbsent(definition.category, () => []).add(app);
      }
    }
    final usage = buckets.entries
        .map(
          (entry) => PermissionUsage(
            category: entry.key,
            apps: _uniqueByPackage(entry.value),
          ),
        )
        .toList();
    usage.sort((a, b) {
      final byWeight = b.category.sensitivityWeight.compareTo(
        a.category.sensitivityWeight,
      );
      return byWeight != 0 ? byWeight : b.count.compareTo(a.count);
    });
    return usage;
  }

  /// Apps ranked by how invasive their requested permissions are.
  List<AppInfo> get appsByPrivacyRisk {
    final scored = _allApps.where((a) => !a.isSystemApp).toList()
      ..sort(
        (a, b) => privacyScoreFor(b).compareTo(privacyScoreFor(a)),
      );
    return scored;
  }

  List<String> privacyReasons(AppInfo app) => _privacyEngine.reasons(app);

  int privacyScoreFor(AppInfo app) =>
      _privacyScores[app.packageName] ?? _privacyEngine.scoreFor(app);

  RiskLevel privacyLevelFor(int score) => _privacyEngine.levelFor(score);

  /// Average privacy score across user apps. System apps are excluded because
  /// their permission lists reflect platform internals, not user choice.
  int get privacyScore {
    final apps = userApps;
    if (apps.isEmpty) return 100;
    final total = apps.fold<int>(0, (sum, app) => sum + privacyScoreFor(app));
    final average = total / apps.length;
    // Lower average invasiveness = higher score.
    return (100 - average).round().clamp(0, 100);
  }

  Future<void> scan() async {
    if (_scanning) return;
    _scanning = true;
    _lastError = null;
    notifyListeners();

    try {
      try {
        final visibility = await _bridge.getPackageVisibility();
        _visibilityLimited = visibility != null && visibility['full'] != true;
      } on NativeBridgeException {
        _visibilityLimited = false;
      }
      try {
        _specialAccess = SpecialAccess.fromMap(await _bridge.getSpecialAccess());
      } on NativeBridgeException {
        _specialAccess = const SpecialAccess();
      }
      final raw = await _bridge.getInstalledApps();
      if (raw.isEmpty) {
        _lastError =
            'Android did not return any installed apps. This usually means the '
            'package list is restricted on this device.';
        _allApps = const [];
        _assessments = const [];
        _byPackage = const {};
        _privacyScores = const {};
        _deriveLists();
      } else {
        final engine = RiskEngine(
          flagDebuggable: _flagDebuggable(),
          device: _deviceContext,
        );
        final apps = raw.map(AppInfo.fromMap).toList(growable: false);
        final assessments = apps.map(engine.assess).toList(growable: false);
        _allApps = apps;
        _assessments = assessments;
        _byPackage = {for (final a in assessments) a.app.packageName: a};
        _privacyScores = {
          for (final app in apps) app.packageName: _privacyEngine.scoreFor(app),
        };
        _deriveLists();
      }
    } on NativeBridgeException catch (error) {
      _lastError = 'Scan failed (${error.code}): ${error.message}';
    } catch (error) {
      _lastError = 'Scan failed: $error';
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  /// Re-evaluates the current inventory without another platform round trip,
  /// for example after the debuggable-flag setting changes.
  void reassess() {
    if (_allApps.isEmpty) return;
    final engine = RiskEngine(
      flagDebuggable: _flagDebuggable(),
      device: _deviceContext,
    );
    _assessments = _allApps.map(engine.assess).toList(growable: false);
    _byPackage = {for (final a in _assessments) a.app.packageName: a};
    _deriveLists();
    notifyListeners();
  }

  Future<AppInfo?> lookup(String packageName) async {
    try {
      final map = await _bridge.getAppDetails(packageName);
      return map == null ? null : AppInfo.fromMap(map);
    } on NativeBridgeException {
      return null;
    }
  }

  Future<bool> openAppSettings(String packageName) =>
      _bridge.openAppSettings(packageName);

  Future<bool> openAppUninstall(String packageName) =>
      _bridge.openAppUninstall(packageName);

  List<AppInfo> filter({
    required AppFilter filter,
    AppSort sort = AppSort.name,
  }) {
    final list = switch (filter) {
      AppFilter.all => _allApps.toList(),
      AppFilter.user => userApps.toList(),
      AppFilter.system => systemApps.toList(),
      AppFilter.highRisk => highRisk.map((a) => a.app).toList(),
      AppFilter.mediumRisk => mediumRisk.map((a) => a.app).toList(),
      AppFilter.lowRisk => lowRisk.map((a) => a.app).toList(),
      AppFilter.sideloaded => _allApps
          .where((a) => a.isSideloaded && !a.isSystemApp)
          .toList(),
      AppFilter.large => _allApps
          .where((a) => (a.sizeBytes ?? 0) > 100 * 1024 * 1024)
          .toList(),
    };

    switch (sort) {
      case AppSort.name:
        list.sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
      case AppSort.size:
        list.sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));
      case AppSort.risk:
        list.sort((a, b) {
          final byRisk = _riskScoreFor(b).compareTo(_riskScoreFor(a));
          if (byRisk != 0) return byRisk;
          return privacyScoreFor(b).compareTo(privacyScoreFor(a));
        });
      case AppSort.recent:
        list.sort((a, b) => (b.installTime ?? 0).compareTo(a.installTime ?? 0));
    }
    return list;
  }

  int _riskScoreFor(AppInfo app) => _byPackage[app.packageName]?.score ?? 0;

  AppRiskAssessment? assessmentFor(String packageName) => _byPackage[packageName];

  /// Summary counts for the Security screen checklist.
  int get debuggableAppCount =>
      _allApps.where((a) => a.debuggable && !a.isSystemApp).length;

  int get sideloadedAppCount =>
      _allApps.where((a) => a.isSideloaded && !a.isSystemApp).length;

  int get elevatedAccessCount {
    var count = 0;
    for (final app in _allApps) {
      if (app.isSystemApp) continue;
      if (app.permissions.any(isElevatedPermission)) count++;
    }
    return count;
  }

  /// Apps with permission pairings that the engine treats as serious.
  int get combinedPatternCount => _assessments
      .where((a) => a.indicators.any((i) => i.id == 'sms+contacts' || i.id == 'background-location'))
      .length;

  static List<AppInfo> _uniqueByPackage(List<AppInfo> apps) {
    final seen = <String>{};
    return apps
        .where((app) => seen.add(app.packageName))
        .toList(growable: false);
  }
}

enum AppFilter {
  all,
  user,
  system,
  highRisk,
  mediumRisk,
  lowRisk,
  sideloaded,
  large;

  String get label => switch (this) {
    AppFilter.all => 'All apps',
    AppFilter.user => 'User apps',
    AppFilter.system => 'System apps',
    AppFilter.highRisk => 'High risk',
    AppFilter.mediumRisk => 'Medium risk',
    AppFilter.lowRisk => 'Low risk',
    AppFilter.sideloaded => 'Sideloaded',
    AppFilter.large => 'Large apps',
  };
}

enum AppSort {
  name,
  size,
  risk,
  recent;

  String get label => switch (this) {
    AppSort.name => 'Name',
    AppSort.size => 'Size',
    AppSort.risk => 'Risk',
    AppSort.recent => 'Recently added',
  };
}
