import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
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
    final s = Strings.of(context);
    final sliderValue =
        _sliderValue ?? settings.largeFileThresholdMb.toDouble().clamp(20, 1020);

    return AppPageScaffold(
      title: s.settingsTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.tight,
          AppSpacing.screen,
          AppSpacing.standard * 2,
        ),
        children: [
          SectionHeader(title: s.forFamilySection),
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
                            Text(s.appLanguageTitle,
                                style: AppTypography.bodyStrong),
                            Text(
                              s.appLanguageSubtitle,
                              style: AppTypography.small.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('English')),
                          ButtonSegment(value: 'hi', label: Text('हिन्दी')),
                        ],
                        selected: {settings.language},
                        onSelectionChanged: (selection) => settings.setLanguage(selection.first),
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
                  title: Text(s.simpleModeTitle, style: AppTypography.bodyStrong),
                  subtitle: Text(
                    s.simpleModeSubtitle,
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
                  title: Text(s.installAlertsTitle, style: AppTypography.bodyStrong),
                  subtitle: Text(
                    s.installAlertsSubtitle,
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(title: s.scamDataSection),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailRow(
                  label: s.listVersionLabel,
                  value: 'v${threat.data.version} (${threat.source})'
                      '${threat.data.updatedAt.isEmpty ? '' : ' · ${threat.data.updatedAt}'}',
                ),
                DetailRow(
                  label: s.lastCheckedLabel,
                  value: threat.lastChecked == null
                      ? s.neverLabel
                      : formatRelative(threat.lastChecked!.millisecondsSinceEpoch),
                ),
                DetailRow(
                  label: s.contentsLabel,
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
                  label: Text(s.checkForUpdatesNow),
                ),
              ],
            ),
          ),
          SectionHeader(title: s.appearanceSection),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.themeTitle, style: AppTypography.bodyStrong),
                const SizedBox(height: 4),
                Text(
                  s.themeSubtitle,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(s.themeSystem),
                      icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(s.themeLight),
                      icon: const Icon(Icons.light_mode_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(s.themeDark),
                      icon: const Icon(Icons.dark_mode_rounded, size: 16),
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
          SectionHeader(title: s.scanOptionsSection),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.saveHistory,
                  onChanged: settings.setSaveHistory,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    s.saveHistoryTitle,
                    style: AppTypography.bodyStrong,
                  ),
                  subtitle: Text(
                    s.saveHistorySubtitle,
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
                    s.hapticsTitle,
                    style: AppTypography.bodyStrong,
                  ),
                  subtitle: Text(
                    s.hapticsSubtitle,
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
                    s.flagDebuggableTitle,
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
          SectionHeader(title: s.largeFileThresholdSection),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.flagFilesAbove,
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
          SectionHeader(title: s.privacySection),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.noCloudTitle, style: AppTypography.bodyStrong),
                const SizedBox(height: 6),
                Text(
                  s.noCloudBody,
                  style: const TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
          SectionHeader(title: s.yourDataSection),
          const _DataControls(),
          const SizedBox(height: AppSpacing.tight),
          FeatureCard(
            icon: Icons.policy_outlined,
            title: s.privacyPolicyTitle,
            subtitle: s.privacyPolicySubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
            ),
            statusIcon: Icons.chevron_right_rounded,
          ),
          SectionHeader(title: s.aboutSection),
          AppCard(
            child: Column(
              children: [
                DetailRow(label: s.appLabel, value: AppConstants.appName),
                DetailRow(label: s.versionLabel, value: AppConstants.version),
                DetailRow(
                  label: s.packageLabel,
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
    final s = Strings.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.storedOnDeviceTitle, style: AppTypography.bodyStrong),
          const SizedBox(height: 4),
          Text(
            s.storedOnDeviceSubtitle,
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
                    title: s.clearHistoryConfirmTitle,
                    message: s.clearHistoryConfirmMsg,
                    confirmLabel: s.clearHistoryBtn,
                    action: () async {
                      await history.clear();
                      if (context.mounted) showAppSnack(context, s.clearHistoryDone);
                    },
                  ),
                  icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
                  label: Text(s.clearHistoryBtn),
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
                    title: s.deleteAllConfirmTitle,
                    message: s.deleteAllConfirmMsg,
                    confirmLabel: s.deleteEverythingBtn,
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
                  label: Text(s.deleteAllBtn),
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
