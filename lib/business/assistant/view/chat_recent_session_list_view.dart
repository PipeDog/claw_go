import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/ui/markdown/markdown.dart';
import '../model/assistant_task.dart';
import '../model/task_quick_action.dart';

/// 聊天页右侧的最近会话列表。
///
/// 保持紧凑展示，方便快速切换任务，同时尽量把主区域留给当前对话。
class ChatRecentSessionListView extends StatelessWidget {
  const ChatRecentSessionListView({
    super.key,
    required this.tasks,
    required this.selectedTaskId,
    required this.currentAgentId,
    required this.onSelect,
    this.onOpenAll,
    this.onRevert,
    this.showHeader = true,
  });

  final List<AssistantTask> tasks;
  final String? selectedTaskId;
  final String currentAgentId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onOpenAll;
  final ValueChanged<String>? onRevert;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showHeader) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        l10n.text('chat.recent_sessions'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenAll != null)
                TextButton(
                  onPressed: onOpenAll,
                  child: Text(l10n.text('common.view_all')),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: tasks.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.text('sessions.empty'),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppTheme.borderOf(context),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return _RecentSessionItem(
                      task: tasks[index],
                      selected: tasks[index].id == selectedTaskId,
                      onTap: () => onSelect(tasks[index].id),
                      canRevert: onRevert != null &&
                          _canRevertTask(tasks[index], currentAgentId),
                      onRevert: () => onRevert?.call(tasks[index].id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _canRevertTask(AssistantTask task, String currentAgentId) {
    return task.quickActionId == TaskQuickAction.chatId &&
        task.agentId == currentAgentId;
  }
}

class _RecentSessionItem extends StatelessWidget {
  const _RecentSessionItem({
    required this.task,
    required this.selected,
    required this.onTap,
    required this.canRevert,
    this.onRevert,
  });

  final AssistantTask task;
  final bool selected;
  final VoidCallback onTap;
  final bool canRevert;
  final VoidCallback? onRevert;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accentColor = AppTheme.accent;
    final Color borderColor = selected ? accentColor : Colors.transparent;
    final Color backgroundColor =
        selected ? accentColor.withValues(alpha: 0.08) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Feedback.forTap(context);
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: selected ? borderColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: MarkdownTextView(
                      data: task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textColor: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(task.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                  if (canRevert) ...<Widget>[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: AppLocalizations.of(context).text('task.revert'),
                      onPressed: onRevert,
                      icon: const Icon(
                        Icons.history_toggle_off_rounded,
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              MarkdownTextView(
                data: _buildPreview(task),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.45,
                ),
                textColor: AppTheme.textSecondaryOf(context),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _MiniMeta(
                    icon: _statusIcon(task.status),
                    label: _statusLabel(context, task.status),
                    color: _statusColor(task.status),
                  ),
                  _MiniMeta(
                    icon: Icons.folder_open_rounded,
                    label: task.profileName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildPreview(AssistantTask task) {
    if (task.chatMessages.isNotEmpty) {
      final String latest = task.chatMessages.last.content.trim();
      if (latest.isNotEmpty) {
        return latest.replaceAll('\n', ' ');
      }
    }
    final String summary = (task.summary ?? '').trim();
    if (summary.isNotEmpty) {
      return summary.replaceAll('\n', ' ');
    }
    return task.prompt.replaceAll('\n', ' ');
  }

  IconData _statusIcon(AssistantTaskStatus status) {
    return switch (status) {
      AssistantTaskStatus.running => Icons.autorenew_rounded,
      AssistantTaskStatus.completed => Icons.check_circle_outline_rounded,
      AssistantTaskStatus.failed => Icons.error_outline_rounded,
      AssistantTaskStatus.stopped => Icons.stop_circle_outlined,
    };
  }

  Color _statusColor(AssistantTaskStatus status) {
    return switch (status) {
      AssistantTaskStatus.running => AppTheme.accent,
      AssistantTaskStatus.completed => AppTheme.success,
      AssistantTaskStatus.failed => AppTheme.warning,
      AssistantTaskStatus.stopped => Colors.grey,
    };
  }

  String _statusLabel(BuildContext context, AssistantTaskStatus status) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return switch (status) {
      AssistantTaskStatus.running => l10n.text('status.running'),
      AssistantTaskStatus.completed => l10n.text('status.completed'),
      AssistantTaskStatus.failed => l10n.text('status.failed'),
      AssistantTaskStatus.stopped => l10n.text('status.stopped'),
    };
  }

  String _formatTime(DateTime time) {
    return '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color resolvedColor = color ?? AppTheme.textSecondaryOf(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: resolvedColor),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: resolvedColor,
            ),
          ),
        ),
      ],
    );
  }
}
