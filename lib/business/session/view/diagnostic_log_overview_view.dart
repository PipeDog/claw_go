import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../model/diagnostic_log_entry.dart';

/// 诊断日志概览区。
///
/// 目标不是堆更多装饰，而是在进入日志明细前，
/// 先把“当前日志量级、异常占比、连接相关状态”快速讲清楚。
class DiagnosticLogOverviewView extends StatelessWidget {
  const DiagnosticLogOverviewView({
    super.key,
    required this.entries,
  });

  final List<DiagnosticLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final DiagnosticLogEntry? latestEntry =
        entries.isEmpty ? null : entries.first;
    final int errorCount = _countOf(DiagnosticLogCategory.error);
    final int gatewayCount = _countOf(DiagnosticLogCategory.gateway);
    final int requestCount = _countOf(DiagnosticLogCategory.request);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _DiagnosticMetricCard(
          label: '总日志',
          value: entries.length.toString(),
          icon: Icons.receipt_long_rounded,
          accentColor: AppTheme.accent,
        ),
        _DiagnosticMetricCard(
          label: '异常条目',
          value: errorCount.toString(),
          icon: Icons.error_outline_rounded,
          accentColor: AppTheme.danger,
        ),
        _DiagnosticMetricCard(
          label: '网关事件',
          value: gatewayCount.toString(),
          icon: Icons.hub_outlined,
          accentColor: const Color(0xFF06B6D4),
        ),
        _DiagnosticMetricCard(
          label: '请求交互',
          value: requestCount.toString(),
          icon: Icons.sync_alt_rounded,
          accentColor: const Color(0xFF60A5FA),
        ),
        _DiagnosticLatestCard(entry: latestEntry),
      ],
    );
  }

  int _countOf(DiagnosticLogCategory category) {
    return entries.where((DiagnosticLogEntry entry) {
      return entry.category == category;
    }).length;
  }
}

class _DiagnosticMetricCard extends StatelessWidget {
  const _DiagnosticMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryOf(context),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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

class _DiagnosticLatestCard extends StatelessWidget {
  const _DiagnosticLatestCard({required this.entry});

  final DiagnosticLogEntry? entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String subtitle = entry == null
        ? '当前还没有诊断日志'
        : '${_categoryLabel(entry!.category)} · #${entry!.sequence}';

    return Container(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '最新状态',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (entry != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              entry!.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  String _categoryLabel(DiagnosticLogCategory category) {
    return switch (category) {
      DiagnosticLogCategory.error => '异常',
      DiagnosticLogCategory.success => '成功',
      DiagnosticLogCategory.request => '请求',
      DiagnosticLogCategory.gateway => '网关',
      DiagnosticLogCategory.normal => '常规',
    };
  }
}
