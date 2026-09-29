import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../device_tests/hardware_tests_page.dart';
import '../emergency/emergency_page.dart';
import '../emergency/scam_call_page.dart';
import '../history/changes_page.dart';
import '../history/history_page.dart';
import '../privacy/finance_apps_page.dart';
import '../privacy/special_access_page.dart';
import '../scam_scanner/call_check_page.dart';
import '../scam_scanner/screenshot_check_page.dart';
import '../settings/privacy_policy_page.dart';
import '../qr_scanner/qr_scanner_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../storage/downloads_page.dart';
import '../storage/duplicates_page.dart';

/// More tab: everything that does not belong to a single daily task.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text(s.moreTitle, style: AppTypography.pageTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          SectionHeader(title: s.scamProtectionSection),
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
          FeatureCard(
            icon: Icons.document_scanner_outlined,
            title: s.checkScreenshotTitle,
            subtitle: s.checkScreenshotSubtitle,
            onTap: () => _open(context, const ScreenshotCheckPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.call_outlined,
            title: s.checkPhoneTitle,
            subtitle: s.checkPhoneSubtitle,
            onTap: () => _open(context, const CallCheckPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
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
          FeatureCard(
            icon: Icons.account_balance_outlined,
            title: s.financeAppsTitle,
            subtitle: s.financeAppsSubtitle,
            iconColor: AppColors.gold,
            onTap: () => _open(context, const FinanceAppsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          SectionHeader(title: s.toolsSection),
          FeatureCard(
            icon: Icons.fact_check_outlined,
            title: s.reportsTitle,
            subtitle: s.reportsSubtitle,
            onTap: () => _open(context, const ReportsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.history_rounded,
            title: s.historyTitle,
            subtitle: s.historySubtitle,
            onTap: () => _open(context, const HistoryPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.qr_code_scanner_rounded,
            title: s.qrScannerTitle,
            subtitle: s.qrScannerSubtitle,
            onTap: () => _open(context, const QrScannerPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.developer_mode_rounded,
            title: s.hardwareTestsTitle,
            subtitle: s.hardwareTestsSubtitle,
            onTap: () => _open(context, const HardwareTestsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          SectionHeader(title: s.storageShortcutsSection),
          FeatureCard(
            icon: Icons.copy_all_rounded,
            title: s.duplicatesTitle,
            subtitle: s.duplicatesSubtitle,
            onTap: () => _open(context, const DuplicatesPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.download_rounded,
            title: s.downloadsTitle,
            subtitle: s.downloadsSubtitle,
            onTap: () => _open(context, const DownloadsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          SectionHeader(title: s.appSection),
          FeatureCard(
            icon: Icons.settings_outlined,
            title: s.settingsTitle,
            subtitle: s.isHindi
                ? 'भाषा, सरल मोड, अलर्ट, थीम और डेटा सेटिंग्स'
                : 'Language, simple mode, alerts, appearance and data controls',
            onTap: () => _open(context, const SettingsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.policy_outlined,
            title: s.privacyPolicyTitle,
            subtitle: s.privacyPolicySubtitle,
            onTap: () => _open(context, const PrivacyPolicyPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          const SizedBox(height: AppSpacing.standard),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName, style: AppTypography.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Version ${AppConstants.version}',
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  AppConstants.privacyPromise,
                  style: AppTypography.small.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
