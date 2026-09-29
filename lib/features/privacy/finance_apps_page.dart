import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/platform/native_models.dart';
import '../../services/threat_data/threat_data.dart';
import '../../state/security_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import 'app_detail_page.dart';

/// Bank, payment and loan apps on the phone, checked against the official
/// package list and the regulated-lender list. Entirely offline.
class FinanceAppsPage extends StatefulWidget {
  const FinanceAppsPage({super.key});

  @override
  State<FinanceAppsPage> createState() => _FinanceAppsPageState();
}

class _FinanceAppsPageState extends State<FinanceAppsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scanner = context.read<AppScannerService>();
      if (!scanner.hasScanned && !scanner.isScanning) {
        context.read<SecurityController>().runScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<AppScannerService>();
    final threat = context.watch<ThreatDataService>();
    final theme = Theme.of(context);
    final fakes = scanner.impersonatingApps;
    final loans = scanner.unlistedLoanApps;
    final listed = scanner.listedFinanceApps;

    return AppPageScaffold(
      title: 'Bank & loan app check',
      subtitle: 'Fake banking apps and unregulated lenders',
      child: scanner.isScanning && !scanner.hasScanned
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.tight,
                AppSpacing.screen,
                AppSpacing.standard * 2,
              ),
              children: [
                if (fakes.isEmpty && loans.isEmpty)
                  SuccessBanner(
                    title: 'No look-alike bank apps or unlisted loan apps',
                    message:
                        '${listed.length} recognised finance app${listed.length == 1 ? '' : 's'} '
                        'found. Nothing on this phone borrows a bank or payment brand '
                        'name without being the official package.',
                  )
                else
                  CriticalBanner(
                    title:
                        '${fakes.length + loans.length} app${fakes.length + loans.length == 1 ? '' : 's'} need a look',
                    message:
                        'Do not sign in, enter card details or borrow through the '
                        'apps below until you have confirmed them. Tap an app for '
                        'details and the uninstall button.',
                  ),
                if (fakes.isNotEmpty) ...[
                  const SectionHeader(title: 'Looks like a bank or payment app'),
                  for (final app in fakes)
                    AppListTile(
                      app: app,
                      subtitleOverride:
                          'Not the official ${scanner.impersonatedBrandFor(app) ?? 'brand'} package · ${app.packageName}',
                      trailing: const RiskPill(level: RiskLevel.high),
                      onTap: () => _openApp(context, app),
                    ),
                ],
                if (loans.isNotEmpty) ...[
                  const SectionHeader(title: 'Loan apps not on the regulated list'),
                  for (final app in loans)
                    AppListTile(
                      app: app,
                      subtitleOverride:
                          '${app.isSideloaded ? 'Sideloaded · ' : ''}${app.packageName}',
                      trailing: RiskPill(
                        level: app.isSideloaded ? RiskLevel.high : RiskLevel.medium,
                      ),
                      onTap: () => _openApp(context, app),
                    ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to verify a lender',
                          style: AppTypography.bodyStrong,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Every legal digital lender in India must name the '
                          'RBI-regulated bank or NBFC behind it inside the app and '
                          'on the Play listing. If you cannot find that name, or '
                          'the app was installed from a link, do not borrow. '
                          'Unregistered lenders can be reported on RBI Sachet.',
                          style: AppTypography.small.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.tight),
                        TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://sachet.rbi.org.in'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Open RBI Sachet'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (listed.isNotEmpty) ...[
                  const SectionHeader(title: 'Recognised finance apps'),
                  for (final app in listed)
                    AppListTile(
                      app: app,
                      subtitleOverride: _listedSubtitle(threat.data, app),
                      trailing: const StatusPill(
                        label: 'Official',
                        color: AppColors.safe,
                        dense: true,
                      ),
                      onTap: () => _openApp(context, app),
                    ),
                ],
                const SizedBox(height: AppSpacing.standard),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About this check', style: AppTypography.bodyStrong),
                      const SizedBox(height: 4),
                      Text(
                        'The app compares installed package names with a list of '
                        '${threat.data.officialApps.length} official bank, UPI, wallet '
                        'and government apps and ${threat.data.loanApps.length} apps '
                        'run by RBI-regulated lenders (list version '
                        '${threat.data.version}, ${threat.source}). A brand name on an '
                        'app that is not in that list is flagged. The list is a '
                        'starter set and grows with updates; an app missing from '
                        'it is "unverified", not proven fake.',
                        style: AppTypography.small.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.tight),
                const DisclaimerNote(text: AppConstants.disclaimerRisk),
              ],
            ),
    );
  }

  static String _listedSubtitle(ThreatData data, AppInfo app) {
    final loan = data.loanApps[app.packageName];
    if (loan != null && loan.lender.isNotEmpty) {
      return '${loan.lender} · ${loan.regulator}';
    }
    final official = data.officialApps[app.packageName];
    if (official != null) return '${official.brand} · ${official.category}';
    return app.packageName;
  }

  void _openApp(BuildContext context, AppInfo app) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppDetailPage(packageName: app.packageName),
      ),
    );
  }
}
