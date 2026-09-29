import 'package:flutter/foundation.dart';

import '../../core/theme/risk_palette.dart';
import '../../services/device_service/device_service.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../services/risk_engine/text_analyzers.dart';

/// Aggregated health indicator for the dashboard.
class HealthSummary {
  const HealthSummary({
    required this.batteryLevel,
    required this.batteryLabel,
    required this.storagePressure,
    required this.networkQuality,
    required this.networkLabel,
    required this.securityLevel,
    required this.deviceSecure,
  });

  final RiskLevel batteryLevel;
  final String batteryLabel;
  final RiskLevel storagePressure;
  final RiskLevel networkQuality;
  final String networkLabel;
  final RiskLevel securityLevel;
  final bool deviceSecure;
}

/// One-shot tools (scam scanner, URL checker) keep their text here so a rebuild
/// never loses what the user typed.
class ToolsController extends ChangeNotifier {
  ToolsController();

  ScamFinding? _scam;
  UrlAnalysis? _url;
  String _scamInput = '';
  String _urlInput = '';

  ScamFinding? get scam => _scam;
  UrlAnalysis? get url => _url;
  String get scamInput => _scamInput;
  String get urlInput => _urlInput;

  void analyzeScam(String text) {
    _scamInput = text;
    _scam = text.trim().isEmpty ? null : const ScamTextScanner().analyze(text);
    notifyListeners();
  }

  void analyzeUrl(String text) {
    _urlInput = text;
    _url = text.trim().isEmpty ? null : const UrlSafetyAnalyzer().analyze(text);
    notifyListeners();
  }

  void clearScam() {
    _scamInput = '';
    _scam = null;
    notifyListeners();
  }

  void clearUrl() {
    _urlInput = '';
    _url = null;
    notifyListeners();
  }
}

HealthSummary buildHealthSummary({
  required DeviceService device,
  required StorageService storage,
  required int? securityScore,
}) {
  final battery = device.battery;
  final percent = battery?.percent;
  final batteryLevel = switch (percent) {
    null => RiskLevel.medium,
    final int p when p <= 15 => RiskLevel.high,
    final int p when p <= 25 => RiskLevel.medium,
    _ => RiskLevel.safe,
  };
  final batteryLabel = percent == null
      ? 'Unknown'
      : battery!.isCharging
      ? '$percent% charging'
      : '$percent%';

  final quality = ConnectionQuality.from(device.network);

  return HealthSummary(
    batteryLevel: batteryLevel,
    batteryLabel: batteryLabel,
    storagePressure: storage.storagePressure(),
    networkQuality: quality.level,
    networkLabel: quality.label,
    securityLevel: securityScore == null
        ? RiskLevel.medium
        : RiskPalette.levelForScore(securityScore),
    deviceSecure: device.security?.deviceSecure ?? false,
  );
}
