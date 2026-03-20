import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/ui/app_tab_bar_view.dart';
import '../model/assistant_task.dart';
import '../model/task_quick_action.dart';
import 'task_detail_process_tab_view.dart';
import 'task_detail_result_tab_view.dart';
import 'task_detail_summary_tab_view.dart';
import 'task_execution_feedback_view.dart';

/// 任务详情视图。
///
/// 当前详情区采用与聊天页一致的“分区背景 + 最少卡片”结构：
/// - 顶部摘要区负责身份识别、元信息与动作；
/// - 中部通过状态反馈条快速表达结果态；
/// - 底部使用页内 Tab 承载摘要、结果、过程。
class TaskDetailView extends StatelessWidget {
  const TaskDetailView({
    super.key,
    required this.task,
    required this.canStop,
    required this.onStop,
    this.onRevert,
  });

  final AssistantTask? task;
  final bool canStop;
  final VoidCallback onStop;
  final VoidCallback? onRevert;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (task == null) {
      return Center(
        child: Text(l10n.text('task.no_detail')),
      );
    }

    final ThemeData theme = Theme.of(context);
    final Color statusColor = _statusColor(task!.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: DefaultTabController(
            key: ValueKey<String>('task-detail-tabs-${task!.id}'),
            length: 3,
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  color: AppTheme.sectionMutedOf(context),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
                                  task!.title,
                                  style: theme.textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.text('sessions.last_updated')}：${_formatTime(task!.updatedAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                              if (canStop)
                                OutlinedButton.icon(
                                  onPressed: onStop,
                                  icon: const Icon(
                                    Icons.stop_circle_outlined,
                                    size: 18,
                                  ),
                                  label: Text(l10n.text('task.stop')),
                                ),
                              if (onRevert != null &&
                                  task!.quickActionId == TaskQuickAction.chatId)
                                OutlinedButton.icon(
                                  onPressed: onRevert,
                                  icon: const Icon(
                                    Icons.history_toggle_off_rounded,
                                    size: 18,
                                  ),
                                  label: Text(l10n.text('task.revert')),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _StatusBadge(
                            label: _statusLabel(task!.status, l10n),
                            color: statusColor,
                          ),
                          _InlineMetaText(
                            label: l10n.text('task.source_action'),
                            value: task!.commandLabel,
                          ),
                          _InlineMetaText(
                            label: l10n.text('task.profile'),
                            value: task!.profileName,
                          ),
                          _InlineMetaText(
                            label: l10n.text('task.agent'),
                            value: task!.agentId,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TaskExecutionFeedbackView(task: task!),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.borderOf(context)),
                Container(
                  width: double.infinity,
                  color: AppTheme.sectionMutedOf(context),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: AppTabBarView(
                    compact: true,
                    isScrollable: true,
                    tabs: <Widget>[
                      Tab(text: l10n.text('task.tab_summary')),
                      Tab(text: l10n.text('task.tab_result')),
                      Tab(text: l10n.text('task.tab_process')),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.borderOf(context)),
                Expanded(
                  child: ColoredBox(
                    color: AppTheme.sectionCanvasOf(context),
                    child: TabBarView(
                      children: <Widget>[
                        TaskDetailSummaryTabView(task: task!),
                        TaskDetailResultTabView(task: task!),
                        TaskDetailProcessTabView(task: task!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(AssistantTaskStatus status, AppLocalizations l10n) {
    return switch (status) {
      AssistantTaskStatus.running => l10n.text('status.running'),
      AssistantTaskStatus.completed => l10n.text('status.completed'),
      AssistantTaskStatus.failed => l10n.text('status.failed'),
      AssistantTaskStatus.stopped => l10n.text('status.stopped'),
    };
  }

  Color _statusColor(AssistantTaskStatus status) {
    return switch (status) {
      AssistantTaskStatus.running => AppTheme.accent,
      AssistantTaskStatus.completed => AppTheme.success,
      AssistantTaskStatus.failed => AppTheme.danger,
      AssistantTaskStatus.stopped => AppTheme.warning,
    };
  }

  String _formatTime(DateTime time) {
    return '${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _InlineMetaText extends StatelessWidget {
  const _InlineMetaText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryOf(context),
            ),
        children: <InlineSpan>[
          TextSpan(
            text: '$label：',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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
