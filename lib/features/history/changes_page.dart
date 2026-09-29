import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions/permission_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/scan_repository.dart';
import '../../services/history/scan_diff.dart';
import '../../widgets/app_widgets.dart';
import '../privacy/app_detail_page.dart';

/// What changed since the previous safety check: new apps, removed apps and
/// apps whose sensitive permissions grew after an update.
class ChangesPage extends StatefulWidget {
  const ChangesPage({super.key});

  @override
  State<ChangesPage> createState() => _ChangesPageState();
}

class _ChangesPageState extends State<ChangesPage> {
  ScanDiff? _diff;
  bool _loading = true;
  bool _notEnough = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final diff = await ScanDiffService(context.read<ScanRepository>()).latest();
    if (!mounted) return;
    setState(() {
      _diff = diff;
      _notEnough = diff == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = _diff;
    return AppPageScaffold(
      title: 'What changed',
      subtitle: 'Since your previous safety check',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notEnough || diff == null
          ? const EmptyState(
              title: 'Need two checks to compare',
              message:
                  'Run the safety check again later (with "Save scan history" on) '
                  'and this screen will show new apps and permission changes.',
              icon: Icons.compare_arrows_rounded,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.tight,
                AppSpacing.screen,
                AppSpacing.standard * 2,
              ),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatDateTime(diff.previous.createdAt)}  →  ${formatDateTime(diff.latest.createdAt)}',
                        style: AppTypography.small.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Safety score ${diff.previous.score} → ${diff.latest.score}',
                            style: AppTypography.bodyStrong,
                          ),
                          const SizedBox(width: 8),
                          if (diff.scoreDelta != 0)
                            StatusPill(
                              label: '${diff.scoreDelta > 0 ? '+' : ''}${diff.scoreDelta}',
                              color: diff.scoreDelta > 0 ? AppColors.safe : AppColors.warning,
                              dense: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (diff.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.standard),
                    child: SuccessBanner(
                      title: 'Nothing changed',
                      message: 'Same apps, same sensitive permissions as last time.',
                    ),
                  ),
                if (diff.changed.isNotEmpty) ...[
                  SectionHeader(title: 'Permissions changed (${diff.changed.length})'),
                  for (final change in diff.changed)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
                      padding: const EdgeInsets.all(12),
                      onTap: () => _openApp(change.packageName),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(change.appName, style: AppTypography.bodyStrong),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final p in change.added)
                                StatusPill(
                                  label: '+ ${permissionTitle(p)}',
                                  color: AppColors.warning,
                                  dense: true,
                                ),
                              for (final p in change.removed)
                                StatusPill(
                                  label: '− ${permissionTitle(p)}',
                                  color: AppColors.safe,
                                  dense: true,
                                ),
                            ],
                          ),
                          if (change.added.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'An update added sensitive access. Ask whether the app needs it for what you use it for.',
                                style: AppTypography.small.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
                if (diff.installed.isNotEmpty) ...[
                  SectionHeader(title: 'New apps (${diff.installed.length})'),
                  for (final snapshot in diff.installed)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
                      padding: const EdgeInsets.all(12),
                      onTap: () => _openApp(snapshot.packageName),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(snapshot.appName, style: AppTypography.bodyStrong),
                                Text(
                                  '${snapshot.permissionsSensitive} sensitive permission${snapshot.permissionsSensitive == 1 ? '' : 's'}'
                                  '${snapshot.sideloaded ? ' · sideloaded' : ''}',
                                  style: AppTypography.small.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (snapshot.riskScore > 0)
                            StatusPill(
                              label: '${snapshot.riskScore}',
                              color: snapshot.riskScore >= 35 ? AppColors.warning : AppColors.info,
                              dense: true,
                            ),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                ],
                if (diff.removed.isNotEmpty) ...[
                  SectionHeader(title: 'Removed apps (${diff.removed.length})'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final snapshot in diff.removed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${snapshot.appName} · ${snapshot.packageName}',
                              style: AppTypography.small,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _openApp(String packageName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppDetailPage(packageName: packageName),
      ),
    );
  }
}
