import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../services/risk_engine/sender_id.dart';
import '../../services/risk_engine/text_analyzers.dart';
import '../../state/dashboard_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/share_card.dart';
import '../url_checker/url_checker_page.dart';

/// Paste a message to spot pressure tactics, payment requests and OTP traps.
///
/// The scanner looks for language patterns only. It cannot verify whether a
/// sender is real, so the wording on screen is deliberately cautious.
class ScamScannerPage extends StatefulWidget {
  const ScamScannerPage({super.key, this.initialText});

  /// Text handed over by the share sheet.
  final String? initialText;

  @override
  State<ScamScannerPage> createState() => _ScamScannerPageState();
}

class _ScamScannerPageState extends State<ScamScannerPage> {
  late final TextEditingController _controller;
  final TextEditingController _sender = TextEditingController();
  SenderVerdict? _senderVerdict;

  @override
  void initState() {
    super.initState();
    final tools = context.read<ToolsController>();
    final initial = widget.initialText;
    _controller = TextEditingController(text: initial ?? tools.scamInput);
    if (initial != null && initial.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => tools.analyzeScam(initial),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _sender.dispose();
    super.dispose();
  }

  void _onSenderChanged(String value) {
    setState(() {
      _senderVerdict =
          value.trim().isEmpty ? null : const SenderIdAnalyzer().analyze(value);
    });
  }

  ShareCardData _cardFor(ScamFinding finding) {
    final lines = <String>[
      for (final i in finding.indicators.take(3)) i.title,
      if (_senderVerdict != null &&
          _senderVerdict!.level == RiskLevel.high)
        _senderVerdict!.title,
    ];
    return ShareCardData(
      kind: 'Message check',
      headline: finding.suspectedScamType ?? finding.headline,
      level: finding.level,
      lines: lines.isEmpty ? const ['No scam wording found'] : lines,
      quote: quoteFor(_controller.text),
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
    context.read<ToolsController>().analyzeScam(text);
  }

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<ToolsController>();
    final finding = tools.scam;
    final theme = Theme.of(context);
    final s = Strings.of(context);
    final color = finding == null
        ? theme.colorScheme.primary
        : RiskPalette.color(context, finding.level);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.scamScannerTitle),
        actions: [
          if (finding != null)
            IconButton(
              onPressed: () {
                _controller.clear();
                tools.clearScam();
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
                Text(s.isHindi ? 'मैसेज यहाँ पेस्ट करें' : 'Paste a message', style: AppTypography.sectionTitle),
                const SizedBox(height: 6),
                Text(
                  s.isHindi
                      ? 'SMS, WhatsApp, ईमेल या किसी भी चैट का संदिग्ध मैसेज यहाँ पेस्ट करें। सब कुछ आपके फ़ोन पर जाँचा जाता है।'
                      : 'Works for SMS, WhatsApp, email and anything else you received. '
                          'You can also share a message straight to Jemixo Safe. The text '
                          'stays on your phone.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                TextField(
                  controller: _controller,
                  minLines: 5,
                  maxLines: 10,
                  onChanged: tools.analyzeScam,
                  decoration: InputDecoration(
                    hintText: s.enterMessageHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.tight),
                TextField(
                  controller: _sender,
                  onChanged: _onSenderChanged,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: s.isHindi
                        ? 'भेजने वाला (वैकल्पिक): AX-SBIINB या +91 98xxxxxxx'
                        : 'Sender (optional): AX-SBIINB or +91 98xxxxxxx',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    filled: true,
                  ),
                ),
                if (_senderVerdict != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _senderVerdict!.level == RiskLevel.high
                            ? Icons.error_outline_rounded
                            : _senderVerdict!.level == RiskLevel.medium
                            ? Icons.help_outline_rounded
                            : Icons.verified_outlined,
                        size: 18,
                        color: RiskPalette.color(context, _senderVerdict!.level),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _senderVerdict!.title,
                              style: AppTypography.bodyStrong.copyWith(
                                color: RiskPalette.color(context, _senderVerdict!.level),
                              ),
                            ),
                            Text(
                              _senderVerdict!.detail,
                              style: AppTypography.small.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_senderVerdict!.suffixMeaning != null)
                              Text(
                                'Header type: ${_senderVerdict!.suffixMeaning}',
                                style: AppTypography.small.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.tight),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_controller.text.length} characters',
                        style: AppTypography.small.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.content_paste_rounded, size: 16),
                      label: const Text('Paste'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (finding != null) ...[
            const SectionHeader(title: 'Result'),
            AppCard(
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
                        child: Icon(_iconFor(finding), color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              finding.headline,
                              style: AppTypography.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              finding.level.label,
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
                  if (finding.suspectedScamType != null) ...[
                    const SizedBox(height: AppSpacing.tight),
                    StatusPill(
                      label: 'Looks like: ${finding.suspectedScamType}',
                      color: color,
                    ),
                  ],
                  if (finding.urls.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.standard),
                    Text(
                      'Links in this message',
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    for (final url in finding.urls)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                url,
                                style: AppTypography.mono.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                tools.analyzeUrl(url);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const UrlCheckerPage(),
                                  ),
                                );
                              },
                              child: const Text('Check'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
            ShareResultButton(data: _cardFor(finding)),
            const SizedBox(height: AppSpacing.tight),
            if (finding.isClean)
              SuccessBanner(
                title: 'No warning signs found',
                message:
                    'Nothing in the wording stood out. That is not a guarantee the '
                    'message is legitimate — check who sent it.',
              )
            else ...[
              const SectionHeader(title: 'What triggered this'),
              AppCard(
                child: Column(
                  children: [
                    for (final indicator in finding.indicators)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: RiskPalette.color(context, finding.level),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
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
                                  if (indicator.matched.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          for (final phrase
                                              in indicator.matched.take(4))
                                            StatusPill(
                                              label: '"$phrase"',
                                              color: color,
                                              dense: true,
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
                ),
              ),
              const SectionHeader(title: 'What to do next'),
              const _AdviceCard(),
            ],
          ] else ...[
            const SectionHeader(title: 'Common patterns this looks for'),
            const _PatternList(),
          ],
          const SizedBox(height: AppSpacing.standard),
          const DisclaimerNote(
            text:
                'This scanner matches language patterns. It cannot confirm '
                'whether a sender is genuine. ${AppConstants.disclaimerRisk}',
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ScamFinding finding) => switch (finding.level) {
    RiskLevel.critical || RiskLevel.high => Icons.warning_amber_rounded,
    RiskLevel.medium => Icons.help_outline_rounded,
    _ => Icons.check_circle_outline_rounded,
  };
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Advice(
            icon: Icons.pause_circle_outline_rounded,
            text:
                'Do not act immediately. Real institutions rarely demand a '
                'decision within minutes.',
          ),
          _Advice(
            icon: Icons.call_outlined,
            text:
                'Contact the organisation using the number on your card or their '
                'official website, not the one in the message.',
          ),
          _Advice(
            icon: Icons.password_rounded,
            text:
                'Never share an OTP, PIN or CVV with anyone, including someone '
                'claiming to be your bank or the police.',
          ),
          _Advice(
            icon: Icons.link_off_rounded,
            text:
                'Do not open links in the message. Type the address yourself.',
          ),
          _Advice(
            icon: Icons.report_outlined,
            text:
                'Report the message as spam in your messaging app. In India you '
                'can also report cyber fraud at 1930 or cybercrime.gov.in.',
          ),
        ],
      ),
    );
  }
}

class _Advice extends StatelessWidget {
  const _Advice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.royalBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.small.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternList extends StatelessWidget {
  const _PatternList();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        children: [
          _Advice(
            icon: Icons.timer_outlined,
            text:
                'Urgency and countdowns ("act within 2 hours", "last chance").',
          ),
          _Advice(
            icon: Icons.payments_outlined,
            text: 'Unexpected requests for money, gift cards, QR scans or crypto.',
          ),
          _Advice(
            icon: Icons.password_rounded,
            text: 'Asking you to read out an OTP, PIN or install a screen-sharing app.',
          ),
          _Advice(
            icon: Icons.account_balance_outlined,
            text: 'Claims your account, SIM or electricity will be cut unless you act now.',
          ),
          _Advice(
            icon: Icons.badge_outlined,
            text:
                'Impersonating a bank, police, customs, courier or employer.',
          ),
          _Advice(
            icon: Icons.link_rounded,
            text: 'Shortened links that hide the real destination.',
          ),
        ],
      ),
    );
  }
}
