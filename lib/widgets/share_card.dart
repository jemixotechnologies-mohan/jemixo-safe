import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/risk_palette.dart';
import '../core/utils/haptics.dart';
import 'app_widgets.dart';

/// A result rendered as a square image card for WhatsApp and family groups.
///
/// The card is shown in a preview sheet first, then rasterised from its own
/// RepaintBoundary and handed to the system share sheet as a PNG.
class ShareCardData {
  const ShareCardData({
    required this.kind,
    required this.headline,
    required this.level,
    required this.lines,
    this.quote,
  });

  /// "Message check", "Link check", "QR check".
  final String kind;
  final String headline;
  final RiskLevel level;

  /// Up to four short bullet points.
  final List<String> lines;

  /// The message or link being judged, shortened.
  final String? quote;
}

/// Opens the preview sheet and shares the rendered card on confirmation.
Future<void> shareResultCard(BuildContext context, ShareCardData data) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _ShareSheet(data: data),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.data});

  final ShareCardData data;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _boundary = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final level = widget.data.level;
      final verdict = switch (level) {
        RiskLevel.high || RiskLevel.critical => 'HIGH RISK',
        RiskLevel.medium => 'REVIEW',
        RiskLevel.low => 'LOW RISK',
        _ => 'LOOKS OK',
      };
      if (mounted) AppHaptics.success(context);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes.buffer.asUint8List(),
              name: 'jemixo-safe-check.png',
              mimeType: 'image/png',
            ),
          ],
          text:
              '$verdict: ${widget.data.headline}\n'
              'Checked with ${AppConstants.appName}. Report cyber fraud at 1930.',
          subject: '${AppConstants.appName} check',
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.standard,
          AppSpacing.screen,
          AppSpacing.standard + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this result', style: AppTypography.sectionTitle),
            const SizedBox(height: 4),
            Text(
              'The card is an image, so it works in WhatsApp groups and status. '
              'Your original message is not included.',
              style: AppTypography.small.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            Center(
              child: RepaintBoundary(
                key: _boundary,
                child: ShareCard(data: widget.data),
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share card'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card itself: fixed size so it renders identically everywhere.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.data});

  final ShareCardData data;

  @override
  Widget build(BuildContext context) {
    final level = data.level;
    final accent = switch (level) {
      RiskLevel.high || RiskLevel.critical => AppColors.danger,
      RiskLevel.medium => AppColors.warning,
      RiskLevel.low => AppColors.info,
      _ => AppColors.safe,
    };
    final verdict = switch (level) {
      RiskLevel.high || RiskLevel.critical => 'HIGH RISK',
      RiskLevel.medium => 'REVIEW CAREFULLY',
      RiskLevel.low => 'LOW RISK',
      _ => 'NO WARNING SIGNS',
    };
    final icon = switch (level) {
      RiskLevel.high || RiskLevel.critical => Icons.warning_amber_rounded,
      RiskLevel.medium => Icons.help_outline_rounded,
      _ => Icons.check_circle_outline_rounded,
    };

    return Container(
      width: 320,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.midnightGreen,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 17,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppConstants.appName,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Text(
                data.kind,
                style: AppTypography.small.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(icon, color: accent, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  verdict,
                  style: AppTypography.pageTitle.copyWith(
                    color: accent,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.headline,
            style: AppTypography.bodyStrong.copyWith(color: AppColors.darkText),
          ),
          if (data.quote != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${data.quote}"',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.small.copyWith(
                  color: AppColors.darkTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final line in data.lines.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTypography.small.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 10),
          Text(
            'Fraud helpline 1930 · cybercrime.gov.in · Checked offline on the phone',
            style: AppTypography.small.copyWith(
              color: AppColors.darkTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shortens a message for the card quote.
String quoteFor(String text, {int max = 110}) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= max) return compact;
  return '${compact.substring(0, max - 1)}…';
}

/// Small helper so pages can place a consistent "Share result" button.
class ShareResultButton extends StatelessWidget {
  const ShareResultButton({super.key, required this.data});

  final ShareCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => shareResultCard(context, data),
        icon: const Icon(Icons.share_rounded, size: 18),
        label: const Text('Share this result as an image'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
        ),
      ),
    );
  }
}

/// Convenience for pages that want the standard card container elsewhere.
Widget shareCardPreview(ShareCardData data) => AppCard(child: ShareCard(data: data));
