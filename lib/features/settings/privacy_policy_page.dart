import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// The privacy policy, readable offline. The same text is published at
/// [AppConstants.privacyPolicyUrl] for the Play listing.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const sections = <(String, String)>[
    (
      'What Jemixo Safe collects',
      'Nothing. The app has no account, no server and no analytics. It does not '
          'collect, transmit or sell any personal data.',
    ),
    (
      'What stays on your phone',
      'Scan results, the apps and files it reviewed, your settings and history are '
          'stored in a local database inside the app\'s private storage. '
          'Uninstalling the app deletes all of it.',
    ),
    (
      'Installed apps (QUERY_ALL_PACKAGES)',
      'The safety check reads the list of installed apps, their permissions, install '
          'source and signing certificate to flag risky combinations, fake brand '
          'names and unregulated loan apps. This list never leaves the device.',
    ),
    (
      'Photos, videos and downloads',
      'With your permission the Clean tab reads file names, sizes and dates from '
          'the media library to find large files, duplicates and screenshots. Files '
          'are only deleted after you confirm, and thumbnails are generated locally.',
    ),
    (
      'Messages, links and QR codes',
      'Text you paste, share or scan is analysed on the device with offline rules '
          'and discarded when you clear it. The camera is used only while the QR '
          'scanner is open.',
    ),
    (
      'Notifications',
      'If you turn on "New app alerts", the app checks the installed-app list every '
          '30 minutes and shows a notification for new sideloaded apps. This is '
          'off by default and runs entirely on the device.',
    ),
    (
      'Updates to scam data',
      'Once a week the app downloads a small JSON file with updated scam phrases, '
          'brand rules and app lists from the project\'s own static hosting. The '
          'request carries no identifiers or device data.',
    ),
    (
      'Sharing',
      'When you share a result card or a PDF report, the file goes to the app you '
          'choose through Android\'s share sheet. Jemixo Safe never uploads it.',
    ),
    (
      'Children',
      'The app is not directed at children under 13 and collects no data from anyone.',
    ),
    (
      'Contact',
      'Questions about this policy: see the contact address on the Play Store listing.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      title: 'Privacy policy',
      subtitle: '${AppConstants.appName} ${AppConstants.version}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          for (final (title, body) in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.standard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(AppConstants.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Open the published policy'),
          ),
        ],
      ),
    );
  }
}
