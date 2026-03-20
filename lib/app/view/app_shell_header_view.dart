import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/assistant/view_model/assistant_task_center_view_model.dart';
import '../../business/assistant/view_model/chat_runtime_view_model.dart';
import '../../business/session/view_model/session_view_model.dart';
import '../../foundation/i18n/app_localizations.dart';
import '../config/app_theme.dart';

/// 桌面壳层顶部状态栏。
///
/// 左侧区域完全交由外层传入，壳层只负责承载右侧通用状态信息。
class AppShellHeaderView extends ConsumerWidget {
  const AppShellHeaderView({
    super.key,
    this.leftSlot,
    required this.versionText,
    required this.healthText,
    required this.ready,
  });

  final Widget? leftSlot;
  final String versionText;
  final String healthText;
  final bool ready;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelColor = AppTheme.panelOf(context);
    final borderColor = AppTheme.borderOf(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final assistantTaskCenterViewModel =
        ref.watch(assistantTaskCenterViewModelProvider);
    final chatRuntimeViewModel = ref.watch(chatRuntimeViewModelProvider);
    final sessionViewModel = ref.watch(sessionViewModelProvider);
    final List<String> issueMessages = _collectIssueMessages(
      taskErrorMessage: assistantTaskCenterViewModel.errorMessage,
      runtimeErrorMessage: chatRuntimeViewModel.errorMessage,
      sessionErrorMessage: sessionViewModel.errorMessage,
    );
    final bool hasIssues = issueMessages.isNotEmpty;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: leftSlot ?? const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                reverse: true,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _IssueIndicator(
                      active: hasIssues,
                      onTap: () {
                        _showIssueDialog(
                          context: context,
                          issues: issueMessages,
                          title: l10n.text('chat.issue_title'),
                          emptyText: l10n.text('chat.issue_empty'),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(
                      dotColor: AppTheme.success,
                      label: '${l10n.text('shell.version')}  $versionText',
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(
                      dotColor: ready ? AppTheme.success : AppTheme.danger,
                      label: '${l10n.text('shell.health')}  $healthText',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _collectIssueMessages({
    required String? taskErrorMessage,
    required String? runtimeErrorMessage,
    required String? sessionErrorMessage,
  }) {
    final List<String> messages = <String>[];
    for (final String item in <String>[
      taskErrorMessage ?? '',
      runtimeErrorMessage ?? '',
      sessionErrorMessage ?? '',
    ]) {
      final String trimmed = item.trim();
      if (trimmed.isEmpty || messages.contains(trimmed)) {
        continue;
      }
      messages.add(trimmed);
    }
    return messages;
  }

  Future<void> _showIssueDialog({
    required BuildContext context,
    required List<String> issues,
    required String title,
    required String emptyText,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: issues.isEmpty
                ? Text(
                    emptyText,
                    style: theme.textTheme.bodyMedium,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: issues.map((String item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: AppTheme.warning,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.of(dialogContext).text('common.close'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IssueIndicator extends StatelessWidget {
  const _IssueIndicator({
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.panelSecondaryOf(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppTheme.warning : AppTheme.borderOf(context),
          ),
        ),
        child: Text(
          '!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: active
                    ? AppTheme.warning
                    : AppTheme.textSecondaryOf(context),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1,
              ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.dotColor,
    required this.label,
  });

  final Color dotColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final panelSecondary = AppTheme.panelSecondaryOf(context);
    final borderColor = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: panelSecondary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
