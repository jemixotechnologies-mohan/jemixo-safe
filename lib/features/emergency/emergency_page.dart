import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/threat_data/threat_data.dart';
import '../../widgets/app_widgets.dart';

/// "I think I have been scammed" flow. The first hour decides whether the
/// money can be frozen, so this screen is nothing but the next three actions.
class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final threat = context.watch<ThreatDataService>();
    final helplines = threat.data.helplines;
    final theme = Theme.of(context);
    final banks = helplines.where((h) => h.kind == 'bank').toList();
    final upi = helplines.where((h) => h.kind == 'upi').toList();
    final portals = helplines
        .where((h) => h.kind != 'bank' && h.kind != 'upi' && h.url != null)
        .toList();

    return AppPageScaffold(
      title: 'I got scammed',
      subtitle: 'What to do in the first hour',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.standard),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call ${AppConstants.cyberHelpline} now',
                  style: AppTypography.pageTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'National Cyber Crime Helpline. Reporting within the first '
                  'hour lets banks freeze the money before it is moved on. '
                  'Free, 24×7, all languages.',
                  style: AppTypography.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _dial(context, AppConstants.cyberHelpline),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Dial 1930'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _open(context, AppConstants.cyberPortal),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Report online'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Do these now, in this order'),
          const AppCard(
            child: Column(
              children: [
                _Step(
                  number: 1,
                  title: 'Stop the bleeding',
                  body:
                      'End the call or chat. Do not send "one more" payment or '
                      'OTP. If a screen-sharing app (AnyDesk, TeamViewer, QuickSupport) '
                      'was installed, switch the phone to airplane mode and uninstall it.',
                ),
                _Step(
                  number: 2,
                  title: 'Freeze the money',
                  body:
                      'Call 1930, then your bank or UPI app helpline below. Ask '
                      'them to block the card / UPI and raise a chargeback. Note '
                      'the complaint number they give you.',
                ),
                _Step(
                  number: 3,
                  title: 'Lock the accounts',
                  body:
                      'Change your net-banking, UPI PIN, email and WhatsApp '
                      'passwords from a different device if possible. Turn on '
                      'two-step verification in WhatsApp and email.',
                ),
                _Step(
                  number: 4,
                  title: 'Keep the evidence',
                  body:
                      'Screenshots of messages, the number that called, UPI '
                      'transaction IDs, the app or link used. The complaint '
                      'needs these; do not delete anything yet.',
                ),
                _Step(
                  number: 5,
                  title: 'Report and warn',
                  body:
                      'File at cybercrime.gov.in, report the number on Sanchar '
                      'Saathi, and tell family so the same story does not work '
                      'on them.',
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Bank helplines'),
          AppCard(
            child: Column(
              children: [
                for (final line in banks)
                  _HelplineRow(
                    line: line,
                    onCall: () => _dial(context, line.number!),
                    onCopy: () => _copy(context, line.number!),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Numbers are the public customer-care lines. Always cross-check '
                  'on the back of your card or the bank\'s website; never trust a '
                  'number sent to you in a message.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'UPI and wallet helplines'),
          AppCard(
            child: Column(
              children: [
                for (final line in upi)
                  _HelplineRow(
                    line: line,
                    onCall: line.number == null
                        ? null
                        : () => _dial(context, line.number!),
                    onCopy: line.number == null
                        ? null
                        : () => _copy(context, line.number!),
                    onOpen: line.url == null ? null : () => _open(context, line.url!),
                  ),
              ],
            ),
          ),
          const SectionHeader(title: 'Official portals'),
          AppCard(
            child: Column(
              children: [
                for (final line in portals)
                  _HelplineRow(
                    line: line,
                    onOpen: () => _open(context, line.url!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.standard),
          Text(
            'Jemixo Safe is not connected to any bank or authority. This screen '
            'only dials numbers and opens websites; nothing is sent from the app.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dial(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      showAppSnack(context, 'No dialler available. Number: $number');
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showAppSnack(context, 'Could not open $url');
  }

  Future<void> _copy(BuildContext context, String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (context.mounted) showAppSnack(context, 'Copied $number');
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppTypography.smallStrong.copyWith(
                color: AppColors.royalBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
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

class _HelplineRow extends StatelessWidget {
  const _HelplineRow({
    required this.line,
    this.onCall,
    this.onCopy,
    this.onOpen,
  });

  final Helpline line;
  final VoidCallback? onCall;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: AppTypography.bodyStrong),
                Text(
                  line.number ?? line.url ?? '',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (line.note != null)
                  Text(
                    line.note!,
                    style: AppTypography.small.copyWith(color: AppColors.warning),
                  ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy',
            ),
          if (onCall != null)
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded, size: 20),
              color: AppColors.safe,
              tooltip: 'Call',
            ),
          if (onOpen != null)
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              tooltip: 'Open',
            ),
        ],
      ),
    );
  }
}
