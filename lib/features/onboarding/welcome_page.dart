import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';

/// First-run screen. Sets expectations before any permission is requested:
/// everything runs locally, no account, and scores are indicators.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.screen,
                  AppSpacing.screen,
                  0,
                ),
                children: [
                  const SizedBox(height: AppSpacing.section),
                  const _BrandMark(),
                  const SizedBox(height: AppSpacing.standard),
                  Text(
                    'Know your phone.\nProtect your privacy.',
                    style: AppTypography.brand.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    'Jemixo Safe inspects the apps, files and settings on this '
                    'device and explains what it finds in plain language.',
                    style: AppTypography.body.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.standard * 1.5),
                  const _Point(
                    icon: Icons.shield_outlined,
                    title: 'Everything stays on your phone',
                    body:
                        'Scans, scores and reports are produced locally. There is '
                        'no account and nothing is uploaded.',
                  ),
                  const _Point(
                    icon: Icons.rule_outlined,
                    title: 'Scores are indicators, not verdicts',
                    body:
                        'A risk level reflects what this app can observe. It is '
                        'never proof that an app is malicious or that your phone '
                        'is infection-free.',
                  ),
                  const _Point(
                    icon: Icons.touch_app_outlined,
                    title: 'You approve every action',
                    body:
                        'Jemixo Safe never deletes a file or uninstalls an app '
                        'without your confirmation.',
                  ),
                  const SizedBox(height: AppSpacing.standard),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                      ),
                      onPressed: () async {
                        final settings = context.read<SettingsController>();
                        await settings.completeOnboarding();
                      },
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    'Jemixo Safe never asks for a login and never shows ads.',
                    textAlign: TextAlign.center,
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
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            gradient: const LinearGradient(
              colors: [AppColors.midnightGreen, Color(0xFF155744)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.shield_rounded, color: AppColors.gold),
        ),
        const SizedBox(width: AppSpacing.standard),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jemixo Safe', style: AppTypography.pageTitle),
            Text(
              'On-device Android companion',
              style: AppTypography.small.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.standard),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.royalBlue, size: 22),
            const SizedBox(width: AppSpacing.standard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTypography.small.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
