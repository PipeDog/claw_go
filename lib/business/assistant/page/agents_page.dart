import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../session/view_model/session_view_model.dart';
import '../../workspace/view_model/workspace_view_model.dart';
import '../view/agent_diagnostics_view.dart';
import '../view/agent_directory_list_view.dart';
import '../view/agent_directory_overview_view.dart';
import '../view/agent_workspace_view.dart';
import '../view_model/agent_directory_view_model.dart';
import '../view_model/assistant_task_center_view_model.dart';
import '../view_model/chat_runtime_view_model.dart';

/// Agents 页面。
class AgentsPage extends ConsumerWidget {
  const AgentsPage({
    super.key,
    required this.onOpenChat,
    required this.onOpenSessions,
    required this.onOpenProfiles,
    required this.onOpenConnect,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenSessions;
  final VoidCallback onOpenProfiles;
  final VoidCallback onOpenConnect;

  static const double _kWideBreakpoint = 1180;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final agentDirectory = ref.watch(agentDirectoryViewModelProvider);
    final taskCenter = ref.watch(assistantTaskCenterViewModelProvider);
    final sessionViewModel = ref.watch(sessionViewModelProvider);
    ref.watch(chatRuntimeViewModelProvider);
    ref.watch(workspaceViewModelProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: !agentDirectory.hasProfile
                ? ColoredBox(
                    color: AppTheme.sectionCanvasOf(context),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _AgentsSection(
                        title: l10n.text('agents.empty_profile_title'),
                        subtitle: l10n.text('agents.empty_profile_desc'),
                        child: FilledButton.icon(
                          onPressed: onOpenProfiles,
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(
                            l10n.text('agents.action_open_profiles'),
                          ),
                        ),
                      ),
                    ),
                  )
                : agentDirectory.errorMessage != null &&
                        agentDirectory.items.isEmpty
                    ? ColoredBox(
                        color: AppTheme.sectionCanvasOf(context),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: _AgentsSection(
                            title: l10n.text(
                              'agents.diagnostics_panel_title',
                            ),
                            subtitle: l10n.text(
                              'agents.diagnostics_panel_subtitle',
                            ),
                            child: Text(agentDirectory.errorMessage!),
                          ),
                        ),
                      )
                    : ColoredBox(
                        color: AppTheme.sectionCanvasOf(context),
                        child: TabBarView(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: LayoutBuilder(
                                builder: (
                                  BuildContext context,
                                  BoxConstraints constraints,
                                ) {
                                  final bool isWide = constraints.maxWidth >=
                                      _kWideBreakpoint;
                                  final Widget overviewPanel = _AgentsSection(
                                    title: l10n.text(
                                      'agents.overview_title',
                                    ),
                                    subtitle: l10n.text(
                                      'agents.overview_subtitle',
                                    ),
                                    child: AgentDirectoryOverviewView(
                                      profile:
                                          agentDirectory.selectedProfile!,
                                      selectedAgent:
                                          agentDirectory.selectedAgent,
                                      selectedModelLabel:
                                          agentDirectory.selectedModelLabel,
                                      totalAgents: agentDirectory.totalAgents,
                                      defaultAgents:
                                          agentDirectory.defaultAgents,
                                      onOpenChat: onOpenChat,
                                      onOpenSessions: onOpenSessions,
                                    ),
                                  );

                                  final Widget listPanel = _AgentsSection(
                                    title: l10n.text('agents.list_title'),
                                    subtitle: l10n.text(
                                      'agents.list_subtitle',
                                    ),
                                    expandChild: true,
                                    child: AgentDirectoryListView(
                                      items: agentDirectory.items,
                                      loading: agentDirectory.loading,
                                      onSelectAgent: (String agentId) async {
                                        await ref
                                            .read(
                                              agentDirectoryViewModelProvider,
                                            )
                                            .selectAgent(agentId);
                                        await ref
                                            .read(
                                              chatRuntimeViewModelProvider,
                                            )
                                            .load();
                                      },
                                    ),
                                  );

                                  if (!isWide) {
                                    return ListView(
                                      children: <Widget>[
                                        overviewPanel,
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          height: 560,
                                          child: listPanel,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(flex: 5, child: overviewPanel),
                                      const SizedBox(width: 14),
                                      Expanded(flex: 6, child: listPanel),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: _AgentsSection(
                                title: l10n.text('agents.workspace_title'),
                                subtitle: l10n.text(
                                  'agents.workspace_subtitle',
                                ),
                                expandChild: true,
                                child: AgentWorkspaceView(
                                  selectedAgent: agentDirectory.selectedAgent,
                                  tasks: taskCenter
                                      .recentTasks(limit: 20)
                                      .where(
                                        (task) =>
                                            task.agentId ==
                                            (agentDirectory.selectedAgentId ??
                                                'main'),
                                      )
                                      .toList(),
                                  onOpenChat: onOpenChat,
                                  onOpenSessions: onOpenSessions,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: _AgentsSection(
                                title: l10n.text(
                                  'agents.diagnostics_panel_title',
                                ),
                                subtitle: l10n.text(
                                  'agents.diagnostics_panel_subtitle',
                                ),
                                expandChild: true,
                                child: AgentDiagnosticsView(
                                  gatewayStatus:
                                      sessionViewModel.gatewayStatus,
                                  connectionState:
                                      sessionViewModel.gatewayConnectionState,
                                  logs: sessionViewModel.diagnosticLogs,
                                  onOpenConnect: onOpenConnect,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AgentsSection extends StatelessWidget {
  const _AgentsSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.expandChild = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sectionMutedOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          if (expandChild)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: child,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
        ],
      ),
    );
  }
}
