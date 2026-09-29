import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../state/history_controller.dart';
import '../../widgets/app_widgets.dart';
import 'scan_detail_page.dart';

/// Past scans, newest first. Everything here is local and deletable.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan history'),
        actions: [
          if (history.records.isNotEmpty)
            IconButton(
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: history.load,
        child: history.isLoading && history.records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : history.records.isEmpty
            ? ListView(
                children: const [
                  EmptyState(
                    title: 'No scans yet',
                    message:
                        'Run a security scan and it will be recorded here so you '
                        'can compare results over time.',
                    icon: Icons.history_rounded,
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.tight,
                  AppSpacing.screen,
                  AppSpacing.standard * 2,
                ),
                itemCount: history.records.length,
                itemBuilder: (context, index) {
                  final record = history.records[index];
                  final previous = index + 1 < history.records.length
                      ? history.records[index + 1]
                      : null;
                  return _RecordTile(
                    record: record,
                    delta: previous == null ? null : record.score - previous.score,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ScanDetailPage(scanId: record.id),
                      ),
                    ),
                    onDelete: () => _confirmDelete(context, record),
                  );
                },
              ),
      ),
      bottomNavigationBar: history.records.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.standard),
                child: Text(
                  '${history.records.length} record${history.records.length == 1 ? '' : 's'} stored on this device',
                  textAlign: TextAlign.center,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ScanRecord record) async {
    final history = context.read<HistoryController>();
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete this record?',
      message:
          'The ${_RecordTile._labelFor(record.scanType).toLowerCase()} from '
          '${formatDateTime(record.createdAt)} will be removed.',
    );
    if (!confirmed || !context.mounted) return;
    await history.delete(record.id);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final history = context.read<HistoryController>();
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Clear all scan history?',
      message: 'Every stored scan record will be removed from this device.',
      confirmLabel: 'Clear all',
    );
    if (!confirmed || !context.mounted) return;
    await history.clear();
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.onTap,
    required this.onDelete,
    this.delta,
  });

  final ScanRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Score change versus the previous record of any type.
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = _levelFor(record.riskLevel);
    final color = RiskPalette.color(context, level);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${record.score}',
              style: AppTypography.bodyStrong.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _labelFor(record.scanType),
                      style: AppTypography.bodyStrong,
                    ),
                    if (delta != null && delta != 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${delta! > 0 ? '+' : ''}$delta',
                        style: AppTypography.small.copyWith(
                          color: delta! > 0 ? AppColors.safe : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    formatDateTime(record.createdAt),
                    if (record.appsScanned > 0) '${record.appsScanned} apps',
                    if (record.findingsCount > 0)
                      '${record.findingsCount} findings',
                  ].join(' · '),
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.danger,
            tooltip: 'Delete record',
          ),
        ],
      ),
    );
  }

  static RiskLevel _levelFor(String name) => RiskLevel.values.firstWhere(
    (level) => level.name == name,
    orElse: () => RiskLevel.medium,
  );

  static String _labelFor(String type) => switch (type) {
    'security' => 'Security scan',
    _ => type,
  };
}
