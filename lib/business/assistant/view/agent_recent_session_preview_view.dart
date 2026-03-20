import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_task.dart';

/// 当前 Agent 最近会话预览。
///
/// 该区块作为“Agent 资产页”与“Agent 工作区”的桥梁：
/// 用户可以先看清 Agent 的最近活跃情况，再决定是否跳转到 Chat / Sessions。
class AgentRecentSessionPreviewView extends StatelessWidget {
  const AgentRecentSessionPreviewView({
    super.key,
    required this.tasks,
    required this.onOpenSessions,
  });

  final List<AssistantTask> tasks;
  final VoidCallback onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (tasks.isEmpty) {
      return Center(
        child: Text(l10n.text('agents.recent_empty')),
      );
    }

    return Column(
      children: <Widget>[
        ...tasks.map(
          (AssistantTask task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecentSessionRow(task: task),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onOpenSessions,
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(l10n.text('agents.action_open_sessions')),
          ),
        ),
      ],
    );
  }
}

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({required this.task});

  final AssistantTask task;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (task.status) {
      AssistantTaskStatus.running => AppTheme.accent,
      AssistantTaskStatus.completed => AppTheme.success,
      AssistantTaskStatus.failed => AppTheme.danger,
      AssistantTaskStatus.stopped => AppTheme.warning,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.sectionMutedOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.status.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (task.summary ?? task.prompt).replaceAll('\n', ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
