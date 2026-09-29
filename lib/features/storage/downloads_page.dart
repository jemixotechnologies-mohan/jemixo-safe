import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import '../security/apk_analyzer_page.dart';
import 'large_files_page.dart';
import 'storage_list_scaffold.dart';

/// Downloads grouped by file type, with APK installers called out because
/// they are the most common way unwanted software gets onto a device.
class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    return StorageListScaffold(
      title: 'Downloads',
      requiredAccess: StorageAccess.media,
      summaryLabel: storage.downloadsLoaded
          ? '${storage.downloads.length} file${storage.downloads.length == 1 ? '' : 's'}'
          : null,
      summaryBytes: storage.downloads.fold<int>(0, (s, f) => s + f.sizeBytes),
      isLoading: (storage) => storage.isLoadingDownloads,
      onLoad: (storage, _) => storage.loadDownloads(),
      onReload: (storage, _) => storage.loadDownloads(force: true),
      builder: (context, storage, selection, onToggle) {
        final groups = storage.downloadsByType();
        if (groups.isEmpty) {
          return const EmptyState(
            title: 'Downloads folder is empty',
            message: 'Nothing to review here yet.',
            icon: Icons.download_rounded,
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          children: [
            for (final entry in groups.entries) ...[
              SectionHeader(
                title: entry.key,
                actionLabel: formatBytes(
                  entry.value.fold<int>(0, (sum, file) => sum + file.sizeBytes),
                ),
                onAction: () {},
              ),
              for (final file in entry.value.take(30))
                FileListTile(
                  file: file,
                  thumbnailLoader: storage.thumbnail,
                  selected: selection.contains(file.id),
                  onTap: () => onToggle(file, !selection.contains(file.id)),
                  onOpen: () => openStorageFile(context, storage, file),
                  note: file.isApk
                      ? 'App installer — inspect before installing'
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (file.isApk)
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ApkAnalyzerPage(
                                initialPath: file.hasPath
                                    ? file.path
                                    : file.target,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.policy_outlined,
                            size: 20,
                            color: AppColors.gold,
                          ),
                          tooltip: 'Inspect APK',
                        ),
                      Checkbox(
                        value: selection.contains(file.id),
                        onChanged: (value) => onToggle(file, value ?? false),
                      ),
                    ],
                  ),
                ),
              if (entry.value.length > 30)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.tight),
                  child: Text(
                    '+ ${entry.value.length - 30} more in this category',
                    style: AppTypography.small.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
