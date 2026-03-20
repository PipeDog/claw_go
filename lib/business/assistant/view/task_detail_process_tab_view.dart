import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_task.dart';

/// 会话详情的“过程”Tab。
///
/// 这个区域专门承接 transcript / stdout / stderr 类过程信息，
/// 与摘要、结果分离后，用户只在需要排障时才会进入这里。
class TaskDetailProcessTabView extends StatelessWidget {
  const TaskDetailProcessTabView({
    super.key,
    required this.task,
  });

  final AssistantTask task;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String processText = task.transcript.join('\n').trim();

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
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
              l10n.text('task.process'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.text('task.process_desc'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryOf(context),
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.panelOf(context).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderOf(context)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    processText.isEmpty
                        ? l10n.text('task.process_empty')
                        : processText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimaryOf(context),
                          fontFamily: 'monospace',
                          height: 1.55,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
