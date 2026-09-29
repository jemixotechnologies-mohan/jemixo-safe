import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/dashboard_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';
import '../emergency/emergency_page.dart';
import '../emergency/scam_call_page.dart';
import '../qr_scanner/qr_scanner_page.dart';
import '../scam_scanner/call_check_page.dart';
import '../scam_scanner/scam_scanner_page.dart';
import '../scam_scanner/screenshot_check_page.dart';
import '../url_checker/url_checker_page.dart';

/// Simple mode: large text, big buttons, nothing else. Built for parents and
/// grandparents who only need "is this message safe?". Available in Hindi.
class SimpleHomePage extends StatelessWidget {
  const SimpleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final settings = context.read<SettingsController>();
    final theme = Theme.of(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.25),
      ),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: AppSpacing.screen,
          title: Text(AppConstants.appName, style: AppTypography.pageTitle),
          actions: [
            TextButton(
              onPressed: () => settings.setLanguage(s.isHindi ? 'en' : 'hi'),
              child: Text(s.isHindi ? 'EN' : 'हिं'),
            ),
            TextButton(
              onPressed: () => settings.setSimpleMode(false),
              child: Text(s.fullApp),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text(s.simpleTitle, style: AppTypography.sectionTitle),
            const SizedBox(height: 6),
            Text(
              s.simpleSubtitle,
              style: AppTypography.body.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            _BigButton(
              icon: Icons.sms_outlined,
              color: AppColors.royalBlue,
              title: s.checkMessage,
              subtitle: s.checkMessageSub,
              onTap: () => _open(context, const ScamScannerPage()),
            ),
            _BigButton(
              icon: Icons.document_scanner_outlined,
              color: AppColors.midnightGreen,
              title: s.checkScreenshot,
              subtitle: s.checkScreenshotSub,
              onTap: () => _open(context, const ScreenshotCheckPage()),
            ),
            _BigButton(
              icon: Icons.link_rounded,
              color: AppColors.info,
              title: s.checkLink,
              subtitle: s.checkLinkSub,
              onTap: () => _open(context, const UrlCheckerPage()),
            ),
            _BigButton(
              icon: Icons.qr_code_scanner_rounded,
              color: AppColors.gold,
              title: s.checkQr,
              subtitle: s.checkQrSub,
              onTap: () => _open(context, const QrScannerPage()),
            ),
            _BigButton(
              icon: Icons.call_outlined,
              color: AppColors.slate,
              title: s.checkCaller,
              subtitle: s.checkCallerSub,
              onTap: () => _open(context, const CallCheckPage()),
            ),
            _BigButton(
              icon: Icons.content_paste_rounded,
              color: AppColors.royalBlue,
              title: s.checkClipboard,
              subtitle: s.checkClipboardSub,
              onTap: () => _checkClipboard(context, s),
            ),
            const SizedBox(height: AppSpacing.tight),
            _BigButton(
              icon: Icons.phone_in_talk_rounded,
              color: AppColors.warning,
              title: s.scamCallNow,
              subtitle: s.scamCallNowSub,
              onTap: () => _open(context, const ScamCallPage()),
            ),
            _BigButton(
              icon: Icons.sos_rounded,
              color: AppColors.danger,
              title: s.gotScammed,
              subtitle: s.gotScammedSub,
              onTap: () => _open(context, const EmergencyPage()),
            ),
            const SizedBox(height: AppSpacing.standard),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.threeRulesTitle, style: AppTypography.bodyStrong),
                  const SizedBox(height: 8),
                  Text(s.rule1),
                  const SizedBox(height: 4),
                  Text(s.rule2),
                  const SizedBox(height: 4),
                  Text(s.rule3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _checkClipboard(BuildContext context, Strings s) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!context.mounted) return;
    if (text == null || text.isEmpty) {
      showAppSnack(context, s.nothingCopied);
      return;
    }
    final tools = context.read<ToolsController>();
    final looksLikeUrl = RegExp(
      r'^(https?://|www\.)|^[a-z0-9-]+(\.[a-z0-9-]+)+(/|$)',
      caseSensitive: false,
    ).hasMatch(text);
    if (looksLikeUrl && !text.contains(' ')) {
      tools.analyzeUrl(text);
      _open(context, const UrlCheckerPage());
    } else {
      _open(context, ScamScannerPage(initialText: text));
    }
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.tight),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.sectionTitle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 26),
          ],
        ),
      ),
    );
  }
}
