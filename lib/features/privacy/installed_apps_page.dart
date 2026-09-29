import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../services/app_scanner/app_scanner_service.dart';
import '../../services/platform/native_models.dart';
import '../../state/security_controller.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/list_tiles.dart';
import 'app_detail_page.dart';

/// Installed app analyzer: filter, sort and search the full package list.
class InstalledAppsPage extends StatefulWidget {
  const InstalledAppsPage({
    super.key,
    this.initialFilter = AppFilter.all,
    this.initialSort = AppSort.name,
  });

  final AppFilter initialFilter;
  final AppSort initialSort;

  @override
  State<InstalledAppsPage> createState() => _InstalledAppsPageState();
}

class _InstalledAppsPageState extends State<InstalledAppsPage> {
  late AppFilter _filter = widget.initialFilter;
  late AppSort _sort = widget.initialSort;
  String _query = '';

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
    final theme = Theme.of(context);

    var apps = scanner.filter(filter: _filter, sort: _sort);
    if (_query.isNotEmpty) {
      final needle = _query.toLowerCase();
      apps = apps
          .where(
            (app) =>
                app.label.toLowerCase().contains(needle) ||
                app.packageName.toLowerCase().contains(needle),
          )
          .toList(growable: false);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed apps'),
        actions: [
          PopupMenuButton<AppSort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => [
              for (final sort in AppSort.values)
                PopupMenuItem(value: sort, child: Text(sort.label)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.tight,
            ),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search apps or package names',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                filled: true,
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              children: [
                for (final filter in AppFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.tight),
          Expanded(
            child: scanner.isScanning && !scanner.hasScanned
                ? const Center(child: CircularProgressIndicator())
                : !scanner.hasScanned
                ? EmptyState(
                    title: 'No apps loaded',
                    message:
                        scanner.lastError ??
                        'Run a security scan to load your app list.',
                    icon: Icons.apps_rounded,
                    actionLabel: 'Run scan',
                    onAction: () =>
                        context.read<SecurityController>().runScan(),
                  )
                : apps.isEmpty
                ? const EmptyState(
                    title: 'No matching apps',
                    message: 'Try another filter or a shorter search.',
                    icon: Icons.search_off_rounded,
                    compact: true,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      AppSpacing.standard * 2,
                    ),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return AppListTile(
                        app: app,
                        subtitleOverride: _subtitleFor(app),
                        trailing: _trailingFor(scanner, app),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                AppDetailPage(packageName: app.packageName),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: scanner.hasScanned
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Text(
                  '${apps.length} of ${scanner.allApps.length} apps · ${formatBytes(_totalSize(apps))}',
                  textAlign: TextAlign.center,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _subtitleFor(AppInfo app) {
    final parts = <String>[
      if (app.isSystemApp) 'System',
      if (app.isSideloaded && !app.isSystemApp) 'Sideloaded',
      '${app.permissions.length} permissions',
      if (app.sizeBytes != null) formatBytes(app.sizeBytes!),
    ];
    return parts.join(' · ');
  }

  Widget _trailingFor(AppScannerService scanner, AppInfo app) {
    final assessment = scanner.assessmentFor(app.packageName);
    if (assessment != null && assessment.needsReview) {
      return RiskPill(level: assessment.level);
    }
    final privacyLevel = scanner.privacyLevelFor(scanner.privacyScoreFor(app));
    if (privacyLevel == RiskLevel.safe) {
      return const StatusPill(
        label: 'Low access',
        color: AppColors.safe,
        dense: true,
      );
    }
    return RiskPill(level: privacyLevel);
  }

  int _totalSize(List<AppInfo> apps) =>
      apps.fold<int>(0, (sum, app) => sum + (app.sizeBytes ?? 0));
}
