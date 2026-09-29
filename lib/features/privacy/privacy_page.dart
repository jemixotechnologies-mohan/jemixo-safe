import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/permissions/permission_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/platform/native_models.dart';
import '../../widgets/app_widgets.dart';
import '../security/apk_analyzer_page.dart';
import 'app_detail_page.dart';
import 'installed_apps_page.dart';

/// Privacy tab root: permission overview, privacy score, and the entry points
/// into the installed-app and APK analyzers.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<AppScannerService>();
    final theme = Theme.of(context);
    final s = Strings.of(context);
    final score = scanner.userApps.isEmpty ? null : scanner.privacyScore;
    final level = score == null
        ? RiskLevel.medium
        : score >= 75
        ? RiskLevel.safe
        : score >= 55
        ? RiskLevel.low
        : score >= 35
        ? RiskLevel.medium
        : RiskLevel.high;
    final usage = scanner.permissionUsage;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text(s.privacyTitle, style: AppTypography.pageTitle),
      ),
      body: RefreshIndicator(
        onRefresh: scanner.scan,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.tight,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.standard),
              child: Column(
                children: [
                  ScoreRing(
                    score: score ?? 0,
                    color: RiskPalette.color(context, level),
                    size: 150,
                    label: level.localizedLabel(context),
                    caption: s.privacyScore,
                    animate: false,
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  Text(
                    score == null
                        ? (s.isHindi ? 'प्राइवेसी स्कोर देखने के लिए सुरक्षा जाँच चलाएं।' : 'Run a security scan to calculate your privacy score.')
                        : s.privacyScoreHint,
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _open(context, const InstalledAppsPage()),
                      icon: const Icon(Icons.apps_rounded, size: 18),
                      label: Text(s.reviewInstalledApps),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(title: s.analyzers),
            FeatureCard(
              icon: Icons.verified_user_outlined,
              title: s.installedAppAnalyzerTitle,
              subtitle: s.installedAppAnalyzerSubtitle,
              iconColor: AppColors.royalBlue,
              statusIcon: Icons.chevron_right_rounded,
              onTap: () => _open(context, const InstalledAppsPage()),
            ),
            FeatureCard(
              icon: Icons.android_outlined,
              title: s.apkAnalyzerTitle,
              subtitle: s.apkAnalyzerSubtitle,
              iconColor: AppColors.gold,
              statusIcon: Icons.chevron_right_rounded,
              onTap: () => _open(context, const ApkAnalyzerPage()),
            ),
            SectionHeader(title: s.permissionsByCategory),
            if (usage.isEmpty)
              const EmptyState(
                title: 'No permission data yet',
                message: 'Run a security scan to map which apps request sensitive permissions.',
                icon: Icons.privacy_tip_outlined,
                compact: true,
              )
            else
              for (final bucket in usage)
                _PermissionCategoryTile(bucket: bucket),
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(text: AppConstants.disclaimerRisk),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _PermissionCategoryTile extends StatelessWidget {
  const _PermissionCategoryTile({required this.bucket});

  final PermissionUsage bucket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = bucket.isSensitive ? AppColors.warning : AppColors.info;

    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      onTap: () => _open(context),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(bucket.category.icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bucket.category.label, style: AppTypography.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  '${bucket.count} app${bucket.count == 1 ? '' : 's'} request this',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PermissionCategoryPage(
          category: bucket.category,
          apps: bucket.apps,
        ),
      ),
    );
  }
}

class PermissionCategoryPage extends StatelessWidget {
  const PermissionCategoryPage({
    super.key,
    required this.category,
    required this.apps,
  });

  final PermissionCategory category;
  final List<AppInfo> apps;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: category.label,
      subtitle: '${apps.length} app${apps.length == 1 ? '' : 's'}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          InfoBanner(
            title: 'What ${category.label.toLowerCase()} access means',
            message: _explanation(category),
            icon: category.icon,
          ),
          const SizedBox(height: AppSpacing.standard),
          for (final app in apps) AppListTileRoute(app: app),
          const SizedBox(height: AppSpacing.standard),
          const DisclaimerNote(text: AppConstants.disclaimerRisk),
        ],
      ),
    );
  }

  static String _explanation(PermissionCategory category) => switch (category) {
    PermissionCategory.camera =>
      'Camera access lets an app take photos and record video. Some apps '
          'legitimately need it — a camera, a scanner, a video call.',
    PermissionCategory.microphone =>
      'Microphone access lets an app record audio. Messaging and voice apps '
          'usually need it; a calculator does not.',
    PermissionCategory.location =>
      'Location is among the most revealing permissions. Revoke it in Android '
          'Settings if you do not use the feature.',
    PermissionCategory.contacts =>
      'Contacts access lets an app read your address book. Only share it with '
          'apps you trust with your contacts.',
    PermissionCategory.phone =>
      'Phone access can read call history and make calls without your '
          'confirmation.',
    PermissionCategory.sms =>
      'SMS access can read and send messages. Very few apps genuinely need it, '
          'so treat it seriously.',
    PermissionCategory.notifications =>
      'Notification access is common and usually harmless, but can expose '
          'content of messages shown on your lock screen.',
    PermissionCategory.photos =>
      'Photo and video access grants read access to your media library.',
    PermissionCategory.videos =>
      'Video access is separate from photos on newer Android versions.',
    PermissionCategory.files =>
      'File and storage access lets an app read files in shared storage.',
    PermissionCategory.calendar =>
      'Calendar access can read and create events.',
    PermissionCategory.nearbyDevices =>
      'Nearby device access enables Bluetooth and local network connections.',
    PermissionCategory.sensors =>
      'Body and sensor access covers heart rate, step count and motion data.',
    PermissionCategory.other =>
      'These permissions are not in the sensitive list, so they are not '
          'counted toward your privacy score.',
  };
}

/// Small wrapper so the category page stays consistent with the app list.
class AppListTileRoute extends StatelessWidget {
  const AppListTileRoute({super.key, required this.app});

  final AppInfo app;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.tight),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AppDetailPage(packageName: app.packageName),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.label, style: AppTypography.bodyStrong),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    style: AppTypography.small.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (app.sizeBytes != null)
              Text(
                formatBytes(app.sizeBytes!),
                style: AppTypography.small.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
