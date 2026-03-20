import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/task_session_scope.dart';

/// 会话页作用域切换条。
///
/// 用于把“当前 Agent 工作区”和“全部任务历史”这两种视角明确区分开，
/// 减少用户在会话页中混淆上下文来源。
class TaskSessionScopeBarView extends StatelessWidget {
  const TaskSessionScopeBarView({
    super.key,
    required this.scope,
    required this.currentAgentLabel,
    required this.currentAgentTaskCount,
    required this.allTaskCount,
    required this.onScopeChanged,
  });

  final TaskSessionScope scope;
  final String currentAgentLabel;
  final int currentAgentTaskCount;
  final int allTaskCount;
  final ValueChanged<TaskSessionScope> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _CountChip(
          label: currentAgentLabel,
          value: currentAgentTaskCount.toString(),
          color: AppTheme.accent,
        ),
        _CountChip(
          label: l10n.text('sessions.scope_all'),
          value: allTaskCount.toString(),
          color: AppTheme.textSecondaryOf(context),
        ),
        ChoiceChip(
          label: Text(l10n.text('sessions.scope_current_agent')),
          selected: scope == TaskSessionScope.currentAgent,
          onSelected: (_) {
            onScopeChanged(TaskSessionScope.currentAgent);
          },
        ),
        ChoiceChip(
          label: Text(l10n.text('sessions.scope_all')),
          selected: scope == TaskSessionScope.all,
          onSelected: (_) {
            onScopeChanged(TaskSessionScope.all);
          },
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
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
        color: color.withValues(alpha: 0.1),
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
