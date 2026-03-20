import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/assistant/model/assistant_task.dart';
import '../../business/assistant/view_model/assistant_task_center_view_model.dart';
import '../../business/onboarding/view_model/onboarding_view_model.dart';
import '../../business/settings/view_model/settings_view_model.dart';
import '../../business/workspace/view_model/workspace_view_model.dart';
import '../../foundation/i18n/app_localizations.dart';
import '../../foundation/ui/app_panel.dart';
import '../config/app_theme.dart';

/// 总览页。
class OverviewPage extends ConsumerWidget {
  const OverviewPage({
    super.key,
    required this.onOpenChat,
    required this.onOpenProfiles,
    required this.onOpenConsole,
    required this.onOpenConfig,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenProfiles;
  final VoidCallback onOpenConsole;
  final VoidCallback onOpenConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final taskCenter = ref.watch(assistantTaskCenterViewModelProvider);
    final onboarding = ref.watch(onboardingViewModelProvider);
    final workspace = ref.watch(workspaceViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);

    final int totalTasks = taskCenter.tasks.length;
    final int failedTasks = taskCenter.tasks
        .where(
          (AssistantTask task) => task.status == AssistantTaskStatus.failed,
        )
        .length;
    final bool hasProfile = workspace.profiles.isNotEmpty;
    final AssistantTask? latestTask =
        taskCenter.tasks.isEmpty ? null : taskCenter.tasks.first;
    final nodeRuntimeInfo = onboarding.detectionResult?.nodeRuntimeInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.text('overview.title'),
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            l10n.text('overview.description'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _InlineAlert(
              message: hasProfile
                  ? l10n.text('overview.alert_ready')
                  : l10n.text('overview.alert_setup'),
              danger: !hasProfile,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: AppPanel(
                  title: l10n.text('overview.access_title'),
                  subtitle: l10n.text('overview.access_subtitle'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _FieldBlock(
                              label: l10n.text('overview.default_shell'),
                              value: settings.settings.defaultShell,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FieldBlock(
                              label: l10n.text('overview.default_profile'),
                              value: workspace.selectedProfile?.name ??
                                  l10n.text('setup.not_found'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _FieldBlock(
                              label: l10n.text('overview.profiles'),
                              value: workspace.profiles.length.toString(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FieldBlock(
                              label: l10n.text('overview.log_level'),
                              value: settings.settings.logLevel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _FieldBlock(
                              label: l10n.text('setup.node_version'),
                              value: nodeRuntimeInfo == null
                                  ? (onboarding.loading
                                      ? l10n.text('setup.detecting')
                                      : l10n.text('setup.not_found'))
                                  : (nodeRuntimeInfo.version ??
                                      l10n.text('setup.not_found')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FieldBlock(
                              label: l10n.text('setup.node_path'),
                              value: nodeRuntimeInfo == null
                                  ? l10n.text('setup.not_found')
                                  : (nodeRuntimeInfo.executablePath ??
                                      l10n.text('setup.not_found')),
                            ),
                          ),
                        ],
                      ),
                      if (nodeRuntimeInfo != null &&
                          (!nodeRuntimeInfo.isDetected ||
                              !nodeRuntimeInfo.isSatisfied)) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.warning),
                          ),
                          child: SelectableText(
                            '${l10n.text('overview.node_warning_title')}\n'
                            '${l10n.text('setup.node_requirement')}: '
                            '>= ${nodeRuntimeInfo.requiredVersion}\n'
                            '${l10n.text('setup.node_version')}: '
                            '${nodeRuntimeInfo.version ?? l10n.text('setup.not_found')}\n'
                            '${l10n.text('setup.node_path')}: '
                            '${nodeRuntimeInfo.executablePath ?? l10n.text('setup.not_found')}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton(
                            onPressed: onOpenChat,
                            child: Text(l10n.text('overview.open_chat')),
                          ),
                          OutlinedButton(
                            onPressed: onOpenProfiles,
                            child: Text(l10n.text('overview.manage_profiles')),
                          ),
                          OutlinedButton(
                            onPressed: onOpenConfig,
                            child: Text(l10n.text('overview.open_config')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 5,
                child: AppPanel(
                  title: l10n.text('overview.snapshot_title'),
                  subtitle: l10n.text('overview.snapshot_subtitle'),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _SnapshotCard(
                              label: l10n.text('overview.status'),
                              value: hasProfile
                                  ? l10n.text('shell.ready')
                                  : l10n.text('shell.setup_required'),
                              valueColor: hasProfile
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SnapshotCard(
                              label: l10n.text('overview.running_task'),
                              value: taskCenter.hasRunningTask
                                  ? l10n.text('common.yes')
                                  : l10n.text('common.no'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _SnapshotCard(
                              label: l10n.text('overview.last_task'),
                              value: latestTask?.title ??
                                  l10n.text('setup.not_found'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SnapshotCard(
                              label: l10n.text('overview.last_result'),
                              value: _taskStatusLabel(latestTask?.status, l10n),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: hasProfile
                              ? AppTheme.success.withValues(alpha: 0.08)
                              : AppTheme.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                hasProfile ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                        child: Text(
                          hasProfile
                              ? l10n.text('overview.ready_message')
                              : l10n.text('overview.needs_setup'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                hasProfile ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  label: l10n.text('overview.tasks_metric'),
                  value: totalTasks.toString(),
                  description: l10n.text('overview.tasks_desc'),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _MetricCard(
                  label: l10n.text('overview.profiles_metric'),
                  value: workspace.profiles.length.toString(),
                  description: l10n.text('overview.profiles_desc'),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _MetricCard(
                  label: l10n.text('overview.failed_metric'),
                  value: failedTasks.toString(),
                  description: l10n.text('overview.failed_desc'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppPanel(
            title: l10n.text('overview.notes_title'),
            subtitle: l10n.text('overview.notes_subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _NoteItem(
                  title: l10n.text('overview.note_profiles_title'),
                  description: l10n.text('overview.note_profiles_desc'),
                ),
                const SizedBox(height: 12),
                _NoteItem(
                  title: l10n.text('overview.note_chat_title'),
                  description: l10n.text('overview.note_chat_desc'),
                ),
                const SizedBox(height: 12),
                _NoteItem(
                  title: l10n.text('overview.note_console_title'),
                  description: l10n.text('overview.note_console_desc'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: onOpenProfiles,
                      child: Text(l10n.text('overview.go_profiles')),
                    ),
                    OutlinedButton(
                      onPressed: onOpenConsole,
                      child: Text(l10n.text('overview.open_console')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _taskStatusLabel(AssistantTaskStatus? status, AppLocalizations l10n) {
    return switch (status) {
      AssistantTaskStatus.running => l10n.text('status.running'),
      AssistantTaskStatus.completed => l10n.text('status.completed'),
      AssistantTaskStatus.failed => l10n.text('status.failed'),
      AssistantTaskStatus.stopped => l10n.text('status.stopped'),
      null => l10n.text('setup.not_found'),
    };
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message, required this.danger});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (danger ? AppTheme.danger : AppTheme.warning)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: danger ? AppTheme.danger : AppTheme.warning),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: danger ? AppTheme.danger : AppTheme.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelSecondary = AppTheme.panelSecondaryOf(context);
    final borderColor = AppTheme.borderOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: panelSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Text(value, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelSecondary = AppTheme.panelSecondaryOf(context);
    final borderColor = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: theme.textTheme.labelLarge),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: valueColor ?? textPrimary),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.description,
  });

  final String label;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  const _NoteItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
