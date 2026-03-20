import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../model/diagnostic_log_entry.dart';

/// 诊断日志明细列表。
///
/// 这里采用“单面板 + 平铺行式日志”的方式：
/// - 保留日志的连续阅读感；
/// - 避免每一条都做成厚重卡片，导致有效信息密度过低；
/// - 用轻量分隔、类别标签和序号强化扫描效率。
class DiagnosticLogListView extends StatelessWidget {
  const DiagnosticLogListView({
    super.key,
    required this.entries,
  });

  final List<DiagnosticLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panelOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '实时日志流',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '按最新优先展示，便于快速定位刚刚发生的问题。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryOf(context),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <Widget>[
                    _LegendChip(
                      label: '异常',
                      color: Color(0xFFEF4444),
                    ),
                    _LegendChip(
                      label: '请求',
                      color: Color(0xFF60A5FA),
                    ),
                    _LegendChip(
                      label: '网关',
                      color: Color(0xFF06B6D4),
                    ),
                    _LegendChip(
                      label: '成功',
                      color: Color(0xFF16A34A),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      '当前还没有可展示的诊断日志',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 18,
                      endIndent: 18,
                      color: AppTheme.borderOf(context).withValues(alpha: 0.72),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final DiagnosticLogEntry entry = entries[index];
                      return _DiagnosticLogRow(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticLogRow extends StatelessWidget {
  const _DiagnosticLogRow({required this.entry});

  final DiagnosticLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final _CategoryVisual visual = _visualOf(
      context,
      entry.category,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '#${entry.sequence}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: visual.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: visual.color.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              visual.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: visual.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              entry.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimaryOf(context),
                    fontFamily: 'monospace',
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  _CategoryVisual _visualOf(
    BuildContext context,
    DiagnosticLogCategory category,
  ) {
    return switch (category) {
      DiagnosticLogCategory.error => const _CategoryVisual(
          label: '异常',
          color: AppTheme.danger,
        ),
      DiagnosticLogCategory.success => const _CategoryVisual(
          label: '成功',
          color: AppTheme.success,
        ),
      DiagnosticLogCategory.request => const _CategoryVisual(
          label: '请求',
          color: Color(0xFF60A5FA),
        ),
      DiagnosticLogCategory.gateway => const _CategoryVisual(
          label: '网关',
          color: Color(0xFF06B6D4),
        ),
      DiagnosticLogCategory.normal => _CategoryVisual(
          label: '常规',
          color: AppTheme.textSecondaryOf(context),
        ),
    };
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}
