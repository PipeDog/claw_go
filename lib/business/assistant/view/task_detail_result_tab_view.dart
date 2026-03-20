import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_task.dart';

/// 会话详情的“结果”Tab。
///
/// 该视图只承接任务结果与失败原因，
/// 让用户先判断“结果好不好、接下来要不要继续追问或排障”。
class TaskDetailResultTabView extends StatelessWidget {
  const TaskDetailResultTabView({
    super.key,
    required this.task,
  });

  final AssistantTask task;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String summary = (task.summary ?? '').trim();
    final String failureMessage = (task.failureMessage ?? '').trim();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _SectionCard(
          title: l10n.text('task.summary'),
          child: SelectableText(
            summary.isEmpty ? l10n.text('task.result_empty') : summary,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (failureMessage.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.text('status.failed'),
            titleColor: AppTheme.danger,
            child: SelectableText(
              failureMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.danger,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.titleColor,
  });

  final String title;
  final Widget child;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: titleColor,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
