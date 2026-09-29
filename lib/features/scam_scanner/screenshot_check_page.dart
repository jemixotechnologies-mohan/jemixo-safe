import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../services/ocr/ocr_service.dart';
import '../../services/platform/native_models.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../widgets/app_widgets.dart';
import '../storage/storage_list_scaffold.dart';
import 'scam_scanner_page.dart';

/// Pick a recent screenshot or photo, read its text on the phone, and run the
/// scam scanner on it. Also the landing point for images shared to the app.
class ScreenshotCheckPage extends StatefulWidget {
  const ScreenshotCheckPage({super.key, this.initialImagePath});

  /// Image handed over by the share sheet; checked immediately.
  final String? initialImagePath;

  @override
  State<ScreenshotCheckPage> createState() => _ScreenshotCheckPageState();
}

class _ScreenshotCheckPageState extends State<ScreenshotCheckPage> {
  bool _loading = true;
  String? _workingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = widget.initialImagePath;
      if (initial != null) {
        await _run(initial, id: initial);
      }
      await _load();
    });
  }

  Future<void> _load() async {
    final storage = context.read<StorageService>();
    await storage.checkStorageAccess();
    if (storage.canReadMedia) {
      await storage.loadScreenshots();
      if (storage.screenshots.length < 12) await storage.loadImages(limit: 60);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _run(String target, {required String id}) async {
    final ocr = context.read<OcrService>();
    setState(() => _workingId = id);
    final text = await ocr.recognize(target);
    if (!mounted) return;
    setState(() => _workingId = null);
    if (text == null || text.trim().length < 8) {
      AppHaptics.warning(context);
      showAppSnack(
        context,
        ocr.lastError ?? 'No readable text in that image. Try a clearer screenshot.',
      );
      return;
    }
    AppHaptics.success(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScamScannerPage(initialText: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final ocr = context.watch<OcrService>();
    final theme = Theme.of(context);
    final files = <StorageFile>[
      ...storage.screenshots,
      ...storage.images.where(
        (i) => !storage.screenshots.any((s) => s.id == i.id),
      ),
    ]..sort((a, b) => (b.modified ?? 0).compareTo(a.modified ?? 0));

    return AppPageScaffold(
      title: 'Check a screenshot',
      subtitle: 'Text is read on the phone, never uploaded',
      child: !storage.canReadMedia && !_loading
          ? const StorageAccessGate(required: StorageAccess.media)
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    AppSpacing.tight,
                  ),
                  child: InfoBanner(
                    title: 'Tap a screenshot to check it',
                    message:
                        'Works for SMS, WhatsApp, email and Telegram screenshots in '
                        'English and Hindi. You can also share any image to Jemixo Safe '
                        'from the gallery.',
                    icon: Icons.document_scanner_outlined,
                  ),
                ),
                if (ocr.isBusy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.tight),
                    child: LinearProgressIndicator(minHeight: 4),
                  ),
                Expanded(
                  child: files.isEmpty
                      ? const EmptyState(
                          title: 'No screenshots found',
                          message:
                              'Take a screenshot of the message, or share the image to '
                              'Jemixo Safe from your gallery.',
                          icon: Icons.screenshot_rounded,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            0,
                            AppSpacing.screen,
                            AppSpacing.standard * 2,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            final file = files[index];
                            return _Tile(
                              file: file,
                              working: _workingId == file.id,
                              thumbnail: storage.thumbnail(file, size: 256),
                              onTap: ocr.isBusy
                                  ? null
                                  : () => _run(file.target, id: file.id),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.tight),
                  child: Text(
                    'Only the screenshot you tap is read. Nothing is stored.',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.file,
    required this.working,
    required this.thumbnail,
    required this.onTap,
  });

  final StorageFile file;
  final bool working;
  final Future<Uint8List?> thumbnail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<Uint8List?>(
              future: thumbnail,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null || data.isEmpty) {
                  return Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    child: const Icon(Icons.image_outlined),
                  );
                }
                return Image.memory(data, fit: BoxFit.cover, gaplessPlayback: true);
              },
            ),
          ),
          if (working)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}
