import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/risk_engine/risk_engine.dart';
import '../../state/security_controller.dart';
import '../../widgets/app_widgets.dart';
import '../privacy/app_detail_page.dart';
import '../history/changes_page.dart';
import '../privacy/finance_apps_page.dart';
import '../privacy/installed_apps_page.dart';
import '../privacy/special_access_page.dart';

/// Security tab. Owns the full scan experience: run it, explain it, and let
/// the user step into any app the engine flagged.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<AppScannerService>();
    final security = context.watch<SecurityController>();
    final theme = Theme.of(context);
    final score = security.score;
    final review = scanner.needsReview;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text('Safety check', style: AppTypography.pageTitle),
        actions: [
          IconButton(
            onPressed: security.isRunning ? null : security.runScan,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: security.runScan,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.tight,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          children: [
            if (security.isRunning) const _ScanProgressCard(),
            if (security.lastError != null && !security.isRunning)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.standard),
                child: WarningBanner(
                  title: 'Scan problem',
                  message: security.lastError!,
                  actionLabel: 'Try again',
                  onAction: security.runScan,
                ),
              ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.standard),
              child: Column(
                children: [
                  ScoreRing(
                    score: score ?? 0,
                    color: RiskPalette.color(
                      context,
                      score == null
                          ? RiskLevel.medium
                          : RiskPalette.levelForScore(score),
                    ),
                    size: 168,
                    label: score == null
                        ? 'Not scanned'
                        : RiskPalette.scoreBand(context, score),
                    caption: score == null
                        ? 'Run a scan to see your score'
                        : '${scanner.userApps.length} user apps reviewed',
                    animate: !security.isRunning,
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: security.isRunning ? null : security.runScan,
                      icon: security.isRunning
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        security.isRunning
                            ? 'Scanning…'
                            : 'Start safety check',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  if (security.lastScanAt != null) ...[
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      'Finished in ${formatMillis(security.lastDurationMs.toDouble())} · '
                      'checked ${formatRelative(security.lastScanAt!.millisecondsSinceEpoch)}',
                      style: AppTypography.small.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (scanner.hasScanned && scanner.visibilityLimited)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.standard),
                child: InfoBanner(
                  title: 'Only apps with an icon were checked',
                  message:
                      'This Android version hides background-only apps from '
                      'Jemixo Safe. Everything you can open from the launcher was reviewed.',
                ),
              ),
            if (scanner.hasScanned) ...[
              const SectionHeader(title: 'What we checked'),
              _Checklist(
                label: 'Fake bank & payment apps',
                detail: scanner.impersonatingApps.isEmpty
                    ? 'No app borrows a bank, UPI or government brand name without being the official package.'
                    : '${scanner.impersonatingApps.length} app${scanner.impersonatingApps.length == 1 ? '' : 's'} '
                          'use a bank or payment brand name but are not the official app.',
                ok: scanner.impersonatingApps.isEmpty,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FinanceAppsPage()),
                ),
              ),
              _Checklist(
                label: 'Special access & hidden apps',
                detail: scanner.specialAccess.userAppCount + scanner.hiddenApps.length == 0
                    ? 'No user app can read the screen or notifications, none is a device admin, and no hidden spying-type app was found.'
                    : '${scanner.specialAccess.userAppCount + scanner.hiddenApps.length} app${scanner.specialAccess.userAppCount + scanner.hiddenApps.length == 1 ? '' : 's'} '
                          'hold accessibility, notification access, device admin, or are hidden with spying-type permissions.',
                ok: scanner.specialAccess.userAppCount + scanner.hiddenApps.length == 0,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SpecialAccessPage()),
                ),
              ),
              _Checklist(
                label: 'Loan apps',
                detail: scanner.unlistedLoanApps.isEmpty
                    ? 'No loan app outside the regulated-lender list.'
                    : '${scanner.unlistedLoanApps.length} loan app${scanner.unlistedLoanApps.length == 1 ? '' : 's'} '
                          'not on the RBI-regulated lender list.',
                ok: scanner.unlistedLoanApps.isEmpty,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FinanceAppsPage()),
                ),
              ),
              _Checklist(
                label: 'Debuggable builds',
                detail: scanner.debuggableAppCount == 0
                    ? 'No installed app allows a debugger to attach.'
                    : '${scanner.debuggableAppCount} app${scanner.debuggableAppCount == 1 ? '' : 's'} '
                          'were built in debug mode. Store releases never are.',
                ok: scanner.debuggableAppCount == 0,
              ),
              _Checklist(
                label: 'Install sources',
                detail: scanner.sideloadedAppCount == 0
                    ? 'Every user app came from a recognised app store.'
                    : '${scanner.sideloadedAppCount} app${scanner.sideloadedAppCount == 1 ? '' : 's'} '
                          'were installed from outside a known store (APK file, ADB or unknown).',
                ok: scanner.sideloadedAppCount == 0,
                onTap: () => _openApps(context, AppFilter.sideloaded),
              ),
              _Checklist(
                label: 'Elevated access',
                detail: scanner.elevatedAccessCount == 0
                    ? 'No user app asks for accessibility, device admin, overlay or notification access.'
                    : '${scanner.elevatedAccessCount} app${scanner.elevatedAccessCount == 1 ? '' : 's'} '
                          'request accessibility, device admin, overlay, install or notification access.',
                ok: scanner.elevatedAccessCount == 0,
              ),
              _Checklist(
                label: 'Risky permission pairings',
                detail: scanner.combinedPatternCount == 0
                    ? 'No app combines SMS with contacts or tracks location in the background.'
                    : '${scanner.combinedPatternCount} app${scanner.combinedPatternCount == 1 ? '' : 's'} '
                          'combine SMS with contacts or track location in the background.',
                ok: scanner.combinedPatternCount == 0,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ChangesPage()),
                  ),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: const Text('What changed since the previous check'),
                ),
              ),
              const SectionHeader(title: 'Needs review'),
              if (review.isEmpty && !security.isRunning)
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.safe,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No apps stood out in this scan.',
                          style: AppTypography.bodyStrong,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final assessment in review.take(12))
                  _AssessmentTile(assessment: assessment),
              if (review.length > 12)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.tight),
                  child: TextButton(
                    onPressed: () => _openApps(context, AppFilter.highRisk),
                    child: Text('See all ${review.length} apps to review'),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(text: AppConstants.disclaimerRisk),
          ],
        ),
      ),
    );
  }

  void _openApps(BuildContext context, AppFilter filter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InstalledAppsPage(initialFilter: filter),
      ),
    );
  }
}

class _ScanProgressCard extends StatelessWidget {
  const _ScanProgressCard();

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityController>();
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scanning installed apps…', style: AppTypography.cardTitle),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: security.progress / 100,
              minHeight: 8,
              backgroundColor: AppColors.linearTrack,
            ),
          ),
        ],
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({
    required this.label,
    required this.detail,
    required this.ok,
    this.onTap,
  });

  final String label;
  final String detail;
  final bool ok;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.safe : AppColors.warning;
    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      onTap: ok ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!ok && onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.assessment});

  final AppRiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final color = RiskPalette.color(context, assessment.level);
    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AppDetailPage(packageName: assessment.app.packageName),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${assessment.score}',
              style: AppTypography.bodyStrong.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.app.label,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  assessment.topIndicator?.title ?? 'Minor indicators',
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
