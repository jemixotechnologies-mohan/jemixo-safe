import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/share_card.dart';
import 'emergency_page.dart';

/// The panic card for a scam call in progress. Deliberately one screen, big
/// text, four instructions, and the helpline. Available in Hindi.
class ScamCallPage extends StatelessWidget {
  const ScamCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.15),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(s.panicTitle)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _Step(
              color: AppColors.danger,
              icon: Icons.call_end_rounded,
              title: s.panicHangUp,
              body: s.panicHangUpBody,
            ),
            _Step(
              color: AppColors.warning,
              icon: Icons.block_rounded,
              title: s.panicNoPay,
              body: s.panicNoPayBody,
            ),
            _Step(
              color: AppColors.royalBlue,
              icon: Icons.family_restroom_rounded,
              title: s.panicTell,
              body: s.panicTellBody,
            ),
            _Step(
              color: AppColors.safe,
              icon: Icons.verified_user_outlined,
              title: s.panicVerify,
              body: s.panicVerifyBody,
            ),
            const SizedBox(height: AppSpacing.tight),
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri(scheme: 'tel', path: AppConstants.cyberHelpline),
              ),
              icon: const Icon(Icons.call_rounded, size: 20),
              label: Text(s.panicDial),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EmergencyPage()),
              ),
              icon: const Icon(Icons.sos_rounded, size: 18),
              label: Text(s.panicAlreadyPaid),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
            OutlinedButton.icon(
              onPressed: () => shareResultCard(
                context,
                ShareCardData(
                  kind: s.isHindi ? 'चेतावनी' : 'Warning',
                  headline: s.panicTitle,
                  level: RiskLevel.high,
                  lines: [s.panicHangUp, s.panicNoPay, s.panicTell, s.panicVerify],
                ),
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(s.panicShare),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            Text(s.panicScripts, style: AppTypography.sectionTitle),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in s.panicScriptLines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.slate),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line,
                              style: AppTypography.small.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
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
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.tight),
      child: AppCard(
        borderColor: color.withValues(alpha: 0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.sectionTitle.copyWith(color: color)),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTypography.body.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
