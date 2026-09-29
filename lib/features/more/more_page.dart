import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text('More', style: AppTypography.pageTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          const SectionHeader(title: 'Scam protection'),
          FeatureCard(
            icon: Icons.phone_in_talk_rounded,
            title: 'Scam call in progress?',
            subtitle: 'The four things to do while they are still talking',
            iconColor: AppColors.warning,
            onTap: () => _open(context, const ScamCallPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.sos_rounded,
            title: 'I think I got scammed',
            subtitle: 'Call 1930, freeze the money, keep the evidence',
            iconColor: AppColors.danger,
            onTap: () => _open(context, const EmergencyPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.document_scanner_outlined,
            title: 'Check a screenshot',
            subtitle: 'Read a message screenshot on the phone and scan it',
            onTap: () => _open(context, const ScreenshotCheckPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.call_outlined,
            title: 'Check a phone number',
            subtitle: 'TRAI number rules: 140, 1600, foreign, personal',
            onTap: () => _open(context, const CallCheckPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.visibility_outlined,
            title: 'Apps with special access',
            subtitle: 'Accessibility, notification access, device admin, hidden apps',
            onTap: () => _open(context, const SpecialAccessPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.compare_arrows_rounded,
            title: 'What changed',
            subtitle: 'New apps and permissions since the previous check',
            onTap: () => _open(context, const ChangesPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.account_balance_outlined,
            title: 'Bank & loan app check',
            subtitle: 'Fake banking apps and unregulated lenders on this phone',
            iconColor: AppColors.gold,
            onTap: () => _open(context, const FinanceAppsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          const SectionHeader(title: 'Tools'),
          FeatureCard(
            icon: Icons.fact_check_outlined,
            title: 'Reports',
            subtitle: 'Full breakdown of your security and privacy position',
            onTap: () => _open(context, const ReportsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.history_rounded,
            title: 'Scan history',
            subtitle: 'Past scans, stored only on this device',
            onTap: () => _open(context, const HistoryPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'QR scanner',
            subtitle: 'Read a code and check what it points to',
            onTap: () => _open(context, const QrScannerPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.developer_mode_rounded,
            title: 'Hardware tests',
            subtitle: 'Sensor, proximity, compass and torch checks',
            onTap: () => _open(context, const HardwareTestsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          const SectionHeader(title: 'Storage shortcuts'),
          FeatureCard(
            icon: Icons.copy_all_rounded,
            title: 'Duplicates',
            subtitle: 'Identical copies found by content hash',
            onTap: () => _open(context, const DuplicatesPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.download_rounded,
            title: 'Downloads',
            subtitle: 'Installers, archives and media',
            onTap: () => _open(context, const DownloadsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          const SectionHeader(title: 'App'),
          FeatureCard(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Simple mode, alerts, appearance and data controls',
            onTap: () => _open(context, const SettingsPage()),
            statusIcon: Icons.chevron_right_rounded,
          ),
          FeatureCard(
            icon: Icons.policy_outlined,
            title: 'Privacy policy',
            subtitle: 'What the app reads and what it never sends',
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
