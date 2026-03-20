import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../foundation/i18n/app_localizations.dart';

/// 对话输入区域。
///
/// 当前只负责输入与操作，不再额外制造一层卡片，
/// 由父级分区背景来表达层级。
class TaskComposerView extends StatelessWidget {
  const TaskComposerView({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSubmit,
    required this.onOpenTasks,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): _SubmitMessageIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _SubmitMessageIntent: CallbackAction<_SubmitMessageIntent>(
                onInvoke: (_SubmitMessageIntent intent) {
                  if (!loading) {
                    onSubmit();
                  }
                  return null;
                },
              ),
            },
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: l10n.text('chat.composer_hint'),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            TextButton.icon(
              onPressed: onOpenTasks,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(l10n.text('chat.open_sessions')),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: const Icon(Icons.send_rounded),
              label: Text(
                loading ? l10n.text('chat.processing') : l10n.text('chat.send'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubmitMessageIntent extends Intent {
  const _SubmitMessageIntent();
}
