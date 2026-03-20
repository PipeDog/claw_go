import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_agent_directory_item.dart';

/// Agent 列表视图。
///
/// 列表项使用更轻量的纵向信息行，兼顾：
/// - 当前 / 默认状态识别
/// - workspace / model 快速扫描
/// - 一键切换当前 Agent
class AgentDirectoryListView extends StatelessWidget {
  const AgentDirectoryListView({
    super.key,
    required this.items,
    required this.loading,
    required this.onSelectAgent,
  });

  final List<AssistantAgentDirectoryItem> items;
  final bool loading;
  final ValueChanged<String> onSelectAgent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (items.isEmpty) {
      return Center(child: Text(l10n.text('agents.empty')));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final AssistantAgentDirectoryItem item = items[index];
        return _AgentListCard(
          item: item,
          loading: loading,
          onSelectAgent: onSelectAgent,
        );
      },
    );
  }
}

class _AgentListCard extends StatelessWidget {
  const _AgentListCard({
    required this.item,
    required this.loading,
    required this.onSelectAgent,
  });

  final AssistantAgentDirectoryItem item;
  final bool loading;
  final ValueChanged<String> onSelectAgent;

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        item.isSelected ? AppTheme.accent : AppTheme.borderOf(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isSelected
            ? AppTheme.accent.withValues(alpha: 0.08)
            : AppTheme.panelSecondaryOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.displayLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description ?? l10n.text('agents.no_description'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
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
                alignment: WrapAlignment.end,
                children: <Widget>[
                  if (item.isSelected)
                    _Badge(
                      label: l10n.text('agents.badge_current'),
                      color: AppTheme.accent,
                    ),
                  if (item.isDefault)
                    const _Badge(
                      label: 'Default',
                      color: Color(0xFFF59E0B),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                Icons.folder_open_outlined,
                size: 16,
                color: AppTheme.textSecondaryOf(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.workspace.isEmpty
                      ? l10n.text('common.none')
                      : item.workspace,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.memory_outlined,
                size: 16,
                color: AppTheme.textSecondaryOf(context),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.modelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: item.isSelected
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(l10n.text('agents.badge_current')),
                  )
                : FilledButton.icon(
                    onPressed: loading ? null : () => onSelectAgent(item.id),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(l10n.text('agents.action_use_current')),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
