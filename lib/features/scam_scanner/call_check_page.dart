import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../services/risk_engine/call_number.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/share_card.dart';
import '../emergency/scam_call_page.dart';

/// Offline caller-number check using TRAI numbering rules.
class CallCheckPage extends StatefulWidget {
  const CallCheckPage({super.key});

  @override
  State<CallCheckPage> createState() => _CallCheckPageState();
}

class _CallCheckPageState extends State<CallCheckPage> {
  final TextEditingController _controller = TextEditingController();
  CallerVerdict? _verdict;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze(String value) {
    setState(() {
      _verdict = value.trim().isEmpty ? null : const CallNumberAnalyzer().analyze(value);
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      showAppSnack(context, 'Clipboard is empty.');
      return;
    }
    _controller.text = text;
    _analyze(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = _verdict;
    final color = verdict == null
        ? theme.colorScheme.primary
        : RiskPalette.color(context, verdict.level);

    return AppPageScaffold(
      title: 'Check a phone number',
      subtitle: 'Who can really be calling from it?',
      child: ListView(
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
                Text('Number that called or messaged', style: AppTypography.sectionTitle),
                const SizedBox(height: 6),
                Text(
                  'No lookup service is used. The check applies TRAI numbering '
                  'rules: 140 = telemarketer, 1600 = verified service call, '
                  'foreign or personal numbers cannot be a bank, police or courier.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  onChanged: _analyze,
                  decoration: InputDecoration(
                    hintText: '+91 98765 43210, 1600xxxxxx, +92…',
                    prefixIcon: const Icon(Icons.call_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.tight),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                    label: const Text('Paste'),
                  ),
                ),
              ],
            ),
          ),
          if (verdict != null) ...[
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
                        child: Icon(
                          switch (verdict.kind) {
                            CallerKind.international => Icons.public_off_rounded,
                            CallerKind.verifiedService => Icons.verified_outlined,
                            CallerKind.telemarketer => Icons.campaign_outlined,
                            CallerKind.tollFree => Icons.support_agent_rounded,
                            CallerKind.indianMobile => Icons.smartphone_rounded,
                            CallerKind.indianLandline => Icons.phone_rounded,
                            CallerKind.unknown => Icons.help_outline_rounded,
                          },
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(verdict.title, style: AppTypography.cardTitle),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    verdict.detail,
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
            ShareResultButton(
              data: ShareCardData(
                kind: 'Caller check',
                headline: verdict.title,
                level: verdict.level,
                lines: [verdict.detail.split('. ').first],
                quote: _controller.text,
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ScamCallPage()),
                ),
                icon: const Icon(Icons.sos_rounded, size: 18, color: AppColors.danger),
                label: const Text('They are threatening me on the call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
          ] else ...[
            const SectionHeader(title: 'Number ranges in India'),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RangeRow(prefix: '1600', meaning: 'Verified service / transactional calls (banks, insurers, government)'),
                  _RangeRow(prefix: '140', meaning: 'Registered telemarketers, promotional only'),
                  _RangeRow(prefix: '1800 / 1860', meaning: 'Toll-free helplines; they rarely call out'),
                  _RangeRow(prefix: '6–9 + 9 digits', meaning: 'Personal mobiles; never an official bank or police call'),
                  _RangeRow(prefix: '+92, +84, +62, +1, +44 …', meaning: 'Foreign numbers; job, parcel and "digital arrest" scams'),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.standard),
          Text(
            'Caller ID can be spoofed, so a "good" pattern is not proof. The '
            'safest move is always to hang up and call the official number yourself.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.prefix, required this.meaning});

  final String prefix;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(prefix, style: AppTypography.mono.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              meaning,
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
