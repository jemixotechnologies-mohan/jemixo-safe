import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../widgets/app_widgets.dart';
import 'downloads_page.dart';
import 'duplicates_page.dart';
import 'large_files_page.dart';
import 'screenshots_page.dart';
import 'similar_photos_page.dart';

/// Clean tab root. Storage overview plus the five cleanup surfaces.
class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  StorageAccess? _overviewFor;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final storage = context.read<StorageService>();
    await storage.checkStorageAccess();
    _overviewFor = storage.access;
    await storage.refreshOverview();
  }

  Future<void> _requestMedia(StorageService storage) async {
    setState(() => _requesting = true);
    await storage.requestMediaAccess();
    if (!mounted) return;
    setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final overview = storage.overview;
    final theme = Theme.of(context);
    final pressure = storage.storagePressure();

    // A permission granted elsewhere changes what the breakdown can see.
    if (_overviewFor != null &&
        _overviewFor != storage.access &&
        !storage.isLoadingOverview) {
      _overviewFor = storage.access;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => storage.refreshOverview(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text('Clean', style: AppTypography.pageTitle),
        actions: [
          IconButton(
            onPressed: storage.isLoadingOverview ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Storage',
                          style: AppTypography.sectionTitle,
                        ),
                      ),
                      StatusPill(
                        label: pressure == RiskLevel.safe
                            ? 'Healthy'
                            : pressure == RiskLevel.medium
                            ? 'Getting low'
                            : 'Nearly full',
                        color: RiskPalette.color(context, pressure),
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    overview == null
                        ? 'Reading device storage…'
                        : '${formatBytes(overview.usedBytes)} used of '
                              '${formatBytes(overview.totalBytes)}',
                    style: AppTypography.bodyStrong,
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  if (storage.isLoadingOverview && overview == null)
                    const LinearProgressIndicator(minHeight: 8)
                  else
                    MetricBar(
                      label: 'Used',
                      valueLabel: formatPercent(overview?.usedFraction ?? 0),
                      fraction: overview?.usedFraction ?? 0,
                      color: RiskPalette.color(context, pressure),
                    ),
                  if (overview != null) ...[
                    MetricBar(
                      label: 'Free',
                      valueLabel:
                          '${formatBytes(overview.freeBytes)} · ${formatPercent(1 - overview.usedFraction)}',
                      fraction: 1 - overview.usedFraction,
                      color: AppColors.safe,
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      pressure == RiskLevel.high
                          ? 'Storage is nearly full. Android starts misbehaving when free space runs low.'
                          : pressure == RiskLevel.medium
                          ? 'Free space is getting low. Cleaning large files now avoids trouble later.'
                          : 'You have comfortable free space right now.',
                      style: AppTypography.small.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (storage.categories.isNotEmpty) ...[
              const SectionHeader(title: 'Where space goes'),
              AppCard(
                child: Column(
                  children: [
                    for (final category in storage.categories.take(8))
                      MetricBar(
                        label: category.category,
                        valueLabel: formatBytes(category.bytes),
                        fraction: overview == null || overview.totalBytes == 0
                            ? 0
                            : category.bytes / overview.totalBytes,
                        color: category.category == 'Other'
                            ? AppColors.slate
                            : AppColors.royalBlue,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '"Apps & system" is everything outside the media library: '
                        'installed apps, their data and Android itself.',
                        style: AppTypography.small.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!storage.canReadMedia) ...[
              const SectionHeader(title: 'File access needed'),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.standard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow access to see your files',
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Screenshots, photos and downloads need the media permission. '
                      'Files stay on your device and are only read to measure them.',
                      style: AppTypography.small.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _requesting
                            ? null
                            : () => _requestMedia(storage),
                        icon: const Icon(Icons.perm_media_outlined, size: 18),
                        label: Text(_requesting ? 'Waiting…' : 'Allow access'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SectionHeader(title: 'Cleanup tools'),
            FeatureCard(
              icon: Icons.data_usage_rounded,
              title: 'Large files',
              subtitle: storage.largeFilesLoaded && storage.largeFiles.isNotEmpty
                  ? '${storage.largeFiles.length} files · ${formatBytes(storage.largeFileTotalBytes)}'
                  : 'Big videos, photos and downloads, sorted by size',
              onTap: () => _open(context, const LargeFilesPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.copy_all_rounded,
              title: 'Duplicates',
              subtitle: storage.duplicates.isEmpty
                  ? 'Identical copies found by content hash'
                  : '${storage.duplicateWastedBytesLabel} reclaimable',
              onTap: () => _open(context, const DuplicatesPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.photo_library_outlined,
              title: 'Similar photos',
              subtitle: 'Bursts and re-saved shots that look the same',
              onTap: () => _open(context, const SimilarPhotosPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.screenshot_rounded,
              title: 'Screenshots',
              subtitle: storage.screenshotsLoaded
                  ? '${storage.screenshots.length} found · ${formatBytes(storage.screenshotTotalBytes)}'
                  : 'Old screenshots pile up quickly',
              onTap: () => _open(context, const ScreenshotsPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            FeatureCard(
              icon: Icons.download_rounded,
              title: 'Downloads',
              subtitle: storage.downloadsLoaded
                  ? '${storage.downloads.length} files'
                  : 'Installers, archives and media in Downloads',
              onTap: () => _open(context, const DownloadsPage()),
              statusIcon: Icons.chevron_right_rounded,
            ),
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(
              text:
                  'Jemixo Safe only reads file names, sizes and dates. Nothing is '
                  'uploaded, and nothing is deleted without your confirmation.',
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
