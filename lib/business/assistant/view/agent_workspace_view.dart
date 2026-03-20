import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_agent_directory_item.dart';
import '../model/assistant_task.dart';
import 'agent_recent_session_preview_view.dart';

/// Agent 工作区视图。
///
/// 该区域不再继续堆叠更多列表，而是聚焦回答三个问题：
/// 1. 当前 Agent 是谁；
/// 2. 它最近在做什么；
/// 3. 下一步应该进入 Chat 还是 Sessions。
class AgentWorkspaceView extends StatelessWidget {
  const AgentWorkspaceView({
    super.key,
    required this.selectedAgent,
    required this.tasks,
    required this.onOpenChat,
    required this.onOpenSessions,
  });

  final AssistantAgentDirectoryItem? selectedAgent;
  final List<AssistantTask> tasks;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AssistantAgentDirectoryItem? agent = selectedAgent;

    if (agent == null) {
      return Center(
        child: Text(l10n.text('agents.no_current_agent_desc')),
      );
    }

    final List<AssistantTask> recentTasks = tasks.take(4).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.sectionMutedOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                agent.displayLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                agent.description ?? l10n.text('agents.no_description'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _MetaChip(
                    label: l10n.text('agents.metric_workspace'),
                    value: agent.workspace.isEmpty
                        ? l10n.text('common.none')
                        : agent.workspace,
                    color: const Color(0xFF60A5FA),
                  ),
                  _MetaChip(
                    label: l10n.text('agents.metric_model'),
                    value: agent.modelLabel,
                    color: AppTheme.success,
                  ),
                  if (agent.isDefault)
                    _MetaChip(
                      label: l10n.text('agents.metric_default'),
                      value: '1',
                      color: const Color(0xFFF59E0B),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(l10n.text('agents.action_open_chat')),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenSessions,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.text('agents.action_open_sessions')),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.text('agents.recent_title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        AgentRecentSessionPreviewView(
          tasks: recentTasks,
          onOpenSessions: onOpenSessions,
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          children: <InlineSpan>[
            TextSpan(
              text: '$label：',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
