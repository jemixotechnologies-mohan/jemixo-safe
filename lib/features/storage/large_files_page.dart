import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import '../security/apk_analyzer_page.dart';
import 'storage_list_scaffold.dart';

/// Large files, filtered by the user's size threshold from Settings.
class LargeFilesPage extends StatelessWidget {
  const LargeFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final threshold = context.watch<SettingsController>().largeFileThresholdMb;
    return StorageListScaffold(
      title: 'Large files',
      requiredAccess: StorageAccess.media,
      summaryLabel: 'Files above $threshold MB',
      summaryBytes: context.watch<StorageService>().largeFileTotalBytes,
      isLoading: (storage) => storage.isLoadingLargeFiles,
      onLoad: (storage, minBytes) => storage.loadLargeFiles(minBytes: minBytes),
      onReload: (storage, minBytes) =>
          storage.loadLargeFiles(minBytes: minBytes, force: true),
      builder: (context, storage, selection, onToggle) {
        final files = storage.largeFiles;
        if (files.isEmpty) {
          return EmptyState(
            title: 'No large files found',
            message:
                'No photo, video, audio or download is above $threshold MB. You '
                'can lower the threshold in Settings → Large file threshold.',
            icon: Icons.data_usage_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final selected = selection.contains(file.id);
            final risk = storage.riskFor(file);
            return FileListTile(
              file: file,
              thumbnailLoader: storage.thumbnail,
              selected: selected,
              onTap: () => onToggle(file, !selected),
              onOpen: () => _open(context, storage, file),
              note: risk >= 90
                  ? 'Windows executable — not runnable on Android'
                  : risk > 0
                  ? 'App installer file — tap the badge to inspect it'
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (risk > 0)
                    GestureDetector(
                      onTap: file.isApk
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ApkAnalyzerPage(
                                  initialPath: file.hasPath
                                      ? file.path
                                      : file.target,
                                ),
                              ),
                            )
                          : null,
                      child: StatusPill(
                        label: risk >= 90 ? 'Executable' : 'Installer',
                        color: RiskPalette.color(
                          context,
                          risk >= 90 ? RiskLevel.high : RiskLevel.medium,
                        ),
                        dense: true,
                      ),
                    ),
                  Checkbox(
                    value: selected,
                    onChanged: (value) => onToggle(file, value ?? false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _open(
    BuildContext context,
    StorageService storage,
    StorageFile file,
  ) async {
    final opened = await storage.open(file);
    if (!opened && context.mounted) {
      showAppSnack(context, 'No app on this device can open ${file.name}.');
    }
  }
}

/// Shared "open" fallback message so every list behaves the same.
Future<void> openStorageFile(
  BuildContext context,
  StorageService storage,
  StorageFile file,
) async {
  final opened = await storage.open(file);
  if (!opened && context.mounted) {
    showAppSnack(context, 'No app on this device can open ${file.name}.');
  }
}

/// Single-file delete with confirmation, shared by the list screens.
Future<void> deleteStorageFile(
  BuildContext context,
  StorageService storage,
  StorageFile file,
) async {
  final confirmed = await confirmDestructiveAction(
    context,
    title: 'Delete ${file.name}?',
    message:
        'This permanently removes ${formatBytes(file.sizeBytes)} and cannot be undone.',
  );
  if (!confirmed || !context.mounted) return;
  final result = await storage.deleteFiles([file]);
  if (!context.mounted) return;
  reportDeleteResult(context, result, 1);
}

/// Colour helper kept next to the list pages so they stay consistent.
Color storageAccent(BuildContext context) => AppColors.royalBlue;
