import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/risk_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/scan_repository.dart';
import '../../state/history_controller.dart';
import '../../widgets/app_widgets.dart';
import '../privacy/app_detail_page.dart';

/// One stored scan: score, breakdown and every finding captured at the time.
class ScanDetailPage extends StatefulWidget {
  const ScanDetailPage({super.key, required this.scanId});

  final int scanId;

  @override
  State<ScanDetailPage> createState() => _ScanDetailPageState();
}

class _ScanDetailPageState extends State<ScanDetailPage> {
  ScanRecord? _record;
  List<AppSnapshot> _snapshots = const [];
  List<FindingRecord> _findings = const [];
  bool _loading = true;
  bool _showAllFindings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final history = context.read<HistoryController>();
    final repository = context.read<ScanRepository>();
    final record = await repository.scan(widget.scanId);
    if (!mounted) return;
    if (record == null) {
      setState(() => _loading = false);
      return;
    }
    final results = await Future.wait([
      history.snapshots(widget.scanId),
      history.findings(widget.scanId),
    ]);
    if (!mounted) return;
    setState(() {
      _record = record;
      _snapshots = results[0] as List<AppSnapshot>;
      _findings = results[1] as List<FindingRecord>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = _record;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan report')),
        body: const EmptyState(
          title: 'Record not found',
          message: 'This scan was deleted or never finished saving.',
          icon: Icons.history_toggle_off_rounded,
        ),
      );
    }

    final level = RiskLevel.values.firstWhere(
      (value) => value.name == record.riskLevel,
      orElse: () => RiskLevel.medium,
    );
    final color = RiskPalette.color(context, level);
    final high = _findings.where((f) => f.severity == 'high').toList();
    final medium = _findings.where((f) => f.severity == 'medium').toList();
    final low = _findings.where((f) => f.severity == 'low').toList();
    final flagged = _snapshots.where((s) => s.riskScore > 0).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    final shownFindings = _showAllFindings ? _findings : _findings.take(25);

    return AppPageScaffold(
      title: 'Scan report',
      subtitle: formatDateTime(record.createdAt),
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
                  score: record.score,
                  color: color,
                  size: 150,
                  label: RiskPalette.scoreBand(context, record.score),
                  caption: 'Score at the time of this scan',
                  animate: false,
                ),
                const SizedBox(height: AppSpacing.standard),
                Text(
                  record.summary.isEmpty
                      ? 'No summary was stored.'
                      : record.summary,
                  textAlign: TextAlign.center,
                  style: AppTypography.small.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                DetailRow(
                  label: 'Apps scanned',
                  value: '${record.appsScanned}',
                ),
                DetailRow(
                  label: 'Duration',
                  value: formatMillis(record.durationMs.toDouble()),
                ),
                DetailRow(label: 'Findings', value: '${record.findingsCount}'),
              ],
            ),
          ),
          const SectionHeader(title: 'Breakdown'),
          AppCard(
            child: Column(
              children: [
                MetricBar(
                  label: 'High severity',
                  valueLabel: '${high.length}',
                  fraction: record.findingsCount == 0
                      ? 0
                      : high.length / record.findingsCount,
                  color: AppColors.danger,
                ),
                MetricBar(
                  label: 'Worth a look',
                  valueLabel: '${medium.length}',
                  fraction: record.findingsCount == 0
                      ? 0
                      : medium.length / record.findingsCount,
                  color: AppColors.warning,
                ),
                MetricBar(
                  label: 'Informational',
                  valueLabel: '${low.length}',
                  fraction: record.findingsCount == 0
                      ? 0
                      : low.length / record.findingsCount,
                  color: AppColors.info,
                ),
              ],
            ),
          ),
          if (_findings.isNotEmpty) ...[
            SectionHeader(title: 'Findings (${_findings.length})'),
            for (final finding in shownFindings)
              _FindingTile(finding: finding),
            if (_findings.length > 25 && !_showAllFindings)
              TextButton(
                onPressed: () => setState(() => _showAllFindings = true),
                child: Text('Show all ${_findings.length} findings'),
              ),
          ],
          if (flagged.isNotEmpty) ...[
            SectionHeader(title: 'Apps flagged (${flagged.length})'),
            AppCard(
              child: Column(
                children: [
                  for (final snapshot in flagged.take(30))
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AppDetailPage(packageName: snapshot.packageName),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapshot.appName,
                                    style: AppTypography.bodyStrong,
                                  ),
                                  Text(
                                    snapshot.reasons.isEmpty
                                        ? snapshot.packageName
                                        : snapshot.reasons.split('\n').first,
                                    style: AppTypography.small.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${snapshot.riskScore}',
                              style: AppTypography.bodyStrong.copyWith(
                                color: RiskPalette.color(
                                  context,
                                  _levelOf(snapshot.riskLevel),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.standard),
          const DisclaimerNote(),
        ],
      ),
    );
  }

  static RiskLevel _levelOf(String name) => RiskLevel.values.firstWhere(
    (level) => level.name == name,
    orElse: () => RiskLevel.medium,
  );
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.finding});

  final FindingRecord finding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (finding.severity) {
      'high' => AppColors.danger,
      'medium' => AppColors.warning,
      _ => AppColors.info,
    };

    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: AppSpacing.tight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(finding.title, style: AppTypography.bodyStrong),
                if (finding.detail.isNotEmpty)
                  Text(
                    finding.detail,
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
