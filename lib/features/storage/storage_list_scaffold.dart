import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';

/// Callback for a row toggle.
typedef FileToggle = void Function(StorageFile file, bool selected);

/// Shared scaffolding for the storage list screens: the permission gate, a
/// loader, a multi-select action bar, and a user-confirmed delete.
class StorageListScaffold extends StatefulWidget {
  const StorageListScaffold({
    super.key,
    required this.title,
    required this.onLoad,
    required this.builder,
    required this.isLoading,
    this.requiredAccess = StorageAccess.media,
    this.summaryLabel,
    this.summaryBytes,
    this.onReload,
  });

  final String title;
  final StorageAccess requiredAccess;
  final Future<void> Function(StorageService storage, int minBytes) onLoad;
  final Future<void> Function(StorageService storage, int minBytes)? onReload;
  final bool Function(StorageService storage) isLoading;
  final Widget Function(
    BuildContext context,
    StorageService storage,
    Set<String> selection,
    FileToggle onToggle,
  )
  builder;
  final String? summaryLabel;
  final int? summaryBytes;

  @override
  State<StorageListScaffold> createState() => _StorageListScaffoldState();
}

class _StorageListScaffoldState extends State<StorageListScaffold> {
  final Map<String, StorageFile> _selected = {};
  StorageAccess? _loadedWith;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfAllowed());
  }

  bool _allowed(StorageService storage) => switch (widget.requiredAccess) {
    StorageAccess.media => storage.canReadMedia,
    StorageAccess.none => true,
  };

  Future<void> _loadIfAllowed({bool force = false}) async {
    final storage = context.read<StorageService>();
    if (!_allowed(storage)) return;
    if (_loadedWith == storage.access && !force) return;
    _loadedWith = storage.access;
    final minBytes = context.read<SettingsController>().largeFileThresholdBytes;
    final load = force && widget.onReload != null ? widget.onReload! : widget.onLoad;
    await load(storage, minBytes);
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    // Permission granted while this screen was open (user came back from
    // Settings): load without making them leave and re-enter.
    if (_allowed(storage) && _loadedWith != storage.access) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfAllowed());
    }

    return AppPageScaffold(
      title: widget.title,
      actions: [
        if (_allowed(storage))
          IconButton(
            onPressed: widget.isLoading(storage)
                ? null
                : () => _loadIfAllowed(force: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Scan again',
          ),
      ],
      bottom: _selected.isEmpty
          ? null
          : _SelectionBar(
              count: _selected.length,
              bytes: _selected.values.fold(0, (s, f) => s + f.sizeBytes),
              onClear: () => setState(_selected.clear),
              onDelete: () => _confirmDelete(storage),
            ),
      child: Column(
        children: [
          if (widget.summaryLabel != null && _allowed(storage))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.tight,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.summaryLabel!,
                      style: AppTypography.bodyStrong,
                    ),
                  ),
                  if (widget.summaryBytes != null)
                    Text(
                      formatBytes(widget.summaryBytes!),
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.royalBlue,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: !_allowed(storage)
                ? StorageAccessGate(required: widget.requiredAccess)
                : widget.isLoading(storage)
                ? const _Scanning()
                : widget.builder(context, storage, _selected.keys.toSet(), _toggle),
          ),
        ],
      ),
    );
  }

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

  Future<void> _confirmDelete(StorageService storage) async {
    final files = _selected.values.toList();
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete ${files.length} file${files.length == 1 ? '' : 's'}?',
      message:
          'This permanently removes ${formatBytes(files.fold(0, (s, f) => s + f.sizeBytes))} '
          'and cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    final result = await storage.deleteFiles(files);
    if (!mounted) return;
    setState(_selected.clear);
    reportDeleteResult(context, result, files.length);
  }
}

/// Shared snack-bar wording for a delete outcome.
void reportDeleteResult(BuildContext context, DeleteResult result, int requested) {
  final String message;
  if (result.cancelled) {
    message = 'Delete cancelled.';
    AppHaptics.tap(context);
  } else if (result.deleted == 0) {
    message = 'Nothing was deleted. Android refused access to those files.';
    AppHaptics.warning(context);
  } else if (result.deleted < requested) {
    message =
        'Deleted ${result.deleted} of $requested. Android refused the rest.';
    AppHaptics.warning(context);
  } else {
    message = 'Deleted ${result.deleted} file${result.deleted == 1 ? '' : 's'}.';
    AppHaptics.success(context);
  }
  showAppSnack(context, message);
}

class _Scanning extends StatelessWidget {
  const _Scanning();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.standard),
          Text(
            'Scanning your storage…',
            style: AppTypography.small.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.bytes,
    required this.onClear,
    required this.onDelete,
  });

  final int count;
  final int bytes;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count selected · ${formatBytes(bytes)}',
                style: AppTypography.bodyStrong,
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Clear')),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains which permission a screen needs and requests it. Media access is
/// a normal runtime prompt; all-files access is a Settings toggle on
/// Android 11+, so the copy sets that expectation.
class StorageAccessGate extends StatefulWidget {
  const StorageAccessGate({super.key, required this.required});

  final StorageAccess required;

  @override
  State<StorageAccessGate> createState() => _StorageAccessGateState();
}

class _StorageAccessGateState extends State<StorageAccessGate> {
  bool _busy = false;
  bool _permanentlyDenied = false;

  Future<void> _requestMedia(StorageService storage) async {
    setState(() => _busy = true);
    final granted = await storage.requestMediaAccess();
    if (!mounted) return;
    if (!granted) {
      final denied = await storage.mediaPermanentlyDenied();
      if (!mounted) return;
      setState(() => _permanentlyDenied = denied);
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final theme = Theme.of(context);
    final action = _permanentlyDenied
        ? storage.openOwnAppSettings
        : () => _requestMedia(storage);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.perm_media_outlined, color: AppColors.royalBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Allow access to your photos and files',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Jemixo Safe reads file names, sizes and dates from the media '
                'library to find what is taking space. Files are only read to '
                'measure them and never leave your device.',
                style: AppTypography.small.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (_permanentlyDenied) ...[
                const SizedBox(height: 8),
                Text(
                  'The permission was declined earlier, so Android will only '
                  'change it from the app settings screen.',
                  style: AppTypography.small.copyWith(color: AppColors.warning),
                ),
              ],
              const SizedBox(height: AppSpacing.standard),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : action,
                  icon: _busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(
                    _permanentlyDenied ? 'Open app settings' : 'Allow access',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
