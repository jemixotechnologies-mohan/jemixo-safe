import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../services/device_service/device_service.dart';
import '../../widgets/app_widgets.dart';

/// Network state as Android reports it. No active probing, no speed test — the
/// screen only describes what the platform already knows.
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final theme = Theme.of(context);
    final network = device.network;
    final quality = ConnectionQuality.from(network);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text('Network', style: AppTypography.pageTitle),
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        switch (network?.type) {
                          'wifi' => Icons.wifi_rounded,
                          'cellular' => Icons.signal_cellular_alt_rounded,
                          'vpn' => Icons.vpn_lock_rounded,
                          'ethernet' => Icons.settings_ethernet_rounded,
                          _ => Icons.wifi_off_rounded,
                        },
                        size: 28,
                        color: RiskPalette.color(context, quality.level),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              network?.typeLabel ?? 'No connection',
                              style: AppTypography.sectionTitle,
                            ),
                            Text(
                              quality.label,
                              style: AppTypography.small.copyWith(
                                color: RiskPalette.color(
                                  context,
                                  quality.level,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  DetailRow(
                    label: 'Connected',
                    value: network?.connected == true ? 'Yes' : 'No',
                  ),
                  DetailRow(
                    label: 'Internet access',
                    value: switch (network?.validated) {
                      true => 'Validated by Android',
                      false => 'Not validated (captive portal or no internet)',
                      null => 'Unknown',
                    },
                  ),
                  if (network?.wifiName != null)
                    DetailRow(
                      label: 'Wi-Fi network',
                      value: network!.wifiName!,
                    ),
                  if (network?.carrierName != null)
                    DetailRow(label: 'Carrier', value: network!.carrierName!),
                  DetailRow(
                    label: 'Metered',
                    value: network?.metered == true
                        ? 'Yes — data may be charged'
                        : 'No',
                  ),
                  if (network?.downstreamKbps != null)
                    DetailRow(
                      label: 'Link speed',
                      value: _speed(network!.downstreamKbps!),
                    ),
                ],
              ),
            ),
            if (network?.type == 'vpn')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.standard),
                child: InfoBanner(
                  title: 'A VPN is active',
                  message:
                      'All traffic is routed through the VPN app. Make sure it is '
                      'one you installed on purpose; a VPN you do not recognise '
                      'can read everything you send.',
                  icon: Icons.vpn_lock_rounded,
                ),
              ),
            if (network != null && network.connected && !network.validated)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.standard),
                child: WarningBanner(
                  title: 'Connected without internet',
                  message:
                      'Android could not reach the internet on this network. On '
                      'public Wi-Fi this usually means a sign-in page is waiting.',
                ),
              ),
            const SectionHeader(title: 'Connections'),
            FeatureCard(
              icon: Icons.wifi_rounded,
              title: 'Wi-Fi settings',
              subtitle: 'Switch networks and review saved ones',
              onTap: () => _openSetting(context, device.openWifiSettings),
              statusIcon: Icons.open_in_new_rounded,
            ),
            FeatureCard(
              icon: Icons.signal_cellular_alt_rounded,
              title: 'Mobile data',
              subtitle: 'Data usage and roaming settings',
              onTap: () => _openSetting(context, device.openDataSettings),
              statusIcon: Icons.open_in_new_rounded,
            ),
            FeatureCard(
              icon: Icons.airplanemode_active_rounded,
              title: 'Airplane mode',
              subtitle: 'Turn every radio off at once',
              onTap: () =>
                  _openSetting(context, device.openAirplaneModeSettings),
              statusIcon: Icons.open_in_new_rounded,
            ),
            const SectionHeader(title: 'Tips'),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tip(
                    icon: Icons.wifi_lock_rounded,
                    title: 'Prefer a password-protected WPA2/WPA3 network',
                    body:
                        'Open Wi-Fi networks let others on the same network see '
                        'unencrypted traffic.',
                  ),
                  _Tip(
                    icon: Icons.vpn_lock_outlined,
                    title: 'Use a VPN you trust on public Wi-Fi',
                    body:
                        'A VPN encrypts your traffic between your phone and the '
                        'VPN server. It does not make you anonymous.',
                  ),
                  _Tip(
                    icon: Icons.phonelink_lock_outlined,
                    title: 'Check the network name before joining',
                    body:
                        'Look-alike hotspots ("Cafe_WiFi_Free") are a common way '
                        'to intercept traffic in public places.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            Text(
              'Jemixo Safe does not run speed tests or contact any server. This '
              'screen only reflects Android connectivity state.',
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

  static String _speed(int kbps) =>
      kbps >= 1000 ? '${(kbps / 1000).toStringAsFixed(0)} Mbps' : '$kbps kbps';

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

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.body});

  final IconData icon;
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
          Icon(icon, size: 20, color: AppColors.royalBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyStrong),
                Text(
                  body,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
