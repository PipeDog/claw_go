import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/ui/top_notification_overlay.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/diagnostic_log_entry.dart';
import '../view/diagnostic_log_list_view.dart';
import '../view/diagnostic_log_overview_view.dart';
import '../view_model/session_view_model.dart';

/// 诊断日志页。
class LogsPage extends ConsumerWidget {
  const LogsPage({
    super.key,
    this.showPageHeader = true,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
  });

  final bool showPageHeader;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SessionViewModel sessionViewModel =
        ref.watch(sessionViewModelProvider);
    final ThemeData theme = Theme.of(context);
    final List<String> logs = sessionViewModel.diagnosticLogs;
    final List<DiagnosticLogEntry> entries = List<DiagnosticLogEntry>.generate(
      logs.length,
      (int index) {
        final int sourceIndex = logs.length - 1 - index;
        return DiagnosticLogEntry.fromLine(
          sequence: sourceIndex + 1,
          line: logs[sourceIndex],
        );
      },
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showPageHeader) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.text('logs.title'),
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.text('logs.description'),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionButtons(context, ref, logs, l10n),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...<Widget>[
            Container(
              width: double.infinity,
              color: AppTheme.sectionMutedOf(context),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildActionButtons(context, ref, logs, l10n),
              ),
            ),
            Divider(height: 1, color: AppTheme.borderOf(context)),
            const SizedBox(height: 12),
          ],
          DiagnosticLogOverviewView(entries: entries),
          const SizedBox(height: 16),
          Expanded(
            child: DiagnosticLogListView(entries: entries),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    List<String> logs,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: logs.isEmpty
              ? null
              : () {
                  ref.read(sessionViewModelProvider).clearDiagnosticLogs();
                },
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(l10n.text('chat.logs_clear')),
        ),
        OutlinedButton.icon(
          onPressed: logs.isEmpty ? null : () => _copyLogs(context, logs, l10n),
          icon: const Icon(Icons.copy_all_rounded),
          label: Text(l10n.text('chat.logs_copy')),
        ),
      ],
    );
  }

  Future<void> _copyLogs(
    BuildContext context,
    List<String> logs,
    AppLocalizations l10n,
  ) async {
    await Clipboard.setData(ClipboardData(text: logs.join('\n')));
    if (context.mounted) {
      TopNotificationOverlay.show(
        context,
        message: l10n.text('chat.logs_copied'),
        style: TopNotificationStyle.success,
      );
    }
  }
}
