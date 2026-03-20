import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_task.dart';

/// 会话详情的“摘要”Tab。
///
/// 该视图只回答“这个任务是什么、为什么发起、核心输入是什么”，
/// 避免把结果与过程信息继续混在一起。
class TaskDetailSummaryTabView extends StatelessWidget {
  const TaskDetailSummaryTabView({
    super.key,
    required this.task,
  });

  final AssistantTask task;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _SectionCard(
          title: l10n.text('task.prompt'),
          child: SelectableText(
            task.prompt,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: l10n.text('task.summary_context'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InfoRow(
                label: l10n.text('task.source_action'),
                value: task.commandLabel,
              ),
              _InfoRow(
                label: l10n.text('task.profile'),
                value: task.profileName,
              ),
              _InfoRow(
                label: l10n.text('task.agent'),
                value: task.agentId,
              ),
              if ((task.revertToTaskId ?? '').isNotEmpty)
                _InfoRow(
                  label: l10n.text('task.revert_anchor'),
                  value: task.revertToTaskId!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: <InlineSpan>[
            TextSpan(
              text: '$label：',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontWeight: FontWeight.w600,
              ),
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
      ),
    );
  }
}
