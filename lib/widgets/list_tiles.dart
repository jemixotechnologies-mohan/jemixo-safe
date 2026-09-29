import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/risk_palette.dart';
import '../core/utils/formatters.dart';
import '../services/platform/native_models.dart';
import 'app_widgets.dart';

/// Round app icon derived from the package name. No icon is fetched from the
/// network — the monogram is generated locally and tinted deterministically.
class AppMonogram extends StatelessWidget {
  const AppMonogram({
    super.key,
    required this.appName,
    this.size = 42,
    this.packageName,
  });

  final String appName;
  final int size;
  final String? packageName;

  static const _palette = [
    Color(0xFF0B3328),
    Color(0xFF2C63EB),
    Color(0xFF0E7490),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
    Color(0xFF0F766E),
  ];

  @override
  Widget build(BuildContext context) {
    final seedSource = packageName ?? appName;
    var hash = 0;
    for (final unit in seedSource.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    final color = _palette[hash % _palette.length];
    final initials = _initials(appName);

    return Container(
      height: size.toDouble(),
      width: size.toDouble(),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.cardTitle.copyWith(
          color: color,
          fontSize: size * 0.38,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// List row for an installed app.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.app,
    this.onTap,
    this.trailing,
    this.subtitleOverride,
  });

  final AppInfo app;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      child: Row(
        children: [
          AppMonogram(appName: app.label, packageName: app.packageName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.label,
                  style: AppTypography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleOverride ??
                      '${app.permissions.length} permission'
                          '${app.permissions.length == 1 ? '' : 's'}'
                          '${app.sizeBytes == null ? '' : ' · ${formatBytes(app.sizeBytes!)}'}',
                  style: AppTypography.small.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
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

/// Loads a small preview for an image file; null for anything else.
typedef ThumbnailLoader = Future<Uint8List?> Function(StorageFile file);

/// List row for a file, with an optional thumbnail.
class FileListTile extends StatelessWidget {
  const FileListTile({
    super.key,
    required this.file,
    this.onTap,
    this.trailing,
    this.onOpen,
    this.onDelete,
    this.selected = false,
    this.note,
    this.thumbnailLoader,
  });

  final StorageFile file;
  final ThumbnailLoader? thumbnailLoader;
  final VoidCallback? onTap;
  final Widget? trailing;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;
  final bool selected;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      borderColor: selected ? theme.colorScheme.primary : null,
      child: Row(
        children: [
          _Thumbnail(file: file, loader: thumbnailLoader),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    formatBytes(file.sizeBytes),
                    if (file.modified != null) formatRelative(file.modified),
                    if (file.hasPath) shortenPath(file.path, maxSegments: 2),
                  ].join(' · '),
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note!,
                    style: AppTypography.small.copyWith(color: AppColors.gold),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (trailing != null)
            trailing!
          else ...[
            if (onOpen != null)
              IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                tooltip: 'Open',
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.danger,
                tooltip: 'Delete',
              ),
          ],
        ],
      ),
    );
  }
}

class _Thumbnail extends StatefulWidget {
  const _Thumbnail({required this.file, this.loader});

  final StorageFile file;
  final ThumbnailLoader? loader;

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.id != widget.file.id) _start();
  }

  void _start() {
    final loader = widget.loader;
    _future = loader == null || !(widget.file.isImage || widget.file.isVideo)
        ? null
        : loader(widget.file);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(
        _iconFor(widget.file),
        size: 20,
        color: theme.colorScheme.primary,
      ),
    );

    final future = _future;
    if (future == null) return box;
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.isEmpty) return box;
        return ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.memory(
            data,
            height: 42,
            width: 42,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => box,
          ),
        );
      },
    );
  }

  static IconData _iconFor(StorageFile file) {
    final mime = file.mimeType ?? '';
    if (file.isApk) return Icons.android_rounded;
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('video/')) return Icons.movie_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('zip') || mime.contains('compressed')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}

/// Risk pill reused by app and file rows.
class RiskPill extends StatelessWidget {
  const RiskPill({super.key, required this.level, this.dense = true});

  final RiskLevel level;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: level.shortLabel,
      color: RiskPalette.color(context, level),
      dense: dense,
    );
  }
}
