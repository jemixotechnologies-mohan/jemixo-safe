import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/device_service/device_service.dart';
import '../../services/platform/native_models.dart';
import '../../state/security_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import 'app_detail_page.dart';

/// Apps that can read your screen, your notifications or control the device,
/// plus hidden apps. These four capabilities are what banking trojans and
/// stalkerware are built on, and Android exposes all of them without any
/// permission on our side.
class SpecialAccessPage extends StatefulWidget {
  const SpecialAccessPage({super.key});

  @override
  State<SpecialAccessPage> createState() => _SpecialAccessPageState();
}

class _SpecialAccessPageState extends State<SpecialAccessPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scanner = context.read<AppScannerService>();
      if (!scanner.hasScanned && !scanner.isScanning) {
        context.read<SecurityController>().runScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<AppScannerService>();
    final device = context.watch<DeviceService>();
    final theme = Theme.of(context);
    final access = scanner.specialAccess;
    final hidden = scanner.hiddenApps;
    final userAccessibility =
        access.accessibility.where((e) => !e.isSystemApp).toList();
    final userListeners =
        access.notificationListeners.where((e) => !e.isSystemApp).toList();
    final userAdmins = access.deviceAdmins.where((e) => !e.isSystemApp).toList();
    final concerns = userAccessibility.length +
        userListeners.length +
        userAdmins.length +
        hidden.length;

    return AppPageScaffold(
      title: 'Apps with special access',
      subtitle: 'Screen readers, notification access, device admin, hidden apps',
      actions: [
        IconButton(
          onPressed: scanner.isScanning
              ? null
              : () => context.read<SecurityController>().runScan(),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Re-check',
        ),
      ],
      child: scanner.isScanning && !scanner.hasScanned
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.tight,
                AppSpacing.screen,
                AppSpacing.standard * 2,
              ),
              children: [
                if (concerns == 0)
                  const SuccessBanner(
                    title: 'No user app holds special access',
                    message:
                        'Only Android and manufacturer apps can read the screen, '
                        'notifications or administer the device, and no hidden '
                        'app with spying-type permissions was found.',
                  )
                else
                  WarningBanner(
                    title: '$concerns thing${concerns == 1 ? '' : 's'} to review',
                    message:
                        'These capabilities are legitimate for screen readers, '
                        'smartwatch apps and company MDM. For anything else, '
                        'switch them off: that alone stops most banking trojans.',
                  ),
                _Section(
                  title: 'Can read the screen (accessibility)',
                  why:
                      'An enabled accessibility service sees every screen and '
                      'can tap for you, including inside banking apps.',
                  entries: access.accessibility,
                  emptyText: 'No accessibility service is enabled.',
                  settingsLabel: 'Accessibility settings',
                  onSettings: () => _openSetting(device.openAccessibilitySettings),
                  onOpenApp: _openApp,
                ),
                _Section(
                  title: 'Can read notifications',
                  why:
                      'Notification access exposes every message, including OTPs, '
                      'to the app.',
                  entries: access.notificationListeners,
                  emptyText: 'No app has notification access.',
                  settingsLabel: 'Notification access settings',
                  onSettings: () => _openSetting(
                    () => device.openNotificationAccessSettings(),
                  ),
                  onOpenApp: _openApp,
                ),
                _Section(
                  title: 'Device administrators',
                  why:
                      'A device admin can lock or wipe the phone and block its own '
                      'uninstall.',
                  entries: access.deviceAdmins,
                  emptyText: 'No device administrator is active.',
                  settingsLabel: 'Security settings',
                  onSettings: () => _openSetting(device.openSecuritySettings),
                  onOpenApp: _openApp,
                ),
                const SectionHeader(title: 'Hidden apps with spying-type permissions'),
                if (hidden.isEmpty)
                  AppCard(
                    child: Text(
                      'No app without a home-screen icon asks for SMS, microphone, '
                      'camera, location or call log.',
                      style: AppTypography.small.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final app in hidden)
                    AppListTile(
                      app: app,
                      subtitleOverride:
                          'No icon · ${app.packageName}${app.isSideloaded ? ' · sideloaded' : ''}',
                      trailing: const RiskPill(level: RiskLevel.high),
                      onTap: () => _openApp(app.packageName),
                    ),
                const SizedBox(height: AppSpacing.standard),
                const DisclaimerNote(text: AppConstants.disclaimerRisk),
              ],
            ),
    );
  }

  void _openApp(String packageName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppDetailPage(packageName: packageName),
      ),
    );
  }

  Future<void> _openSetting(Future<bool> Function() action) async {
    final ok = await action();
    if (!ok && mounted) {
      showAppSnack(context, 'That settings screen is not available on this device.');
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.why,
    required this.entries,
    required this.emptyText,
    required this.settingsLabel,
    required this.onSettings,
    required this.onOpenApp,
  });

  final String title;
  final String why;
  final List<SpecialAccessEntry> entries;
  final String emptyText;
  final String settingsLabel;
  final VoidCallback onSettings;
  final void Function(String packageName) onOpenApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = entries.where((e) => !e.isSystemApp).toList();
    final system = entries.where((e) => e.isSystemApp).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                why,
                style: AppTypography.small.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.tight),
              if (entries.isEmpty)
                Text(emptyText, style: AppTypography.bodyStrong)
              else ...[
                for (final entry in user)
                  _EntryRow(
                    entry: entry,
                    level: RiskLevel.high,
                    onTap: () => onOpenApp(entry.packageName),
                  ),
                for (final entry in system)
                  _EntryRow(entry: entry, level: RiskLevel.safe),
              ],
              const SizedBox(height: AppSpacing.tight),
              TextButton.icon(
                onPressed: onSettings,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(settingsLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.level, this.onTap});

  final SpecialAccessEntry entry;
  final RiskLevel level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              entry.isSystemApp ? Icons.android_rounded : Icons.apps_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label, style: AppTypography.bodyStrong),
                  Text(
                    entry.packageName,
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            StatusPill(
              label: entry.isSystemApp ? 'System' : 'Review',
              color: entry.isSystemApp ? AppColors.slate : RiskPalette.color(context, level),
              dense: true,
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
