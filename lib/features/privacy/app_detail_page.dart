import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/permissions/permission_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/platform/native_models.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';

/// Everything known about a single app, with the platform hand-off buttons for
/// reviewing and (only at the user's request) uninstalling it.
class AppDetailPage extends StatefulWidget {
  const AppDetailPage({super.key, required this.packageName});

  final String packageName;

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  AppInfo? _app;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final scanner = context.read<AppScannerService>();
    final local = scanner.allApps.where(
      (a) => a.packageName == widget.packageName,
    );
    if (local.isNotEmpty) {
      setState(() {
        _app = local.first;
        _loading = false;
      });
      return;
    }
    final fetched = await scanner.lookup(widget.packageName);
    if (!mounted) return;
    setState(() {
      _app = fetched;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<AppScannerService>();
    final theme = Theme.of(context);
    final app = _app;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('App details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('App details')),
        body: EmptyState(
          title: 'App not found',
          message:
              'Android did not return details for ${widget.packageName}. It may '
              'have been uninstalled.',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    final assessment = scanner.assessmentFor(app.packageName);
    final privacyScore = scanner.privacyScoreFor(app);
    final privacyLevel = scanner.privacyLevelFor(privacyScore);
    final level = assessment != null && assessment.indicators.isNotEmpty
        ? assessment.level
        : privacyLevel;
    final sensitive = app.permissions
        .where((p) => resolvePermission(p) != null)
        .toList();
    final elevated = app.permissions.where(isElevatedPermission).toList();

    return AppPageScaffold(
      title: app.label,
      subtitle: app.packageName,
      actions: [
        IconButton(
          onPressed: () => _openSettings(scanner, app),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Open in Android settings',
        ),
      ],
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
                Row(
                  children: [
                    AppMonogram(
                      appName: app.label,
                      packageName: app.packageName,
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.label, style: AppTypography.pageTitle),
                          const SizedBox(height: 2),
                          Text(
                            app.versionLabel,
                            style: AppTypography.small.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RiskPill(level: level, dense: false),
                  ],
                ),
                const SizedBox(height: AppSpacing.standard),
                if (assessment != null)
                  MetricBar(
                    label: 'Security indicator',
                    valueLabel: '${assessment.score}/100',
                    fraction: assessment.score / 100,
                    color: RiskPalette.color(context, assessment.level),
                  ),
                MetricBar(
                  label: 'Privacy exposure',
                  valueLabel: '$privacyScore/100',
                  fraction: privacyScore / 100,
                  color: RiskPalette.color(context, privacyLevel),
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  AppConstants.disclaimerRisk,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (assessment != null && assessment.indicators.isNotEmpty) ...[
            const SectionHeader(title: 'Why this was flagged'),
            AppCard(
              child: Column(
                children: [
                  for (final indicator in assessment.indicators)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 22,
                            width: 22,
                            decoration: BoxDecoration(
                              color:
                                  (indicator.isCritical
                                          ? AppColors.danger
                                          : indicator.severity == 2
                                          ? AppColors.warning
                                          : AppColors.info)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              indicator.isCritical
                                  ? Icons.priority_high_rounded
                                  : indicator.severity == 2
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline_rounded,
                              size: 14,
                              color: indicator.isCritical
                                  ? AppColors.danger
                                  : indicator.severity == 2
                                  ? AppColors.warning
                                  : AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  indicator.title,
                                  style: AppTypography.bodyStrong,
                                ),
                                Text(
                                  indicator.description,
                                  style: AppTypography.small.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SectionHeader(title: 'Details'),
          AppCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Package',
                  value: app.packageName,
                  monospace: true,
                ),
                DetailRow(label: 'Version', value: app.versionLabel),
                if (app.sizeBytes != null)
                  DetailRow(
                    label: 'App size',
                    value: formatBytes(app.sizeBytes!),
                  ),
                if (app.targetSdk != null)
                  DetailRow(
                    label: 'Target Android',
                    value: 'API ${app.targetSdk}',
                  ),
                if (app.installTime != null)
                  DetailRow(
                    label: 'Installed',
                    value: formatDate(app.installTime),
                  ),
                if (app.lastUpdateTime != null)
                  DetailRow(
                    label: 'Last updated',
                    value: formatDate(app.lastUpdateTime),
                  ),
                DetailRow(
                  label: 'Install source',
                  value: app.installSourceLabel ?? 'Unknown',
                  valueColor: app.isSideloaded && !app.isSystemApp
                      ? AppColors.warning
                      : null,
                ),
                DetailRow(
                  label: 'Type',
                  value: app.isSystemApp ? 'System app' : 'User app',
                ),
                if (!app.isEnabled)
                  const DetailRow(
                    label: 'State',
                    value: 'Disabled',
                    valueColor: AppColors.warning,
                  ),
                if (app.signatures.isNotEmpty)
                  DetailRow(
                    label: 'Signature',
                    value: 'SHA-256 ${app.signatures.first.shortFingerprint}…',
                    monospace: true,
                  ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Requested permissions (${app.permissions.length})',
            actionLabel: sensitive.isEmpty
                ? null
                : '${sensitive.length} sensitive',
            onAction: sensitive.isEmpty
                ? null
                : () => showAppSnack(
                    context,
                    '${sensitive.length} of these are on the sensitive watch list.',
                  ),
          ),
          if (app.permissions.isEmpty)
            const AppCard(
              child: Text('This app declares no permissions in its manifest.'),
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (final permission in _sortedPermissions(app.permissions))
                    _PermissionRow(permission: permission),
                ],
              ),
            ),
          if (elevated.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.standard),
            WarningBanner(
              title: 'Elevated access',
              message:
                  '${elevated.length} permission${elevated.length == 1 ? '' : 's'} on this app can '
                  'reach sensitive device features. Review them in Android settings if any look '
                  'unnecessary for what the app does.',
            ),
          ],
          const SizedBox(height: AppSpacing.standard),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSettings(scanner, app),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Permissions'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: app.isSystemApp
                      ? null
                      : () => _confirmUninstall(app),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Uninstall'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          if (app.isSystemApp)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'System apps cannot be uninstalled, but you can disable them in Android settings.',
                style: AppTypography.small.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.tight),
          const DisclaimerNote(text: AppConstants.disclaimerRisk),
        ],
      ),
    );
  }

  /// Sensitive and elevated permissions first, then everything else.
  static List<String> _sortedPermissions(List<String> permissions) {
    int rank(String p) {
      if (isElevatedPermission(p)) return 0;
      if (resolvePermission(p) != null) return 1;
      return 2;
    }

    return [...permissions]..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.compareTo(b);
    });
  }

  Future<void> _openSettings(AppScannerService scanner, AppInfo app) async {
    final opened = await scanner.openAppSettings(app.packageName);
    if (!opened && mounted) {
      showAppSnack(context, 'Android settings could not be opened.');
    }
  }

  Future<void> _confirmUninstall(AppInfo app) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Uninstall ${app.label}?',
      message:
          'Android will show its own confirmation. Jemixo Safe never removes '
          'an app on your behalf.',
      confirmLabel: 'Continue',
    );
    if (!confirmed || !mounted) return;
    final opened = await context.read<AppScannerService>().openAppUninstall(
      app.packageName,
    );
    if (!opened && mounted) {
      showAppSnack(context, 'The uninstall screen could not be opened.');
    }
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.permission});

  final String permission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final definition = resolvePermission(permission);
    final elevated = isElevatedPermission(permission);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            definition?.category.icon ?? Icons.apps_rounded,
            size: 17,
            color: elevated
                ? AppColors.warning
                : definition != null
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition?.title ?? permissionTitle(permission),
                  style: AppTypography.bodyStrong,
                ),
                Text(
                  definition?.why ?? permission,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (elevated)
            const StatusPill(
              label: 'Elevated',
              color: AppColors.warning,
              icon: Icons.priority_high_rounded,
              dense: true,
            ),
        ],
      ),
    );
  }
}
