import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/similar_photo_finder.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import 'large_files_page.dart';
import 'storage_list_scaffold.dart';

/// Visually similar photos, clustered with a perceptual hash. The largest copy
/// in each group is kept and the rest are offered for review — nothing is
/// deleted without confirmation.
class SimilarPhotosPage extends StatefulWidget {
  const SimilarPhotosPage({super.key});

  @override
  State<SimilarPhotosPage> createState() => _SimilarPhotosPageState();
}

class _SimilarPhotosPageState extends State<SimilarPhotosPage> {
  late final SimilarPhotoFinder _finder;
  List<SimilarPhotoGroup> _groups = const [];
  bool _loading = false;
  bool _ran = false;
  int _scannedCount = 0;
  final Map<String, StorageFile> _selected = {};

  @override
  void initState() {
    super.initState();
    _finder = SimilarPhotoFinder(context.read<StorageService>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _runIfAllowed());
  }

  @override
  void dispose() {
    _finder.dispose();
    super.dispose();
  }

  Future<void> _runIfAllowed() async {
    final storage = context.read<StorageService>();
    if (!storage.canReadMedia || _loading) return;
    await _run();
  }

  Future<void> _run() async {
    final storage = context.read<StorageService>();
    setState(() {
      _loading = true;
      _ran = true;
    });
    final source = await storage.loadImages(limit: 400);
    final groups = await _finder.find(source, maxPhotos: 400);
    if (!mounted) return;
    setState(() {
      _groups = groups;
      _scannedCount = source.where((f) => f.isImage).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final theme = Theme.of(context);
    final reclaimable = _groups.fold<int>(
      0,
      (sum, group) => sum + group.reclaimableBytes,
    );

    if (storage.canReadMedia && !_ran && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runIfAllowed());
    }

    return AppPageScaffold(
      title: 'Similar photos',
      actions: [
        if (storage.canReadMedia)
          IconButton(
            onPressed: _loading ? null : _run,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Scan again',
          ),
      ],
      bottom: _selected.isEmpty
          ? null
          : Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 6,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.standard,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selected.length} selected · ${formatBytes(_selectedBytes())}',
                          style: AppTypography.bodyStrong.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(_selected.clear),
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(88, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      child: Column(
        children: [
          if (storage.canReadMedia)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.tight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grouped by how similar the pictures look, not by file name. '
                    'The largest copy in each group is kept.',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_groups.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.tight),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_groups.length} group${_groups.length == 1 ? '' : 's'} in $_scannedCount recent photos',
                            style: AppTypography.bodyStrong,
                          ),
                        ),
                        Text(
                          '${formatBytes(reclaimable)} reclaimable',
                          style: AppTypography.bodyStrong.copyWith(
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: !storage.canReadMedia
                ? const StorageAccessGate(required: StorageAccess.media)
                : _loading
                ? _Progress(finder: _finder)
                : _groups.isEmpty
                ? EmptyState(
                    title: 'No similar photos found',
                    message:
                        'Checked $_scannedCount recent photos. Either your library '
                        'is tidy, or the matches are subtler than the heuristic '
                        'can see.',
                    icon: Icons.photo_library_outlined,
                    actionLabel: 'Scan again',
                    onAction: _run,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      AppSpacing.standard * 2,
                    ),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) => _GroupCard(
                      group: _groups[index],
                      storage: storage,
                      selection: _selected.keys.toSet(),
                      onToggle: _toggle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  int _selectedBytes() =>
      _selected.values.fold(0, (total, file) => total + file.sizeBytes);

  void _toggle(StorageFile file, bool selected) {
    AppHaptics.tap(context);
    setState(() {
      if (selected) {
        _selected[file.id] = file;
      } else {
        _selected.remove(file.id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final storage = context.read<StorageService>();
    final files = _selected.values.toList();
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete ${files.length} photo${files.length == 1 ? '' : 's'}?',
      message:
          'The copy you were keeping in each group stays. This frees '
          '${formatBytes(_selectedBytes())} and cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    final result = await storage.deleteFiles(files);
    if (!mounted) return;
    final removed = result.deleted == 0
        ? <String>{}
        : files.map((f) => f.id).toSet();
    setState(() {
      _selected.clear();
      _groups = _groups
          .map((g) => g.without(removed))
          .whereType<SimilarPhotoGroup>()
          .toList();
    });
    reportDeleteResult(context, result, files.length);
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.finder});

  final SimilarPhotoFinder finder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: finder,
      builder: (context, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.standard * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: finder.total == 0 ? null : finder.progress,
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              Text(
                finder.total == 0
                    ? 'Reading your photo library…'
                    : 'Comparing ${finder.processed} of ${finder.total} photos…',
                style: AppTypography.bodyStrong,
              ),
              const SizedBox(height: 6),
              Text(
                'A small fingerprint is computed for each photo. This happens '
                'entirely on your device.',
                textAlign: TextAlign.center,
                style: AppTypography.small.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.storage,
    required this.selection,
    required this.onToggle,
  });

  final SimilarPhotoGroup group;
  final StorageService storage;
  final Set<String> selection;
  final FileToggle onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  'Group of ${group.count}',
                  style: AppTypography.cardTitle,
                ),
              ),
              StatusPill(
                label: formatBytes(group.reclaimableBytes),
                color: AppColors.royalBlue,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          FileListTile(
            file: group.keeper,
            thumbnailLoader: storage.thumbnail,
            onOpen: () => openStorageFile(context, storage, group.keeper),
            trailing: const StatusPill(
              label: 'Keeping',
              color: AppColors.safe,
              dense: true,
            ),
          ),
          for (final file in group.duplicates)
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
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Photos that look alike are not always truly the same. Check '
                  'the group before deleting anything.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  for (final file in group.duplicates) {
                    onToggle(file, true);
                  }
                },
                child: const Text('Select all'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
