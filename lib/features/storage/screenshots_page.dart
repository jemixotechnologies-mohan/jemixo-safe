import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import 'large_files_page.dart';
import 'storage_list_scaffold.dart';

/// Screenshots, oldest first. They add up quickly and are safe to review
/// because they are easy to recreate.
class ScreenshotsPage extends StatefulWidget {
  const ScreenshotsPage({super.key});

  @override
  State<ScreenshotsPage> createState() => _ScreenshotsPageState();
}

class _ScreenshotsPageState extends State<ScreenshotsPage> {
  bool _oldestFirst = true;

  @override
  Widget build(BuildContext context) {
    return StorageListScaffold(
      title: 'Screenshots',
      requiredAccess: StorageAccess.media,
      summaryLabel: 'Total size',
      summaryBytes: context.watch<StorageService>().screenshotTotalBytes,
      isLoading: (storage) => storage.isLoadingScreenshots,
      onLoad: (storage, _) => storage.loadScreenshots(),
      onReload: (storage, _) => storage.loadScreenshots(force: true),
      builder: (context, storage, selection, onToggle) {
        final files = storage.screenshots;
        if (files.isEmpty) {
          return const EmptyState(
            title: 'No screenshots found',
            message:
                'Screenshots usually live in Pictures/Screenshots or DCIM/Screenshots.',
            icon: Icons.screenshot_rounded,
          );
        }

        final sorted = [...files]
          ..sort(
            (a, b) => _oldestFirst
                ? (a.modified ?? 0).compareTo(b.modified ?? 0)
                : (b.modified ?? 0).compareTo(a.modified ?? 0),
          );
        final yearAgo = DateTime.now()
            .subtract(const Duration(days: 365))
            .millisecondsSinceEpoch;
        final old = files.where((f) => (f.modified ?? 0) < yearAgo).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          itemCount: sorted.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.tight),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${files.length} screenshot${files.length == 1 ? '' : 's'}'
                        '${old.isEmpty ? '' : ' · ${old.length} older than a year'}',
                        style: AppTypography.small.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (old.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          for (final file in old) {
                            onToggle(file, true);
                          }
                        },
                        child: Text('Select ${old.length} old'),
                      ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _oldestFirst = !_oldestFirst),
                      icon: Icon(
                        _oldestFirst
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 18,
                      ),
                      tooltip: _oldestFirst ? 'Oldest first' : 'Newest first',
                    ),
                  ],
                ),
              );
            }
            final file = sorted[index - 1];
            final selected = selection.contains(file.id);
            return FileListTile(
              file: file,
              thumbnailLoader: storage.thumbnail,
              selected: selected,
              onTap: () => onToggle(file, !selected),
              onOpen: () => openStorageFile(context, storage, file),
              note: (file.modified ?? 0) < yearAgo ? 'Older than a year' : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (file.width != null && file.height != null)
                    Text(
                      '${file.width}×${file.height}',
                      style: AppTypography.small.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
}

/// Kept for callers that only need the accent colour.
Color screenshotAccent() => AppColors.royalBlue;
