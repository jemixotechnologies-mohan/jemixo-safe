import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/permissions/permission_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../services/apk_analyzer/apk_analyzer_service.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import '../storage/storage_list_scaffold.dart';

/// Inspects an APK the user already has on their device. The file is only read
/// from paths the user explicitly handed over (Downloads or the share sheet);
/// nothing is installed.
class ApkAnalyzerPage extends StatefulWidget {
  const ApkAnalyzerPage({super.key, this.initialPath});

  /// Path or content URI handed over by the share sheet or another screen.
  final String? initialPath;

  @override
  State<ApkAnalyzerPage> createState() => _ApkAnalyzerPageState();
}

class _ApkAnalyzerPageState extends State<ApkAnalyzerPage> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = context.read<StorageService>();
      if (storage.canReadMedia) storage.loadDownloads();
      final initial = widget.initialPath;
      if (initial != null && initial.isNotEmpty) {
        _analyze(initial);
      } else {
        context.read<ApkAnalyzerService>().clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyzer = context.watch<ApkAnalyzerService>();
    final storage = context.watch<StorageService>();
    final analysis = analyzer.lastResult;
    final theme = Theme.of(context);

    final apkCandidates = storage.downloads
        .where((file) => file.isApk)
        .toList(growable: false);

    return AppPageScaffold(
      title: 'APK analyzer',
      subtitle: 'Inspect a file before you install it',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          InfoBanner(
            title: 'Jemixo Safe never installs anything',
            message:
                'Pick an APK from your downloads, or share one to Jemixo Safe from '
                'any file manager. You stay in control of whether it gets installed.',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.standard),
          if (analyzer.isAnalyzing)
            const AppCard(
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Reading package manifest…'),
                ],
              ),
            ),
          if (analyzer.lastError != null && !analyzer.isAnalyzing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.standard),
              child: WarningBanner(
                title: 'Could not analyze that file',
                message: analyzer.lastError!,
              ),
            ),
          if (analysis != null) ...[
            const SectionHeader(
              title: 'Result',
              padding: EdgeInsets.only(bottom: 10),
            ),
            _AnalysisCard(analysis: analysis),
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(text: AppConstants.disclaimerRisk),
          ],
          const SectionHeader(title: 'APK files in Downloads'),
          if (!storage.canReadMedia)
            const SizedBox(
              height: 260,
              child: StorageAccessGate(required: StorageAccess.media),
            )
          else if (storage.isLoadingDownloads && !storage.downloadsLoaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.standard),
                child: CircularProgressIndicator(),
              ),
            )
          else if (apkCandidates.isEmpty)
            const EmptyState(
              title: 'No APK files found in Downloads',
              message:
                  'Share an APK to Jemixo Safe from your file manager, or copy '
                  'one into Downloads and pull to refresh.',
              icon: Icons.android_outlined,
              compact: true,
            )
          else
            for (final file in apkCandidates)
              FileListTile(
                file: file,
                selected: _selected == _targetOf(file),
                onTap: () => _analyze(_targetOf(file)),
                note: file.sizeBytes > 300 * 1024 * 1024
                    ? 'Unusually large for an app package'
                    : null,
                trailing: IconButton(
                  onPressed: () => _analyze(_targetOf(file)),
                  icon: const Icon(Icons.policy_outlined, size: 20),
                  tooltip: 'Analyze',
                ),
              ),
          const SizedBox(height: AppSpacing.standard),
          Text(
            'Manifest data is read locally and discarded when you leave this screen.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _targetOf(StorageFile file) =>
      file.hasPath ? file.path : file.target;

  Future<void> _analyze(String target) async {
    setState(() => _selected = target);
    final analyzer = context.read<ApkAnalyzerService>();
    final result = await analyzer.analyze(target);
    if (!mounted) return;
    if (result == null) {
      AppHaptics.warning(context);
    } else {
      AppHaptics.success(context);
      showAppSnack(context, 'Analyzed ${result.displayName}');
    }
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis});

  final ApkAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final analyzer = context.read<ApkAnalyzerService>();
    final theme = Theme.of(context);
    final notes = analyzer.review(analysis);
    final score = analyzer.privacyScore(analysis);
    final level = analyzer.privacyLevel(analysis);
    final sensitive = analyzer.sensitivePermissions(analysis);
    final elevated = analyzer.elevatedPermissions(analysis).toSet();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppMonogram(
                appName: analysis.displayName,
                packageName: analysis.packageName,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.displayName, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      analysis.packageName ?? 'Unknown package',
                      style: AppTypography.small.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (analysis.valid) RiskPill(level: level, dense: false),
            ],
          ),
          const SizedBox(height: AppSpacing.standard),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.tight),
          DetailRow(label: 'File', value: analysis.fileName),
          DetailRow(label: 'Size', value: formatBytes(analysis.sizeBytes)),
          if (analysis.versionName != null)
            DetailRow(
              label: 'Version',
              value: analysis.versionCode == null
                  ? analysis.versionName!
                  : '${analysis.versionName} (${analysis.versionCode})',
            ),
          if (analysis.isInstalled)
            DetailRow(
              label: 'On this device',
              value: 'Installed (build ${analysis.installedVersionCode})',
            ),
          if (analysis.minSdk != null)
            DetailRow(label: 'Min Android', value: 'API ${analysis.minSdk}'),
          if (analysis.targetSdk != null)
            DetailRow(
              label: 'Target Android',
              value: 'API ${analysis.targetSdk}',
            ),
          if (analysis.valid) ...[
            DetailRow(
              label: 'Permissions',
              value: '${analysis.permissions.length} requested',
            ),
            DetailRow(
              label: 'Sensitive',
              value: '${sensitive.length} on the watch list',
              valueColor: sensitive.isEmpty ? AppColors.safe : AppColors.warning,
            ),
          ],
          if (analysis.hasNativeCode != null)
            DetailRow(
              label: 'Native code',
              value: analysis.hasNativeCode! ? 'Yes' : 'No',
            ),
          if (analysis.signatures.isNotEmpty)
            DetailRow(
              label: 'Signature',
              value: 'SHA-256 ${analysis.signatures.first.shortFingerprint}…',
              monospace: true,
            ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.standard),
            Text('Review notes', style: AppTypography.sectionTitle),
            const SizedBox(height: 8),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      note.level == RiskLevel.safe
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                      color: RiskPalette.color(context, note.level),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.title, style: AppTypography.bodyStrong),
                          Text(
                            note.message,
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
          if (analysis.valid) ...[
            const SizedBox(height: AppSpacing.tight),
            MetricBar(
              label: 'Privacy exposure for this file',
              valueLabel: '$score/100',
              fraction: score / 100,
              color: RiskPalette.color(context, level),
            ),
          ],
          if (sensitive.isNotEmpty || elevated.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.tight),
            Text('Permissions to know about', style: AppTypography.sectionTitle),
            const SizedBox(height: 8),
            for (final permission in {...elevated, ...sensitive})
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      elevated.contains(permission)
                          ? Icons.priority_high_rounded
                          : categoryFor(permission).icon,
                      size: 16,
                      color: elevated.contains(permission)
                          ? AppColors.warning
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvePermission(permission)?.title ??
                                permissionTitle(permission),
                            style: AppTypography.bodyStrong,
                          ),
                          Text(
                            resolvePermission(permission)?.why ??
                                'Elevated: ${elevatedPermissionTitle(permission)}.',
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
        ],
      ),
    );
  }
}
