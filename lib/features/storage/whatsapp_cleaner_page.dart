import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../services/storage_analyzer/whatsapp_media.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import 'large_files_page.dart';
import 'storage_list_scaffold.dart';

/// WhatsApp photos, videos, voice notes and GIFs in one place: how much space
/// they take, which are old, big, duplicated or sent by you, and a
/// confirmed delete.
class WhatsAppCleanerPage extends StatefulWidget {
  const WhatsAppCleanerPage({super.key});

  @override
  State<WhatsAppCleanerPage> createState() => _WhatsAppCleanerPageState();
}

class _WhatsAppCleanerPageState extends State<WhatsAppCleanerPage> {
  WhatsAppFilter _filter = WhatsAppFilter.all;
  WhatsAppKind? _kind;
  Set<String> _duplicateIds = const {};
  bool _findingDuplicates = false;
  bool _duplicatesChecked = false;

  Future<void> _findDuplicates(StorageService storage) async {
    setState(() => _findingDuplicates = true);
    await storage.loadDuplicates();
    if (!mounted) return;
    setState(() {
      _duplicateIds = WhatsAppCleaner.duplicateIdsFrom(storage.duplicates);
      _duplicatesChecked = true;
      _findingDuplicates = false;
      _filter = WhatsAppFilter.duplicates;
    });
    if (_duplicateIds.isEmpty) {
      showAppSnack(context, 'No duplicate WhatsApp files found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    return StorageListScaffold(
      title: 'WhatsApp cleaner',
      requiredAccess: StorageAccess.media,
      summaryLabel: 'WhatsApp media on this phone',
      summaryBytes: storage.whatsappTotalBytes,
      isLoading: (s) => s.isLoadingWhatsApp,
      onLoad: (s, _) => s.loadWhatsApp(),
      onReload: (s, _) => s.loadWhatsApp(force: true),
      builder: (context, storage, selection, onToggle) {
        final all = storage.whatsapp;
        if (all.isEmpty) {
          return const EmptyState(
            title: 'No WhatsApp media found',
            message:
                'Either WhatsApp is not installed, media auto-download is off, '
                'or Android has not indexed the files yet. Only photos, videos, '
                'GIFs and audio are visible to this app.',
            icon: Icons.chat_outlined,
          );
        }

        // Restore the shown list after each rebuild without keeping stale ids.
        var shown = all.where((m) {
          if (_kind != null && m.kind != _kind) return false;
          return WhatsAppCleaner.matches(m, _filter, duplicateIds: _duplicateIds);
        }).toList()
          ..sort((a, b) => b.file.sizeBytes.compareTo(a.file.sizeBytes));
        final shownBytes = shown.fold<int>(0, (s, m) => s + m.file.sizeBytes);
        final byKind = WhatsAppCleaner.bytesByKind(all);
        final total = storage.whatsappTotalBytes;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatBytes(total)} in ${all.length} files',
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: 4),
                  for (final entry in byKind.take(5))
                    MetricBar(
                      label: entry.key.label,
                      valueLabel: formatBytes(entry.value),
                      fraction: total == 0 ? 0 : entry.value / total,
                      color: entry.key == WhatsAppKind.videos
                          ? AppColors.warning
                          : AppColors.royalBlue,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
            const InfoBanner(
              title: 'Deleted files stay in the chat as "missing"',
              message:
                  'The message remains but the photo or video will not open. Keep '
                  'anything you still need, or back it up first. Documents (PDF, '
                  'APK, zip) are not visible to Jemixo Safe.',
            ),
            const SizedBox(height: AppSpacing.standard),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final filter in WhatsAppFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: _filter == filter,
                        onSelected: (_) {
                          if (filter == WhatsAppFilter.duplicates &&
                              !_duplicatesChecked) {
                            _findDuplicates(storage);
                          } else {
                            setState(() => _filter = filter);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All types'),
                      selected: _kind == null,
                      onSelected: (_) => setState(() => _kind = null),
                    ),
                  ),
                  for (final entry in byKind)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.key.label),
                        selected: _kind == entry.key,
                        onSelected: (_) => setState(() => _kind = entry.key),
                      ),
                    ),
                ],
              ),
            ),
            if (_findingDuplicates)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.tight),
                child: LinearProgressIndicator(minHeight: 4),
              ),
            const SizedBox(height: AppSpacing.tight),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${shown.length} file${shown.length == 1 ? '' : 's'} · ${formatBytes(shownBytes)}',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (shown.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      for (final media in shown) {
                        onToggle(media.file, true);
                      }
                    },
                    child: const Text('Select all shown'),
                  ),
              ],
            ),
            if (shown.isEmpty)
              const EmptyState(
                title: 'Nothing matches this filter',
                message: 'Try another filter or file type.',
                icon: Icons.filter_alt_off_rounded,
                compact: true,
              )
            else
              for (final media in shown.take(400))
                FileListTile(
                  file: media.file,
                  thumbnailLoader: storage.thumbnail,
                  selected: selection.contains(media.file.id),
                  onTap: () => onToggle(
                    media.file,
                    !selection.contains(media.file.id),
                  ),
                  onOpen: () => openStorageFile(context, storage, media.file),
                  note: [
                    media.kind.label,
                    if (media.sent) 'Sent by you',
                    if (media.business) 'WhatsApp Business',
                  ].join(' · '),
                  trailing: Checkbox(
                    value: selection.contains(media.file.id),
                    onChanged: (v) => onToggle(media.file, v ?? false),
                  ),
                ),
            if (shown.length > 400)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.tight),
                child: Text(
                  'Showing the 400 biggest of ${shown.length}. Delete some and refresh to see the rest.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
