import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/device_service/device_service.dart';
import '../../services/storage_analyzer/storage_service.dart';
import '../../state/security_controller.dart';
import '../../widgets/app_widgets.dart';

/// A single consolidated report. The PDF is generated on-device and handed to
/// the system share sheet, so the user decides where it goes.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<AppScannerService>();
    final security = context.watch<SecurityController>();
    final device = context.watch<DeviceService>();
    final storage = context.watch<StorageService>();
    final theme = Theme.of(context);

    final score = security.score;
    final level = score == null
        ? RiskLevel.medium
        : RiskPalette.levelForScore(score);

    return AppPageScaffold(
      title: 'Reports',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          if (!scanner.hasScanned)
            EmptyState(
              title: 'No report data yet',
              message:
                  'Run a security scan first so there is something to report.',
              icon: Icons.fact_check_outlined,
              actionLabel: security.isRunning ? null : 'Run scan',
              onAction: security.isRunning ? null : security.runScan,
            )
          else ...[
            AppCard(
              child: Column(
                children: [
                  ScoreRing(
                    score: score ?? 0,
                    color: RiskPalette.color(context, level),
                    size: 150,
                    label: score == null
                        ? 'Not scanned'
                        : RiskPalette.scoreBand(context, score),
                    caption: 'Safety score',
                    animate: false,
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  Text(
                    security.lastScanAt == null
                        ? 'Based on the current app inventory'
                        : 'Based on the scan from ${formatDateTime(security.lastScanAt!.millisecondsSinceEpoch)}',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Summary'),
            AppCard(
              child: Column(
                children: [
                  DetailRow(
                    label: 'User apps',
                    value: '${scanner.userApps.length}',
                  ),
                  DetailRow(
                    label: 'System apps',
                    value: '${scanner.systemApps.length}',
                  ),
                  DetailRow(
                    label: 'Needs review',
                    value: '${scanner.needsReview.length}',
                    valueColor: scanner.needsReview.isEmpty
                        ? AppColors.safe
                        : AppColors.warning,
                  ),
                  DetailRow(
                    label: 'Debuggable builds',
                    value: '${scanner.debuggableAppCount}',
                  ),
                  DetailRow(
                    label: 'Sideloaded',
                    value: '${scanner.sideloadedAppCount}',
                  ),
                  DetailRow(
                    label: 'Privacy score',
                    value: '${scanner.privacyScore}/100',
                  ),
                  if (device.device != null)
                    DetailRow(
                      label: 'Device',
                      value: device.device!.displayName,
                    ),
                  if (device.security != null)
                    DetailRow(
                      label: 'Screen lock',
                      value: device.security!.deviceSecure ? 'Set' : 'Not set',
                    ),
                  if (storage.overview != null)
                    DetailRow(
                      label: 'Free storage',
                      value: formatBytes(storage.overview!.freeBytes),
                    ),
                ],
              ),
            ),
            if (scanner.needsReview.isNotEmpty) ...[
              SectionHeader(
                title: 'Apps to review (${scanner.needsReview.length})',
              ),
              AppCard(
                child: Column(
                  children: [
                    for (final assessment in scanner.needsReview.take(15))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusPill(
                              label: '${assessment.score}',
                              color: RiskPalette.color(
                                context,
                                assessment.level,
                              ),
                              dense: true,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assessment.app.label,
                                    style: AppTypography.bodyStrong,
                                  ),
                                  if (assessment.topIndicator != null)
                                    Text(
                                      assessment.topIndicator!.title,
                                      style: AppTypography.small.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SectionHeader(title: 'Export'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Share as PDF', style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    "The PDF is written to app storage on this device and handed to "
                    "Android's share sheet. Nothing is uploaded by Jemixo Safe.",
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _exporting
                          ? null
                          : () => _export(
                              context,
                              scanner: scanner,
                              device: device,
                              storage: storage,
                              score: score,
                              scoreBand: score == null
                                  ? 'Not scanned'
                                  : RiskPalette.scoreBand(context, score),
                            ),
                      icon: _exporting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        _exporting
                            ? 'Building report…'
                            : 'Generate and share report',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(
              text:
                  '${AppConstants.disclaimerScore} ${AppConstants.disclaimerRisk}',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext context, {
    required AppScannerService scanner,
    required DeviceService device,
    required StorageService storage,
    required int? score,
    required String scoreBand,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final bytes = await _buildPdf(
        scanner: scanner,
        device: device,
        storage: storage,
        score: score,
        scoreBand: scoreBand,
      );
      final stamp = DateTime.now();
      final name =
          'jemixo-safe-report-${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}.pdf';
      if (mounted) AppHaptics.success(this.context);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, name: name, mimeType: 'application/pdf'),
          ],
          subject: 'Jemixo Safe report',
          fileNameOverrides: [name],
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not build the report: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<Uint8List> _buildPdf({
    required AppScannerService scanner,
    required DeviceService device,
    required StorageService storage,
    required int? score,
    required String scoreBand,
  }) async {
    // Inter covers Latin, Cyrillic and Greek; app labels in other scripts fall
    // back to the PDF core font rather than failing the export.
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'),
    );
    final document = pw.Document(
      title: 'Jemixo Safe report',
      author: AppConstants.appName,
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        fontFallback: [pw.Font.helvetica()],
      ),
    );
    final now = DateTime.now();
    final review = scanner.needsReview;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Generated on-device by ${AppConstants.appName} ${AppConstants.version} · page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Jemixo Safe — Device Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated ${formatDateTime(now.millisecondsSinceEpoch)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          if (score != null)
            pw.Text(
              'Safety score: $score / 100 — $scoreBand',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          pw.SizedBox(height: 12),
          _table(context, 'Summary', [
            ('User apps', '${scanner.userApps.length}'),
            ('System apps', '${scanner.systemApps.length}'),
            ('Apps needing review', '${review.length}'),
            ('High risk indicators', '${scanner.highRisk.length}'),
            ('Debuggable builds', '${scanner.debuggableAppCount}'),
            ('Installed outside a known store', '${scanner.sideloadedAppCount}'),
            ('Privacy score', '${scanner.privacyScore}/100'),
            if (device.device != null) ('Device', device.device!.displayName),
            if (device.device?.androidRelease != null)
              ('Android', device.device!.androidRelease!),
            if (device.device?.securityPatch != null)
              ('Security patch', device.device!.securityPatch!),
            if (storage.overview != null)
              ('Free storage', formatBytes(storage.overview!.freeBytes)),
            if (device.security != null)
              (
                'Screen lock',
                device.security!.deviceSecure ? 'Set' : 'Not set',
              ),
          ]),
          pw.SizedBox(height: 18),
          if (review.isNotEmpty) ...[
            pw.Text(
              'Apps to review',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            for (final assessment in review.take(40))
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${assessment.app.label} (${assessment.app.packageName}) — ${assessment.score}/100',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    for (final indicator in assessment.indicators.take(4))
                      pw.Text(
                        '• ${indicator.title}: ${indicator.description}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              ),
            pw.SizedBox(height: 12),
          ],
          pw.Text(
            AppConstants.disclaimerScore,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            AppConstants.disclaimerRisk,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _table(
    pw.Context context,
    String title,
    List<(String, String)> rows,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          context: context,
          headers: const ['Item', 'Value'],
          data: <List<String>>[
            for (final row in rows) [row.$1, row.$2],
          ],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          border: null,
          cellAlignments: const {},
        ),
      ],
    );
  }
}
