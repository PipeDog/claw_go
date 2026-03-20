import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../session/view_model/session_view_model.dart';
import '../../workspace/view_model/workspace_view_model.dart';
import '../model/assistant_chat_message.dart';
import '../model/assistant_task.dart';
import '../view/chat_recent_session_list_view.dart';
import '../view/chat_runtime_selector_card_view.dart';
import '../view/task_chat_timeline_view.dart';
import '../view/task_composer_view.dart';
import '../view_model/assistant_task_center_view_model.dart';
import '../view_model/chat_runtime_view_model.dart';

/// Chat 首页。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenTasks,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenTasks;
  final VoidCallback onOpenSettings;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _promptController = TextEditingController();

  static const double _kCompactWidthBreakpoint = 1080;
  static const double _kExpandedRecentPanelWidth = 280;
  static const double _kCollapsedRecentPanelWidth = 56;

  bool _recentSessionsExpanded = true;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AssistantTaskCenterViewModel taskCenter =
        ref.watch(assistantTaskCenterViewModelProvider);
    final ChatRuntimeViewModel chatRuntimeViewModel =
        ref.watch(chatRuntimeViewModelProvider);
    final SessionViewModel sessionViewModel =
        ref.watch(sessionViewModelProvider);
    final OpenClawProfile? selectedProfile =
        ref.watch(workspaceViewModelProvider).selectedProfile;
    final String currentAgentId =
        chatRuntimeViewModel.selectedAgentId ?? 'main';
    final String currentAgentLabel = _resolveAgentLabel(
      currentAgentId,
      chatRuntimeViewModel,
    );
    final List<AssistantTask> recentTasks = taskCenter.recentTasks();
    final List<AssistantChatMessage> activeMessages =
        taskCenter.chatMessagesForAgent(agentId: currentAgentId);
    final AssistantTask? revertedFromTask =
        taskCenter.chatRevertTargetForAgent(agentId: currentAgentId);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < _kCompactWidthBreakpoint;

        final Widget runtimeToolbar = ChatRuntimeSelectorCardView(
          agents: chatRuntimeViewModel.agents,
          models: chatRuntimeViewModel.models,
          selectedAgentId: chatRuntimeViewModel.selectedAgentId,
          selectedModelId: chatRuntimeViewModel.selectedModelId,
          loading: chatRuntimeViewModel.loading,
          onAgentChanged: (String? agentId) {
            if (agentId == null) {
              return;
            }
            ref.read(chatRuntimeViewModelProvider).selectAgent(agentId);
          },
          onModelChanged: (String? modelId) {
            if (modelId == null) {
              return;
            }
            Future<void>(() async {
              await ref.read(chatRuntimeViewModelProvider).selectModel(modelId);
              if (selectedProfile == null) {
                return;
              }
              final gatewayStatus = await ref
                  .read(sessionViewModelProvider)
                  .refreshGatewayStatus(selectedProfile);
              if (gatewayStatus.success &&
                  sessionViewModel.gatewayStatus.isRunning) {
                await ref
                    .read(sessionViewModelProvider)
                    .restartGateway(selectedProfile);
              }
            });
          },
        );

        final Widget recentSessionList = ChatRecentSessionListView(
          tasks: recentTasks,
          selectedTaskId: taskCenter.selectedTask?.id,
          currentAgentId: currentAgentId,
          onOpenAll: widget.onOpenTasks,
          showHeader: false,
          onSelect: (String taskId) async {
            final AssistantTask? task = taskCenter.findTaskById(taskId);
            if (task == null) {
              return;
            }
            final ChatRuntimeViewModel runtimeViewModel =
                ref.read(chatRuntimeViewModelProvider);
            if (task.agentId != currentAgentId &&
                runtimeViewModel.agents.any(
                  (item) => item.id == task.agentId,
                )) {
              await runtimeViewModel.selectAgent(task.agentId);
            }
            ref
                .read(assistantTaskCenterViewModelProvider)
                .openTaskInChat(taskId);
            if (mounted) {
              setState(() {});
            }
          },
          onRevert: (String taskId) async {
            final AssistantTask? task = taskCenter.findTaskById(taskId);
            if (task == null) {
              return;
            }
            final ChatRuntimeViewModel runtimeViewModel =
                ref.read(chatRuntimeViewModelProvider);
            if (task.agentId != currentAgentId &&
                runtimeViewModel.agents.any(
                  (item) => item.id == task.agentId,
                )) {
              await runtimeViewModel.selectAgent(task.agentId);
            }
            await ref
                .read(assistantTaskCenterViewModelProvider)
                .revertToTask(taskId);
            if (mounted) {
              setState(() {});
            }
          },
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderOf(context)),
          ),
          child: isCompact
              ? Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      color: AppTheme.sectionMutedOf(context),
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: runtimeToolbar,
                    ),
                    Divider(height: 1, color: AppTheme.borderOf(context)),
                    Expanded(
                      child: ColoredBox(
                        color: AppTheme.sectionCanvasOf(context),
                        child: TaskChatTimelineView(
                          messages: activeMessages,
                          agentLabel: currentAgentLabel,
                          revertedFromTaskTitle: revertedFromTask?.title,
                        ),
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.borderOf(context)),
                    Container(
                      width: double.infinity,
                      color: AppTheme.sectionMutedOf(context),
                      padding: const EdgeInsets.only(top: 8, right: 10),
                      child: TaskComposerView(
                        controller: _promptController,
                        loading: taskCenter.loading,
                        onSubmit: () => _submitPrompt(
                          taskCenter: taskCenter,
                          selectedAgentId: currentAgentId,
                        ),
                        onOpenTasks: widget.onOpenTasks,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: double.infinity,
                            color: AppTheme.sectionMutedOf(context),
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                            child: runtimeToolbar,
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.borderOf(context),
                          ),
                          Expanded(
                            child: ColoredBox(
                              color: AppTheme.sectionCanvasOf(context),
                              child: TaskChatTimelineView(
                                messages: activeMessages,
                                agentLabel: currentAgentLabel,
                                revertedFromTaskTitle: revertedFromTask?.title,
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.borderOf(context),
                          ),
                          Container(
                            width: double.infinity,
                            color: AppTheme.sectionMutedOf(context),
                            padding: const EdgeInsets.only(top: 8, right: 10),
                            child: TaskComposerView(
                              controller: _promptController,
                              loading: taskCenter.loading,
                              onSubmit: () => _submitPrompt(
                                taskCenter: taskCenter,
                                selectedAgentId: currentAgentId,
                              ),
                              onOpenTasks: widget.onOpenTasks,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: _recentSessionsExpanded
                          ? _kExpandedRecentPanelWidth
                          : _kCollapsedRecentPanelWidth,
                      child: _recentSessionsExpanded
                          ? _ExpandedRecentSessionRail(
                              count: recentTasks.length,
                              onOpenAll: widget.onOpenTasks,
                              onCollapse: () {
                                setState(() {
                                  _recentSessionsExpanded = false;
                                });
                              },
                              child: recentSessionList,
                            )
                          : _CollapsedRecentSessionRail(
                              count: recentTasks.length,
                              expandTooltip:
                                  '${l10n.text('common.expand')} ${l10n.text('chat.recent_sessions')}',
                              onExpand: () {
                                setState(() {
                                  _recentSessionsExpanded = true;
                                });
                              },
                              onOpenAll: widget.onOpenTasks,
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _resolveAgentLabel(
    String agentId,
    ChatRuntimeViewModel chatRuntimeViewModel,
  ) {
    for (final item in chatRuntimeViewModel.agents) {
      if (item.id == agentId) {
        return item.label;
      }
    }
    return agentId;
  }

  Future<void> _submitPrompt({
    required AssistantTaskCenterViewModel taskCenter,
    required String selectedAgentId,
  }) async {
    final String prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      return;
    }
    _promptController.clear();
    await ref.read(assistantTaskCenterViewModelProvider).submitPrompt(
          prompt: prompt,
          chatAgentId: selectedAgentId,
          chatSessionKey: taskCenter.resolveActiveChatSessionKey(
            agentId: selectedAgentId,
          ),
        );
  }
}

class _ExpandedRecentSessionRail extends StatelessWidget {
  const _ExpandedRecentSessionRail({
    required this.count,
    required this.onOpenAll,
    required this.onCollapse,
    required this.child,
  });

  final int count;
  final VoidCallback onOpenAll;
  final VoidCallback onCollapse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderOf(context),
        ),
        Expanded(
          child: Container(
            color: AppTheme.sectionMutedOf(context),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: <Widget>[
                _RecentRailHeader(
                  count: count,
                  onOpenAll: onOpenAll,
                  trailing: IconButton(
                    tooltip:
                        '${AppLocalizations.of(context).text('common.collapse')} ${AppLocalizations.of(context).text('chat.recent_sessions')}',
                    onPressed: onCollapse,
                    icon: const Icon(Icons.last_page_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsedRecentSessionRail extends StatelessWidget {
  const _CollapsedRecentSessionRail({
    required this.count,
    required this.expandTooltip,
    required this.onExpand,
    required this.onOpenAll,
  });

  final int count;
  final String expandTooltip;
  final VoidCallback onExpand;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderOf(context),
        ),
        Expanded(
          child: Container(
            color: AppTheme.sectionMutedOf(context),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                IconButton(
                  tooltip: expandTooltip,
                  onPressed: onExpand,
                  icon: const Icon(Icons.first_page_rounded),
                ),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: AppLocalizations.of(context).text('common.view_all'),
                  onPressed: onOpenAll,
                  icon: const Icon(Icons.history_rounded),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentRailHeader extends StatelessWidget {
  const _RecentRailHeader({
    required this.count,
    required this.onOpenAll,
    this.trailing,
  });

  final int count;
  final VoidCallback onOpenAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          AppLocalizations.of(context).text('chat.recent_sessions'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        IconButton(
          tooltip: AppLocalizations.of(context).text('common.view_all'),
          onPressed: onOpenAll,
          icon: const Icon(Icons.history_rounded),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
