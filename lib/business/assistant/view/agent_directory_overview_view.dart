import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_agent_directory_item.dart';

/// Agent 目录概览区。
///
/// 这里将“当前环境、当前 Agent、总量、默认项、模型”集中展示，
/// 让用户进入页面后先建立整体认知，再决定是否切换或查看会话。
class AgentDirectoryOverviewView extends StatelessWidget {
  const AgentDirectoryOverviewView({
    super.key,
    required this.profile,
    required this.selectedAgent,
    required this.selectedModelLabel,
    required this.totalAgents,
    required this.defaultAgents,
    required this.onOpenChat,
    required this.onOpenSessions,
  });

  final OpenClawProfile profile;
  final AssistantAgentDirectoryItem? selectedAgent;
  final String? selectedModelLabel;
  final int totalAgents;
  final int defaultAgents;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AssistantAgentDirectoryItem? agent = selectedAgent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.sectionMutedOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                agent?.displayLabel ?? l10n.text('agents.no_current_agent'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                agent?.description ?? l10n.text('agents.no_current_agent_desc'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _InfoChip(
                    label: l10n.text('agents.metric_environment'),
                    value: profile.name,
                    color: AppTheme.accent,
                  ),
                  _InfoChip(
                    label: l10n.text('agents.metric_workspace'),
                    value: agent?.workspace.isNotEmpty == true
                        ? agent!.workspace
                        : l10n.text('common.none'),
                    color: const Color(0xFF60A5FA),
                  ),
                  _InfoChip(
                    label: l10n.text('agents.metric_model'),
                    value: agent?.modelLabel ?? selectedModelLabel ?? 'n/a',
                    color: AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _MetricCard(
                    label: l10n.text('agents.metric_total'),
                    value: totalAgents.toString(),
                    icon: Icons.hub_outlined,
                    color: AppTheme.accent,
                  ),
                  _MetricCard(
                    label: l10n.text('agents.metric_default'),
                    value: defaultAgents.toString(),
                    icon: Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(l10n.text('agents.action_open_chat')),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenSessions,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.text('agents.action_open_sessions')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panelOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
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
