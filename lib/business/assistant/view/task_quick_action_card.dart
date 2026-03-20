import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/task_quick_action.dart';

/// 快捷动作卡片。
class TaskQuickActionCard extends StatelessWidget {
  const TaskQuickActionCard({
    super.key,
    required this.action,
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final TaskQuickAction action;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final panelColor = AppTheme.panelOf(context);
    final borderColor = AppTheme.borderOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxHeight < 110;
            final double verticalGap = compact ? 4 : 8;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  14, compact ? 10 : 12, 14, compact ? 10 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _localizedTitle(context),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 15 : null,
                          ),
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: favorite
                            ? l10n.text('chat.unfavorite_action')
                            : l10n.text('chat.favorite_action'),
                        onPressed: onToggleFavorite,
                        constraints: const BoxConstraints.tightFor(
                            width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        splashRadius: 18,
                        icon: Icon(
                          favorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 18,
                          color: favorite ? AppTheme.warning : textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalGap),
                  Expanded(
                    child: Text(
                      _localizedSubtitle(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: compact ? 13 : null,
                      ),
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: verticalGap),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded,
                          size: 16, color: AppTheme.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.text('chat.send'),
                          style: theme.textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _localizedTitle(BuildContext context) {
    return switch (action.id) {
      TaskQuickAction.chatId => AppLocalizations.of(context).text(
          'chat.quick_action.chat_title',
        ),
      TaskQuickAction.checkReadyId => AppLocalizations.of(context).text(
          'chat.quick_action.check_ready_title',
        ),
      TaskQuickAction.viewStatusId => AppLocalizations.of(context).text(
          'chat.quick_action.view_status_title',
        ),
      TaskQuickAction.recentChangesId => AppLocalizations.of(context).text(
          'chat.quick_action.recent_changes_title',
        ),
      TaskQuickAction.viewHistoryId => AppLocalizations.of(context).text(
          'chat.quick_action.view_history_title',
        ),
      TaskQuickAction.startGuideId => AppLocalizations.of(context).text(
          'chat.quick_action.start_guide_title',
        ),
      TaskQuickAction.fixSetupId => AppLocalizations.of(context).text(
          'chat.quick_action.fix_setup_title',
        ),
      _ => action.title,
    };
  }

  String _localizedSubtitle(BuildContext context) {
    return switch (action.id) {
      TaskQuickAction.chatId => AppLocalizations.of(context).text(
          'chat.quick_action.chat_subtitle',
        ),
      TaskQuickAction.checkReadyId => AppLocalizations.of(context).text(
          'chat.quick_action.check_ready_subtitle',
        ),
      TaskQuickAction.viewStatusId => AppLocalizations.of(context).text(
          'chat.quick_action.view_status_subtitle',
        ),
      TaskQuickAction.recentChangesId => AppLocalizations.of(context).text(
          'chat.quick_action.recent_changes_subtitle',
        ),
      TaskQuickAction.viewHistoryId => AppLocalizations.of(context).text(
          'chat.quick_action.view_history_subtitle',
        ),
      TaskQuickAction.startGuideId => AppLocalizations.of(context).text(
          'chat.quick_action.start_guide_subtitle',
        ),
      TaskQuickAction.fixSetupId => AppLocalizations.of(context).text(
          'chat.quick_action.fix_setup_subtitle',
        ),
      _ => action.subtitle,
    };
  }
}
