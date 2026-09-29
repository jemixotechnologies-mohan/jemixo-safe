import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/device_service/device_service.dart';
import '../../widgets/app_widgets.dart';

/// Battery detail. Deliberately avoids inventing a "battery health percentage":
/// Android does not expose design capacity, so only measured facts are shown.
class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  Map<String, String> _names = const {};
  bool _loadingUsage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsage());
  }

  Future<void> _loadUsage() async {
    final device = context.read<DeviceService>();
    final scanner = context.read<AppScannerService>();
    setState(() => _loadingUsage = true);
    await device.loadBatteryUsage();
    if (!mounted) return;
    final names = await device.batteryUsageNames(scanner);
    if (!mounted) return;
    setState(() {
      _names = names;
      _loadingUsage = false;
    });
  }

  Future<void> _openSetting(Future<bool> Function() action) async {
    final opened = await action();
    if (!opened && mounted) {
      showAppSnack(context, 'That settings screen is not available on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final theme = Theme.of(context);
    final battery = device.battery;
    final usage = device.batteryUsage;

    final percent = battery?.percent;
    final level = switch (percent) {
      null => RiskLevel.medium,
      final int value when value <= 15 => RiskLevel.high,
      final int value when value <= 25 => RiskLevel.medium,
      _ => RiskLevel.safe,
    };

    return AppPageScaffold(
      title: 'Battery',
      subtitle: percent == null
          ? 'Unavailable'
          : '$percent% · ${battery!.statusLabel}',
      actions: [
        IconButton(
          onPressed: () => _openSetting(device.openBatteryUsageSettings),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Battery settings',
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          await device.refresh();
          await _loadUsage();
        },
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
                children: [
                  ScoreRing(
                    score: percent ?? 0,
                    color: RiskPalette.color(context, level),
                    size: 150,
                    label: percent == null
                        ? 'Unknown'
                        : percent <= 15
                        ? 'Low'
                        : percent <= 25
                        ? 'Getting low'
                        : 'Good',
                    caption: battery?.isCharging == true
                        ? 'Charging'
                        : 'On battery',
                    animate: false,
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  if (battery != null) ...[
                    DetailRow(label: 'Status', value: battery.statusLabel),
                    DetailRow(label: 'Health (reported)', value: battery.healthLabel),
                    if (battery.hasCapacityInfo)
                      DetailRow(
                        label: 'Charge now',
                        value: '${battery.chargeCounterMah} mAh',
                      ),
                    if (battery.temperatureCelsius != null)
                      DetailRow(
                        label: 'Temperature',
                        value:
                            '${battery.temperatureCelsius!.toStringAsFixed(1)} °C',
                      ),
                    if (battery.voltageMillivolts != null)
                      DetailRow(
                        label: 'Voltage',
                        value: '${battery.voltageMillivolts} mV',
                      ),
                    if (battery.technology != null)
                      DetailRow(label: 'Technology', value: battery.technology!),
                    DetailRow(
                      label: 'Power saver',
                      value: battery.isPowerSaveMode ? 'On' : 'Off',
                    ),
                  ],
                ],
              ),
            ),
            if (battery?.temperatureCelsius != null &&
                battery!.temperatureCelsius! > 42) ...[
              const SizedBox(height: AppSpacing.standard),
              WarningBanner(
                title: 'Battery is running warm',
                message:
                    'Above roughly 42 °C, sustained heavy use can shorten battery '
                    'life. Charging while gaming has the same effect.',
              ),
            ],
            const SectionHeader(title: 'What Android can and cannot tell us'),
            const AppCard(
              child: Text(
                'Jemixo Safe does not show a battery health percentage. Modern '
                'Android versions no longer report the design capacity needed to '
                'compute one, and a made-up number would be worse than none. The '
                '"Health" line above is the raw status the battery driver reports.',
                style: TextStyle(height: 1.45),
              ),
            ),
            const SectionHeader(title: 'Screen time by app (24 h)'),
            if (_loadingUsage)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.standard),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (usage.isEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.security?.usageAccessGranted == true
                          ? 'No usage data available yet.'
                          : 'Usage access is not granted, so per-app figures are '
                                'unavailable.',
                      style: AppTypography.bodyStrong,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usage access is a special Android permission that lets an app '
                      'read screen-time statistics. Jemixo Safe only uses it for '
                      'this list and never uploads it.',
                      style: AppTypography.small.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (device.security?.usageAccessGranted != true) ...[
                      const SizedBox(height: AppSpacing.standard),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _openSetting(device.openUsageAccessSettings),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Open usage access settings'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              AppCard(
                child: Column(
                  children: [
                    for (final entry in usage.take(15))
                      MetricBar(
                        label: _names[entry.packageName] ?? entry.packageName,
                        valueLabel: formatDurationSeconds(
                          entry.foregroundMillis / 1000,
                        ),
                        fraction:
                            entry.foregroundMillis /
                            (usage.first.foregroundMillis == 0
                                ? 1
                                : usage.first.foregroundMillis),
                        color: AppColors.royalBlue,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Screen time is the closest per-app figure Android shares '
                      'with third-party apps. Exact battery drain is only shown in '
                      'system settings.',
                      style: AppTypography.small.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.standard),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openSetting(device.openBatterySettings),
                    icon: const Icon(Icons.battery_saver_outlined, size: 18),
                    label: const Text('Battery saver'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.tight),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openSetting(device.openBatteryUsageSettings),
                    icon: const Icon(Icons.apps_rounded, size: 18),
                    label: const Text('App battery use'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.tight),
            Text(
              'Figures come from Android system APIs and update as the system '
              'reports them.',
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
}
