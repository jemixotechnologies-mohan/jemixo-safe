import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/haptics.dart';
import '../../services/risk_engine/upi_parser.dart';
import '../../state/dashboard_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/share_card.dart';
import '../url_checker/url_checker_page.dart';

/// QR scanner. A scanned code can be a link, a UPI payment request, a Wi-Fi
/// config or plain text, so the result is routed to whichever checker fits.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;
  String _raw = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR scanner'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Torch',
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Switch camera',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) return;
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.isNotEmpty) {
                  _handled = true;
                  _onDetected(value);
                  return;
                }
              }
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.standard),
                child: EmptyState(
                  title: 'Camera unavailable',
                  message:
                      'Jemixo Safe needs camera permission to scan a code. You can '
                      'still paste a link in the URL checker instead.',
                  icon: Icons.no_photography_outlined,
                  actionLabel: 'Open URL checker',
                  onAction: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const UrlCheckerPage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          if (_raw.isNotEmpty)
            Positioned(
              left: AppSpacing.standard,
              right: AppSpacing.standard,
              bottom: AppSpacing.standard,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_kindLabel(_raw), style: AppTypography.label),
                    const SizedBox(height: 4),
                    Text(
                      _raw,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _analyze(_raw),
                            icon: Icon(
                              UpiPayment.looksLikeUpi(_raw)
                                  ? Icons.currency_rupee_rounded
                                  : _looksLikeUrl(_raw)
                                  ? Icons.link_rounded
                                  : Icons.fact_check_outlined,
                              size: 18,
                            ),
                            label: Text(
                              UpiPayment.looksLikeUpi(_raw)
                                  ? 'Check payment'
                                  : _looksLikeUrl(_raw)
                                  ? 'Check link'
                                  : 'Check text',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.tight),
                        OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(52, 44),
                          ),
                          child: const Icon(Icons.refresh_rounded, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: AppSpacing.standard,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  _raw.isEmpty ? 'Point at a QR code' : 'Code captured',
                  style: AppTypography.small.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          if (_raw.isEmpty)
            Positioned(
              bottom: AppSpacing.standard,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_rounded, size: 16),
                  label: const Text('Paste instead'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    backgroundColor: theme.colorScheme.surface.withValues(
                      alpha: 0.85,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      showAppSnack(context, 'Clipboard is empty.');
      return;
    }
    _handled = true;
    _onDetected(text);
  }

  void _onDetected(String value) {
    AppHaptics.success(context);
    setState(() => _raw = value);
    _controller.stop();
  }

  Future<void> _reset() async {
    setState(() {
      _raw = '';
      _handled = false;
    });
    try {
      await _controller.start();
    } catch (_) {
      // Camera may already be running.
    }
  }

  static bool _looksLikeUrl(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return true;
    }
    if (lower.startsWith('upi://') || lower.startsWith('wifi:')) return false;
    return RegExp(r'^(www\.)?[a-z0-9-]+(\.[a-z0-9-]+)+(/|$)').hasMatch(lower);
  }

  static String _kindLabel(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.startsWith('upi://')) return 'UPI payment request';
    if (lower.startsWith('wifi:')) return 'Wi-Fi network';
    if (lower.startsWith('tel:')) return 'Phone number';
    if (lower.startsWith('mailto:')) return 'Email address';
    if (_looksLikeUrl(value)) return 'Link';
    return 'Text';
  }

  void _analyze(String value) {
    if (UpiPayment.looksLikeUpi(value)) {
      final payment = UpiPayment.parse(value);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UpiResultPage(payment: payment, raw: value),
        ),
      );
      return;
    }
    final tools = context.read<ToolsController>();
    final isUrl = _looksLikeUrl(value);
    if (isUrl) {
      tools.analyzeUrl(value);
    } else {
      tools.analyzeScam(value);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QrResultPage(isUrl: isUrl)),
    );
  }
}

/// Decoded UPI payment request: who gets paid, how much, and what to check.
class UpiResultPage extends StatelessWidget {
  const UpiResultPage({super.key, required this.payment, required this.raw});

  final UpiPayment? payment;
  final String raw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = payment;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('UPI code')),
        body: EmptyState(
          title: 'Could not read this UPI code',
          message:
              'The code uses the UPI scheme but has no payee address. Do not pay '
              'through it.\n\n$raw',
          icon: Icons.qr_code_2_rounded,
        ),
      );
    }
    final level = p.level;
    final color = RiskPalette.color(context, level);
    final observations = p.observations();
    return Scaffold(
      appBar: AppBar(title: const Text('UPI payment check')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.standard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.hasAmount
                      ? 'You would PAY ₹${p.amount!.toStringAsFixed(p.amount! == p.amount!.roundToDouble() ? 0 : 2)}'
                      : 'You would PAY (amount typed by you)',
                  style: AppTypography.pageTitle.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scanning never gives you money. Only continue if you meant to pay this person or shop.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                DetailRow(label: 'Payee name', value: p.payeeName ?? 'Not given'),
                DetailRow(label: 'UPI address', value: p.payeeAddress, monospace: true),
                DetailRow(
                  label: 'Bank handle',
                  value: p.handle.isEmpty
                      ? 'Missing'
                      : '@${p.handle}${p.knownHandle ? ' · recognised' : ' · unfamiliar'}',
                ),
                if (p.note != null) DetailRow(label: 'Note', value: p.note!),
                DetailRow(
                  label: 'Type',
                  value: p.isCollect
                      ? 'Collect request'
                      : p.isMandate
                      ? 'Recurring mandate'
                      : p.isMerchant
                      ? 'Merchant payment'
                      : 'Person-to-person payment',
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'What to check'),
          AppCard(
            child: Column(
              children: [
                for (final note in observations)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          note.level == RiskLevel.high
                              ? Icons.error_outline_rounded
                              : note.level == RiskLevel.medium
                              ? Icons.help_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 18,
                          color: RiskPalette.color(context, note.level),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note.title, style: AppTypography.bodyStrong),
                              Text(
                                note.detail,
                                style: AppTypography.small.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
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
          const SizedBox(height: AppSpacing.standard),
          ShareResultButton(
            data: ShareCardData(
              kind: 'QR / UPI check',
              headline: p.hasAmount
                  ? 'Pays ₹${p.amount!.toStringAsFixed(0)} to ${p.payeeName ?? p.payeeAddress}'
                  : 'Pays ${p.payeeName ?? p.payeeAddress}',
              level: level,
              lines: observations.map((o) => o.title).toList(),
              quote: p.payeeAddress,
            ),
          ),
          const SizedBox(height: AppSpacing.standard),
          const DisclaimerNote(
            text:
                'Jemixo Safe does not start the payment. Open your UPI app only if '
                'you meant to pay, and read the verified payee name it shows.',
          ),
        ],
      ),
    );
  }
}

/// Shows whichever analysis the scanned code produced.
class QrResultPage extends StatelessWidget {
  const QrResultPage({super.key, required this.isUrl});

  final bool isUrl;

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<ToolsController>();
    final theme = Theme.of(context);
    final url = tools.url;
    final scam = tools.scam;

    if (isUrl && url != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scanned link')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            UrlResultCard(analysis: url),
            const SectionHeader(title: 'Checks'),
            UrlChecksCard(analysis: url),
            const SizedBox(height: AppSpacing.standard),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const UrlCheckerPage(),
                  ),
                ),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Open in URL checker'),
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(
              text:
                  'A scanned code is not opened automatically, and a clean result '
                  'does not mean the destination is safe.',
            ),
          ],
        ),
      );
    }

    if (!isUrl && scam != null) {
      final color = RiskPalette.color(context, scam.level);
      return Scaffold(
        appBar: AppBar(title: const Text('Scanned text')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scam.headline, style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  StatusPill(label: scam.level.label, color: color),
                  if (tools.scamInput.toLowerCase().startsWith('upi://')) ...[
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      'This is a UPI payment request. Only pay if you initiated '
                      'the purchase and recognise the payee name shown by your '
                      'UPI app.',
                      style: AppTypography.small.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (scam.indicators.isNotEmpty) ...[
              const SectionHeader(title: 'What triggered this'),
              AppCard(
                child: Column(
                  children: [
                    for (final indicator in scam.indicators)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              indicator.title,
                              style: AppTypography.bodyStrong,
                            ),
                            Text(
                              indicator.why,
                              style: AppTypography.small.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.standard),
                child: SuccessBanner(
                  title: 'No warning signs in the text',
                  message:
                      'Nothing in the wording stood out. That is not proof the '
                      'code is legitimate.',
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scanned content')),
      body: const EmptyState(
        title: 'Nothing to analyze',
        message: 'The code did not contain a link or text we recognise.',
        icon: Icons.qr_code_2_rounded,
      ),
    );
  }
}
