import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/device_service/device_service.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../services/threat_data/threat_data.dart';
import '../../state/dashboard_controller.dart';
import '../../state/security_controller.dart';
import '../../widgets/app_widgets.dart';
import '../device_health/device_health_page.dart';
import '../emergency/emergency_page.dart';
import '../more/more_page.dart';
import '../emergency/scam_call_page.dart';
import '../history/changes_page.dart';
import '../privacy/finance_apps_page.dart';
import '../privacy/special_access_page.dart';
import '../qr_scanner/qr_scanner_page.dart';
import '../scam_scanner/call_check_page.dart';
import '../scam_scanner/screenshot_check_page.dart';
import '../network/network_page.dart';
import '../scam_scanner/scam_scanner_page.dart';
import '../security/security_page.dart';
import '../settings/settings_page.dart';
import '../storage/storage_page.dart';
import '../storage/whatsapp_cleaner_page.dart';
import '../url_checker/url_checker_page.dart';

/// Home tab. Answers "is anything wrong right now?" in one screen, then routes
/// into the tool that resolves it.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final security = context.read<SecurityController>();
      if (security.lastScanAt == null) _scan(security);
      context.read<StorageService>().refreshOverview();
    });
  }

  Future<void> _scan(SecurityController security) async {
    await security.runScan();
    if (!mounted) return;
    if (security.lastError != null) {
      AppHaptics.warning(context);
    } else {
      AppHaptics.success(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<AppScannerService>();
    final security = context.watch<SecurityController>();
    final device = context.watch<DeviceService>();
    final storage = context.watch<StorageService>();
    final threat = context.watch<ThreatDataService>();
    final theme = Theme.of(context);
    final s = Strings.of(context);

    final score = security.score;
    final fakes = scanner.impersonatingApps.length + scanner.unlistedLoanApps.length;
    final special = scanner.specialAccess.userAppCount + scanner.hiddenApps.length;
    final health = buildHealthSummary(
      device: device,
      storage: storage,
      securityScore: score,
    );
    final needsReview = scanner.needsReview.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Row(
          children: [
            const _ShieldMark(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.appName, style: AppTypography.pageTitle),
                Text(
                  s.tagline,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _open(context, const SettingsPage()),
            icon: const Icon(Icons.settings_outlined),
            tooltip: s.settings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _scan(security),
            device.refresh(),
            storage.refreshOverview(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.tight,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          children: [
            _ScoreCard(
              score: score,
              isScanning: security.isRunning,
              lastScanAt: security.lastScanAt,
              needsReview: needsReview,
              error: security.lastError,
              onScan: () => _scan(security),
            ),
            if (fakes > 0) ...[
              const SizedBox(height: AppSpacing.standard),
              CriticalBanner(
                title: s.isHindi
                    ? '$fakes संदिग्ध बैंकिंग या लोन ऐप'
                    : '$fakes suspicious finance app${fakes == 1 ? '' : 's'}',
                message: s.isHindi
                    ? 'नकली बैंक या बिना लाइसेंस वाला लोन ऐप मिला है। उपयोग से पहले जाँच करें।'
                    : 'A look-alike bank / payment app or an unlisted loan app is installed. Review it before you sign in or borrow.',
                actionLabel: s.reviewNow,
                onAction: () => _open(context, const FinanceAppsPage()),
              ),
            ],
            if (special > 0) ...[
              const SizedBox(height: AppSpacing.standard),
              WarningBanner(
                title: s.isHindi
                    ? '$special विशेष अनुमति वाले ऐप्स'
                    : '$special app${special == 1 ? '' : 's'} with special access',
                message: s.isHindi
                    ? 'कोई ऐप आपकी स्क्रीन या नोटिफ़िकेशन पढ़ सकता है या डिवाइस एडमिन बना हुआ है।'
                    : 'An app can read your screen or notifications, is a device admin, or is hidden with spying-type permissions.',
                actionLabel: s.review,
                onAction: () => _open(context, const SpecialAccessPage()),
              ),
            ],
            const SizedBox(height: AppSpacing.standard),
            _HealthGrid(health: health),
            SectionHeader(title: s.checkBeforeYouAct),
            _QuickTool(
              icon: Icons.fact_check_outlined,
              title: s.scamScannerTitle,
              subtitle: s.scamScannerSub,
              onTap: () => _open(context, const ScamScannerPage()),
            ),
            _QuickTool(
              icon: Icons.document_scanner_outlined,
              title: s.checkScreenshotTitle,
              subtitle: s.checkScreenshotSubtitle,
              onTap: () => _open(context, const ScreenshotCheckPage()),
            ),
            _QuickTool(
              icon: Icons.call_outlined,
              title: s.checkPhoneTitle,
              subtitle: s.checkPhoneSubtitle,
              onTap: () => _open(context, const CallCheckPage()),
            ),
            _QuickTool(
              icon: Icons.link_outlined,
              title: s.checkUrlTitle,
              subtitle: s.checkUrlSubtitle,
              onTap: () => _open(context, const UrlCheckerPage()),
            ),
            _QuickTool(
              icon: Icons.qr_code_scanner_rounded,
              title: s.checkQrTitle,
              subtitle: s.checkQrSubtitle,
              onTap: () => _open(context, const QrScannerPage()),
            ),
            FeatureCard(
              icon: Icons.phone_in_talk_rounded,
              title: s.threatCallTitle,
              subtitle: s.threatCallSubtitle,
              iconColor: AppColors.warning,
              onTap: () => _open(context, const ScamCallPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.sos_rounded,
              title: s.gotScammedTitle,
              subtitle: s.gotScammedSubtitle,
              iconColor: AppColors.danger,
              onTap: () => _open(context, const EmergencyPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            SectionHeader(title: s.yourApps),
            FeatureCard(
              icon: Icons.visibility_outlined,
              title: s.appsSpecialAccessTitle,
              subtitle: s.appsSpecialAccessSubtitle,
              onTap: () => _open(context, const SpecialAccessPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.compare_arrows_rounded,
              title: s.whatChangedTitle,
              subtitle: s.whatChangedSubtitle,
              onTap: () => _open(context, const ChangesPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            if (threat.data.radar.isNotEmpty) ...[
              SectionHeader(title: s.isHindi ? 'फ़्रॉड रडार' : 'Scam radar'),
              for (final item in threat.data.radar.take(3))
                _RadarCard(item: item),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s.isHindi
                      ? 'इस सप्ताह रिपोर्ट किए गए पैटर्न · सूची v${threat.data.version}'
                      : 'Patterns reported this week · list v${threat.data.version}'
                          '${threat.data.updatedAt.isEmpty ? '' : ' · ${threat.data.updatedAt}'}',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            SectionHeader(title: s.deviceSection),
            _QuickTool(
              icon: Icons.cleaning_services_outlined,
              title: s.storageCleanupTitle,
              subtitle: storage.overview == null
                  ? s.storageCleanupSubtitle
                  : '${formatBytes(storage.overview!.freeBytes)} ${s.free}',
              onTap: () => _open(context, const StoragePage()),
            ),
            _QuickTool(
              icon: Icons.chat_outlined,
              title: s.whatsappCleanerTitle,
              subtitle: storage.whatsappLoaded
                  ? '${formatBytes(storage.whatsappTotalBytes)} · ${s.whatsappCleanerTitle}'
                  : s.whatsappCleanerSubtitle,
              onTap: () => _open(context, const WhatsAppCleanerPage()),
            ),
            FeatureCard(
              icon: Icons.health_and_safety_outlined,
              title: s.deviceHealthTitle,
              subtitle: s.deviceHealthSubtitle,
              onTap: () => _open(context, const DeviceHealthPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.wifi_outlined,
              title: s.networkTitle,
              subtitle: s.networkSubtitle,
              onTap: () => _open(context, const NetworkPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.grid_view_rounded,
              title: s.allToolsTitle,
              subtitle: s.allToolsSubtitle,
              onTap: () => _open(context, const MorePage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(),
            const SizedBox(height: AppSpacing.tight),
            Text(
              '${AppConstants.appName} ${AppConstants.version} · ${s.runsOnDevice}',
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ShieldMark extends StatelessWidget {
  const _ShieldMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [AppColors.midnightGreen, Color(0xFF155744)],
        ),
      ),
      child: const Icon(Icons.shield_rounded, size: 19, color: AppColors.gold),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.isScanning,
    required this.lastScanAt,
    required this.needsReview,
    required this.onScan,
    this.error,
  });

  final int? score;
  final bool isScanning;
  final DateTime? lastScanAt;
  final int needsReview;
  final VoidCallback onScan;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Strings.of(context);
    final level = score == null
        ? RiskLevel.medium
        : RiskPalette.levelForScore(score!);
    final color = RiskPalette.color(context, level);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: Column(
        children: [
          ScoreRing(
            score: score ?? 0,
            color: color,
            size: 150,
            label: score == null
                ? s.notScanned
                : RiskPalette.scoreBand(context, score!),
            caption: s.safetyScore,
            animate: !isScanning,
          ),
          const SizedBox(height: AppSpacing.standard),
          Text(
            error != null && score == null
                ? (s.isHindi ? 'स्कैन आपके ऐप्स को नहीं पढ़ सका।' : 'The scan could not read your apps.')
                : score == null
                ? s.runCheckToSeeScore
                : needsReview == 0
                ? s.noAttentionNeeded
                : s.appsWorthLook(needsReview),
            textAlign: TextAlign.center,
            style: AppTypography.bodyStrong,
          ),
          const SizedBox(height: 4),
          Text(
            lastScanAt == null
                ? s.firstScanTakesFewSeconds
                : s.lastCheckedRelative(formatRelative(lastScanAt!.millisecondsSinceEpoch)),
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.standard),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isScanning
                      ? null
                      : () => _open(context, const SecurityPage()),
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  label: Text(s.details),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isScanning ? null : onScan,
                  icon: isScanning
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(isScanning ? s.scanning : s.scanNow),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.tight),
          const DisclaimerNote(),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _HealthGrid extends StatelessWidget {
  const _HealthGrid({required this.health});

  final HealthSummary health;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                icon: Icons.battery_charging_full_rounded,
                title: s.battery,
                value: health.batteryLabel,
                level: health.batteryLevel,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeviceHealthPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.tight),
            Expanded(
              child: _HealthTile(
                icon: Icons.sd_storage_outlined,
                title: s.storage,
                value: health.storagePressure == RiskLevel.safe
                    ? s.healthy
                    : health.storagePressure == RiskLevel.medium
                    ? s.gettingLow
                    : s.nearlyFull,
                level: health.storagePressure,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const StoragePage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.tight),
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                icon: Icons.wifi_rounded,
                title: s.networkTitle,
                value: health.networkLabel,
                level: health.networkQuality,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NetworkPage()),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.tight),
            Expanded(
              child: _HealthTile(
                icon: health.deviceSecure
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                title: s.isHindi ? 'स्क्रीन लॉक' : 'Lock screen',
                value: health.deviceSecure
                    ? (s.isHindi ? 'सुरक्षित' : 'Protected')
                    : (s.isHindi ? 'सेट नहीं है' : 'Not set'),
                level: health.deviceSecure ? RiskLevel.safe : RiskLevel.medium,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeviceHealthPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.level,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final RiskLevel level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = RiskPalette.color(context, level);
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyStrong,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({required this.item});

  final RadarItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.radar_rounded, size: 18, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTool extends StatelessWidget {
  const _QuickTool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconColor: AppColors.royalBlue,
      onTap: onTap,
      statusIcon: Icons.chevron_right_rounded,
    );
  }
}
