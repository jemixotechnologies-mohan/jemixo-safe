import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/utils/formatters.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/platform/native_bridge.dart';
import '../../services/threat_data/threat_data.dart';
import '../../state/history_controller.dart';
import 'privacy_policy_page.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double? _sliderValue;
  bool _alertsBusy = false;

  Future<void> _setInstallAlerts(SettingsController settings, bool value) async {
    setState(() => _alertsBusy = true);
    try {
      if (value) {
        // Android 13+ needs the runtime prompt; older versions post freely.
        try {
          final status = await ph.Permission.notification.request();
          if (!status.isGranted && mounted) {
            showAppSnack(context, 'Notifications are blocked, so alerts cannot be shown.');
            return;
          }
        } catch (_) {
          // Plugin unavailable; the worker checks the permission itself.
        }
      }
      final ok = await NativeBridge.instance.setInstallWatch(value);
      await settings.setInstallAlerts(value && ok);
      if (mounted && value && ok) {
        showAppSnack(context, 'You will be told when a new sideloaded app asks for sensitive access.');
      }
    } finally {
      if (mounted) setState(() => _alertsBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final threat = context.watch<ThreatDataService>();
    final theme = Theme.of(context);
    final sliderValue =
        _sliderValue ?? settings.largeFileThresholdMb.toDouble().clamp(20, 1020);

    return AppPageScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          const SectionHeader(title: 'For family'),
          AppCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.tight),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Language for simple mode & emergency screens',
                                style: AppTypography.bodyStrong),
                            Text(
                              'The rest of the app stays in English for now.',
                              style: AppTypography.small.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('EN')),
                          ButtonSegment(value: 'hi', label: Text('हिं')),
                        ],
                        selected: {settings.language},
                        onSelectionChanged: (s) => settings.setLanguage(s.first),
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.simpleMode,
                  onChanged: (value) {
                    AppHaptics.tap(context);
                    settings.setSimpleMode(value);
                    if (value) Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: Text('Simple mode', style: AppTypography.bodyStrong),
                  subtitle: Text(
                    'Large text and four big buttons: check a message, a link, a '
                    'QR code, or get help. Good for parents and grandparents.',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.installAlerts,
                  onChanged: _alertsBusy
                      ? null
                      : (value) => _setInstallAlerts(settings, value),
                  contentPadding: EdgeInsets.zero,
                  title: Text('New app alerts', style: AppTypography.bodyStrong),
                  subtitle: Text(
                    'Every 30 minutes, check for newly installed apps and warn '
                    'when one came from outside a store or asks for SMS, contacts '
                    'or accessibility. Runs on the device only.',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Scam data'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailRow(
                  label: 'List version',
                  value: 'v${threat.data.version} (${threat.source})'
                      '${threat.data.updatedAt.isEmpty ? '' : ' · ${threat.data.updatedAt}'}',
                ),
                DetailRow(
                  label: 'Last checked',
                  value: threat.lastChecked == null
                      ? 'Never'
                      : formatRelative(threat.lastChecked!.millisecondsSinceEpoch),
                ),
                DetailRow(
                  label: 'Contents',
                  value:
                      '${threat.data.brands.length} brands · ${threat.data.officialApps.length} official apps · ${threat.data.loanApps.length} lenders',
                ),
                if (threat.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      threat.lastError!,
                      style: AppTypography.small.copyWith(color: AppColors.warning),
                    ),
                  ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  'Scam phrases, brand rules and app lists are updated weekly from '
                  'the project\'s own file. The request carries no device data.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.tight),
                OutlinedButton.icon(
                  onPressed: threat.isUpdating
                      ? null
                      : () async {
                          final applied = await threat.refresh();
                          if (!context.mounted) return;
                          if (applied) context.read<AppScannerService>().reassess();
                          showAppSnack(
                            context,
                            applied
                                ? 'Updated to list v${threat.data.version}.'
                                : threat.lastError ?? 'Already up to date.',
                          );
                        },
                  icon: threat.isUpdating
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Check for updates now'),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Appearance'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: AppTypography.bodyStrong),
                const SizedBox(height: 4),
                Text(
                  'Dark mode follows your system setting by default.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_rounded, size: 16),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    AppHaptics.tap(context);
                    settings.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Scan options'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.saveHistory,
                  onChanged: settings.setSaveHistory,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Save scan history',
                    style: AppTypography.bodyStrong,
                  ),
                  subtitle: Text(
                    'Keeps a local record of each scan so Reports and History '
                    'have something to show.',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.haptics,
                  onChanged: (value) {
                    settings.setHaptics(value);
                    if (value) AppHaptics.success(context);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Haptic feedback',
                    style: AppTypography.bodyStrong,
                  ),
                  subtitle: Text(
                    'A short vibration when a scan or cleanup completes.',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.showDebuggable,
                  onChanged: (value) async {
                    await settings.setShowDebuggable(value);
                    if (!context.mounted) return;
                    context.read<AppScannerService>().reassess();
                  },
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Flag debuggable builds',
                    style: AppTypography.bodyStrong,
                  ),
                  subtitle: Text(
                    'Counts debug builds as a risk indicator. Turn off if you '
                    'develop apps on this phone.',
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Large file threshold'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Flag files above',
                        style: AppTypography.bodyStrong,
                      ),
                    ),
                    StatusPill(
                      label: '${sliderValue.round()} MB',
                      color: AppColors.royalBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Applies to the Large files screen. 100 MB is a sensible '
                  'default; raise it if the list is too noisy.',
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: sliderValue,
                  min: 20,
                  max: 1020,
                  divisions: 50,
                  label: '${sliderValue.round()} MB',
                  onChanged: (value) => setState(() => _sliderValue = value),
                  onChangeEnd: (value) {
                    settings.setLargeFileThreshold(value.round());
                    setState(() => _sliderValue = null);
                  },
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Privacy'),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No account, no cloud', style: AppTypography.bodyStrong),
                SizedBox(height: 6),
                Text(
                  'Jemixo Safe has no sign-in, no server and no analytics. Scans, '
                  'scores, reports and history are all produced and stored on '
                  'this device. Uninstalling the app removes all of it.',
                  style: TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Your data'),
          const _DataControls(),
          const SizedBox(height: AppSpacing.tight),
          FeatureCard(
            icon: Icons.policy_outlined,
            title: 'Privacy policy',
            subtitle: 'Readable offline; published copy linked inside',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
            ),
            statusIcon: Icons.chevron_right_rounded,
          ),
          const SectionHeader(title: 'About'),
          AppCard(
            child: Column(
              children: [
                DetailRow(label: 'App', value: AppConstants.appName),
                DetailRow(label: 'Version', value: AppConstants.version),
                DetailRow(
                  label: 'Package',
                  value: 'com.jemixo.safe',
                  monospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.standard),
          const DisclaimerNote(text: AppConstants.disclaimerRisk),
        ],
      ),
    );
  }
}

class _DataControls extends StatelessWidget {
  const _DataControls();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = context.read<HistoryController>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stored on this device', style: AppTypography.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'You can remove any of it at any time.',
            style: AppTypography.small.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.standard),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirm(
                    context,
                    title: 'Clear scan history?',
                    message:
                        'Past scan records will be removed from this device.',
                    confirmLabel: 'Clear',
                    action: () async {
                      await history.clear();
                      if (context.mounted) showAppSnack(context, 'History cleared.');
                    },
                  ),
                  icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
                  label: const Text('Clear history'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirm(
                    context,
                    title: 'Delete all app data?',
                    message:
                        'Scan history, preferences and every other setting will '
                        'be erased and the welcome screen will show again. This '
                        'cannot be undone.',
                    confirmLabel: 'Delete everything',
                    action: () async {
                      final repository = context.read<SettingsRepository>();
                      final settings = context.read<SettingsController>();
                      // Leave the settings route first so the welcome screen
                      // is not shown underneath an open page.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      await repository.wipe();
                      await history.load();
                      await settings.load();
                    },
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('Delete all'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() action,
  }) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );
    if (!confirmed || !context.mounted) return;
    AppHaptics.success(context);
    await action();
  }
}
