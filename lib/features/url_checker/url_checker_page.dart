import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../services/risk_engine/link_reveal.dart';
import '../../services/risk_engine/text_analyzers.dart';
import '../../state/dashboard_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/share_card.dart';
import '../qr_scanner/qr_scanner_page.dart';

/// Structural URL checks. The app never visits the address, so it cannot tell
/// you whether a site is currently serving malware — only whether the link
/// itself looks deceptive.
class UrlCheckerPage extends StatefulWidget {
  const UrlCheckerPage({super.key});

  @override
  State<UrlCheckerPage> createState() => _UrlCheckerPageState();
}

class _UrlCheckerPageState extends State<UrlCheckerPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<ToolsController>().urlInput,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<ToolsController>();
    final analysis = tools.url;
    final theme = Theme.of(context);
    final s = Strings.of(context);

    // Keep the field in sync when another screen (scam scanner, QR) set the URL.
    if (analysis != null && _controller.text != tools.urlInput) {
      _controller.text = tools.urlInput;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.checkUrlTitle),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QrScannerPage()),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: s.checkQr,
          ),
          if (analysis != null)
            IconButton(
              onPressed: () {
                _controller.clear();
                tools.clearUrl();
              },
              icon: const Icon(Icons.clear_all_rounded),
              tooltip: s.isHindi ? 'हटाएं' : 'Clear',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.checkLink, style: AppTypography.sectionTitle),
                const SizedBox(height: 6),
                Text(
                  s.isHindi
                      ? 'कोई भी लिंक यहाँ पेस्ट करें। Jemixo Safe जाँच करेगा कि यह किसी बैंक या संस्था का फ़र्ज़ी लिंक तो नहीं है।'
                      : 'Paste a link and Jemixo Safe will inspect how it is written — '
                          'scheme, domain shape, and brand impersonation.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onChanged: tools.analyzeUrl,
                  decoration: InputDecoration(
                    hintText: 'https://example.com/page',
                    prefixIcon: const Icon(Icons.link_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('Paste from clipboard'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (analysis != null) ...[
            const SectionHeader(title: 'Result'),
            UrlResultCard(analysis: analysis),
            if (analysis.checks.any((c) => c.title == 'Shortened link' && !c.passed)) ...[
              const SizedBox(height: AppSpacing.tight),
              _RevealCard(analysis: analysis),
            ],
            const SectionHeader(title: 'Checks'),
            UrlChecksCard(analysis: analysis),
            const SizedBox(height: AppSpacing.standard),
            ShareResultButton(
              data: ShareCardData(
                kind: 'Link check',
                headline: analysis.verdict,
                level: analysis.level,
                lines: analysis.failures.isEmpty
                    ? const ['No suspicious patterns in the address']
                    : analysis.failures.map((f) => f.title).toList(),
                quote: quoteFor(analysis.original, max: 80),
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            _HowToRead(analysis: analysis),
          ],
          const SizedBox(height: AppSpacing.standard),
          const DisclaimerNote(
            text:
                'Jemixo Safe does not open the link or contact the website. This '
                'is a check of how the address is written, not a live safety test. '
                '${AppConstants.disclaimerRisk}',
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
    _controller.text = text;
    context.read<ToolsController>().analyzeUrl(text);
  }
}

/// Verdict header shared with the QR result screen.
class UrlResultCard extends StatelessWidget {
  const UrlResultCard({super.key, required this.analysis});

  final UrlAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final color = RiskPalette.color(context, analysis.level);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  analysis.level == RiskLevel.safe
                      ? Icons.verified_rounded
                      : Icons.gpp_maybe_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.verdict, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      analysis.level.label,
                      style: AppTypography.small.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (analysis.isOfficial) ...[
            const SizedBox(height: AppSpacing.tight),
            const StatusPill(
              label: 'Verified official domain',
              color: AppColors.safe,
              icon: Icons.verified_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.standard),
          DetailRow(label: 'Host', value: analysis.host, monospace: true),
          DetailRow(
            label: 'Encryption',
            value: !analysis.hasScheme
                ? 'Not stated'
                : analysis.isHttps
                ? 'HTTPS'
                : 'Not HTTPS',
            valueColor: !analysis.hasScheme
                ? null
                : analysis.isHttps
                ? AppColors.safe
                : AppColors.warning,
          ),
          DetailRow(
            label: 'Checks passed',
            value:
                '${analysis.checks.where((c) => c.passed).length} of ${analysis.checks.length}',
          ),
        ],
      ),
    );
  }
}

/// Per-check list shared with the QR result screen.
class UrlChecksCard extends StatelessWidget {
  const UrlChecksCard({super.key, required this.analysis});

  final UrlAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = RiskPalette.color(context, analysis.level);
    final sorted = [...analysis.checks]
      ..sort((a, b) => (a.passed ? 1 : 0).compareTo(b.passed ? 1 : 0));
    return AppCard(
      child: Column(
        children: [
          for (final check in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    check.passed
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 19,
                    color: check.passed ? AppColors.safe : color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(check.title, style: AppTypography.bodyStrong),
                        Text(
                          check.detail,
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
    );
  }
}

/// Resolves a shortened link's redirect chain with HEAD requests.
class _RevealCard extends StatefulWidget {
  const _RevealCard({required this.analysis});

  final UrlAnalysis analysis;

  @override
  State<_RevealCard> createState() => _RevealCardState();
}

class _RevealCardState extends State<_RevealCard> {
  LinkRevealResult? _result;
  bool _busy = false;

  Future<void> _reveal() async {
    final proceed = await confirmDestructiveAction(
      context,
      title: 'Reveal where this link goes?',
      message:
          'Jemixo Safe will ask the link shortener where it redirects, without '
          'loading the page. The shortener (and whoever made the link) can see '
          'that the link was resolved. No cookies or identifiers are sent.',
      confirmLabel: 'Reveal',
    );
    if (!proceed || !mounted) return;
    setState(() => _busy = true);
    final result = await const LinkReveal().reveal(widget.analysis.normalized);
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shortened link', style: AppTypography.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'The real destination is hidden. You can reveal it without opening the page.',
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.tight),
          if (result == null)
            OutlinedButton.icon(
              onPressed: _busy ? null : _reveal,
              icon: _busy
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.travel_explore_rounded, size: 18),
              label: const Text('Reveal destination'),
            )
          else ...[
            if (result.error != null)
              Text(result.error!, style: AppTypography.small.copyWith(color: AppColors.warning)),
            for (final hop in result.hops)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${hop.status}  ${hop.url}',
                  style: AppTypography.mono.copyWith(fontSize: 12),
                ),
              ),
            const SizedBox(height: 6),
            Text('Ends at:', style: AppTypography.small),
            Text(result.finalUrl, style: AppTypography.bodyStrong),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => context.read<ToolsController>().analyzeUrl(result.finalUrl),
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: const Text('Check the final address'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowToRead extends StatelessWidget {
  const _HowToRead({required this.analysis});

  final UrlAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final risky =
        analysis.level == RiskLevel.high || analysis.level == RiskLevel.critical;
    return AppCard(
      color: AppColors.gold.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to judge a link', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'A clean result means nothing suspicious was found in the address. It '
            'does not mean the site is safe. Before signing in, check the domain '
            'carefully and prefer typing the address yourself.',
            style: AppTypography.small.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.standard),
          SizedBox(
            width: double.infinity,
            child: risky
                ? OutlinedButton.icon(
                    onPressed: () => _open(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open anyway'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () => _open(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open in browser'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    if (analysis.level != RiskLevel.safe && analysis.level != RiskLevel.low) {
      final proceed = await confirmDestructiveAction(
        context,
        title: 'Open a risky link?',
        message:
            '${analysis.verdict}. If you continue, the link opens in your '
            'browser. Do not enter passwords or OTPs on the page.',
        confirmLabel: 'Open anyway',
      );
      if (!proceed || !context.mounted) return;
    }
    final uri = Uri.tryParse(analysis.normalized);
    if (uri == null || uri.host.isEmpty) {
      showAppSnack(context, 'That address could not be opened.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showAppSnack(context, 'No app could open that address.');
    }
  }
}
