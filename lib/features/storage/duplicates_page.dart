import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import 'large_files_page.dart';
import 'storage_list_scaffold.dart';

/// Exact duplicates, matched by file content hash rather than file name.
class DuplicatesPage extends StatelessWidget {
  const DuplicatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StorageListScaffold(
      title: 'Duplicates',
      requiredAccess: StorageAccess.media,
      summaryLabel: 'Reclaimable space',
      summaryBytes: context.watch<StorageService>().duplicateWastedBytes,
      isLoading: (storage) => storage.isLoadingDuplicates,
      onLoad: (storage, _) => storage.loadDuplicates(),
      onReload: (storage, _) => storage.loadDuplicates(force: true),
      builder: (context, storage, selection, onToggle) {
        final groups = storage.duplicates;
        if (groups.isEmpty) {
          return const EmptyState(
            title: 'No exact duplicates found',
            message:
                'Files are compared by content, not by name. Two copies with the '
                'same bytes are grouped together here.',
            icon: Icons.copy_all_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          itemCount: groups.length,
          itemBuilder: (context, index) => _DuplicateGroupCard(
            group: groups[index],
            storage: storage,
            selection: selection,
            onToggle: onToggle,
          ),
        );
      },
    );
  }
}

class _DuplicateGroupCard extends StatelessWidget {
  const _DuplicateGroupCard({
    required this.group,
    required this.storage,
    required this.selection,
    required this.onToggle,
  });

  final DuplicateGroup group;
  final StorageService storage;
  final Set<String> selection;
  final FileToggle onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keeper = group.files.first;
    final others = group.files.skip(1).toList();

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.standard),
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  keeper.name,
                  style: AppTypography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusPill(
                label: '${group.files.length} copies',
                color: AppColors.royalBlue,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatBytes(group.sizeBytes)} each · ${formatBytes(group.wastedBytes)} reclaimable',
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.tight),
          FileListTile(
            file: keeper,
            thumbnailLoader: storage.thumbnail,
            onOpen: () => openStorageFile(context, storage, keeper),
            note: 'Keeping this copy',
            trailing: const StatusPill(
              label: 'Keep',
              color: AppColors.safe,
              dense: true,
            ),
          ),
          for (final file in others)
            FileListTile(
              file: file,
              thumbnailLoader: storage.thumbnail,
              selected: selection.contains(file.id),
              onTap: () => onToggle(file, !selection.contains(file.id)),
              onOpen: () => openStorageFile(context, storage, file),
              trailing: Checkbox(
                value: selection.contains(file.id),
                onChanged: (value) => onToggle(file, value ?? false),
              ),
            ),
          const SizedBox(height: AppSpacing.tight),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    for (final file in others) {
                      onToggle(file, true);
                    }
                  },
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: Text(
                    'Select ${others.length} cop${others.length == 1 ? 'y' : 'ies'}',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Tooltip(
                message: 'Show in Files',
                child: OutlinedButton(
                  onPressed: () async {
                    final opened = await storage.openLocation(keeper);
                    if (!opened && context.mounted) {
                      showAppSnack(
                        context,
                        'No file manager on this device can show that folder.',
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 44),
                  ),
                  child: const Icon(Icons.folder_open_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
