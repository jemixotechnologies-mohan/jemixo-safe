import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/device_service/device_service.dart';
import '../../widgets/app_widgets.dart';
import 'battery_page.dart';

/// Device health: battery, memory, storage pressure and the security switches
/// Android exposes, each with a direct hand-off to the right settings screen.
class DeviceHealthPage extends StatelessWidget {
  const DeviceHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final theme = Theme.of(context);
    final info = device.device;
    final memory = device.memory;
    final security = device.security;
    final battery = device.battery;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text('Device health', style: AppTypography.pageTitle),
        actions: [
          IconButton(
            onPressed: device.isLoading ? null : device.refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: device.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.tight,
            AppSpacing.screen,
            AppSpacing.standard * 2,
          ),
          children: [
            if (info != null)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            info.displayName,
                            style: AppTypography.sectionTitle,
                          ),
                        ),
                        if (info.isEmulator)
                          const StatusPill(
                            label: 'Emulator',
                            color: AppColors.warning,
                            dense: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DetailRow(
                      label: 'Android',
                      value: info.androidRelease == null
                          ? 'Unknown'
                          : 'Android ${info.androidRelease}'
                                '${info.sdkInt == null ? '' : ' (API ${info.sdkInt})'}',
                    ),
                    if (info.securityPatch != null)
                      DetailRow(
                        label: 'Security patch',
                        value: _patchLabel(info.securityPatch!),
                        valueColor: _patchIsOld(info.securityPatch!)
                            ? AppColors.warning
                            : null,
                      ),
                    if (info.abi != null)
                      DetailRow(label: 'Architecture', value: info.abi!),
                    if (info.locale != null)
                      DetailRow(label: 'Locale', value: info.locale!),
                    if (info.securityPatch != null &&
                        _patchIsOld(info.securityPatch!))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.tight),
                        child: WarningBanner(
                          title: 'Security patch is more than 6 months old',
                          message:
                              'Check Settings → System → Software update. If no '
                              'update is offered, the manufacturer may have stopped '
                              'supporting this phone.',
                        ),
                      ),
                    if (info.isEmulator)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.tight),
                        child: InfoBanner(
                          title: 'Running on an emulator',
                          message:
                              'Sensor, battery and network readings on emulators do not '
                              'reflect real hardware.',
                          icon: Icons.developer_mode_rounded,
                        ),
                      ),
                  ],
                ),
              ),
            const SectionHeader(title: 'Battery'),
            AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BatteryPage()),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          battery == null || battery.percent == null
                              ? 'Battery level unavailable'
                              : '${battery.percent}% · ${battery.statusLabel}',
                          style: AppTypography.bodyStrong,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  if (battery?.percent != null) ...[
                    const SizedBox(height: AppSpacing.tight),
                    MetricBar(
                      label: 'Charge',
                      valueLabel: '${battery!.percent}%',
                      fraction: battery.percent! / 100,
                      color: battery.percent! <= 15
                          ? AppColors.danger
                          : battery.percent! <= 25
                          ? AppColors.warning
                          : AppColors.safe,
                    ),
                  ],
                  if (battery?.temperatureCelsius != null)
                    DetailRow(
                      label: 'Temperature',
                      value:
                          '${battery!.temperatureCelsius!.toStringAsFixed(1)} °C',
                      valueColor: battery.temperatureCelsius! > 42
                          ? AppColors.warning
                          : null,
                    ),
                ],
              ),
            ),
            if (memory != null) ...[
              const SectionHeader(title: 'Memory'),
              AppCard(
                child: Column(
                  children: [
                    MetricBar(
                      label: 'RAM in use',
                      valueLabel:
                          '${formatBytes(memory.totalRamBytes - memory.availableRamBytes)}'
                          ' / ${formatBytes(memory.totalRamBytes)}',
                      fraction: memory.usedFraction,
                      color: memory.lowMemory
                          ? AppColors.warning
                          : AppColors.royalBlue,
                    ),
                    MetricBar(
                      label: 'Data partition',
                      valueLabel:
                          '${formatBytes(memory.totalDataBytes - memory.freeDataBytes)}'
                          ' / ${formatBytes(memory.totalDataBytes)}',
                      fraction: memory.totalDataBytes == 0
                          ? 0
                          : (memory.totalDataBytes - memory.freeDataBytes) /
                                memory.totalDataBytes,
                      color: AppColors.midnightGreen,
                    ),
                    if (memory.lowMemory)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.tight),
                        child: WarningBanner(
                          title: 'Android reports low memory',
                          message:
                              'Close unused apps. Background activity is the usual cause, '
                              'not a fault in your device.',
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SectionHeader(title: 'Security settings'),
            AppCard(
              child: Column(
                children: [
                  _SettingRow(
                    label: 'Screen lock',
                    detail: security?.deviceSecure == true
                        ? 'PIN, pattern, password or biometric is set'
                        : 'No screen lock configured — anyone who picks up the phone can open it',
                    ok: security?.deviceSecure == true,
                    onTap: () =>
                        _openSetting(context, device.openSecuritySettings),
                  ),
                  _SettingRow(
                    label: 'Install from unknown sources',
                    detail: security?.unknownSourcesAllowed == true
                        ? 'Jemixo Safe is allowed to install apps. It never does; you can switch this off.'
                        : 'Blocked for Jemixo Safe. Review other apps in Android settings.',
                    ok: security?.unknownSourcesAllowed != true,
                    onTap: () =>
                        _openSetting(context, device.openUnknownSourcesSettings),
                  ),
                  _SettingRow(
                    label: 'Device administrators',
                    detail: (security?.activeDeviceAdmins ?? 0) == 0
                        ? 'None active'
                        : '${security!.activeDeviceAdmins} active — a device admin can lock or wipe the phone',
                    ok: (security?.activeDeviceAdmins ?? 0) == 0,
                    onTap: () =>
                        _openSetting(context, device.openSecuritySettings),
                  ),
                  _SettingRow(
                    label: 'Accessibility services',
                    detail: security?.accessibilityServicesEnabled == true
                        ? 'A service is enabled — it can read screen content and act on your behalf'
                        : 'None enabled',
                    ok: security?.accessibilityServicesEnabled != true,
                    onTap: () =>
                        _openSetting(context, device.openAccessibilitySettings),
                  ),
                  _SettingRow(
                    label: 'USB debugging',
                    detail: security?.adbEnabled == true
                        ? 'Enabled — a connected computer can control this phone'
                        : security?.developerOptionsEnabled == true
                        ? 'Developer options are on, debugging is off'
                        : 'Off',
                    ok: security?.adbEnabled != true,
                    onTap: () =>
                        _openSetting(context, device.openDeveloperSettings),
                  ),
                  _SettingRow(
                    label: 'Usage access',
                    detail: security?.usageAccessGranted == true
                        ? 'Granted — battery usage details are available'
                        : 'Optional. Needed only for per-app battery usage.',
                    ok: true,
                    onTap: () =>
                        _openSetting(context, device.openUsageAccessSettings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            const DisclaimerNote(
              text:
                  'Readings come from Android system APIs and reflect the state '
                  'of the device at this moment. ${AppConstants.disclaimerRisk}',
            ),
            const SizedBox(height: AppSpacing.tight),
            Text(
              'No background service is running. Values refresh when you open this screen.',
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _patchLabel(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return formatDate(date.millisecondsSinceEpoch);
  }

  static bool _patchIsOld(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return false;
    return DateTime.now().difference(date).inDays > 183;
  }

  Future<void> _openSetting(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final opened = await action();
    if (!opened && context.mounted) {
      showAppSnack(context, 'That settings screen is not available on this device.');
    }
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.detail,
    required this.ok,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool ok;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ok
        ? AppColors.safe
        : RiskPalette.color(context, RiskLevel.medium);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              ok
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyStrong),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppTypography.small.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
