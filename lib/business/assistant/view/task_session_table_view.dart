import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_task.dart';

/// 会话列表视图。
///
/// 这里使用更轻量的纵向会话行，减少标签堆叠，
/// 让左侧列表把空间优先让给标题、预览和关键信息。
class TaskSessionTableView extends StatelessWidget {
  const TaskSessionTableView({
    super.key,
    required this.tasks,
    required this.selectedTaskId,
    required this.onSelect,
  });

  final List<AssistantTask> tasks;
  final String? selectedTaskId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (tasks.isEmpty) {
      return Center(child: Text(l10n.text('sessions.empty')));
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final AssistantTask task = tasks[index];
        return _TaskSessionListItem(
          task: task,
          selected: task.id == selectedTaskId,
          onTap: () => onSelect(task.id),
        );
      },
    );
  }
}

class _TaskSessionListItem extends StatelessWidget {
  const _TaskSessionListItem({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final AssistantTask task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accentColor = AppTheme.accent;
    final Color statusColor = switch (task.status) {
      AssistantTaskStatus.running => AppTheme.accent,
      AssistantTaskStatus.completed => AppTheme.success,
      AssistantTaskStatus.failed => AppTheme.danger,
      AssistantTaskStatus.stopped => AppTheme.warning,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.08)
                : AppTheme.panelSecondaryOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accentColor : AppTheme.borderOf(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatTime(task.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _buildPreview(task),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(task.status, AppLocalizations.of(context)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${task.commandLabel} · ${task.profileName}',
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
            ],
          ),
        ),
      ),
    );
  }

  String _buildPreview(AssistantTask task) {
    final String summary = (task.summary ?? '').trim();
    if (summary.isNotEmpty) {
      return summary.replaceAll('\n', ' ');
    }
    if (task.chatMessages.isNotEmpty) {
      return task.chatMessages.last.content.replaceAll('\n', ' ').trim();
    }
    return task.prompt.replaceAll('\n', ' ').trim();
  }

  String _statusLabel(AssistantTaskStatus status, AppLocalizations l10n) {
    return switch (status) {
      AssistantTaskStatus.running => l10n.text('status.running'),
      AssistantTaskStatus.completed => l10n.text('status.completed'),
      AssistantTaskStatus.failed => l10n.text('status.failed'),
      AssistantTaskStatus.stopped => l10n.text('status.stopped'),
    };
  }

  String _formatTime(DateTime time) {
    return '${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
