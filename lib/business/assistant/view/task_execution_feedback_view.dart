import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_task.dart';

/// 任务执行反馈视图。
///
/// 相比只展示原始状态枚举，这里进一步补充：
/// - 当前结果态的含义；
/// - 对用户更直接的下一步建议；
/// - 失败态 / 运行态 / 完成态的差异化视觉反馈。
class TaskExecutionFeedbackView extends StatelessWidget {
  const TaskExecutionFeedbackView({
    super.key,
    required this.task,
  });

  final AssistantTask task;

  @override
  Widget build(BuildContext context) {
    final _TaskFeedbackVisual visual = _resolveVisual(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(visual.icon, color: visual.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  visual.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: visual.color,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  visual.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                        height: 1.45,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TaskFeedbackVisual _resolveVisual(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return switch (task.status) {
      AssistantTaskStatus.running => _TaskFeedbackVisual(
          title: l10n.text('task.feedback_running_title'),
          description: l10n.text('task.feedback_running_desc'),
          icon: Icons.autorenew_rounded,
          color: const Color(0xFF60A5FA),
        ),
      AssistantTaskStatus.completed => _TaskFeedbackVisual(
          title: l10n.text('task.feedback_completed_title'),
          description: task.summary?.trim().isNotEmpty == true
              ? task.summary!
              : l10n.text('task.feedback_completed_desc'),
          icon: Icons.check_circle_outline_rounded,
          color: AppTheme.success,
        ),
      AssistantTaskStatus.failed => _TaskFeedbackVisual(
          title: l10n.text('task.feedback_failed_title'),
          description: task.failureMessage?.trim().isNotEmpty == true
              ? task.failureMessage!
              : l10n.text('task.feedback_failed_desc'),
          icon: Icons.error_outline_rounded,
          color: AppTheme.danger,
        ),
      AssistantTaskStatus.stopped => _TaskFeedbackVisual(
          title: l10n.text('task.feedback_stopped_title'),
          description: l10n.text('task.feedback_stopped_desc'),
          icon: Icons.stop_circle_outlined,
          color: AppTheme.warning,
        ),
    };
  }
}

class _TaskFeedbackVisual {
  const _TaskFeedbackVisual({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
